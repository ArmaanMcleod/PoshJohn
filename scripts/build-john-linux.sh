#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., with sudo)"
  exit 1
fi


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

# Install PowerShell if not present
if ! command -v pwsh &> /dev/null; then
  echo "Installing PowerShell..."
  wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
  dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  apt-get update
  apt-get install -y powershell
else
  echo "PowerShell is already installed."
fi

JOHN_REPO="https://github.com/openwall/john.git"
JOHN_DIR="$(dirname "$0")/../john/linux"
SRC_DIR="$JOHN_DIR/src"

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
cd "$SRC_DIR"
echo "Configuring John the Ripper..."
chmod +x ./configure
./configure

echo "Building John the Ripper..."
make -sj"$(nproc)"

echo "John the Ripper build complete. Binaries are in $JOHN_DIR/run"
