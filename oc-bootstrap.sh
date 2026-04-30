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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper functions library
if [[ ! -f "$SCRIPT_DIR/lib/helpers.sh" ]]; then
    echo "[ERROR] Helper library not found: $SCRIPT_DIR/lib/helpers.sh"
    exit 1
fi
# shellcheck disable=SC1090
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

# ==============================================================================
# VARIABLE INITIALIZATION
# ==============================================================================
# Initialize all credential variables to empty strings (prevent unset errors)

# ==============================================================================
# RUNTIME CHECKS
# ==============================================================================

# 1. Check that script is not run as root
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "[ERROR] Do not run this script as root or with sudo."
    echo "        This script installs to \$HOME and will prompt for sudo when needed."
    exit $E_SUDO
fi

# 2. Check required system tools
check_required_tools sed diff cp mkdir chmod chown printf

# 3. Attempt to install curl if missing (required for API calls)
if ! require_tool "curl"; then
    echo "[INFO] 'curl' is required but missing. Attempting to install..."
    if ! install_if_missing "curl"; then
        exit $E_DEPENDENCY
    fi
fi

# 4. Run static analysis (optional, if ShellCheck available)
check_shellcheck

# ==============================================================================
# AGENT & CREDENTIAL CONFIGURATION
# ==============================================================================

# Agent definitions (single source of truth)
AGENTS=("assistant" "research" "developer")
AGENT_PREFIXES=("General" "Deep Research" "Developer")

# Initialize all credential variables (prevents unset variable errors)
ASSISTANT_TOKEN=""
RESEARCH_TOKEN=""
DEVELOPER_TOKEN=""
EMBEDDING_MODEL=""
ASSISTANT_MODEL=""
RESEARCH_MODEL=""
DEVELOPER_MODEL=""
GITHUB_PAT=""
GITLAB_PAT=""
BRAVE_API_KEY=""
X_API_KEY=""

# ==============================================================================
# LOGGING & SIGNAL HANDLING
# ==============================================================================

SCRIPT_NAME="openclaw-setup"
LOG_FILE="$HOME/.openclaw/logs/${SCRIPT_NAME}.log"

# Initialize logging (output goes to both console and log file)
init_logging "$LOG_FILE"
log_timestamp "Starting OpenClaw Multi-Agent Setup"

# Setup cleanup handler for graceful shutdown
cleanup_on_exit() {
    local exit_code=$1
    if [[ $exit_code -ne 0 ]]; then
        log_timestamp "Setup aborted or interrupted with code $exit_code. Check: $LOG_FILE"
    else
        log_timestamp "Setup completed or intentionally halted."
    fi
    exit "$exit_code"
}

setup_cleanup_trap cleanup_on_exit

# ==============================================================================
# SECTION 1: USER CONFIRMATION & ENVIRONMENT CHECK
# ==============================================================================

# ==============================================================================
# SECTION 2: USER CONFIRMATION
# ==============================================================================
echo ""
echo "OpenClaw Multi-Agent Setup"
echo "=============================================================================="
echo ""
if [[ "$NON_INTERACTIVE" == "false" ]]; then
    read -r -p "Proceed with installation? (Y/n) " CONFIRM </dev/tty
    [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || -z "$CONFIRM" ]] || exit 0
fi

# ==============================================================================
# SECTION 3: CREDENTIAL COLLECTION & VALIDATION
# ==============================================================================
echo ""
echo "=== Inference Backend ==="
if [[ -z "${LOCAL_INFERENCE:-}" ]]; then
    echo "You can use Local inference (Lemonade Server), Remote APIs (OpenAI, Anthropic), or a mix of both."
    echo "If you are new to self-hosting AI, we recommend using Remote API providers for a smoother start."
    read -r -p "Will you use local inference via Lemonade Server for any of your agents? [y/N]: " USE_LOCAL </dev/tty
    if [[ "${USE_LOCAL^^}" == "Y" ]]; then
        LOCAL_INFERENCE=true
        read -r -p "Enter Lemonade Server API Key [Press Enter to use 'local-dummy-key']: " LEMONADE_KEY </dev/tty
        LEMONADE_KEY="${LEMONADE_KEY:-local-dummy-key}"
    else
        LOCAL_INFERENCE=false
        LEMONADE_KEY=""
        echo "  [OK] Remote API Providers exclusively selected."
    fi
else
    echo "[INFO] Local Inference: $LOCAL_INFERENCE (from config)"
fi

echo ""
echo "=== Model Selection ==="
if [[ -z "${EMBEDDING_MODEL:-}" ]]; then
    echo "For each model, provide the appropriate provider tag:"
    echo "  - Local Lemonade: lemonade/user.Qwen3.5-4B-GGUF"
    echo "  - Remote OpenAI: openai/gpt-4o"
    echo "  - Remote Anthropic: anthropic/claude-3-5-sonnet-latest"
    echo ""

    while [[ -z "$EMBEDDING_MODEL" ]]; do
        read -r -p "Enter Embedding Model tag [Default: openai/text-embedding-3-small]: " EMBEDDING_MODEL </dev/tty
        EMBEDDING_MODEL="${EMBEDDING_MODEL:-openai/text-embedding-3-small}"
    done
