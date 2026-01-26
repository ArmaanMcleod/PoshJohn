#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "repack7z.h"

int main(int argc, char *argv[])
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <input.7z> <output.7z> <password>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *inputPath = argv[1];
    const char *outputPath = argv[2];
    const char *password = argv[3];

    if (access(inputPath, F_OK) != 0)
    {
        fprintf(stderr, "Input file does not exist or is not readable: %s\n", inputPath);
        return EXIT_FAILURE;
    }

    int result = repack_7z_without_password(inputPath, password, outputPath);
    if (result != 0)
    {
        fprintf(stderr, "Failed to repack 7z archive: %s\n", inputPath);
        return EXIT_FAILURE;
    }

    printf("Successfully repacked 7z archive to: %s\n", outputPath);
    return EXIT_SUCCESS;
}
