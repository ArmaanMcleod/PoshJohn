#include <filesystem>
#include <random>
#include <string>
#include <system_error>

#include "repack7z.h"

#include <bit7z/bitarchivereader.hpp>
#include <bit7z/bitarchivewriter.hpp>

using namespace bit7z;

#if defined(_WIN64)
const std::string libName = "C:/Program Files/7-Zip/7z.dll";
#elif defined(_WIN32)
const std::string libName = "C:/Program Files (x86)/7-Zip/7z.dll";
#elif defined(__linux__)
const std::string libName = "/usr/lib/p7zip/7z.so";
#elif defined(__APPLE__)
const std::string libName = "/usr/local/lib/lib7z.dylib";
#endif

/**
 * @brief Global logging callback function pointer.
 */
static repack7z_log_callback g_log_callback = nullptr;

/**
 * @brief Set the logging callback function.
 *
 * @param cb The callback function to use for logging.
 */
extern "C" REPACK7Z_API void repack7z_set_log_callback(repack7z_log_callback cb)
{
    g_log_callback = cb;
}

/**
 * @brief Internal logging function that invokes the registered callback.
 *
 * @param msg The message to log.
 */
static void log_msg(const std::string &msg)
{
    if (g_log_callback)
    {
        g_log_callback(msg.c_str());
    }
}

/**
 * @brief Check if a C-string is null or empty.
 *
 * @param s The C-string to check.
 * @return true if the string is null or empty, false otherwise.
 */
static bool is_null_or_empty(const char *s)
{
    return s == nullptr || s[0] == '\0';
}

/**
 * @brief Expand a file path that may start with '~' to the user's home directory.
 *
 * @param path The input file path.
 * @return std::string The expanded file path.
 */
static std::string expand_user_path(const std::string &path)
{
    if (!path.empty() && path[0] == '~')
    {
#if defined(_WIN32)
        const char *home = std::getenv("USERPROFILE");
#else
        const char *home = std::getenv("HOME");
#endif
        if (home)
        {
            return std::string(home) + path.substr(1);
        }
    }
    return path;
}

/**
 * @brief Generate a random hexadecimal string of specified length.
 *
 * @param length Length of the desired hex string (default is 24).
 * @return std::string Random hexadecimal string.
 */
static std::string random_hex_string(std::size_t length = 24)
{
    static thread_local std::mt19937_64 rng{std::random_device{}()};
    static const char *hex = "0123456789abcdef";

    std::string out;
    out.reserve(length);
    for (std::size_t i = 0; i < length; ++i)
    {
        out.push_back(hex[rng() & 0xF]);
    }
    return out;
}

/**
 * @brief Create a unique temporary directory path based on the output path.
 *
 * @param outputPath The desired output path for the final archive.
 * @return std::filesystem::path A unique temporary directory path.
 */
static std::filesystem::path make_unique_temp_dir(const std::string &outputPath)
{
    auto base = std::filesystem::path(outputPath).stem().string();
    auto tempRoot = std::filesystem::temp_directory_path();
    std::string name = base + "_" + random_hex_string();
    return tempRoot / name;
}

/**
 * @brief Repack a 7z archive, removing password protection.
 *
 * @param inputPath Path to the input (possibly encrypted) .7z archive.
 * @param password  Password for the input archive (can be empty for unprotected archives).
 * @param outputPath Path to write the new unencrypted .7z archive.
 * @return repack7z_result Result code indicating success or error type.
 */
extern "C" REPACK7Z_API repack7z_result repack_7z_without_password(
    const char *inputPath,
    const char *password,
    const char *outputPath)
{
    if (is_null_or_empty(inputPath))
    {
        log_msg("[ERROR] inputPath is null or empty");
        return REPACK7Z_ERROR_INVALID_ARGUMENT;
    }

    if (is_null_or_empty(outputPath))
    {
        log_msg("[ERROR] outputPath is null or empty");
        return REPACK7Z_ERROR_INVALID_ARGUMENT;
    }

    std::string passwordStr = password ? password : "";

    std::string inputPathStr = expand_user_path(inputPath);
    std::string outputPathStr = expand_user_path(outputPath);

    log_msg("[LOG] Starting repack_7z_without_password");
    log_msg("[LOG] Input: " + inputPathStr);
    log_msg("[LOG] Output: " + outputPathStr);

    std::error_code ec;
    if (!std::filesystem::exists(inputPathStr, ec) || ec)
    {
        log_msg("[ERROR] Input archive does not exist: " + inputPathStr);
        return REPACK7Z_ERROR_IO;
    }

    std::filesystem::path tempDir = make_unique_temp_dir(outputPathStr);
    log_msg("[LOG] Temp directory: " + tempDir.string());

    std::filesystem::create_directories(tempDir, ec);
    if (ec)
    {
        log_msg("[ERROR] Failed to create temp directory");
        return REPACK7Z_ERROR_IO;
    }

    struct TempDirCleaner
    {
        std::filesystem::path dir;
        ~TempDirCleaner()
        {
            if (dir.empty())
                return;
            std::error_code ec2;
            std::filesystem::remove_all(dir, ec2);
        }
    } cleaner{tempDir};

    try
    {
        static Bit7zLibrary lib(libName);

        log_msg("[LOG] Extracting archive...");
        BitArchiveReader reader(lib, inputPathStr, BitFormat::SevenZip, passwordStr);
        reader.extractTo(tempDir.string());
        log_msg("[LOG] Extraction complete");

        if (std::filesystem::exists(outputPathStr, ec) && !ec)
        {
            std::filesystem::remove(outputPathStr, ec);
        }

        BitArchiveWriter writer(lib, outputPathStr, BitFormat::SevenZip);

        int fileCount = 0;
        for (const auto &entry : std::filesystem::recursive_directory_iterator(tempDir))
        {
            if (entry.is_regular_file())
            {
                auto rel = std::filesystem::relative(entry.path(), tempDir, ec);
                if (ec)
                {
                    log_msg("[ERROR] Failed to compute relative path");
                    return REPACK7Z_ERROR_IO;
                }
                writer.addFile(entry.path().string(), rel.string());
                fileCount++;
            }
        }

        log_msg("[LOG] Compressing...");
        writer.compressTo(outputPathStr);
        log_msg("[LOG] Files added: " + std::to_string(fileCount));
        log_msg("[LOG] Output archive created");

        return REPACK7Z_OK;
    }
    catch (const bit7z::BitException &ex)
    {
        log_msg(std::string("[ERROR] bit7z exception: ") + ex.what());
        return REPACK7Z_ERROR_FORMAT;
    }
    catch (const std::exception &ex)
    {
        log_msg(std::string("[ERROR] std::exception: ") + ex.what());
        return REPACK7Z_ERROR_INTERNAL;
    }
    catch (...)
    {
        log_msg("[ERROR] Unknown exception");
        return REPACK7Z_ERROR_INTERNAL;
    }
}
