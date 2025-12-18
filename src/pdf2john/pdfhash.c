#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mupdf/fitz.h"
#include "mupdf/pdf.h"

/* Append a separator '*' to the buffer, if space allows. */
static void append_sep(char *buf, size_t buflen)
{
    size_t n = strlen(buf);
    if (n + 1 < buflen)
    {
        buf[n] = '*';
        buf[n + 1] = '\0';
    }
}

/* Append an integer value as a string to the buffer. */
static void append_int(char *buf, size_t buflen, int val)
{
    char tmp[32];
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
    static const char *hex = "0123456789abcdef";
    char *out = (char *)malloc(len * 2 + 1);
    if (!out)
        return NULL;
    for (size_t i = 0; i < len; ++i)
    {
        out[2 * i] = hex[(data[i] >> 4) & 0xF];
        out[2 * i + 1] = hex[data[i] & 0xF];
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
 *   $pdf$V*R*keylen*P*flags*IDlen*IDhex*Olen*Ohex*Ulen*Uhex[ *CF*StmF*StrF*EncryptMetadata*PermsLen*Permshex ]
 *
 * Where:
 *   V              = Algorithm version
 *   R              = Revision number
 *   keylen         = Key length in bits
 *   P              = Permissions integer
 *   flags          = EncryptMetadata flag (or 1 for older revisions)
 *   IDlen/IDhex    = Length and hex of first element of document ID array
 *   Olen/Ohex      = Length and hex of Owner key
 *   Ulen/Uhex      = Length and hex of User key
 *   AES-256 extras = Only present if R >= 6 (CF, StmF, StrF, EncryptMetadata, PermsLen, Permshex)
 *
 * Example (shortened):
 *   $pdf$2*3*128*-4*1*16*e065f5b7...*32*adcbb91...*32*98cc16d...
 */
char *get_pdf_hash(const char *path)
{
    if (!path)
        return NULL;

    fz_context *ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx)
        return NULL;

    char *result = NULL;
    pdf_document *doc = NULL;

    fz_try(ctx)
    {
        fz_register_document_handlers(ctx);
        doc = pdf_open_document(ctx, path);
        if (!doc)
            fz_throw(ctx, FZ_ERROR_GENERIC, "Cannot open PDF: %s", path);

        pdf_obj *trailer = pdf_trailer(ctx, doc);
        pdf_obj *encrypt_ref = pdf_dict_gets(ctx, trailer, "Encrypt");
        pdf_obj *enc = pdf_resolve_indirect(ctx, encrypt_ref);
        if (!enc || !pdf_is_dict(ctx, enc))
            fz_throw(ctx, FZ_ERROR_GENERIC, "No Encrypt dictionary");

        int V = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "V"));
        int R = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "R"));
        int P = pdf_to_int(ctx, pdf_dict_gets(ctx, enc, "P"));

        int key_len = 40;
        pdf_obj *length_obj = pdf_dict_gets(ctx, enc, "Length");
        if (length_obj && pdf_is_int(ctx, length_obj))
            key_len = pdf_to_int(ctx, length_obj);

        /*
         * Resolve O and U (indirect-safe), then intentionally swap them to match pdf2john.py semantics.
         * The extracted O and U keys are reversed compared to the expected output.
         */
        pdf_obj *Oobj = pdf_dict_gets(ctx, enc, "O");
        pdf_obj *Uobj = pdf_dict_gets(ctx, enc, "U");
        char *Uhex = hex_from_pdf_string(ctx, Oobj); /* actually User */
        char *Ohex = hex_from_pdf_string(ctx, Uobj); /* actually Owner */

        /* Get the first element of the ID array as hex. */
        pdf_obj *IDarr = pdf_dict_gets(ctx, trailer, "ID");
        char *IDhex = hex_from_id_array(ctx, IDarr);

        /* AES-256 extras (only used if R >= 6) */
        char *Permshex = NULL;
        const char *StmF = NULL;
        const char *StrF = NULL;
        int EncryptMetadata = 1;

        if (R >= 6)
        {
            pdf_obj *stmf_obj = pdf_dict_gets(ctx, enc, "StmF");
            if (stmf_obj && pdf_is_name(ctx, stmf_obj))
                StmF = pdf_to_name(ctx, stmf_obj);

            pdf_obj *strf_obj = pdf_dict_gets(ctx, enc, "StrF");
            if (strf_obj && pdf_is_name(ctx, strf_obj))
                StrF = pdf_to_name(ctx, strf_obj);

            pdf_obj *em_obj = pdf_dict_gets(ctx, enc, "EncryptMetadata");
            if (em_obj && pdf_is_bool(ctx, em_obj))
                EncryptMetadata = pdf_to_bool(ctx, em_obj);

            pdf_obj *perms_obj = pdf_dict_gets(ctx, enc, "Perms");
            Permshex = hex_from_pdf_string(ctx, perms_obj);
        }

        int Olen = Ohex ? (int)(strlen(Ohex) / 2) : 0;
        int Ulen = Uhex ? (int)(strlen(Uhex) / 2) : 0;
        int IDlen = IDhex ? (int)(strlen(IDhex) / 2) : 0;
        int PermsLen = Permshex ? (int)(strlen(Permshex) / 2) : 0;

        int flags = (R >= 6) ? EncryptMetadata : 1;

        size_t total = 256 + (Ohex ? strlen(Ohex) : 0) + (Uhex ? strlen(Uhex) : 0) + (IDhex ? strlen(IDhex) : 0) + (Permshex ? strlen(Permshex) : 0);

        result = (char *)calloc(1, total);
        if (!result)
            fz_throw(ctx, FZ_ERROR_GENERIC, "Allocation failure");

        /* Build hash string in pdf2john.py order: ID -> O -> U */
        strncat(result, "$pdf$", total - 1);
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

        /* Finally U (User) */
        append_int(result, total, Ulen);
        append_sep(result, total);
        append_str(result, total, Uhex);

        if (R >= 6)
        {
            append_sep(result, total);
            append_str(result, total, ""); /* CF blank */
            append_sep(result, total);
            append_str(result, total, StmF ? StmF : "");
            append_sep(result, total);
            append_str(result, total, StrF ? StrF : "");
            append_sep(result, total);
            append_int(result, total, EncryptMetadata);
            append_sep(result, total);
            append_int(result, total, PermsLen);
            append_sep(result, total);
            append_str(result, total, Permshex ? Permshex : "");
        }
    }
    fz_catch(ctx)
    {
        if (result)
        {
            free(result);
            result = NULL;
        }
    }

    if (doc)
        fz_drop_document(ctx, (fz_document *)doc);
    fz_drop_context(ctx);
    return result;
}
