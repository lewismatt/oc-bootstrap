#!/bin/bash
# =============================================================================
# OpenClaw Bootstrap - Helper Functions
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print info message
function info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print success message
function success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Print warning message
function warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Print error message
function error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
function is_root() {
    [[ $EUID -eq 0 ]]
}

# Get OS type
function get_os() {
    uname -s | tr '[:upper:]' '[:lower:]'
}

# Get architecture
function get_arch() {
    uname -m
}

# Retry a command multiple times
function retry() {
    local retries=$1
    shift
    local count=0
    until "$@"; do
        exit=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            warn "Command failed, retrying ($count/$retries)..."
            sleep 1
        else
            error "Command failed after $retries attempts"
            return $exit
        fi
    done
}

# Confirm action with user
function confirm() {
    local prompt="${1:-Are you sure?}"
    read -p "$prompt [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Create directory if it doesn't exist
function ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        info "Created directory: $dir"
    fi
}

# Backup a file if it exists
function backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        info "Backed up: $file -> $backup"
    fi
}
