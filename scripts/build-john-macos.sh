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

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
  REPO_PATH="$GITHUB_WORKSPACE"
else
  SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
fi

JOHN_DIR="$REPO_PATH/john/macos"
JOHN_SRC_DIR="$JOHN_DIR/src"
JOHN_RUN_DIR="$JOHN_DIR/run"

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

./configure CC="$GCC_BIN" LDFLAGS="-L$HOMEBREW_PREFIX/lib" CPPFLAGS="-I$HOMEBREW_PREFIX/include"

echo "Cleaning previous builds..."
make -s clean

echo "Building John the Ripper..."
make -sj"$(sysctl -n hw.ncpu)"

echo "Ensuring all binaries are executable..."
chmod +x $JOHN_RUN_DIR/*

echo "John the Ripper build complete. Binaries are in $JOHN_RUN_DIR"
