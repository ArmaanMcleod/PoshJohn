#ifndef REPACK7Z_H
#define REPACK7Z_H

#ifdef _WIN32
#ifdef REPACK7Z_EXPORTS
// When building the DLL
#define REPACK7Z_API __declspec(dllexport)
#elif defined(REPACK7Z_STATIC)
// When building/using static lib or exe
#define REPACK7Z_API
#else
// When consuming the DLL
#define REPACK7Z_API __declspec(dllimport)
#endif
#else
// Linux/macOS: default visibility
#define REPACK7Z_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    // Exported function
    REPACK7Z_API int repack_7z_without_password(
        const char *inputPath, // UTF-8 path to encrypted .7z
        const char *password,  // UTF-8 password
        const char *outputPath // UTF-8 path to new unencrypted .7z
    );
#ifdef __cplusplus
}
#endif

#endif /* REPACK7Z_H */
