#!/bin/bash
# Build John the Ripper for macOS from the submodule

set -e

echo "Building John the Ripper for macOS..."

# Check for required tools
if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
    echo "Error: No C compiler found. Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Check for OpenSSL (recommended)
if ! command -v brew &> /dev/null; then
    echo "Warning: Homebrew not found. OpenSSL support may be limited."
    echo "For best results, install Homebrew: https://brew.sh"
else
    if ! brew list openssl &> /dev/null 2>&1; then
        echo "Installing OpenSSL via Homebrew..."
        brew install openssl
    fi
fi

# Navigate to john source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOHN_SRC="$SCRIPT_DIR/../john/src"

if [ ! -d "$JOHN_SRC" ]; then
    echo "Error: John source not found at $JOHN_SRC"
    exit 1
fi

cd "$JOHN_SRC"

echo "Configuring..."
./configure

echo "Building (this may take a few minutes)..."
make -sj$(sysctl -n hw.ncpu)

# Copy binary
OUTPUT_DIR="$SCRIPT_DIR/../john-binaries/macos"
mkdir -p "$OUTPUT_DIR"

echo "Copying john binary to $OUTPUT_DIR..."
cp ../run/john "$OUTPUT_DIR/john"
chmod +x "$OUTPUT_DIR/john"

echo ""
echo "Build completed successfully!"
echo "Binary is at: $OUTPUT_DIR/john"
