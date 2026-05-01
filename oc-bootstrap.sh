#!/bin/bash
# ==============================================================================
# OpenClaw Multi-Agent Bootstrap Script
# ==============================================================================
# Automated setup for OpenClaw AI agents on Ubuntu 24.04
#
# Usage:
#   ./oc-bootstrap.sh                                 # Interactive mode
#   ./oc-bootstrap.sh --config .env --non-interactive # Automated mode
#
# See README.md for full documentation.
# ==============================================================================

set -euo pipefail
set +o histexpand # Disable history expansion to prevent issues with '!' characters

# ==============================================================================
# CONSTANTS & EXIT CODES
# ==============================================================================

# Exit code constants (for error classification)
E_SUDO=10       # Script run as root or sudo unavailable
E_DEPENDENCY=11 # System package installation failure
E_OPENCLAW=12   # OpenClaw installation or runtime error
E_CONFIG=13     # Configuration operation failed
E_GATEWAY=14    # Gateway start/bind error

# Execution settings
STABILITY_DELAY=5                   # Wait time for gateway to stabilize (seconds)
export FAIL_ON_OPENCLAW_ERRORS=true # Exported for subshells; treat OpenClaw errors as fatal (not just warnings)
NON_INTERACTIVE=false               # Interactive prompts mode
CONFIG_FILE=""                      # Configuration file path (optional)

# ==============================================================================
# SCRIPT INITIALIZATION
# ==============================================================================

# Get script directory (for sourcing helpers and accessing agent templates)
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Source helper functions library
if [[ ! -f "$SCRIPT_DIR/lib/helpers.sh" ]]; then
    echo "[ERROR] Helper library not found: $SCRIPT_DIR/lib/helpers.sh"
    exit 1
fi
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/helpers.sh"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --non-interactive | -y)
        NON_INTERACTIVE=true
        shift
        ;;
    --config | -c)
        CONFIG_FILE="$2"
        shift 2
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--config FILE] [--non-interactive]"
        exit 1
        ;;
    esac
done

# Load configuration file if provided
if [[ -n "$CONFIG_FILE" ]]; then
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "[INFO] Loading configuration from $CONFIG_FILE"
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    else
        echo "[ERROR] Config file not found: $CONFIG_FILE"
        exit $E_CONFIG
    fi
fi