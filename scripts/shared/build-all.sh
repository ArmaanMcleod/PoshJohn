#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_PATH="$(realpath "$SCRIPT_DIR/../..")"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

PLATFORM_SCRIPTS="$REPO_PATH/scripts/$PLATFORM"
SHARED_SCRIPTS="$REPO_PATH/scripts/shared"

echo "========================================="
echo "Building all components for $PLATFORM"
echo "========================================="

# 1. Install dependencies once
echo ""
echo "==> Installing dependencies..."
bash "$PLATFORM_SCRIPTS/install-deps.sh"

# 2. Build components sequentially
echo ""
echo "==> Building John the Ripper..."
bash "$SHARED_SCRIPTS/build-john.sh"

echo ""
echo "==> Building 7z2john..."
bash "$SHARED_SCRIPTS/build-7z2john.sh"

echo ""
echo "==> Building repack7z..."
bash "$SHARED_SCRIPTS/build-repack7z.sh"

echo ""
echo "==> Building pdf2john..."
bash "$SHARED_SCRIPTS/build-pdf2john.sh"

echo ""
echo "========================================="
echo "All builds completed successfully!"
echo "========================================="
