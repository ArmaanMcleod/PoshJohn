#!/bin/bash

set -euo pipefail


# Check and install required system dependencies
echo "Checking and installing required system dependencies..."
REQUIRED_PKGS=(build-essential gcc make pkg-config git libfreetype6-dev libjpeg-dev libopenjp2-7-dev zlib1g-dev)
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Installing missing packages: ${MISSING_PKGS[*]}"
    apt-get update
    apt-get install -y "${MISSING_PKGS[@]}"
else
    echo "All required packages are already installed."
fi

MUPDF_REPO="https://github.com/ArtifexSoftware/mupdf.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/..")"
MUPDF_REPO_DIR="$REPO_PATH/mupdf"
PDF2JOHN_DIR="$REPO_PATH/src/pdf2john"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "MUPDF_REPO_DIR: $MUPDF_REPO_DIR"
echo "PDF2JOHN_DIR: $PDF2JOHN_DIR"

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
make -j$(nproc) build=release XCFLAGS="-fPIC -msse4.1" libs
echo "MuPDF build completed."

cd "$PDF2JOHN_DIR"
echo "Cleaning pdf2john build..."
make clean
echo "Building libpdfhash.so..."
make -j$(nproc) libpdfhash.so
echo "Building pdf2john..."
make -j$(nproc)
echo "pdf2john build completed."
