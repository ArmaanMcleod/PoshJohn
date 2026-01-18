#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

PKG_FILE="$SCRIPT_DIR/packages-linux.txt"
if [ ! -f "$PKG_FILE" ]; then
    echo "Package file $PKG_FILE not found!"
    exit 1
fi

echo "Checking and installing required system dependencies from $PKG_FILE..."
apt-get update -y && apt-get install -y $(cat "$PKG_FILE")
