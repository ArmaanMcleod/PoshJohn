#pragma once

#ifdef _WIN32
#define ARCHIVE7Z_API __declspec(dllexport)
#else
#define ARCHIVE7Z_API
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum archive7z_result
    {
        ARCHIVE7Z_OK = 0,
        ARCHIVE7Z_ERROR_INVALID_ARGUMENT = 1,
        ARCHIVE7Z_ERROR_IO = 2,
        ARCHIVE7Z_ERROR_FORMAT = 3,
        ARCHIVE7Z_ERROR_INTERNAL = 4
    } archive7z_result;

    typedef void (*archive7z_log_callback)(const char *message);

    ARCHIVE7Z_API void archive7z_set_log_callback(archive7z_log_callback cb);

    ARCHIVE7Z_API archive7z_result repack_7z_without_password(
        const char *inputPath,
        const char *password,
        const char *outputPath);

    ARCHIVE7Z_API archive7z_result create_7z_with_password(
        const char *inputPath,
        const char *password,
        const char *outputPath);

#ifdef __cplusplus
}
#endif
