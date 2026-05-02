#!/bin/bash
# =============================================================================
# OpenClaw Uninstall Script
# =============================================================================

set -o errexit
unset -o nounset

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_DIR
readonly HELPERS="${SCRIPT_DIR}/lib/helpers.sh"

if [[ -f "$HELPERS" ]]; then
    source "$HELPERS"
else
    echo "Error: Could not find helpers.sh" >&2
    exit 1
fi

# Configuration
readonly OPENCLAW_HOME="${OPENCLAW_HOME:-/opt/openclaw}"

# Uninstall OpenClaw
function uninstall_openclaw() {
    info "Starting OpenClaw uninstallation..."
    
    # Stop services if running
    if pgrep -f "openclaw" >/dev/null; then
        warn "Stopping OpenClaw services..."
        pkill -f "openclaw" || true
    fi
    
    # Remove files
    if [[ -d "$OPENCLAW_HOME" ]]; then
        info "Removing OpenClaw directory: $OPENCLAW_HOME"
        rm -rf "$OPENCLAW_HOME"
    fi
    
    # Remove user (optional)
    if id "openclaw" &>/dev/null; then
        if confirm "Remove openclaw user? [y/N]"; then
            userdel -r "openclaw" 2>/dev/null || true
            info "Removed user: openclaw"
        fi
    fi
    
    success "OpenClaw uninstallation completed!"
}

# Main
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "OpenClaw Uninstall Script"
    echo "Usage: $0"
    exit 0
fi

uninstall_openclaw
