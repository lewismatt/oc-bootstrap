#!/bin/bash
# =============================================================================
# OpenClaw Bootstrap - Main Installation Script
# =============================================================================

set -o errexit
nset -o nounset
nset -o pipefail

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}") && pwd)"
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
readonly OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"
readonly OPENCLAW_ENV="${OPENCLAW_ENV:-development}"

# Display help
function show_help() {
    cat <<EOF
OpenClaw Bootstrap - Install and configure OpenClaw

Usage: $0 [OPTIONS]

Options:
  --install          Install OpenClaw
  --uninstall        Uninstall OpenClaw
  --help             Show this help message
  --version          Show version information

Environment Variables:
  OPENCLAW_HOME       Installation directory (default: /opt/openclaw)
  OPENCLAW_USER       User to run services (default: openclaw)
  OPENCLAW_ENV        Environment mode (default: development)

EOF
}

# Install OpenClaw
function install_openclaw() {
    info "Starting OpenClaw installation..."
    
    # Check prerequisites
    if ! command_exists "ollama"; then
        warn "Ollama not found. Installing..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    # Create user if not exists
    if ! id "$OPENCLAW_USER" &>/dev/null; then
        info "Creating user: $OPENCLAW_USER"
        useradd -m -s /bin/bash "$OPENCLAW_USER"
    fi
    
    # Create directory structure
    ensure_dir "$OPENCLAW_HOME"
    ensure_dir "$OPENCLAW_HOME/agents"
    ensure_dir "$OPENCLAW_HOME/workspace"
    ensure_dir "$OPENCLAW_HOME/logs"
    
    # Copy files
    cp -r "$SCRIPT_DIR/assistant" "$OPENCLAW_HOME/"
    cp -r "$SCRIPT_DIR/developer" "$OPENCLAW_HOME/"
    cp -r "$SCRIPT_DIR/research" "$OPENCLAW_HOME/"
    
    # Set permissions
    chown -R "$OPENCLAW_USER:$OPENCLAW_USER" "$OPENCLAW_HOME"
    
    success "OpenClaw installation completed!"
}

# Main
function main() {
    case "${1:-}" in
        --install)
            install_openclaw
            ;;
        --uninstall)
            "$SCRIPT_DIR/scripts/uninstall-oc-bootstrap.sh"
            ;;
        --help|-h)
            show_help
            ;;
        --version|-v)
            echo "OpenClaw Bootstrap 1.0.0"
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
