#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
BIT7Z_DIR="$REPO_PATH/bit7z"
ARCHIVE7Z_DIR="$REPO_PATH/src/archive7z"
BIT7Z_REPO="https://github.com/rikyoz/bit7z.git"

echo "Building archive7z for macOS..."
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "BIT7Z_DIR: $BIT7Z_DIR"
echo "ARCHIVE7Z_DIR: $ARCHIVE7Z_DIR"

# Clone bit7z if not present
if [ ! -d "$BIT7Z_DIR" ]; then
    echo "Cloning bit7z repository..."
    git clone "$BIT7Z_REPO" "$BIT7Z_DIR" --depth 1
else
    echo "bit7z directory already exists, skipping clone."
fi

cd "$ARCHIVE7Z_DIR"

# Clean CMake cache to avoid path mismatch issues
if [ -d "build" ]; then
    echo "Cleaning existing CMake build directory..."
    rm -rf build
fi

mkdir -p build
cd build
cmake ..
cmake --build .

echo "archive7z built successfully."
