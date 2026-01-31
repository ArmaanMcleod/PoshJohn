#include <filesystem>
#include <chrono>
#include <sstream>
#include <cstdlib>
#include <iostream>

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

// Helper to create a unique temp directory path based on outputPath's basename
std::filesystem::path make_unique_temp_dir(const std::string &outputPath)
{
    auto basename = std::filesystem::path(outputPath).stem().string();
    auto now = std::chrono::system_clock::now().time_since_epoch().count();
    std::srand(static_cast<unsigned int>(now));
    int random = std::rand();
    std::ostringstream oss;
    oss << basename << "_" << now << "_" << random;
    return std::filesystem::temp_directory_path() / oss.str();
}

std::string expand_user_path(const std::string &path)
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
            std::string expandedPath = std::string(home) + path.substr(1);
            std::cout << "[LOG] Expanded path " << path << " to " << expandedPath << std::endl;
            return expandedPath;
        }
    }
    return path;
}

DLL_EXPORT int repack_7z_without_password(
    const std::string &inputPath,
    const std::string &password,
    const std::string &outputPath)
{
    try
    {
        std::cout << "[LOG] Starting repack_7z_without_password" << std::endl;
        std::cout << "[LOG] Input archive: " << inputPath << std::endl;
        std::cout << "[LOG] Output archive: " << outputPath << std::endl;

        struct TempDirCleaner
        {
            std::filesystem::path dir;
            ~TempDirCleaner()
            {
                if (!dir.empty() && std::filesystem::exists(dir))
                {
                    std::cout << "[LOG] Cleaning up temp directory: " << dir << std::endl;
                    std::filesystem::remove_all(dir);
                }
            }
        };

        std::string inputPathExpanded = expand_user_path(inputPath);
        std::string outputPathExpanded = expand_user_path(outputPath);

        std::filesystem::path tempDir = make_unique_temp_dir(outputPathExpanded);
        std::cout << "[LOG] Created temp directory path: " << tempDir << std::endl;
        TempDirCleaner cleaner{tempDir};

        if (!std::filesystem::exists(inputPathExpanded))
        {
            std::cerr << "[ERROR] Input archive does not exist: " << inputPathExpanded << std::endl;
            throw std::filesystem::filesystem_error(
                "Input archive does not exist",
                inputPathExpanded,
                std::make_error_code(std::errc::no_such_file_or_directory));
        }

        std::cout << "[LOG] Loading 7-Zip library: " << libName << std::endl;
        Bit7zLibrary lib(libName);
        BitArchiveReader reader(lib, inputPathExpanded, BitFormat::SevenZip, password);
        std::cout << "[LOG] Creating temp directory on disk..." << std::endl;
        std::filesystem::create_directory(tempDir);

        std::cout << "[LOG] Extracting archive to temp directory..." << std::endl;
        reader.extractTo(tempDir.string());
        std::cout << "[LOG] Extraction completed." << std::endl;

        BitArchiveWriter writer(lib, outputPath, BitFormat::SevenZip);
        writer.setOverwriteMode(OverwriteMode::Overwrite);
        int fileCount = 0;
        for (const auto &entry : std::filesystem::recursive_directory_iterator(tempDir))
        {
            if (entry.is_regular_file())
            {
                auto relativePath = std::filesystem::relative(entry.path(), tempDir);
                std::cout << "[LOG] Adding file to archive: " << entry.path() << " as " << relativePath << std::endl;
                writer.addFile(entry.path().string(), relativePath.string());
                fileCount++;
            }
        }
        std::cout << "[LOG] Compressing files to output archive..." << std::endl;
        writer.compressTo(outputPathExpanded);
        std::cout << "[LOG] Total files added: " << fileCount << std::endl;
        std::cout << "[LOG] Output archive successfully created: " << outputPathExpanded << std::endl;
        return EXIT_SUCCESS;
    }
    catch (const bit7z::BitException &ex)
    {
        std::cerr << "[ERROR] bit7z exception: " << ex.what() << std::endl;
    }
    catch (const std::filesystem::filesystem_error &ex)
    {
        std::cerr << "[ERROR] Filesystem error: " << ex.what() << std::endl;
    }
    catch (const std::exception &ex)
    {
        std::cerr << "[ERROR] Standard exception: " << ex.what() << std::endl;
    }
    catch (...)
    {
        std::cerr << "[ERROR] Unknown exception occurred." << std::endl;
    }
    std::cerr << "[LOG] repack_7z_without_password failed." << std::endl;
    return EXIT_FAILURE;
}
