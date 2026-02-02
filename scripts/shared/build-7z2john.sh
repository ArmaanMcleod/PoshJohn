#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"
JOHN_DIR="$REPO_PATH/john"
PERL_SCRIPT="$JOHN_DIR/7z2john.pl"
OUTPUT_DIR="$REPO_PATH/perl"
EXE_PATH="$OUTPUT_DIR/7z2john"

echo "Building 7z2john executable using PAR::Packer..."
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "REPO_PATH: $REPO_PATH"
echo "JOHN_DIR: $JOHN_DIR"
echo "PERL_SCRIPT: $PERL_SCRIPT"
echo "OUTPUT_DIR: $OUTPUT_DIR"
echo "EXE_PATH: $EXE_PATH"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if pp (PAR::Packer) is available
if ! command -v pp &> /dev/null; then
    echo "PAR::Packer (pp) not found. Installing..."
    perl -MCPAN -e 'install PAR::Packer'
fi

# Build executable using pp
echo "Packing Perl script into executable..."
pp -o "$EXE_PATH" "$PERL_SCRIPT"

echo "7z2john executable created at: $EXE_PATH"
