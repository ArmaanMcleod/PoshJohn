#include <iostream>
#include <string>
#include "repack7z.h"

int main(int argc, char **argv)
{
    if (argc != 4)
    {
        std::cerr << "Usage: repack7z <input.7z> <password> <output.7z>\n";
        return EXIT_FAILURE;
    }

    std::string inputPath = argv[1];
    std::string password = argv[2];
    std::string outputPath = argv[3];

    int result = repack_7z_without_password(inputPath, password, outputPath);
    if (result != EXIT_SUCCESS)
    {
        std::cerr << "Repack failed with code: " << result << std::endl;
        return result;
    }

    std::cout << "Repack succeeded." << std::endl;
    return EXIT_SUCCESS;
}
