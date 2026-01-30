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

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_OUTPUT_DIR: $JOHN_OUTPUT_DIR"
echo "JOHN_TEMP_DIR: $JOHN_TEMP_DIR"
echo "JOHN_SRC_DIR: $JOHN_SRC_DIR"
echo "JOHN_RUN_DIR: $JOHN_RUN_DIR"
echo "INSTALL_DEPS_SCRIPT: $INSTALL_DEPS_SCRIPT"

# Install dependencies
chmod +x $INSTALL_DEPS_SCRIPT
$INSTALL_DEPS_SCRIPT

# 5. Clean up any previous build
if [ -d "$JOHN_OUTPUT_DIR" ]; then
    echo "Removing previous John build at $JOHN_OUTPUT_DIR..."
    rm -rf "$JOHN_OUTPUT_DIR"
fi

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
cd "$JOHN_RUN_DIR"

# Count before
BEFORE_COUNT=$(find . -type f | wc -l | tr -d ' ')
if [ "$BEFORE_COUNT" -eq 0 ]; then
    echo "Error: No files found in $JOHN_RUN_DIR - build may have failed"
    exit 1
fi
BEFORE_SIZE=$(du -sm . | cut -f1)

# Define what to keep
KEEP_FILES=("john" "zip2john" "pdf2john.py")
KEEP_PATTERNS=("*.conf" "*.chr")
KEEP_DIRS=("lib" "rules")

# Remove root directory files except essential ones
find . -maxdepth 1 -type f | while read -r file; do
    basename="$(basename "$file")"
    keep=false

    # Check exact matches
    for name in "${KEEP_FILES[@]}"; do
        if [[ "$basename" == "$name" ]]; then
            keep=true
            break
        fi
    done

    # Check patterns
    if [ "$keep" = false ]; then
        for pattern in "${KEEP_PATTERNS[@]}"; do
            if [[ "$basename" == $pattern ]]; then
                keep=true
                break
            fi
        done
    fi

    if [ "$keep" = false ]; then
        rm -f "$file"
    fi
done

# Remove directories not in keep list
find . -maxdepth 1 -type d ! -name '.' | while read -r dir; do
    dirname="$(basename "$dir")"
    keep=false

    for keepdir in "${KEEP_DIRS[@]}"; do
        if [[ "$dirname" == "$keepdir" ]]; then
            keep=true
            break
        fi
    done

    if [ "$keep" = false ]; then
        rm -rf "$dir"
    fi
done

# Count after
AFTER_COUNT=$(find . -type f | wc -l | tr -d ' ')
if [ "$AFTER_COUNT" -eq 0 ]; then
    echo "Error: All files were removed from $JOHN_RUN_DIR - file removal logic may be incorrect"
    exit 1
fi
AFTER_SIZE=$(du -sm . | cut -f1)
SAVED=$((BEFORE_COUNT - AFTER_COUNT))
SIZE_SAVED=$((BEFORE_SIZE - AFTER_SIZE))

echo "Removed $SAVED files (saved ${SIZE_SAVED}MB)"
echo "Kept $AFTER_COUNT essential files (${AFTER_SIZE}MB) in $JOHN_RUN_DIR"

# Copy run directory contents to flat output directory
echo "Copying run directory to $JOHN_OUTPUT_DIR..."
mkdir -p "$JOHN_OUTPUT_DIR"
cp -r "$JOHN_RUN_DIR"/* "$JOHN_OUTPUT_DIR/"

echo "Cleaning up temp directory $JOHN_TEMP_DIR..."
rm -rf "$JOHN_TEMP_DIR"

echo "Build complete. John binaries are in $JOHN_OUTPUT_DIR"
