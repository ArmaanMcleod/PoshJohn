#include <chrono>
#include <sstream>
#include <cstdlib>
#include "repack7z.h"
#include <iostream>

#include <filesystem>
#include <chrono>
#include <sstream>
#include <cstdlib>

#include <bit7z/bitarchivereader.hpp>
#include <bit7z/bitarchivewriter.hpp>

using namespace bit7z;

#ifdef _WIN32
const std::string libName = "7z.dll";
#elif __APPLE__
const std::string libName = "lib7z.dylib";
#else
const std::string libName = "lib7z.so";
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

int repack_7z_without_password(
    const std::string &inputPath,
    const std::string &password,
    const std::string &outputPath)
{
    std::cout << "[LOG] Input archive: " << inputPath << std::endl;
    std::cout << "[LOG] Output archive: " << outputPath << std::endl;
    std::filesystem::path tempDir = make_unique_temp_dir(outputPath);
    std::cout << "[LOG] Temp directory: " << tempDir << std::endl;
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
    } cleaner{tempDir};

    try
    {
        std::cout << "[LOG] Creating Bit7zLibrary..." << std::endl;
        Bit7zLibrary lib("C:\\Program Files\\7-Zip\\7z.dll");
        std::cout << "[LOG] Creating BitArchiveReader..." << std::endl;
        BitArchiveReader reader(lib, inputPath, BitFormat::SevenZip, password);

        std::cout << "[LOG] Creating temp directory..." << std::endl;
        std::filesystem::create_directory(tempDir);

        std::cout << "[LOG] Extracting archive to temp directory..." << std::endl;
        reader.extractTo(tempDir.string());

        std::cout << "[LOG] Creating BitArchiveWriter for output: " << outputPath << std::endl;
        BitArchiveWriter writer(lib, outputPath, BitFormat::SevenZip);

        int fileCount = 0;
        for (const auto &entry : std::filesystem::recursive_directory_iterator(tempDir))
        {
            if (entry.is_regular_file())
            {
                std::filesystem::path relativePath = std::filesystem::relative(entry.path(), tempDir);
                std::cout << "[LOG] Adding file to archive: " << entry.path() << " as " << relativePath << std::endl;
                writer.addFile(entry.path().string(), relativePath.string());
                ++fileCount;
            }
        }

        writer.compressTo(outputPath);

        std::cout << "[LOG] Total files added: " << fileCount << std::endl;

        // Check if output file exists
        if (std::filesystem::exists(outputPath))
        {
            std::cout << "[LOG] Output archive successfully created: " << outputPath << std::endl;
        }
        else
        {
            std::cout << "[LOG] Output archive was NOT created: " << outputPath << std::endl;
        }
    }
    catch (const bit7z::BitException &ex)
    {
        std::cerr << "bit7z exception: " << ex.what() << "\n";
        return 1;
    }
    catch (const std::exception &ex)
    {
        std::cerr << "Standard exception: " << ex.what() << "\n";
        return 1;
    }
    catch (...)
    {
        std::cerr << "Unknown exception occurred.\n";
        return 1;
    }

    return 0;
}
