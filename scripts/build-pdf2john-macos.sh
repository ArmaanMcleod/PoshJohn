#!/bin/bash

set -euo pipefail

MUPDF_REPO="https://github.com/ArtifexSoftware/mupdf.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/..")"
MUPDF_REPO_DIR="$REPO_PATH/mupdf"
PDF2JOHN_DIR="$REPO_PATH/src/pdf2john"
INSTALL_DEPS_SCRIPT="$SCRIPT_DIR/install-deps-macos.sh"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "MUPDF_REPO_DIR: $MUPDF_REPO_DIR"
echo "PDF2JOHN_DIR: $PDF2JOHN_DIR"
echo "INSTALL_DEPS_SCRIPT: $INSTALL_DEPS_SCRIPT"

# Install dependencies
chmod +x $INSTALL_DEPS_SCRIPT
$INSTALL_DEPS_SCRIPT

# Clone MuPDF only if directory does not exist
if [ ! -d "$MUPDF_REPO_DIR" ]; then
    echo "Cloning MuPDF into $MUPDF_REPO_DIR..."
    git clone --depth 1 "$MUPDF_REPO" "$MUPDF_REPO_DIR"
else
    echo "MuPDF directory already exists at $MUPDF_REPO_DIR. Skipping clone."
fi

# Build MuPDF
cd "$MUPDF_REPO_DIR"
echo "Building MuPDF..."
git submodule update --init --recursive --depth 1

# Detect architecture and set appropriate flags
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
    echo "Detected x86_64 architecture, using SSE4.1 optimizations"
    XCFLAGS="-fPIC -msse4.1"
else
    echo "Detected $ARCH architecture, skipping x86-specific optimizations"
    XCFLAGS="-fPIC"
fi

# Limit parallelism on macOS to avoid resource exhaustion on CI runners
JOBS=2

make -j$JOBS build=release XCFLAGS="$XCFLAGS" libs
echo "MuPDF build completed."

# Build pdf2john
cd "$PDF2JOHN_DIR"
echo "Cleaning pdf2john build..."
make clean
echo "Building pdf2john..."
make -j$JOBS
echo "pdf2john build completed."