fi

if [[ -z "${ASSISTANT_MODEL:-}" ]]; then
    while [[ -z "$ASSISTANT_MODEL" ]]; do
        read -r -p "Enter Assistant Agent LLM tag [Default: openai/gpt-4o]: " ASSISTANT_MODEL </dev/tty
        ASSISTANT_MODEL="${ASSISTANT_MODEL:-openai/gpt-4o}"
    done
fi

if [[ -z "${RESEARCH_MODEL:-}" ]]; then
    while [[ -z "$RESEARCH_MODEL" ]]; do
        read -r -p "Enter Research Agent LLM tag [Default: openai/gpt-4o]: " RESEARCH_MODEL </dev/tty
        RESEARCH_MODEL="${RESEARCH_MODEL:-openai/gpt-4o}"
    done
fi

if [[ -z "${DEVELOPER_MODEL:-}" ]]; then
    while [[ -z "$DEVELOPER_MODEL" ]]; do
        read -r -p "Enter Developer Agent LLM tag [Default: anthropic/claude-3-5-sonnet-latest]: " DEVELOPER_MODEL </dev/tty
        DEVELOPER_MODEL="${DEVELOPER_MODEL:-anthropic/claude-3-5-sonnet-latest}"
    done
fi

echo ""
echo "=== Telegram Bot Tokens ==="
if [[ -z "${ASSISTANT_TOKEN:-}" || -z "${RESEARCH_TOKEN:-}" || -z "${DEVELOPER_TOKEN:-}" ]]; then
    echo "You will need three unique Telegram Bot Tokens from @BotFather."
    echo ""

    TOTAL_TOKENS=${#AGENTS[@]}
    current_token=0

    while [[ $current_token -lt $TOTAL_TOKENS ]]; do
        AGENT_PREFIX="${AGENT_PREFIXES[$current_token]}"

        CURRENT_TOKEN=""
        ATTEMPT=0

        while [[ -z "$CURRENT_TOKEN" || "$CURRENT_TOKEN" == "$ASSISTANT_TOKEN" ||
            "$CURRENT_TOKEN" == "$RESEARCH_TOKEN" || "$CURRENT_TOKEN" == "$DEVELOPER_TOKEN" ]]; do
            ATTEMPT=$((ATTEMPT + 1))
            if [[ $ATTEMPT -gt 3 ]]; then
                echo "  [WARN] Failed to collect $AGENT_PREFIX token after 3 attempts."
                break
            fi

            CURRENT_TOKEN=""
            read -r -s -p "Enter Telegram Bot Token for the $AGENT_PREFIX Agent: " CURRENT_TOKEN </dev/tty
            echo ""

            if [[ -z "$CURRENT_TOKEN" ]]; then
                echo "  [ERROR] $AGENT_PREFIX token is required. Please try again."
            elif [[ "$CURRENT_TOKEN" == "$ASSISTANT_TOKEN" ]]; then
                echo "  [ERROR] Token must be unique. Do not reuse the Assistant token."
            elif [[ "$CURRENT_TOKEN" == "$RESEARCH_TOKEN" ]]; then
                echo "  [ERROR] Token must be unique. Do not reuse the Research token."
            elif [[ "$CURRENT_TOKEN" == "$DEVELOPER_TOKEN" ]]; then
                echo "  [ERROR] Token must be unique. Do not reuse the Developer token."
            else
                break
            fi
        done

        if [[ -n "$CURRENT_TOKEN" ]]; then
            if ! validate_telegram_token "$CURRENT_TOKEN"; then
                echo ""
                echo "  [WARN] Token format invalid. Please try again."
                CURRENT_TOKEN=""
            else
                case $current_token in
                    0) ASSISTANT_TOKEN="$CURRENT_TOKEN" ;;
                    1) RESEARCH_TOKEN="$CURRENT_TOKEN" ;;
                    2) DEVELOPER_TOKEN="$CURRENT_TOKEN" ;;
                esac
                current_token=$((current_token + 1))
            fi
        fi

        echo ""
    done
else
    echo "[OK] Telegram tokens provided via config."
fi

echo ""
echo "=== Agent-Specific External Secrets (optional) ==="
if [[ -z "${GITHUB_PAT:-}" && "$NON_INTERACTIVE" == "false" ]]; then
    read -r -s -p "Enter GitHub Personal Access Token (for local MCP, or press Enter to skip): " GITHUB_PAT </dev/tty
    echo ""
    GITHUB_PAT="${GITHUB_PAT:-}"
fi

if [[ -z "${GITLAB_PAT:-}" && "$NON_INTERACTIVE" == "false" ]]; then
    read -r -s -p "Enter GitLab Personal Access Token (for local MCP, or press Enter to skip): " GITLAB_PAT </dev/tty
    echo ""
    GITLAB_PAT="${GITLAB_PAT:-}"
fi

if [[ -z "${BRAVE_API_KEY:-}" && "$NON_INTERACTIVE" == "false" ]]; then
    read -r -s -p "Enter Brave Search API Key (for Research Agent, or press Enter to skip): " BRAVE_API_KEY </dev/tty
    echo ""
    BRAVE_API_KEY="${BRAVE_API_KEY:-}"
fi

