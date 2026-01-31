#!/bin/bash

set -euo pipefail

JOHN_REPO="https://github.com/openwall/john.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
JOHN_OUTPUT_DIR="$REPO_PATH/john"
JOHN_TEMP_DIR="$(mktemp -d)"
JOHN_SRC_DIR="$JOHN_TEMP_DIR/src"
JOHN_RUN_DIR="$JOHN_TEMP_DIR/run"
INSTALL_DEPS_SCRIPT="$SCRIPT_DIR/install-deps.sh"
FILTER_JOHN_SCRIPT="$SCRIPT_DIR/../shared/filter-john.sh"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_OUTPUT_DIR: $JOHN_OUTPUT_DIR"
echo "JOHN_TEMP_DIR: $JOHN_TEMP_DIR"
echo "JOHN_SRC_DIR: $JOHN_SRC_DIR"
echo "JOHN_RUN_DIR: $JOHN_RUN_DIR"
echo "INSTALL_DEPS_SCRIPT: $INSTALL_DEPS_SCRIPT"
echo "FILTER_JOHN_SCRIPT: $FILTER_JOHN_SCRIPT"

# Install dependencies
chmod +x $INSTALL_DEPS_SCRIPT
$INSTALL_DEPS_SCRIPT

# 6. Clone John the Ripper to temp directory
echo "Cloning John the Ripper into $JOHN_TEMP_DIR..."
git clone --depth 1 "$JOHN_REPO" "$JOHN_TEMP_DIR"

# 7. Build John the Ripper
cd "$JOHN_SRC_DIR"
echo "Configuring John the Ripper..."
chmod +x ./configure

# Use explicit /opt/homebrew paths for GCC and flags
HOMEBREW_PREFIX="/opt/homebrew"
GCC_BIN="$HOMEBREW_PREFIX/bin/$(ls $HOMEBREW_PREFIX/bin | grep -E '^gcc-[0-9]+$' | sort -V | tail -n1)"

./configure CC="$GCC_BIN" LDFLAGS="-L$HOMEBREW_PREFIX/lib" CPPFLAGS="-I$HOMEBREW_PREFIX/include" --disable-native-tests

echo "Cleaning previous builds..."
make -s clean

echo "Building John the Ripper..."
make -sj"$(sysctl -n hw.ncpu)"

echo "John the Ripper build complete. Binaries are in $JOHN_RUN_DIR"

# Strip unnecessary files to reduce package size
echo "Stripping unnecessary files..."
chmod +x $FILTER_JOHN_SCRIPT
"$FILTER_JOHN_SCRIPT" "$JOHN_RUN_DIR"

# Copy run directory contents to flat output directory
echo "Copying run directory to $JOHN_OUTPUT_DIR..."
mkdir -p "$JOHN_OUTPUT_DIR"
cp -r "$JOHN_RUN_DIR"/* "$JOHN_OUTPUT_DIR/"

echo "Cleaning up temp directory $JOHN_TEMP_DIR..."
rm -rf "$JOHN_TEMP_DIR"

echo "Build complete. John binaries are in $JOHN_OUTPUT_DIR"
