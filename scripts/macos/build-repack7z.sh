#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
BIT7Z_DIR="$REPO_PATH/bit7z"
REPACK7Z_DIR="$REPO_PATH/src/repack7z"
BIT7Z_REPO="https://github.com/rikyoz/bit7z.git"

echo "Building repack7z for macOS..."
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "BIT7Z_DIR: $BIT7Z_DIR"
echo "REPACK7Z_DIR: $REPACK7Z_DIR"

# Clone bit7z if not present
if [ ! -d "$BIT7Z_DIR" ]; then
    echo "Cloning bit7z repository..."
    git clone "$BIT7Z_REPO" "$BIT7Z_DIR" --depth 1
else
    echo "bit7z directory already exists, skipping clone."
fi

cd "$REPACK7Z_DIR"

mkdir -p build
cd build
cmake ..
cmake --build .

echo "repack7z built successfully."