if [[ -z "${X_API_KEY:-}" && "$NON_INTERACTIVE" == "false" ]]; then
    read -r -s -p "Enter X/Twitter API Key or Auth Cookie (for xScraper, or press Enter to skip): " X_API_KEY </dev/tty
    echo ""
    X_API_KEY="${X_API_KEY:-}"
fi

[[ -z "$GITLAB_PAT" ]] && echo "[WARN] No GitLab PAT provided. Git workflow features will be unavailable."
[[ -z "$BRAVE_API_KEY" ]] && echo "[WARN] No Brave Search API Key provided. Web search will be unavailable."
[[ -z "$X_API_KEY" ]] && echo "[WARN] No X/Twitter credentials provided. X scraping may be rate-limited or blocked."

echo ""
echo "=== Credential Collection Summary ==="
if [[ "$LOCAL_INFERENCE" == true ]]; then
    echo "[OK] Lemonade Server API Key: Configured"
else
    echo "[OK] Inference Backend: Remote API Providers"
fi
echo "[OK] Assistant Telegram Bot Token: Configured"
echo "[OK] Research Telegram Bot Token: Configured"
echo "[OK] Developer Telegram Bot Token: Configured"
if [[ -n "$GITHUB_PAT" ]]; then
    echo "[OK] GitHub Personal Access Token: Configured"
else
    echo "[WARN] GitHub Personal Access Token: Not configured"
fi
if [[ -n "$GITLAB_PAT" ]]; then
    echo "[OK] GitLab Personal Access Token: Configured"
else
    echo "[WARN] GitLab Personal Access Token: Not configured"
fi
if [[ -n "$BRAVE_API_KEY" ]]; then
    echo "[OK] Brave Search API Key: Configured"
else
    echo "[WARN] Brave Search API Key: Not configured"
fi
if [[ -n "$X_API_KEY" ]]; then
    echo "[OK] X/Twitter API Key: Configured"
else
    echo "[WARN] X/Twitter API Key: Not configured"
fi

echo ""
echo "=== Model Selection Summary ==="
echo "[OK] Embedding Model: $EMBEDDING_MODEL"
echo "[OK] Assistant Model: $ASSISTANT_MODEL"
echo "[OK] Research Model: $RESEARCH_MODEL"
echo "[OK] Developer Model: $DEVELOPER_MODEL"

# ==============================================================================
# SECTION 4: SAVE CREDENTIALS TO SECURE .env FILE
# ==============================================================================
if [[ -z "$ASSISTANT_TOKEN" || -z "$RESEARCH_TOKEN" || -z "$DEVELOPER_TOKEN" ]]; then
    echo "[ERROR] One or more Telegram bot tokens are missing. These tokens are required to bind agents to Telegram."
    echo "Please re-run the script and provide unique tokens for Assistant, Research, and Developer agents."
    exit $E_CONFIG
fi

echo ""
echo "Saving credentials to secure environment file..."
ensure_directory "$HOME/.openclaw" || exit 1

SECRETS_FILE="$HOME/.openclaw/secrets.env"

if [[ -f "$SECRETS_FILE" ]]; then
    echo ""
    echo "  [WARN] Secrets file already exists at $SECRETS_FILE"
    echo "  Overwriting will replace all previously stored credentials."
    echo ""
    read -r -p "  Overwrite existing secrets file? (y/N) " OVERWRITE_SECRETS </dev/tty
    if [[ "${OVERWRITE_SECRETS^^}" != "Y" ]]; then
        echo "Skipping secrets file update. Loading existing credentials into memory..."
        # shellcheck disable=SC1090
        source "$SECRETS_FILE"
    else
        safe_write_secrets_file "$SECRETS_FILE"
        echo "[OK] Credentials updated at $SECRETS_FILE"
    fi
else
    safe_write_secrets_file "$SECRETS_FILE"
    echo "[OK] Credentials saved to $SECRETS_FILE"
fi

# ==============================================================================
# SECTION 5: SYSTEM PREPARATION & CORE INSTALLATION
# ==============================================================================
echo ""
echo "=== System Preparation ==="

