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

    REPACK7Z_API int repack_7z_without_password(
        const char *inputPath,   // encrypted .7z
        const char *password,    // password to decrypt
        const char *outputPath); // new unencrypted .7z

#ifdef __cplusplus
}
#endif

#include <string>

#include <string>
