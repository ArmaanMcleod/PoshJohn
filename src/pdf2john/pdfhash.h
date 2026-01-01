#ifndef PDFHASH_H
#define PDFHASH_H

#ifdef _WIN32
#ifdef PDFHASH_EXPORTS
// When building the DLL
#define PDFHASH_API __declspec(dllexport)
#elif defined(PDFHASH_STATIC)
// When building/using static lib or exe
#define PDFHASH_API
#else
// When consuming the DLL
#define PDFHASH_API __declspec(dllimport)
#endif
#else
// Linux/macOS: default visibility
#define PDFHASH_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    // Exported function
    PDFHASH_API char *get_pdf_hash(const char *path);
    PDFHASH_API void free_pdf_hash(char *ptr);
    typedef void (*log_callback_pdf_hash_t)(const char *message);
    PDFHASH_API void set_log_callback_pdf_hash(log_callback_pdf_hash_t callback);

#ifdef __cplusplus
}
#endif

#endif /* PDFHASH_H */
