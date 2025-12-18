#!/bin/bash

set -euo pipefail

MUPDF_REPO="https://github.com/ArtifexSoftware/mupdf.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/..")"
MUPDF_REPO_DIR="$REPO_PATH/mupdf"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "MUPDF_REPO_DIR: $MUPDF_REPO_DIR"

# Clean up any previous build
if [ -d "$MUPDF_REPO_DIR" ]; then
    echo "Removing previous MuPDF build at $MUPDF_REPO_DIR..."
    rm -rf "$MUPDF_REPO_DIR"
fi

# Clone MuPDF
mkdir -p "$MUPDF_REPO_DIR"
echo "Cloning MuPDF into $MUPDF_REPO_DIR..."
git clone --depth 1 "$MUPDF_REPO" "$MUPDF_REPO_DIR"

# Build MuPDF
cd "$MUPDF_REPO_DIR"
echo "Building MuPDF..."
git submodule update --init --depth 1
make build=release XCFLAGS="-msse4.1"
echo "MuPDF build completed."
