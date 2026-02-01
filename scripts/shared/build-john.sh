#!/bin/bash

set -euo pipefail

JOHN_REPO="https://github.com/openwall/john.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
JOHN_OUTPUT_DIR="$REPO_PATH/john"
JOHN_TEMP_DIR="$(mktemp -d)"
JOHN_SRC_DIR="$JOHN_TEMP_DIR/src"
JOHN_RUN_DIR="$JOHN_TEMP_DIR/run"
FILTER_JOHN_SCRIPT="$SCRIPT_DIR/filter-john.sh"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_OUTPUT_DIR: $JOHN_OUTPUT_DIR"
echo "JOHN_TEMP_DIR: $JOHN_TEMP_DIR"
echo "JOHN_SRC_DIR: $JOHN_SRC_DIR"
echo "JOHN_RUN_DIR: $JOHN_RUN_DIR"
echo "FILTER_JOHN_SCRIPT: $FILTER_JOHN_SCRIPT"

# Clone John the Ripper to temp directory if not already present
if [ ! -d "$JOHN_TEMP_DIR/src" ]; then
	echo "Cloning John the Ripper into $JOHN_TEMP_DIR..."
	git clone --depth 1 "$JOHN_REPO" "$JOHN_TEMP_DIR"
else
	echo "John the Ripper source already present in $JOHN_TEMP_DIR, skipping clone."
fi

# Build John the Ripper
cd "$JOHN_SRC_DIR"
echo "Configuring John the Ripper..."
chmod +x ./configure

# Platform-specific configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS: Use Homebrew GCC
	HOMEBREW_PREFIX="/opt/homebrew"
	GCC_BIN="$HOMEBREW_PREFIX/bin/$(ls $HOMEBREW_PREFIX/bin | grep -E '^gcc-[0-9]+$' | sort -V | tail -n1)"
	./configure CC="$GCC_BIN" LDFLAGS="-L$HOMEBREW_PREFIX/lib" CPPFLAGS="-I$HOMEBREW_PREFIX/include" --disable-native-tests
	NCPU=$(sysctl -n hw.ncpu)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
	# Linux: Use default configuration
	./configure --disable-native-tests
	NCPU=$(nproc)
else
	# Fallback
	./configure --disable-native-tests
	NCPU=2
fi

echo "Cleaning previous builds..."
make -s clean

echo "Building John the Ripper..."
make -sj"$NCPU"

echo "John the Ripper build complete. Binaries are in $JOHN_RUN_DIR"

# Strip unnecessary files to reduce package size
echo "Stripping unnecessary files..."
chmod +x "$FILTER_JOHN_SCRIPT"
"$FILTER_JOHN_SCRIPT" "$JOHN_RUN_DIR"

# Copy run directory contents to flat output directory
echo "Copying run directory to $JOHN_OUTPUT_DIR..."
mkdir -p "$JOHN_OUTPUT_DIR"
cp -r "$JOHN_RUN_DIR"/* "$JOHN_OUTPUT_DIR/"

echo "Cleaning up temp directory $JOHN_TEMP_DIR..."
rm -rf "$JOHN_TEMP_DIR"

echo "Build complete. John binaries are in $JOHN_OUTPUT_DIR"
