#!/bin/bash
# =============================================================================
# Install Lemonade Server Script
# =============================================================================

set -o errexit
unset -o nounset

# Color codes
GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }

info "Starting Lemonade Server installation..."

# Check if already installed
if command -v lemonade &>/dev/null; then
    info "Lemonade already installed"
    lemonade --version
    exit 0
fi

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

info "Detected OS: $OS, Architecture: $ARCH"

# Download and install
case "$OS" in
    linux)
        curl -fsSL https://github.com/lemonade-server/lemonade/releases/latest/download/lemonade-linux -o /tmp/lemonade
        chmod +x /tmp/lemonade
        mv /tmp/lemonade /usr/local/bin/lemonade
        ;;
    darwin)
        curl -fsSL https://github.com/lemonade-server/lemonade/releases/latest/download/lemonade-darwin -o /tmp/lemonade
        chmod +x /tmp/lemonade
        mv /tmp/lemonade /usr/local/bin/lemonade
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

info "Lemonade Server installed successfully!"
lemonade --version
