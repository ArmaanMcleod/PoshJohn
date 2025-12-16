#!/bin/bash

set -euo pipefail

# 1. Install Xcode command-line tools if not present
if ! xcode-select -p &>/dev/null; then
	echo "Xcode command-line tools not found. Installing..."
	xcode-select --install
	echo "Please re-run this script after Xcode CLI tools are installed."
	exit 1
else
	echo "Xcode command-line tools are installed."
fi

# 2. Check for Homebrew, install if missing
if ! command -v brew &>/dev/null; then
	echo "Homebrew not found. Please install Homebrew from https://brew.sh and re-run this script."
	exit 1
fi

# 3. Install Homebrew dependencies
echo "Checking and installing required Homebrew dependencies..."
REQUIRED_BREW_PKGS=(gcc openssl libpcap git wget)
for pkg in "${REQUIRED_BREW_PKGS[@]}"; do
	if ! brew list "$pkg" &>/dev/null; then
		echo "Installing $pkg..."
		brew install "$pkg"
	else
		echo "$pkg is already installed."
	fi
done

# 4. Recommend PATH update for Homebrew
BREW_PREFIX="$(brew --prefix)"
if [[ ":$PATH:" != *":$BREW_PREFIX/bin:"* ]]; then
	echo "[!] Consider adding $BREW_PREFIX/bin to your PATH for best results."
fi

JOHN_REPO="https://github.com/openwall/john.git"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/..")"
JOHN_DIR="$REPO_PATH/john/macos"
JOHN_SRC_DIR="$JOHN_DIR/src"
JOHN_RUN_DIR="$JOHN_DIR/run"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_DIR: $JOHN_DIR"
echo "JOHN_SRC_DIR: $JOHN_SRC_DIR"
echo "JOHN_RUN_DIR: $JOHN_RUN_DIR"

# 5. Clean up any previous build
if [ -d "$JOHN_DIR" ]; then
    echo "Removing previous John build at $JOHN_DIR..."
    rm -rf "$JOHN_DIR"
fi

# 6. Clone John the Ripper
mkdir -p "$JOHN_DIR"
echo "Cloning John the Ripper into $JOHN_DIR..."
git clone --depth 1 "$JOHN_REPO" "$JOHN_DIR"

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
KEEP_PATTERNS=("*.conf" "*.chr" "libcrypto*" "libssl*" "libz*" "libgmp*")
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
