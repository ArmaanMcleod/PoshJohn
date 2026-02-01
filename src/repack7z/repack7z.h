#pragma once

#ifdef _WIN32
#define REPACK7Z_API __declspec(dllexport)
#else
#define REPACK7Z_API
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum repack7z_result
    {
        REPACK7Z_OK = 0,
        REPACK7Z_ERROR_INVALID_ARGUMENT = 1,
        REPACK7Z_ERROR_IO = 2,
        REPACK7Z_ERROR_FORMAT = 3,
        REPACK7Z_ERROR_INTERNAL = 4
    } repack7z_result;

    typedef void (*repack7z_log_callback)(const char *message);

    REPACK7Z_API void repack7z_set_log_callback(repack7z_log_callback cb);

    REPACK7Z_API repack7z_result repack_7z_without_password(
        const char *inputPath,
        const char *password,
        const char *outputPath);

#ifdef __cplusplus
}
#endif