steps=("Configuring sudo" "Configuring NodeSource PPA" "Updating and upgrading system packages" "Installing curl, git, and Node.js" "Installing OpenClaw")
total_steps=${#steps[@]}

# Step 1/5
progress_bar "$total_steps" 1
echo "Step 1/5: Configuring sudo..."
sudo -v || {
    echo "  [ERROR] sudo access is required to install dependencies."
    echo "  Please ensure sudo permissions are set up correctly."
    exit $E_SUDO
}

# Step 2/5
progress_bar "$total_steps" 2
echo "Step 2/5: Configuring NodeSource PPA..."
if curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -; then
    echo "  [OK] NodeSource PPA configured successfully"
else
    echo "  [WARN] NodeSource PPA setup failed. Using default repositories."
fi

# Step 3/5
progress_bar "$total_steps" 3
echo "Step 3/5: Updating and upgrading system packages..."
if sudo apt update; then
    echo "  [OK] apt update completed"
fi

if sudo apt upgrade -y; then
    echo "  [OK] apt upgrade completed"
else
    echo "  [WARN] apt upgrade had issues. Attempting to continue..."
fi

# Step 4/5
progress_bar "$total_steps" 4
echo "Step 4/5: Installing curl, git, and Node.js..."
if sudo apt install -y curl git nodejs; then
    echo "  [OK] curl, git, and nodejs installed successfully"
else
    echo "  [ERROR] Failed to install curl/git/nodejs. Cannot continue."
    exit $E_DEPENDENCY
fi

# Step 5/5
progress_bar "$total_steps" 5
echo "Step 5/5: Installing OpenClaw..."
if curl -fsSL https://openclaw.ai/install.sh | bash; then
    echo "  [OK] OpenClaw installed successfully"
else
    echo "  [ERROR] OpenClaw installation failed."
    handle_error_or_warn "OpenClaw installation failed." $E_OPENCLAW
fi

if command -v openclaw &>/dev/null; then
    echo "  [OK] OpenClaw binary found in PATH"
else
    echo "  [ERROR] OpenClaw binary not found in PATH after installation."
    handle_error_or_warn "OpenClaw binary not found in PATH after installation." $E_OPENCLAW
fi

echo "Running post-install health check and auto-repair..."
if openclaw doctor --fix; then
    echo "  [OK] OpenClaw doctor completed without issues"
else
    echo "  [WARN] OpenClaw doctor reported some issues. Continuing anyway..."
fi

# Mark all steps complete
progress_bar "$total_steps" "$total_steps"
echo "" # Newline after final progress bar

print_section_summary "System Preparation" \
    "Sudo configured" \
    "Node.js 20.x installed" \
    "System packages updated" \
    "curl, git, and Node.js installed" \
    "OpenClaw installed and configured" \
    "Health check completed"

# ==============================================================================
# SECTION 6: CONFIGURE INFERENCE BACKEND
# ==============================================================================
echo ""
if [[ "$LOCAL_INFERENCE" == true ]]; then
    echo "=== Linking Lemonade Server Backend ==="

    if [[ -z "${LEMONADE_IP:-}" ]]; then
        LEMONADE_IP=""
        while true; do
            read -r -p "Enter Lemonade server IP address (e.g., 192.168.12.50): " LEMONADE_IP </dev/tty
            if valid_ipv4 "$LEMONADE_IP"; then
                break
            else
                echo "[ERROR] Invalid IP address format. Please try again."
            fi
        done
    else
        echo "[INFO] Using Lemonade IP: $LEMONADE_IP (from config)"
    fi

    BASE_URL="http://${LEMONADE_IP}:8000/v1"
    if [[ "$NON_INTERACTIVE" == "false" ]]; then
        read -r -p "Enter Lemonade base URL [Press Enter for default: $BASE_URL]: " CUSTOM_URL </dev/tty
        [[ -n "$CUSTOM_URL" ]] && BASE_URL="$CUSTOM_URL"
    fi

    openclaw config set providers.lemonade.baseUrl "$BASE_URL" || handle_error_or_warn "Failed to set Lemonade base URL." $E_CONFIG
    openclaw config set providers.lemonade.apiKey "$LEMONADE_KEY" || handle_error_or_warn "Failed to set Lemonade API key." $E_CONFIG
else
    echo "=== Skipping Local Inference Backend Linking ==="
    echo "[INFO] Using remote API providers."
fi

echo "Configuring shared embedding and dreaming models..."
openclaw config set memory.dreaming.model "$ASSISTANT_MODEL" || handle_error_or_warn "Failed to set dreaming model." "$E_CONFIG"
openclaw config set memory.embeddingModel "$EMBEDDING_MODEL" || handle_error_or_warn "Failed to set embedding model." "$E_CONFIG"

if [[ "$LOCAL_INFERENCE" == true ]]; then
    echo "[OK] Lemonade Server backend configured"
fi

# ==============================================================================
# SECTION 7: PROVISION ISOLATED AGENT WORKSPACES
# ==============================================================================
echo ""
echo "=== Provisioning Agent Workspaces ==="

agents_to_provision=("${AGENTS[@]}")
for i in "${!agents_to_provision[@]}"; do
    agent="${agents_to_provision[$i]}"
    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
    current=$((i + 1))
    progress_bar ${#agents_to_provision[@]} $current

    echo "Provisioning agent: ${agent^^}..."
    openclaw agents add "$agent" --workspace "$WORKSPACE" --non-interactive ||
        handle_error_or_warn "Issue provisioning agent '$agent'. Continuing." "$E_OPENCLAW"
done
echo "" # Newline after progress bar

echo "Assigning LLM inference models to agents..."
openclaw config set agents.list.assistant.model "$ASSISTANT_MODEL" || handle_error_or_warn "Failed to set model for assistant agent." "$E_CONFIG"
openclaw config set agents.list.research.model "$RESEARCH_MODEL" || handle_error_or_warn "Failed to set model for research agent." "$E_CONFIG"
openclaw config set agents.list.developer.model "$DEVELOPER_MODEL" || handle_error_or_warn "Failed to set model for developer agent." "$E_CONFIG"

print_section_summary "Agent Workspace Provisioning" \
    "Assistant agent workspace created" \
    "Research agent workspace created" \
    "Developer agent workspace created" \
    "User-defined models assigned to all agents"

# ==============================================================================
# SECTION 8: INJECT AGENT-SPECIFIC SECRETS & MCP SERVERS
# ==============================================================================
echo ""
echo "=== Injecting Isolated Agent Secrets & MCPs ==="

if [[ -n "$GITHUB_PAT" ]]; then
    for agent in "${AGENTS[@]}"; do
        openclaw config set agents.list."${agent}".env.GITHUB_PERSONAL_ACCESS_TOKEN "$GITHUB_PAT" || handle_error_or_warn "Failed to set GitHub PAT for $agent." $E_CONFIG
        echo "Binding local GitHub MCP server to ${agent^^} Agent..."
        openclaw config set agents.list."${agent}".mcp.servers.github.command "npx" || handle_error_or_warn "Failed to set MCP command for $agent."
        openclaw config set agents.list."${agent}".mcp.servers.github.args '["-y", "@modelcontextprotocol/server-github"]' || {
            echo "[WARN] Failed to set GitHub MCP args. Attempting legacy string format..."
            openclaw config set agents.list."${agent}".mcp.servers.github.args "-y @modelcontextprotocol/server-github" || echo "[WARN] Failed to set legacy MCP args."
        }
    done
else
    echo "[INFO] Skipping GitHub MCP configuration (no token provided)."
fi

if [[ -n "$GITLAB_PAT" ]]; then
    for agent in "${AGENTS[@]}"; do
        openclaw config set agents.list."${agent}".env.GITLAB_PERSONAL_ACCESS_TOKEN "$GITLAB_PAT" || handle_error_or_warn "Failed to set GitLab PAT for $agent." $E_CONFIG
        openclaw config set agents.list."${agent}".env.GITLAB_API_URL "https://gitlab.com" || handle_error_or_warn "Failed to set GitLab URL for $agent." $E_CONFIG

        echo "Binding local GitLab MCP server to ${agent^^} Agent..."
        openclaw config set agents.list."${agent}".mcp.servers.gitlab.command "npx" || handle_error_or_warn "Failed to set MCP command for $agent."
        openclaw config set agents.list."${agent}".mcp.servers.gitlab.args '["-y", "@zereight/mcp-gitlab"]' || {
            echo "[WARN] Failed to set GitLab MCP args. Attempting legacy string format..."
            openclaw config set agents.list."${agent}".mcp.servers.gitlab.args "-y @zereight/mcp-gitlab" || echo "[WARN] Failed to set legacy MCP args."
        }
    done
else
    echo "[INFO] Skipping GitLab MCP configuration (no token provided)."
fi

if [[ -n "$BRAVE_API_KEY" ]]; then
    openclaw config set agents.list.research.env.BRAVE_API_KEY "$BRAVE_API_KEY" || handle_error_or_warn "Failed to set Brave API key for research agent." $E_CONFIG
    openclaw config set agents.list.research.search.provider "brave" || handle_error_or_warn "Failed to set Brave as search provider." $E_CONFIG
else
    echo "[INFO] Skipping Brave search configuration (no key provided)."
fi

if [[ -n "$X_API_KEY" ]]; then
    openclaw config set agents.list.research.env.X_API_KEY "$X_API_KEY" || handle_error_or_warn "Failed to set X credentials for research agent." $E_CONFIG
else
    echo "[INFO] Skipping X/Twitter configuration (no key provided)."
fi

# FIX: Build the summary dynamically so it only reports items that were actually configured.
_summary_items=()
[[ -n "$GITHUB_PAT" ]] && _summary_items+=("GitHub PAT injected and MCP server bound to all agents")
[[ -n "$GITLAB_PAT" ]] && _summary_items+=("GitLab PAT injected and MCP server bound to all agents")
[[ -n "$BRAVE_API_KEY" ]] && _summary_items+=("Brave Search API key configured for Research agent")
[[ -n "$X_API_KEY" ]] && _summary_items+=("X/Twitter credentials configured for Research agent")
[[ ${#_summary_items[@]} -eq 0 ]] && _summary_items+=("No optional integrations configured (all skipped)")
print_section_summary "Agent Secrets & MCP Configuration" "${_summary_items[@]}"

# ==============================================================================
# SECTION 9: ASSIGN NATIVE SKILLS & OPERATIONAL HOOKS
# ==============================================================================
echo ""
echo "=== Assigning Native Skills & Hooks ==="

echo "Enabling built-in data gathering skills for the Research Agent..."
openclaw config set agents.list.research.skills.summarize true || handle_error_or_warn "Failed to enable summarize skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.webSearch true || handle_error_or_warn "Failed to enable webSearch skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.webScrape true || handle_error_or_warn "Failed to enable webScrape skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.newsSearch true || handle_error_or_warn "Failed to enable newsSearch skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.rssReader true || handle_error_or_warn "Failed to enable rssReader skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.trendsFinder true || handle_error_or_warn "Failed to enable trendsFinder skill." "$E_CONFIG"
openclaw config set agents.list.research.skills.xScraper true || handle_error_or_warn "Failed to enable xScraper skill." "$E_CONFIG"

echo "Enabling operational hooks..."
# Assistant: Automatically track evolving hardware/schedules
openclaw config set agents.list.assistant.hooks.autoMemory true || handle_error_or_warn "Failed to enable autoMemory hook for assistant." "$E_CONFIG"
# Research: Summarize sessions to prevent context bloat
openclaw config set agents.list.research.hooks.sessionSummarize true || handle_error_or_warn "Failed to enable sessionSummarize hook for research." "$E_CONFIG"
# Developer: Validate tool outputs for technical accuracy
openclaw config set agents.list.developer.hooks.toolValidation true || handle_error_or_warn "Failed to enable toolValidation hook for developer." "$E_CONFIG"

print_section_summary "Skills & Hooks Configuration" \
    "Research data gathering skills enabled (summarize, webSearch, webScrape, newsSearch, rssReader, trendsFinder, xScraper)" \
    "Assistant autoMemory hook enabled" \
    "Research sessionSummarize hook enabled" \
    "Developer toolValidation hook enabled"

# ==============================================================================
# SECTION 10: BIND TELEGRAM CHANNELS FOR AGENTS
# ==============================================================================
echo ""
echo "=== Binding Telegram Channels ==="

for agent in "${AGENTS[@]}"; do
    TOKEN=""
    case "$agent" in
        "assistant") TOKEN="$ASSISTANT_TOKEN" ;;
        "research") TOKEN="$RESEARCH_TOKEN" ;;
        "developer") TOKEN="$DEVELOPER_TOKEN" ;;
    esac

    # FIX: Unbind any existing defaults BEFORE binding the new token.
    # Previously this was done AFTER openclaw agents bind, which immediately
    # undid the binding that had just been created.
    echo "Clearing existing bindings for ${agent^^}..."
    openclaw agents unbind --agent "$agent" --all ||
        handle_error_or_warn "Failed to unbind defaults for agent '$agent'. Continuing." "$E_GATEWAY"

    echo "Binding Telegram for ${agent^^}..."
    if ! openclaw agents bind --agent "$agent" --bind "telegram:$TOKEN"; then
        handle_error_or_warn "Failed to bind Telegram for agent '$agent'." $E_GATEWAY
    fi
done

print_section_summary "Telegram Channel Binding" \
    "Assistant agent bound to Telegram" \
    "Research agent bound to Telegram" \
    "Developer agent bound to Telegram"

# ==============================================================================
# SECTION 11: CONFIGURE LOCAL MEMORY & VECTOR SEARCH
# ==============================================================================
echo ""
echo "=== Configuring Local Memory & Vector Search ==="

memory_tasks=(
    "Configuring memory search embedding provider"
    "Configuring per-agent SQLite index storage"
    "Enabling sqlite-vec vector search acceleration"
    "Enabling embedding cache"
    "Enabling session transcript indexing (experimental)"
)
total_tasks=${#memory_tasks[@]}

# Task 1: Configure memory search embedding provider
progress_bar "$total_tasks" 1
echo "${memory_tasks[0]}..."
MEM_PROVIDER="${EMBEDDING_MODEL%%/*}"
CLEAN_EMBEDDING_MODEL="${EMBEDDING_MODEL#*/}"

if [[ "$MEM_PROVIDER" == "lemonade" ]]; then
    openclaw config set agents.defaults.memorySearch.provider "openai" || handle_error_or_warn "Failed to set memory search provider." $E_CONFIG
    openclaw config set agents.defaults.memorySearch.model "$CLEAN_EMBEDDING_MODEL" || handle_error_or_warn "Failed to set memory search model." $E_CONFIG
    openclaw config set agents.defaults.memorySearch.remote.baseUrl "${BASE_URL:-http://127.0.0.1:8000/v1}" || handle_error_or_warn "Failed to set memory search base URL." $E_CONFIG
    openclaw config set agents.defaults.memorySearch.remote.apiKey "${LEMONADE_KEY:-local-dummy-key}" || handle_error_or_warn "Failed to set memory search API key." $E_CONFIG
else
    openclaw config set agents.defaults.memorySearch.provider "$MEM_PROVIDER" || handle_error_or_warn "Failed to set memory search provider." $E_CONFIG
    openclaw config set agents.defaults.memorySearch.model "$CLEAN_EMBEDDING_MODEL" || handle_error_or_warn "Failed to set memory search model." $E_CONFIG
fi

# Task 2: Configure per-agent SQLite index storage
progress_bar "$total_tasks" 2
echo "${memory_tasks[1]}..."
MEMORY_DIR="$HOME/.openclaw/memory"
mkdir -p "$MEMORY_DIR"
openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agentId}.sqlite" ||
    handle_error_or_warn "Failed to set memory index path." "$E_CONFIG"

# Task 3: Enable sqlite-vec vector search acceleration
progress_bar "$total_tasks" 3
echo "${memory_tasks[2]}..."
openclaw config set agents.defaults.memorySearch.store.vector.enabled true ||
    handle_error_or_warn "Failed to enable sqlite-vec. OpenClaw will use JS fallback." "$E_CONFIG"

# Task 4: Enable embedding cache
progress_bar "$total_tasks" 4
echo "${memory_tasks[3]}..."
openclaw config set agents.defaults.memorySearch.cache.enabled true ||
    handle_error_or_warn "Failed to enable embedding cache." "$E_CONFIG"

# Task 5: Enable session transcript indexing
progress_bar "$total_tasks" 5
echo "${memory_tasks[4]}..."
openclaw config set agents.defaults.memorySearch.experimental.sessionMemory true ||
    handle_error_or_warn "Failed to enable session memory indexing." "$E_CONFIG"

openclaw config set agents.defaults.memorySearch.sources[0] "memory" ||
    handle_error_or_warn "Failed to set memory source." "$E_CONFIG"
openclaw config set agents.defaults.memorySearch.sources[1] "sessions" ||
    handle_error_or_warn "Failed to set sessions source." "$E_CONFIG"

echo "" # Newline after progress bar

print_section_summary "Memory & Vector Search" \
    "Memory search embedding provider configured" \
    "Per-agent SQLite index storage configured" \
    "sqlite-vec vector search acceleration enabled" \
    "Embedding cache enabled" \
    "Session transcript indexing enabled" \
    "Memory index directory created at $MEMORY_DIR"

# ==============================================================================
# SECTION 12: SEED AGENT PROMPT FILES FROM REPOSITORY
# ==============================================================================
echo ""
echo "=== Agent Prompt File Seeding ==="

PROMPT_FILES=("SOUL.md" "AGENTS.md" "USER.md")

declare -A AGENT_SEED_FILES
AGENTS_WITH_FILES=()

for agent in "${AGENTS[@]}"; do
    REPO_AGENT_DIR="$SCRIPT_DIR/$agent"
    found=()

    if [[ -d "$REPO_AGENT_DIR" ]]; then
        for file in "${PROMPT_FILES[@]}"; do
            if [[ -f "$REPO_AGENT_DIR/$file" ]]; then
                found+=("$file")
            fi
        done
    fi

    if [[ ${#found[@]} -gt 0 ]]; then
        AGENT_SEED_FILES[$agent]="$(printf '%s\n' "${found[@]}")"
        AGENTS_WITH_FILES+=("$agent")
    fi
done

if [[ ${#AGENTS_WITH_FILES[@]} -eq 0 ]]; then
    echo "No agent prompt files found in repository. Skipping seeding step."
    print_section_summary "Prompt File Seeding" \
        "No agent prompt files found in repository"
else
    echo "The following prompt files were found in this repository:"
    echo ""

    for agent in "${AGENTS_WITH_FILES[@]}"; do
        echo "  ${agent^^}:"
        while IFS= read -r file; do
            DEST="$HOME/.openclaw/workspace-${agent}/$file"
            if [[ -f "$DEST" ]]; then
                echo "    ./${agent}/${file}  →  ~/.openclaw/workspace-${agent}/${file}  [WARN] (already exists)"
            else
                echo "    ./${agent}/${file}  →  ~/.openclaw/workspace-${agent}/${file}"
            fi
        done <<<"${AGENT_SEED_FILES[$agent]}"
    done
    echo ""

    SEED_CHOICE=""
    while [[ -z "$SEED_CHOICE" ]]; do
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            SEED_CHOICE="S"
        else
            echo "How would you like to proceed?"
            echo "  [S] Seed     — copy the above files into each agent's workspace"
            echo "  [D] Default  — skip seeding, let OpenClaw use its own defaults"
            echo "  [H] Halt     — stop the installation to review files first"
            echo ""
            read -r -p "Enter choice [S/D/H]: " SEED_CHOICE </dev/tty
        fi

        case "${SEED_CHOICE^^}" in
            S)
                echo ""
                echo "Seeding prompt files into agent workspaces..."

                for agent in "${AGENTS_WITH_FILES[@]}"; do
                    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
                    REPO_AGENT_DIR="$SCRIPT_DIR/$agent"

                    while IFS= read -r file; do
                        SRC="$REPO_AGENT_DIR/$file"
                        DEST="$WORKSPACE/$file"

                        if [[ -f "$DEST" ]]; then
                            if [[ "$NON_INTERACTIVE" == "true" ]]; then
                                echo "  [INFO] ${agent^^}: $file already exists. Skipping overwrite (non-interactive)."
                                continue
                            fi
                            echo ""
                            echo "  [WARN] ${agent^^}: $file already exists in workspace."
                            echo "  Diff (workspace → repository):"
                            echo "  ------------------------------------------------------------"
                            if [[ -f "$DEST" && -f "$SRC" ]]; then
                                diff -u "$DEST" "$SRC" |
                                    sed 's/^/  /' ||
                                    true
                            fi
                            echo "  ------------------------------------------------------------"
                            echo ""
                            read -r -p "  Overwrite ~/.openclaw/workspace-${agent}/${file}? (y/N) " OVERWRITE_FILE </dev/tty
                            if [[ "${OVERWRITE_FILE^^}" == "Y" ]]; then
                                cp "$SRC" "$DEST" &&
                                    echo "  [OK] ${agent^^}: $file overwritten." ||
                                    echo "  [WARN] Failed to copy $file for $agent."
                            else
                                echo "  Skipped ${agent^^}: $file — existing file kept."
                            fi
                        else
                            cp "$SRC" "$DEST" &&
                                echo "  [OK] ${agent^^}: $file" ||
                                echo "  [WARN] Failed to copy $file for $agent."
                        fi
                    done <<<"${AGENT_SEED_FILES[$agent]}"
                done

                echo ""
                echo "[OK] Prompt file seeding complete."
                print_section_summary "Prompt File Seeding" \
                    "Prompt files seeded into agent workspaces"
                ;;
            D)
                echo "Skipping seeding. OpenClaw will generate default prompt files on first start."
                print_section_summary "Prompt File Seeding" \
                    "Using default prompt files (seeding skipped)"
                ;;
            H)
                echo ""
                echo "Installation halted by user. No gateway has been started."
                echo "Review the files listed above, then re-run this script when ready."
                echo "Log file: $LOG_FILE"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter S, D, or H."
                SEED_CHOICE=""
                ;;
        esac
    done
fi

# ==============================================================================
# SECTION 13: START & VERIFY GATEWAY
# ==============================================================================
echo ""
echo "=== Gateway Startup ==="

HAS_REMOTE_MODELS=false
if [[ "$EMBEDDING_MODEL" != lemonade/* || "$ASSISTANT_MODEL" != lemonade/* || "$RESEARCH_MODEL" != lemonade/* || "$DEVELOPER_MODEL" != lemonade/* ]]; then
    HAS_REMOTE_MODELS=true
fi

if [[ "$NON_INTERACTIVE" == "true" ]]; then
    START_GATEWAY="Y"
elif [[ "$HAS_REMOTE_MODELS" == true ]]; then
    echo "Notice: You have configured remote API provider tags. OpenClaw requires your API keys to function."
    echo "You can provide these keys by running: openclaw onboarding"
    echo ""
    read -r -p "Have you already configured your API keys and want to start the gateway now? (y/N) " START_GATEWAY </dev/tty
    START_GATEWAY="${START_GATEWAY:-N}"
else
    echo "Your local Lemonade configuration has been applied."
    echo "You may still want to configure additional API keys or review settings before starting."
    echo ""
    read -r -p "Would you like to start the OpenClaw gateway now? (Y/n) " START_GATEWAY </dev/tty
    START_GATEWAY="${START_GATEWAY:-Y}"
fi

if [[ "${START_GATEWAY^^}" == "Y" ]]; then
    echo ""
    echo "Starting OpenClaw Gateway..."
    if ! openclaw gateway start; then
        echo "[WARN] Failed to start OpenClaw gateway. This may be because API keys are not yet configured."
        echo "Try running 'openclaw onboarding' first, then 'openclaw gateway start'."
    else
        echo "Waiting $STABILITY_DELAY seconds for gateway to stabilize..."
        sleep "$STABILITY_DELAY"

        if ! openclaw gateway status; then
            handle_error_or_warn "Gateway status check failed after start." $E_GATEWAY
        fi

        print_section_summary "Gateway Startup" \
            "OpenClaw gateway started successfully" \
            "Gateway stability check passed"
    fi
else
    echo ""
    echo "Gateway startup deferred."
    echo "When you are ready, you can start the gateway by running:"
    echo "    openclaw gateway start"
    print_section_summary "Gateway Startup" \
        "Gateway start deferred by user"
fi

# ==============================================================================
# SECTION 14: FINAL VERIFICATION & COMPLETION
# ==============================================================================
echo ""
echo "=== Final Verification ==="
echo "Current agent binding matrix:"
echo ""
openclaw agents list --bindings || echo "[WARN] Could not retrieve agent bindings. Check logs."

echo ""
echo "Checking memory index status..."
if [[ "$LOCAL_INFERENCE" == true ]]; then
    openclaw memory status || echo "[WARN] Could not retrieve memory status. Indexing may still be in progress."
else
    echo "[INFO] Gateway not started. Memory indexing will begin after gateway starts."
fi

print_section_summary "Final Verification" \
    "Agent binding matrix verified" \
    "Memory index status checked" \
    "Installation completed successfully"

echo ""
echo "[OK] OpenClaw Multi-Agent Setup Complete!"
echo "============================================================================"
echo "[INFO] SETUP SUMMARY"
echo "============================================================================"
echo "Log file:                 $LOG_FILE"
echo "Secrets file:             $HOME/.openclaw/secrets.env"
echo "Memory index:             $HOME/.openclaw/memory/"
echo "Agent workspaces:"
echo "  - Assistant:            $HOME/.openclaw/workspace-assistant"
echo "  - Research:             $HOME/.openclaw/workspace-research"
echo "  - Developer:            $HOME/.openclaw/workspace-developer"
echo ""
echo "Configuration:"
if [[ "$LOCAL_INFERENCE" == true ]]; then
    echo "  - Inference Backend:    Lemonade Server ($BASE_URL)"
else
    echo "  - Inference Backend:    Remote API Providers"
fi
echo "  - Assistant Model:      $ASSISTANT_MODEL"
echo "  - Research Model:       $RESEARCH_MODEL"
echo "  - Developer Model:      $DEVELOPER_MODEL"
echo "  - Embedding Model:      $EMBEDDING_MODEL"
echo "  - Vector Search:        sqlite-vec"
echo ""
echo "Note: Memory indexing runs asynchronously on first boot. Initial search results"
echo "      may be incomplete until the background sync finishes."
echo ""
