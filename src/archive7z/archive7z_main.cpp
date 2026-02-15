#include <iostream>
#include <string>
#include "archive7z.h"

/**
 * @brief Console logging callback that prints messages to stdout/stderr.
 *
 * @param msg The message to log.
 */
static void console_log_callback(const char *msg)
{
    if (std::string(msg).rfind("[ERROR]", 0) == 0)
    {
        std::cerr << msg << std::endl;
        return;
    }

    std::cout << msg << std::endl;
}

constexpr int MIN_ARGS = 5;

// Command options
constexpr const char *CMD_REPACK_WITHOUT_PASSWORD = "repack-without-password";
constexpr const char *CMD_CREATE_WITH_PASSWORD = "create-with-password";

/**
 * @brief Print usage information.
 */
static void print_usage()
{
    std::cerr << "Usage: archive7z <command> <input> <password> <output>\n\n";
    std::cerr << "Commands:\n";
    std::cerr << "  " << CMD_REPACK_WITHOUT_PASSWORD << "       Remove password protection from a 7z archive\n";
    std::cerr << "  " << CMD_CREATE_WITH_PASSWORD << "          Create a new password-protected 7z archive\n";
    std::cerr << "\nExamples:\n";
    std::cerr << "  archive7z " << CMD_REPACK_WITHOUT_PASSWORD << " input.7z mypass output.7z\n";
    std::cerr << "  archive7z " << CMD_CREATE_WITH_PASSWORD << " folder/ mypass archive.7z\n";
}

/**
 * @brief Main function for the archive7z utility.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return int Exit code.
 */
int main(int argc, char **argv)
{
    if (argc < MIN_ARGS)
    {
        print_usage();
        return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
    }

    archive7z_set_log_callback(console_log_callback);

    std::string command = argv[1];
    std::string inputPath = argv[2];
    std::string password = argv[3];
    std::string outputPath = argv[4];

    archive7z_result result;

    if (command == CMD_REPACK_WITHOUT_PASSWORD)
    {
        result = repack_7z_without_password(
            inputPath.c_str(),
            password.c_str(),
            outputPath.c_str());

        if (result != ARCHIVE7Z_OK)
        {
            std::cerr << "Repack failed with code: " << result << std::endl;
            return static_cast<int>(result);
        }

        std::cout << "Repack succeeded." << std::endl;
    }
    else if (command == CMD_CREATE_WITH_PASSWORD)
    {
        result = create_7z_with_password(
            inputPath.c_str(),
            password.c_str(),
            outputPath.c_str());

        if (result != ARCHIVE7Z_OK)
        {
            std::cerr << "Create archive failed with code: " << result << std::endl;
            return static_cast<int>(result);
        }

        std::cout << "Archive created successfully." << std::endl;
    }
    else
    {
        std::cerr << "Unknown command: " << command << "\n\n";
        print_usage();
        return ARCHIVE7Z_ERROR_INVALID_ARGUMENT;
    }

    return static_cast<int>(ARCHIVE7Z_OK);
}
