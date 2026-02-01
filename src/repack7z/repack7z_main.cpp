#include <iostream>
#include <string>
#include "repack7z.h"

static void console_log_callback(const char *msg)
{
    if (std::string(msg).rfind("[ERROR]", 0) == 0)
    {
        std::cerr << msg << std::endl;
        return;
    }

    std::cout << msg << std::endl;
}

constexpr int MAX_ARGS = 4;

int main(int argc, char **argv)
{
    if (argc != MAX_ARGS)
    {
        std::cerr << "Usage: repack7z <input.7z> <password> <output.7z>\n";
        return REPACK7Z_ERROR_INVALID_ARGUMENT;
    }

    repack7z_set_log_callback(console_log_callback);

    std::string inputPath = argv[1];
    std::string password = argv[2];
    std::string outputPath = argv[3];

    repack7z_result result = repack_7z_without_password(
        inputPath.c_str(),
        password.c_str(),
        outputPath.c_str());

    if (result != REPACK7Z_OK)
    {
        std::cerr << "Repack failed with code: " << result << std::endl;
        return static_cast<int>(result);
    }

    std::cout << "Repack succeeded." << std::endl;
    return static_cast<int>(REPACK7Z_OK);
}
