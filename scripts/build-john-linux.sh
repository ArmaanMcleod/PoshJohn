#!/bin/bash
# Build John the Ripper for Linux from the submodule

set -e

echo "Building John the Ripper for Linux..."

# Check for required tools and install if missing
if ! command -v gcc &> /dev/null; then
    echo "gcc not found. Installing build tools..."

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y build-essential libssl-dev zlib1g-dev
    elif command -v yum &> /dev/null; then
        sudo yum install -y gcc make openssl-devel zlib-devel
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y gcc make openssl-devel zlib-devel
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm base-devel openssl zlib
    else
        echo "Error: Could not detect package manager. Please install build tools manually:"
        echo "  Debian/Ubuntu: sudo apt-get install build-essential libssl-dev"
        echo "  RHEL/CentOS:   sudo yum install gcc make openssl-devel"
        echo "  Arch:          sudo pacman -S base-devel openssl"
        exit 1
    fi

    echo "Build tools installed successfully."
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
make -sj$(nproc)

# Copy binary
OUTPUT_DIR="$SCRIPT_DIR/../john-binaries/linux"
mkdir -p "$OUTPUT_DIR"

echo "Copying john binary to $OUTPUT_DIR..."
cp ../run/john "$OUTPUT_DIR/john"
chmod +x "$OUTPUT_DIR/john"

echo ""
echo "Build completed successfully!"
echo "Binary is at: $OUTPUT_DIR/john"
