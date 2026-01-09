#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "pdfhash.h"

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s [FILE_PATH]\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (access(argv[1], F_OK) != 0)
    {
        fprintf(stderr, "File does not exist or is not readable: %s\n", argv[1]);
        return EXIT_FAILURE;
    }

    char *hash = get_pdf_hash(argv[1]);
    if (hash == NULL)
    {
        fprintf(stderr, "Failed to extract hash from %s\n", argv[1]);
        return EXIT_FAILURE;
    }

    printf("%s\n", hash);
    free(hash);
    return EXIT_SUCCESS;
}
