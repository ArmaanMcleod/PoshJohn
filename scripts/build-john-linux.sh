#!/bin/bash

set -euo pipefail

# Check and install required system dependencies
echo "Checking and installing required system dependencies..."
REQUIRED_PKGS=(build-essential git libssl-dev zlib1g-dev python3 python3-venv python3-pip wget apt-transport-https software-properties-common)
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

JOHN_REPO="https://github.com/openwall/john.git"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
JOHN_DIR="$REPO_PATH/john/linux"
JOHN_SRC_DIR="$JOHN_DIR/src"
JOHN_RUN_DIR="$JOHN_DIR/run"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_DIR: $JOHN_DIR"
echo "JOHN_SRC_DIR: $JOHN_SRC_DIR"
echo "JOHN_RUN_DIR: $JOHN_RUN_DIR"

# Clean up any previous build
if [ -d "$JOHN_DIR" ]; then
    echo "Removing previous John build at $JOHN_DIR..."
    rm -rf "$JOHN_DIR"
fi

# Clone John the Ripper
mkdir -p "$JOHN_DIR"
echo "Cloning John the Ripper into $JOHN_DIR..."
git clone --depth 1 "$JOHN_REPO" "$JOHN_DIR"

# Build John the Ripper
cd "$JOHN_SRC_DIR"
echo "Configuring John the Ripper..."
chmod +x ./configure
./configure

echo "Cleaning previous builds..."
make -s clean

echo "Building John the Ripper..."
make -sj"$(nproc)"

echo "Ensuring all binaries are executable..."
chmod +x $JOHN_RUN_DIR/*

echo "John the Ripper build complete. Binaries are in $JOHN_RUN_DIR"

