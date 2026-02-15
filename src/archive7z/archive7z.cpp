#include <filesystem>
#include <random>
#include <string>
#include <system_error>

#include "archive7z.h"

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
static archive7z_log_callback g_log_callback = nullptr;

/**
 * @brief Set the logging callback function.
 *
 * @param cb The callback function to use for logging.
 */
extern "C" ARCHIVE7Z_API void archive7z_set_log_callback(archive7z_log_callback cb)
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
 * @brief Get the Bit7zLibrary instance (singleton).
 *
 * @return Bit7zLibrary& Reference to the library instance.
 */
static Bit7zLibrary &get_library()
{
    static Bit7zLibrary lib(libName);
    return lib;
}

/**
 * @brief Validate and expand input/output paths.
 *
 * @param inputPath Input path to validate.
 * @param outputPath Output path to validate.
 * @param expandedInput Output parameter for expanded input path.
 * @param expandedOutput Output parameter for expanded output path.
 * @return archive7z_result Result code indicating success or error.
 */
static archive7z_result validate_and_expand_paths(
    const char *inputPath,
    const char *outputPath,
    std::string &expandedInput,
    std::string &expandedOutput)
{
    if (is_null_or_empty(inputPath))
    {
        log_msg("[ERROR] inputPath is null or empty");
        return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
    }

    if (is_null_or_empty(outputPath))
    {
        log_msg("[ERROR] outputPath is null or empty");
        return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
    }

    expandedInput = expand_user_path(inputPath);
    expandedOutput = expand_user_path(outputPath);

    std::error_code ec;
    if (!std::filesystem::exists(expandedInput, ec) || ec)
    {
        log_msg("[ERROR] Input path does not exist: " + expandedInput);
        return ARCHIVE7Z_ERROR_IO;
    }

    return ARCHIVE7Z_OK;
}

/**
 * @brief Add files from a directory to an archive writer recursively.
 *
 * @param writer The BitArchiveWriter to add files to.
 * @param basePath The base directory path.
 * @param filesAdded Output parameter for number of files added.
 * @return archive7z_result Result code indicating success or error.
 */
static archive7z_result add_files_from_directory(
    BitArchiveWriter &writer,
    const std::filesystem::path &basePath,
    int &filesAdded)
{
    for (const auto &entry : std::filesystem::recursive_directory_iterator(basePath))
    {
        if (entry.is_regular_file())
        {
            std::error_code ec;
            auto rel = std::filesystem::relative(entry.path(), basePath, ec);
            if (ec)
            {
                log_msg("[ERROR] Failed to compute relative path for: " + entry.path().string());
                return ARCHIVE7Z_ERROR_IO;
            }
            writer.addFile(entry.path().string(), rel.string());
            filesAdded++;
        }
    }
    return ARCHIVE7Z_OK;
}

/**
 * @brief Handle exceptions and return appropriate error code.
 *
 * @param ex Exception to handle.
 * @return archive7z_result Appropriate error code.
 */
static archive7z_result handle_exception(const std::exception *ex = nullptr)
{
    if (auto bitEx = dynamic_cast<const BitException *>(ex))
    {
        log_msg(std::string("[ERROR] bit7z exception: ") + bitEx->what());
        return ARCHIVE7Z_ERROR_FORMAT;
    }
    else if (ex)
    {
        log_msg(std::string("[ERROR] std::exception: ") + ex->what());
        return ARCHIVE7Z_ERROR_INTERNAL;
    }

    log_msg("[ERROR] Unknown exception");
    return ARCHIVE7Z_ERROR_INTERNAL;
}

/**
 * @brief Repack a 7z archive, removing password protection.
 *
 * @param inputPath Path to the input (possibly encrypted) .7z archive.
 * @param password  Password for the input archive (can be empty for unprotected archives).
 * @param outputPath Path to write the new unencrypted .7z archive.
 * @return archive7z_result Result code indicating success or error type.
 */
