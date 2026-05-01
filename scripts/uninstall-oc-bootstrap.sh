#!/bin/bash
# ==============================================================================
# OpenClaw Multi-Agent Uninstall Script
# ==============================================================================
# Safely removes all files and directories created by oc-bootstrap.sh
#
# Usage:
#   ./uninstall-oc-bootstrap.sh                          # Interactive mode
#   ./uninstall-oc-bootstrap.sh --yes                    # Skip confirmations
#   ./uninstall-oc-bootstrap.sh --preserve-workspaces    # Keep agent workspaces
#
# ==============================================================================

set -euo pipefail
set +o histexpand

# ==============================================================================
# CONSTANTS & CONFIGURATION
# ==============================================================================

OPENCLAW_DIR="$HOME/.openclaw"

# Parse command-line arguments
SKIP_CONFIRMATIONS=false
PRESERVE_WORKSPACES=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --yes | -y)
        SKIP_CONFIRMATIONS=true
        shift
        ;;
    --preserve-workspaces | -p)
        PRESERVE_WORKSPACES=true
        shift
        ;;
    --help | -h)
        echo "OpenClaw Multi-Agent Uninstall Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -y, --yes                Skip confirmation prompts (use with caution)"
        echo "  -p, --preserve-workspaces  Keep agent workspaces (SOUL.md, AGENTS.md, etc.)"
        echo "  -h, --help               Show this help message"
        echo ""
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--yes] [--preserve-workspaces]"
        exit 1
        ;;
    esac
done

# ==============================================================================
# COLOR OUTPUT HELPERS
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[?]${NC} $1"
}

# ==============================================================================
# CONFIRMATION FUNCTION
# ==============================================================================

