#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mupdf/fitz.h"
#include "mupdf/pdf.h"

#include "pdfhash.h"

/* PDF Standard Security Handler revision numbers */
#define PDF_REVISION_AES256 5 /* Revision 5 introduced AES-256 encryption with OE/UE keys */

/* Buffer size for integer to string conversion (INT_MIN = -2147483648 = 11 chars + null) */
#define INT_STRING_BUFFER_SIZE 16

/* Hex digit lookup table for lowercase hex conversion */
static const char HEX_DIGITS[] = "0123456789abcdef";

/* Separator character used in the hash string */
#define BUFFER_SEPARATOR '*'

/* Default encryption key length in bits for older PDF revisions */
#define DEFAULT_KEY_LENGTH_BITS 40

/* Hash format prefix for PDF password hashes */
#define HASH_PREFIX "$pdf$"

/* Base buffer size for hash string (for prefix, separators, integers, etc.) */
#define HASH_BASE_BUFFER_SIZE 256

/* Default value for EncryptMetadata flag (1 = metadata is encrypted) */
#define DEFAULT_ENCRYPT_METADATA 1

// Logging callback support
static log_callback_pdf_hash_t g_log_callback = NULL;

/* Set the logging callback function */
PDFHASH_API void set_log_callback_pdf_hash(log_callback_pdf_hash_t callback)
{
    g_log_callback = callback;
}

/* Internal logging function */
static void log_message(const char *msg)
{
    if (g_log_callback)
        g_log_callback(msg);
}

/* Append a separator '*' to the buffer, if space allows. */
static void append_sep(char *buf, size_t buflen)
{
    size_t n = strlen(buf);
    if (n + 1 < buflen)
    {
        buf[n] = BUFFER_SEPARATOR;
        buf[n + 1] = '\0';
    }
}

/* Append an integer value as a string to the buffer. */
static void append_int(char *buf, size_t buflen, int val)
{
    char tmp[INT_STRING_BUFFER_SIZE];
    snprintf(tmp, sizeof(tmp), "%d", val);
    strncat(buf, tmp, buflen - strlen(buf) - 1);
}

/* Append a string to the buffer, handling NULL as empty string. */
static void append_str(char *buf, size_t buflen, const char *s)
{
    if (!s)
        s = "";
    strncat(buf, s, buflen - strlen(buf) - 1);
}

/* Convert binary data to a lowercase hexadecimal string. */
static char *hex_lower(const unsigned char *data, size_t len)
{
    char *out = (char *)malloc(len * 2 + 1);
    if (!out)
        return NULL;

    for (size_t i = 0; i < len; ++i)
    {
        out[2 * i] = HEX_DIGITS[(data[i] >> 4) & 0xF];
        out[2 * i + 1] = HEX_DIGITS[data[i] & 0xF];
    }

    out[len * 2] = '\0';

    return out;
}

/* Convert a PDF string object to a lowercase hexadecimal string. */
static char *hex_from_pdf_string(fz_context *ctx, pdf_obj *str_obj)
{
    if (!str_obj)
        return NULL;

    pdf_obj *o = pdf_resolve_indirect(ctx, str_obj);
    if (!o || !pdf_is_string(ctx, o))
        return NULL;

    size_t len = pdf_to_str_len(ctx, o);

    const char *bytes = pdf_to_str_buf(ctx, o);

    return hex_lower((const unsigned char *)bytes, len);
}

/*
 * Convert the first element of a PDF ID array to a lowercase hexadecimal string.
 */
static char *hex_from_id_array(fz_context *ctx, pdf_obj *id_obj)
{
    if (!id_obj || !pdf_is_array(ctx, id_obj) || pdf_array_len(ctx, id_obj) < 1)
        return NULL;

    pdf_obj *id0 = pdf_array_get(ctx, id_obj, 0); /* First element */

    return hex_from_pdf_string(ctx, id0);
}