extern "C" ARCHIVE7Z_API archive7z_result repack_7z_without_password(
    const char *inputPath,
    const char *password,
    const char *outputPath)
{
    std::string inputPathStr, outputPathStr;
    archive7z_result result = validate_and_expand_paths(inputPath, outputPath, inputPathStr, outputPathStr);
    if (result != ARCHIVE7Z_OK)
    {
        return result;
    }

    std::string passwordStr = password ? password : "";

    log_msg("[LOG] Starting repack_7z_without_password");
    log_msg("[LOG] Input: " + inputPathStr);
    log_msg("[LOG] Output: " + outputPathStr);

    std::filesystem::path tempDir = make_unique_temp_dir(outputPathStr);
    log_msg("[LOG] Temp directory: " + tempDir.string());

    std::error_code ec;
    std::filesystem::create_directories(tempDir, ec);
    if (ec)
    {
        log_msg("[ERROR] Failed to create temp directory");
        return ARCHIVE7Z_ERROR_IO;
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
        Bit7zLibrary &lib = get_library();

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
        result = add_files_from_directory(writer, tempDir, fileCount);
        if (result != ARCHIVE7Z_OK)
        {
            return result;
        }

        log_msg("[LOG] Compressing...");
        writer.compressTo(outputPathStr);
        log_msg("[LOG] Files added: " + std::to_string(fileCount));
        log_msg("[LOG] Output archive created");

        return ARCHIVE7Z_OK;
    }
    catch (const std::exception &ex)
    {
        return handle_exception(&ex);
    }
    catch (...)
    {
        return handle_exception();
    }
}

/**
 * @brief Create a new password-protected 7z archive from an input path.
 *
 * @param inputPath Path to a file or directory to add to the archive. If a directory, all files are added recursively.
 * @param password Password to encrypt the archive (required, cannot be empty).
 * @param outputPath Path to write the new encrypted .7z archive.
 * @return archive7z_result Result code indicating success or error type.
 */
extern "C" ARCHIVE7Z_API archive7z_result create_7z_with_password(
    const char *inputPath,
    const char *password,
    const char *outputPath)
{
    if (is_null_or_empty(password))
    {
        log_msg("[ERROR] password is null or empty");
        return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
    }

    std::string inputPathStr, outputPathStr;
    archive7z_result result = validate_and_expand_paths(inputPath, outputPath, inputPathStr, outputPathStr);
    if (result != ARCHIVE7Z_OK)
    {
        return result;
    }

    std::string passwordStr = password;

    log_msg("[LOG] Starting create_7z_with_password");
    log_msg("[LOG] Input: " + inputPathStr);
    log_msg("[LOG] Output: " + outputPathStr);

    try
    {
        Bit7zLibrary &lib = get_library();

        BitArchiveWriter writer(lib, BitFormat::SevenZip);
        writer.setPassword(passwordStr);

        log_msg("[LOG] Adding files to archive...");

        std::filesystem::path fsPath(inputPathStr);
        int filesAdded = 0;

        if (std::filesystem::is_regular_file(fsPath))
        {
            writer.addFile(inputPathStr, fsPath.filename().string());
            filesAdded++;
            log_msg("[LOG] Added file: " + inputPathStr);
        }
        else if (std::filesystem::is_directory(fsPath))
        {
            result = add_files_from_directory(writer, fsPath, filesAdded);
            if (result != ARCHIVE7Z_OK)
            {
                return result;
            }
            log_msg("[LOG] Added directory contents: " + inputPathStr);
        }
        else
        {
            log_msg("[ERROR] Input path is neither a file nor a directory: " + inputPathStr);
            return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
        }

        if (filesAdded == 0)
        {
            log_msg("[ERROR] No files were added to the archive");
            return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
        }

        log_msg("[LOG] Compressing and encrypting...");
        writer.compressTo(outputPathStr);
        log_msg("[LOG] Files added: " + std::to_string(filesAdded));
        log_msg("[LOG] Encrypted archive created successfully");

        return ARCHIVE7Z_OK;
    }
    catch (const std::exception &ex)
    {
        return handle_exception(&ex);
    }
    catch (...)
    {
        return handle_exception();
    }
}
