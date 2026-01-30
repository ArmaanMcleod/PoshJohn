#pragma once

#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    DLL_EXPORT int repack_7z_without_password(
        const std::string &inputPath,   // encrypted .7z
        const std::string &password,    // password to decrypt
        const std::string &outputPath); // new unencrypted .7z

#ifdef __cplusplus
}
#endif

#include <string>

#include <string>