/*
 * Build a PDF password hash string in the same format as pdf2john.py.
 *
 * Output format:
 *   $pdf$V*R*keylen*P*flags*IDlen*IDhex*Olen*Ohex*Ulen*Uhex[ *OElen*OEhex*UElen*UEhex ]
 *
 * Where:
 *   V              = Algorithm version
 *   R              = Revision number
 *   keylen         = Key length in bits
 *   P              = Permissions integer
 *   flags          = EncryptMetadata flag (defaults to 1 if not present)
 *   IDlen/IDhex    = Length and hex of first element of document ID array
 *   Olen/Ohex      = Length and hex of Owner key
 *   Ulen/Uhex      = Length and hex of User key
 *   AES-256 only   = OElen/OEhex (Owner Encryption seed), UElen/UEhex (User Encryption seed)
 *
 * Example (shortened):
 *   $pdf$2*3*128*-4*1*16*e065f5b7...*32*adcbb91...*32*98cc16d...
 */
PDFHASH_API char *get_pdf_hash(const char *path)
{
    if (!path)
    {
        log_message("[pdfhash] ERROR: path is NULL");
        fprintf(stderr, "[pdfhash] ERROR: path is NULL\n");
        return NULL;
    }

    fz_context *ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx)
    {
        log_message("[pdfhash] ERROR: failed to create context");
        fprintf(stderr, "[pdfhash] ERROR: failed to create context\n");
        return NULL;
    }

    char *result = NULL;
    pdf_document *doc = NULL;
    char *Uhex = NULL;
    char *Ohex = NULL;
    char *IDhex = NULL;
    char *OEhex = NULL;
    char *UEhex = NULL;

    fz_try(ctx)
    {
        fz_register_document_handlers(ctx);
        doc = pdf_open_document(ctx, path);
        if (!doc)
        {
            log_message("[pdfhash] ERROR: Cannot open PDF");
            fprintf(stderr, "[pdfhash] ERROR: Cannot open PDF: %s\n", path);
            fz_throw(ctx, FZ_ERROR_GENERIC, "Cannot open PDF: %s", path);
        }

        pdf_obj *trailer = pdf_trailer(ctx, doc);
        if (!trailer)
        {
            log_message("[pdfhash] ERROR: trailer is NULL");
            fprintf(stderr, "[pdfhash] ERROR: trailer is NULL\n");
            fz_throw(ctx, FZ_ERROR_GENERIC, "No trailer");
        }

        pdf_obj *encrypt_ref = pdf_dict_gets(ctx, trailer, "Encrypt");
        pdf_obj *enc = pdf_resolve_indirect(ctx, encrypt_ref);
        if (!enc || !pdf_is_dict(ctx, enc))
        {
            log_message("[pdfhash] ERROR: No Encrypt dictionary");
            fprintf(stderr, "[pdfhash] ERROR: No Encrypt dictionary\n");
            fz_throw(ctx, FZ_ERROR_GENERIC, "No Encrypt dictionary");
        }

        int V = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "V"));
        int R = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "R"));
        int P = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "P"));

        int key_len = DEFAULT_KEY_LENGTH_BITS;
        pdf_obj *length_obj = pdf_dict_gets(ctx, enc, "Length");
        if (length_obj && pdf_is_int(ctx, length_obj))
            key_len = pdf_to_int(ctx, length_obj);

        /*
         * Resolve O and U (indirect-safe), then intentionally swap them to match pdf2john.py semantics.
         * The extracted O and U keys are reversed compared to the expected output.
         */
        pdf_obj *Oobj = pdf_dict_gets(ctx, enc, "O");
        pdf_obj *Uobj = pdf_dict_gets(ctx, enc, "U");
        Uhex = hex_from_pdf_string(ctx, Oobj); /* actually User */
        Ohex = hex_from_pdf_string(ctx, Uobj); /* actually Owner */
        if (!Uhex || !Ohex)
        {
            log_message("[pdfhash] ERROR: Ohex or Uhex is NULL");
            fprintf(stderr, "[pdfhash] ERROR: Ohex or Uhex is NULL\n");
            fz_throw(ctx, FZ_ERROR_GENERIC, "Ohex or Uhex is NULL");
        }

        pdf_obj *IDarr = pdf_dict_gets(ctx, trailer, "ID");
        IDhex = hex_from_id_array(ctx, IDarr);
        if (!IDhex)
        {
            log_message("[pdfhash] ERROR: IDhex is NULL");
            fprintf(stderr, "[pdfhash] ERROR: IDhex is NULL\n");
            fz_throw(ctx, FZ_ERROR_GENERIC, "IDhex is NULL");
        }

        /* For AES-256 encryption, also extract OE and UE */
        if (R >= PDF_REVISION_AES256)
        {
            pdf_obj *OEobj = pdf_dict_gets(ctx, enc, "OE");
            pdf_obj *UEobj = pdf_dict_gets(ctx, enc, "UE");
            OEhex = hex_from_pdf_string(ctx, OEobj);
            UEhex = hex_from_pdf_string(ctx, UEobj);
        }

        /* Read EncryptMetadata flag (defaults to 1 if not present) */
        int flags = DEFAULT_ENCRYPT_METADATA;
        pdf_obj *em_obj = pdf_dict_gets(ctx, enc, "EncryptMetadata");
        if (em_obj && pdf_is_bool(ctx, em_obj))
            flags = pdf_to_bool(ctx, em_obj);

        int Olen = Ohex ? (int)(strlen(Ohex) / 2) : 0;
        int Ulen = Uhex ? (int)(strlen(Uhex) / 2) : 0;
        int IDlen = IDhex ? (int)(strlen(IDhex) / 2) : 0;
        int OElen = OEhex ? (int)(strlen(OEhex) / 2) : 0;
        int UElen = UEhex ? (int)(strlen(UEhex) / 2) : 0;

        size_t total = HASH_BASE_BUFFER_SIZE +
                       (Ohex ? strlen(Ohex) : 0) +
                       (Uhex ? strlen(Uhex) : 0) +
                       (IDhex ? strlen(IDhex) : 0) +
                       (OEhex ? strlen(OEhex) : 0) +
                       (UEhex ? strlen(UEhex) : 0);

        result = (char *)calloc(1, total);
        if (!result)
        {
            log_message("[pdfhash] ERROR: Allocation failure");
            fprintf(stderr, "[pdfhash] ERROR: Allocation failure\n");
            fz_throw(ctx, FZ_ERROR_GENERIC, "Allocation failure");
        }

        /* Build hash string in pdf2john.py order: ID -> O -> U (-> OE -> UE for AES-256) */
        strncat(result, HASH_PREFIX, total - 1);
        append_int(result, total, V);
        append_sep(result, total);
        append_int(result, total, R);
        append_sep(result, total);
        append_int(result, total, key_len);
        append_sep(result, total);
        append_int(result, total, P);
        append_sep(result, total);
        append_int(result, total, flags);
        append_sep(result, total);

        /* ID first */
        append_int(result, total, IDlen);
        append_sep(result, total);
        append_str(result, total, IDhex);
        append_sep(result, total);

        /* Then O (Owner) */
        append_int(result, total, Olen);
        append_sep(result, total);
        append_str(result, total, Ohex);
        append_sep(result, total);

        /* Then U (User) */
        append_int(result, total, Ulen);
        append_sep(result, total);
        append_str(result, total, Uhex);

        /* For AES-256 encryption, append OE and UE */
        if (R >= PDF_REVISION_AES256)
        {
            /* OE (oeseed) */
            if (OEhex)
            {
                append_sep(result, total);
                append_int(result, total, OElen);
                append_sep(result, total);
                append_str(result, total, OEhex);
            }

            /* UE (ueseed) */
            if (UEhex)
            {
                append_sep(result, total);
                append_int(result, total, UElen);
                append_sep(result, total);
                append_str(result, total, UEhex);
            }
        }
    }

    fz_always(ctx)
    {
        /* Free only if allocated, then set to NULL for safety */
        if (Uhex)
        {
            free(Uhex);
            Uhex = NULL;
        }
        if (Ohex)
        {
            free(Ohex);
            Ohex = NULL;
        }
        if (IDhex)
        {
            free(IDhex);
            IDhex = NULL;
        }
        if (OEhex)
        {
            free(OEhex);
            OEhex = NULL;
        }
        if (UEhex)
        {
            free(UEhex);
            UEhex = NULL;
        }

        /* Drop document last, after all MuPDF object usage is done */
        if (doc)
        {
            fz_drop_document(ctx, (fz_document *)doc);
            doc = NULL;
        }
        /* Do NOT drop context here; do it after fz_catch. */
    }
    fz_catch(ctx)
    {
        if (result)
        {
            free(result);
            result = NULL;
        }
    }

    /* Now safe to drop context after fz_catch */
    if (ctx)
    {
        fz_drop_context(ctx);
    }

    return result;
}

/* Free the allocated PDF hash string */
PDFHASH_API void free_pdf_hash(char *ptr)
{
    free(ptr);
}
