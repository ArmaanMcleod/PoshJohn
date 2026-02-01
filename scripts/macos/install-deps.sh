#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

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

PKG_FILE="$SCRIPT_DIR/packages.txt"
if [ ! -f "$PKG_FILE" ]; then
    echo "Package file $PKG_FILE not found!"
    exit 1
fi

echo "Checking and installing required system dependencies from $PKG_FILE..."
brew install $(cat "$PKG_FILE")

# Install PAR::Packer via CPAN
echo "Installing PAR::Packer via CPAN..."
cpan -i PAR::Packer
