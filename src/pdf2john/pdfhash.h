#ifndef PDFHASH_H
#define PDFHASH_H

#ifdef _WIN32
#ifdef PDFHASH_EXPORTS
// When building the DLL
#define PDFHASH_API __declspec(dllexport)
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

#ifdef __cplusplus
}
#endif

#endif /* PDFHASH_H */