confirm() {
    local message="$1"
    local default="${2:-N}"

    if [[ "$SKIP_CONFIRMATIONS" == "true" ]]; then
        return 0
    fi

    print_question "$message"
    read -r -p "Proceed? (y/N): " response </dev/tty
    response="${response:-$default}"
    if [[ "${response^^}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# CHECK FUNCTIONS
# ==============================================================================

check_openclaw_installed() {
    command -v openclaw &>/dev/null
}

get_openclaw_version() {
    if check_openclaw_installed; then
        openclaw --version 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

# ==============================================================================
# MAIN UNINSTALL LOGIC
# ==============================================================================

echo ""
echo "OpenClaw Multi-Agent Uninstall Script"
echo "=============================================================================="
echo ""

# Show current state
print_header "Current Installation State"
echo "OpenClaw version: $(get_openclaw_version)"
echo "OpenClaw directory: $OPENCLAW_DIR"

if [[ -d "$OPENCLAW_DIR" ]]; then
    echo "Directory exists: Yes"
    echo "Directory size: $(du -sh "$OPENCLAW_DIR" 2>/dev/null | cut -f1)"

    # Count items
    if [[ -d "$OPENCLAW_DIR/workspace-assistant" ]]; then
        echo "  - Assistant workspace: Present"
    fi
    if [[ -d "$OPENCLAW_DIR/workspace-research" ]]; then
        echo "  - Research workspace: Present"
    fi
    if [[ -d "$OPENCLAW_DIR/workspace-developer" ]]; then
        echo "  - Developer workspace: Present"
    fi
    if [[ -f "$OPENCLAW_DIR/secrets.env" ]]; then
        echo "  - Secrets file: Present"
    fi
    if [[ -d "$OPENCLAW_DIR/memory" ]]; then
        echo "  - Memory index: Present"
    fi
else
    echo "Directory exists: No"
fi

echo ""

# ==============================================================================
# STEP 1: STOP GATEWAY (if running)
# ==============================================================================

print_header "Step 1: Stopping OpenClaw Gateway"

if check_openclaw_installed; then
    if openclaw gateway status &>/dev/null; then
        print_info "Gateway is running. Attempting to stop..."
        if openclaw gateway stop 2>/dev/null; then
            print_info "Gateway stopped successfully."
        else
            print_warn "Could not stop gateway (may not be running or may require manual intervention)."
        fi
    else
        print_info "Gateway is not running."
    fi
else
    print_info "OpenClaw not installed, skipping gateway stop."
fi

# ==============================================================================
# STEP 2: REMOVE AGENT WORKSPACES
# ==============================================================================

print_header "Step 2: Agent Workspaces"

WORKSPACES=(
    "$OPENCLAW_DIR/workspace-assistant"
    "$OPENCLAW_DIR/workspace-research"
    "$OPENCLAW_DIR/workspace-developer"
)

if [[ "$PRESERVE_WORKSPACES" == "true" ]]; then
    print_info "Preserving agent workspaces (--preserve-workspaces flag set)."
else
    for workspace in "${WORKSPACES[@]}"; do
        if [[ -d "$workspace" ]]; then
            workspace_name=$(basename "$workspace")
            print_question "Found: $workspace"

            if confirm "Delete $workspace_name?"; then
                rm -rf "$workspace"
                print_info "Deleted: $workspace"
            else
                print_info "Skipped: $workspace"
            fi
        fi
    done
fi

# ==============================================================================
# STEP 3: REMOVE SECRETS FILE
# ==============================================================================

print_header "Step 3: Secrets File"

SECRETS_FILE="$OPENCLAW_DIR/secrets.env"
if [[ -f "$SECRETS_FILE" ]]; then
    print_question "Found secrets file: $SECRETS_FILE"
    print_warn "This file contains Telegram bot tokens and API keys!"

    if confirm "Delete secrets.env?"; then
        rm -f "$SECRETS_FILE"
        print_info "Deleted: $SECRETS_FILE"
    else
        print_info "Skipped: $SECRETS_FILE"
    fi
else
    print_info "No secrets file found."
fi

# ==============================================================================
# STEP 4: REMOVE MEMORY INDEX
# ==============================================================================

print_header "Step 4: Memory Index"

MEMORY_DIR="$OPENCLAW_DIR/memory"
if [[ -d "$MEMORY_DIR" ]]; then
    print_question "Found memory index: $MEMORY_DIR"
    print_info "Size: $(du -sh "$MEMORY_DIR" 2>/dev/null | cut -f1)"

    if confirm "Delete memory index?"; then
        rm -rf "$MEMORY_DIR"
        print_info "Deleted: $MEMORY_DIR"
    else
        print_info "Skipped: $MEMORY_DIR"
    fi
else
    print_info "No memory index found."
fi

# ==============================================================================
# STEP 5: REMOVE LOGS
# ==============================================================================

print_header "Step 5: Log Files"

LOGS_DIR="$OPENCLAW_DIR/logs"
if [[ -d "$LOGS_DIR" ]]; then
    print_question "Found logs directory: $LOGS_DIR"
    print_info "Size: $(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1)"

    if confirm "Delete logs?"; then
        rm -rf "$LOGS_DIR"
        print_info "Deleted: $LOGS_DIR"
    else
        print_info "Skipped: $LOGS_DIR"
    fi
else
    print_info "No logs directory found."
fi

# ==============================================================================
# STEP 6: REMOVE OPENCLAW CONFIGURATION
# ==============================================================================

print_header "Step 6: OpenClaw Configuration"

OPENCLAW_CONFIG="$HOME/.config/openclaw"
if [[ -d "$OPENCLAW_CONFIG" ]]; then
    print_question "Found OpenClaw config directory: $OPENCLAW_CONFIG"

    if confirm "Delete OpenClaw configuration (this resets all agent configs)?"; then
        rm -rf "$OPENCLAW_CONFIG"
        print_info "Deleted: $OPENCLAW_CONFIG"
    else
        print_info "Skipped: $OPENCLAW_CONFIG"
    fi
else
    print_info "No OpenClaw config directory found."
fi

# ==============================================================================
# STEP 7: REMOVE MAIN OPENCLAW DIRECTORY (if empty)
# ==============================================================================

print_header "Step 7: Main OpenClaw Directory"

if [[ -d "$OPENCLAW_DIR" ]]; then
    # Check if directory is empty or only contains empty subdirectories
    remaining_files=$(find "$OPENCLAW_DIR" -type f 2>/dev/null | wc -l)

    if [[ "$remaining_files" -eq 0 ]]; then
        print_info "OpenClaw directory is now empty. Removing..."
        rmdir "$OPENCLAW_DIR" 2>/dev/null || rm -rf "$OPENCLAW_DIR"
        print_info "Deleted: $OPENCLAW_DIR"
    else
        print_warn "OpenClaw directory still contains files:"
        find "$OPENCLAW_DIR" -type f 2>/dev/null | while read -r file; do
            echo "  - $file"
        done

        if confirm "Force delete entire $OPENCLAW_DIR directory?"; then
            rm -rf "$OPENCLAW_DIR"
            print_info "Deleted: $OPENCLAW_DIR"
        else
            print_info "Skipped: $OPENCLAW_DIR (directory still exists with files)"
        fi
    fi
else
    print_info "OpenClaw directory does not exist."
fi

# ==============================================================================
# STEP 8: UNINSTALL OPENCLAW ITSELF (Optional)
# ==============================================================================

print_header "Step 8: Uninstall OpenClaw"

if check_openclaw_installed; then
    print_question "OpenClaw is still installed at: $(command -v openclaw)"
    print_info "Version: $(get_openclaw_version)"
    echo ""
    echo "This will remove the OpenClaw binary and related files."
    echo "You may need to manually remove Node.js if it was installed by the bootstrap script."

    if confirm "Uninstall OpenClaw?"; then
        print_info "Attempting to uninstall OpenClaw..."

        # Try openclaw's uninstall if available
        if openclaw uninstall &>/dev/null; then
            print_info "OpenClaw uninstalled via 'openclaw uninstall'."
        else
            # Manual removal - find and remove openclaw
            OPENCLAW_PATH=$(command -v openclaw)
            if [[ -n "$OPENCLAW_PATH" ]]; then
                # Try to find the installation method
                if [[ -f "/usr/local/bin/openclaw" ]]; then
                    sudo rm -f "/usr/local/bin/openclaw"
                    print_info "Removed: /usr/local/bin/openclaw"
                fi

                # Check for npm global installation
                if npm list -g openclaw &>/dev/null; then
                    print_info "Detected npm global installation. Removing..."
                    npm uninstall -g openclaw 2>/dev/null || sudo npm uninstall -g openclaw 2>/dev/null
                fi

                print_warn "Manual uninstall attempted. You may need to verify removal."
            fi
        fi
    else
        print_info "Skipped: OpenClaw uninstall"
    fi
else
    print_info "OpenClaw is not installed."
fi

# ==============================================================================
# STEP 9: SYSTEM PACKAGES (Informational)
# ==============================================================================

print_header "Step 9: System Packages (Informational)"

echo "The bootstrap script may have installed these packages:"
echo "  - curl"
echo "  - git"
echo "  - nodejs (via NodeSource PPA)"
echo ""
print_warn "This uninstall script does NOT remove system packages."
print_warn "If you want to remove them, run manually:"
echo "  sudo apt remove curl git nodejs"
echo "  sudo apt autoremove"
echo ""
print_warn "Note: Other applications may depend on these packages!"

# ==============================================================================
# COMPLETION
# ==============================================================================

echo ""
echo "=============================================================================="
echo "OpenClaw Multi-Agent Uninstall Complete!"
echo "=============================================================================="
echo ""

# Final state
if [[ -d "$OPENCLAW_DIR" ]]; then
    print_warn "OpenClaw directory still exists: $OPENCLAW_DIR"
    print_info "Remaining files:"
    find "$OPENCLAW_DIR" -type f 2>/dev/null | head -20
else
    print_info "OpenClaw directory removed."
fi

if check_openclaw_installed; then
    print_warn "OpenClaw is still installed."
    print_info "Run 'which openclaw' to find the binary location."
else
    print_info "OpenClaw is not installed."
fi

echo ""
print_info "If you want to reinstall, run: ./oc-bootstrap.sh"
echo ""
