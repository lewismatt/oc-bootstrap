#!/bin/bash
# ==============================================================================
# OpenClaw Docker Entrypoint Script
# ==============================================================================
# Handles container initialization, configuration, and service startup
#
# Usage:
#   docker run oc-bootstrap                    # Start gateway (default)
#   docker run oc-bootstrap bootstrap          # Run bootstrap script
#   docker run -it oc-bootstrap bash           # Open shell
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONSTANTS
# ==============================================================================

OPENCLAW_USER="openclaw"
OPENCLAW_HOME="/home/openclaw/.openclaw"
OPENCLAW_CONFIG="${OPENCLAW_HOME}/secrets.env"
BOOTSTRAP_SCRIPT="/home/openclaw/oc-bootstrap/oc-bootstrap.sh"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENTRYPOINT] $*" >&2
}

handle_error() {
    log "ERROR: $*"
    exit 1
}

# Check if running as correct user
check_user() {
    if [[ "$(whoami)" != "$OPENCLAW_USER" ]]; then
        handle_error "Container must run as user '$OPENCLAW_USER', not '$(whoami)'"
    fi
}

# Load environment variables from secrets file if it exists
load_secrets() {
    if [[ -f "$OPENCLAW_CONFIG" ]]; then
        log "Loading secrets from $OPENCLAW_CONFIG"
        # shellcheck disable=SC1090
        source "$OPENCLAW_CONFIG"
    else
        log "No secrets file found at $OPENCLAW_CONFIG"
    fi
}

# Run OpenClaw doctor to verify installation
verify_openclaw() {
    log "Verifying OpenClaw installation..."
    if ! command -v openclaw &>/dev/null; then
        handle_error "OpenClaw CLI not found in PATH"
    fi

    openclaw --version || log "Warning: openclaw --version failed"
    openclaw doctor --fix || log "Warning: openclaw doctor reported issues"
}

# Run bootstrap script if configured
run_bootstrap() {
    if [[ "${RUN_BOOTSTRAP:-false}" == "true" ]]; then
        log "Running OpenClaw bootstrap script..."

        if [[ ! -f "$BOOTSTRAP_SCRIPT" ]]; then
            handle_error "Bootstrap script not found at $BOOTSTRAP_SCRIPT"
        fi

        chmod +x "$BOOTSTRAP_SCRIPT"

        # Run in non-interactive mode with config file if provided
        if [[ -n "${CONFIG_FILE:-}" && -f "$CONFIG_FILE" ]]; then
            log "Using config file: $CONFIG_FILE"
            bash "$BOOTSTRAP_SCRIPT" --config "$CONFIG_FILE" --non-interactive
        else
            log "Running bootstrap in non-interactive mode"
            bash "$BOOTSTRAP_SCRIPT" --non-interactive
        fi
    fi
}

# Start OpenClaw gateway
start_gateway() {
    log "Starting OpenClaw Gateway..."

    # Ensure OpenClaw is properly configured
    verify_openclaw

    # Start gateway in foreground (container will stop when this process ends)
    exec openclaw gateway start --foreground
}

# Start a shell for debugging
start_shell() {
    log "Starting interactive shell..."
    exec /bin/bash
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

log "OpenClaw Docker Entrypoint starting..."
check_user
load_secrets

# If no arguments, start gateway (default behavior)
if [[ $# -eq 0 ]]; then
    start_gateway
fi

# Parse command argument
COMMAND="${1:-gateway}"
shift || true # Remove the command, keep remaining args

case "$COMMAND" in
gateway)
    start_gateway
    ;;
bootstrap)
    run_bootstrap
    log "Bootstrap complete. Starting gateway..."
    start_gateway
    ;;
shell | bash | sh)
    # If additional arguments provided (like -c "command"), pass them to bash
    if [[ $# -gt 0 ]]; then
        exec /bin/bash "$@"
    else
        start_shell
    fi
    ;;
*)
    # Treat unknown command as a direct command to execute
    log "Executing custom command: $COMMAND $*"
    exec "$COMMAND" "$@"
    ;;
esac
