#pragma once

#include <string>

int repack_7z_without_password(
    const std::string &inputPath,   // encrypted .7z
    const std::string &password,    // password to decrypt
    const std::string &outputPath); // new unencrypted .7z
