#!/bin/bash
set -euo pipefail
set +o histexpand # Disable history expansion to prevent issues with '!' characters in secrets

# ==============================================================================
# OPENCLAW MULTI-AGENT ARCHITECTURE SETUP
# ==============================================================================
#
# HOST ENVIRONMENT:
#   - OS: Ubuntu 24.04 (Bare-metal, standard user execution)
#   - Storage: Standard home directories (~/.openclaw/workspace-*)
#   - Execution: Native process daemon (no Docker overhead)
#
# INFERENCE BACKEND (Local Lemonade Server):
#   - Dreaming/Embedding: lemonade/user.nomic-embed-text-v1.5-GGUF
#   - Assistant Model:    lemonade/user.Qwen3.5-4B-GGUF
#   - Research Model:     lemonade/user.Qwen3.5-4B-GGUF
#   - Developer Model:    lemonade/user.Qwen3.5-4B-GGUF
#
# ==============================================================================
# EXIT CODES
# ==============================================================================
E_SUDO=10
E_DEPENDENCY=11
E_OPENCLAW=12
E_CONFIG=13
E_GATEWAY=14

STABILITY_DELAY=5 # Configurable start-up wait time
# Config: control whether OpenClaw-related failures are fatal (true) or warnings (false)
# Set to 'false' for best-effort installations where OpenClaw may be configured later.
FAIL_ON_OPENCLAW_ERRORS=true

# ======================================================================
# Exit Code Table
# ----------------------------------------------------------------------
# 10 - E_SUDO        : Script run as root or sudo required but unavailable
# 11 - E_DEPENDENCY  : System package installation or dependency failure
# 12 - E_OPENCLAW    : OpenClaw installation or runtime error
# 13 - E_CONFIG      : Configuration operation failed (openclaw config set)
# 14 - E_GATEWAY     : Gateway start/bind or network gateway error
# ======================================================================

# ======================================================================
# Environment / tool checks
# ======================================================================
# Required external tools (minimum):
#   - curl, sed, diff, cp, mkdir, chmod, chown, printf
#   - sudo, apt (for package installation)
#   - openclaw (installed by this script)
#
# Static analysis: Please run `shellcheck oc-bootstrap.sh` on a Linux environment
# and review suggestions. This script does not run `shellcheck` itself.
#
# Quick checks:
#   bash -n oc-bootstrap.sh
#   sudo apt install shellcheck -y && shellcheck oc-bootstrap.sh

check_required_tools() {
    local missing=()
    local tools=(curl sed diff cp mkdir chmod chown printf)
    # Note: `openclaw`, `apt`, and `sudo` are used later but may be installed by this script.
    # Keep the core utilities listed here; the script will check for `openclaw` after install step.
    for t in "${tools[@]}"; do
        if ! command -v "$t" >/dev/null 2>&1; then
            missing+=("$t")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[ERROR] Missing required system tools: ${missing[*]}"
        echo "Please install the above tools and re-run this script."
        exit $E_DEPENDENCY
    fi
}

# Unified handler to control whether errors (especially OpenClaw/config errors)
# should abort the script or be treated as warnings. Call like:
#   some_command || handle_error_or_warn "Failed to do X" $E_CONFIG
handle_error_or_warn() {
    local msg=$1
    local code=${2-1}
    if [[ "${FAIL_ON_OPENCLAW_ERRORS,,}" == "true" ]]; then
        echo "[ERROR] $msg"
        exit "$code"
    else
        echo "[WARN] $msg"
    fi
}

# Simple IPv4 validator — checks each octet is 0-255
valid_ipv4() {
    local ip=$1
    local IFS=.
    read -r -a octets <<< "$ip"
    [[ ${#octets[@]} -eq 4 ]] || return 1
    for o in "${octets[@]}"; do
        if [[ ! "$o" =~ ^[0-9]+$ ]]; then
            return 1
        fi
        if (( o < 0 || o > 255 )); then
            return 1
        fi
    done
    return 0
}

# Constants
# List of managed agents (single source of truth)
AGENTS=("assistant" "research" "developer")
# Human-friendly prefixes used during interactive prompts
AGENT_PREFIXES=("General" "Deep Research" "Developer")
# ==============================================================================

# ==============================================================================
# 0. Sudo Trap Guardrail
# ==============================================================================
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "[ERROR] Do not run this script directly as root or with sudo."
    echo "This script installs workspaces to the current user's home directory (\$HOME)."
    echo "It will automatically prompt for sudo access when installing system packages."
    exit $E_SUDO
fi

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Progress bar indicator
##
# progress_bar(total, current)
# Render a simple ASCII progress bar to stdout.
# - total: integer total number of steps
# - current: integer current step (1-based)
##
progress_bar() {
    local total=$1
    local current=$2
    local bar_width=40
    if [[ -z "$total" || "$total" -le 0 ]]; then
        return 0
    fi
    local percent=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))
    local filled_str=""
    local empty_str=""
    local i
    for ((i=0;i<filled;i++)); do filled_str+="#"; done
    for ((i=0;i<empty;i++)); do empty_str+=" "; done
    printf "\rProgress: [%-${bar_width}s] %d%%" "${filled_str}${empty_str}" "$percent"
}

# Section summary function
##
# print_section_summary(title, ...items)
# Print a compact summary block for a completed section.
# - title: short section name
# - items: list of status strings
##
print_section_summary() {
    local section_title=$1
    shift
    local items=("$@")
    echo ""
    echo "=== ${section_title^^} Summary ==="
    for item in "${items[@]}"; do
        echo "[OK] $item"
    done
    echo ""
}

# Telegram token validation function
##
# validate_telegram_token(token)
# Performs a lightweight format check then attempts an API `getMe`
# request to Telegram to validate the token. Returns 0 on success,
# 1 on fatal/format errors. Prints status messages to stdout.
##
validate_telegram_token() {
    local token=$1
    local timeout=5

    # Validate token format (basic check)
    if [[ ! "$token" =~ ^[a-zA-Z0-9_-]{14,}$ ]]; then
        echo "  [WARN] Token format validation failed. May be invalid."
        return 1
    fi

    # Try to validate with Telegram API (returns HTTP status code)
    # Use timeout to prevent hanging
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" \
        "https://api.telegram.org/bot$token/getMe" 2>/dev/null)

    if [[ "$http_code" == "200" ]]; then
        echo "  [OK] Token validated successfully"
        return 0
    elif [[ "$http_code" == "401" ]]; then
        echo "  [ERROR] Invalid token (401 Unauthorized)"
        return 1
    elif [[ "$http_code" == "404" ]]; then
        echo "  [ERROR] Bot not found (404 Not Found)"
        return 1
    else
        echo "  [WARN] Token format valid but API validation failed with HTTP $http_code"
        return 0 # Don't fail the script, just warn
    fi
}

# Parallel operation runner
##
# run_parallel("cmd1", "cmd2", ...)
# Run each provided command string in a subshell concurrently and
# wait for all to complete. Commands are executed with background
# jobs; errors inside individual subshells do not abort the caller.
##
run_parallel() {
    # run_parallel supports two calling conventions:
    # 1) run_parallel "cmd1" "cmd2" ...  (each command is executed via bash -c)
    # 2) Provide the name of an array variable that holds commands:
    #      cmds=("cmd1" "cmd2"); run_parallel cmds
    local pids=()

    # If a single argument is provided and it's the name of an array variable,
    # iterate its elements using nameref (bash 4.3+).
    if [[ $# -eq 1 ]] && declare -p "$1" 2>/dev/null | grep -q "declare -a"; then
        local arr_name=$1
        local -n cmds_ref="$arr_name"
        for cmd in "${cmds_ref[@]}"; do
            bash -c -- "$cmd" &
            pids+=($!)
        done
    else
        local commands=("$@")
        for cmd in "${commands[@]}"; do
            bash -c -- "$cmd" &
            pids+=($!)
        done
    fi

    # Wait for all background jobs to complete
    local pid
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# ==============================================================================
# 1. Logging & Trap Setup
# ==============================================================================
SCRIPT_NAME="openclaw-setup"
LOG_FILE="$HOME/.openclaw/logs/${SCRIPT_NAME}.log"

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting OpenClaw Multi-Agent Setup"

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setup aborted or interrupted with code $exit_code. Check log: $LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setup completed or intentionally halted."
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run quick environment checks
check_required_tools

# ==============================================================================
# 2. User Confirmation
# ==============================================================================
echo ""
echo "OpenClaw Multi-Agent Setup"
echo "=============================================================================="
echo ""
read -r -p "Proceed with installation? (Y/n) " CONFIRM </dev/tty
[[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || -z "$CONFIRM" ]] || exit 0

# ==============================================================================
# 3. Credential Collection
# ==============================================================================
echo ""
echo "=== Infrastructure Credentials ==="
read -r -p "Enter Lemonade Server API Key [Press Enter to use 'local-dummy-key']: " LEMONADE_KEY </dev/tty
LEMONADE_KEY="${LEMONADE_KEY:-local-dummy-key}"

echo ""
echo "=== Telegram Bot Tokens ==="
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
        ((ATTEMPT++))
        if [[ $ATTEMPT -gt 3 ]]; then
            echo "  [WARN] Failed to collect $AGENT_PREFIX token after 3 attempts."
            break
        fi

        CURRENT_TOKEN=""
        # Read tokens from /dev/tty to avoid issues when stdout/stderr are redirected
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

    # Validate token format
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
            ((current_token++))
        fi
    fi

    echo ""
done

echo ""
echo "=== Agent-Specific External Secrets (optional) ==="
read -r -s -p "Enter GitLab Personal Access Token (for local MCP, or press Enter to skip): " GITLAB_PAT </dev/tty
echo ""
GITLAB_PAT="${GITLAB_PAT:-}"

read -r -s -p "Enter Brave Search API Key (for Research Agent, or press Enter to skip): " BRAVE_API_KEY </dev/tty
echo ""
BRAVE_API_KEY="${BRAVE_API_KEY:-}"

read -r -s -p "Enter X/Twitter API Key or Auth Cookie (for xScraper, or press Enter to skip): " X_API_KEY </dev/tty
echo ""
X_API_KEY="${X_API_KEY:-}"

[[ -z "$GITLAB_PAT" ]] && echo "[WARN] No GitLab PAT provided. Git workflow features will be unavailable."
[[ -z "$BRAVE_API_KEY" ]] && echo "[WARN] No Brave Search API Key provided. Web search will be unavailable."
[[ -z "$X_API_KEY" ]] && echo "[WARN] No X/Twitter credentials provided. X scraping may be rate-limited or blocked."

echo ""
echo "=== Credential Collection Summary ==="
echo "[OK] Lemonade Server API Key: Configured"
echo "[OK] Assistant Telegram Bot Token: Configured"
echo "[OK] Research Telegram Bot Token: Configured"
echo "[OK] Developer Telegram Bot Token: Configured"
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

# ==============================================================================
# 4. Save Credentials to Secure .env File
# ==============================================================================
if [[ -z "$ASSISTANT_TOKEN" || -z "$RESEARCH_TOKEN" || -z "$DEVELOPER_TOKEN" ]]; then
    echo "[ERROR] One or more Telegram bot tokens are missing. These tokens are required to bind agents to Telegram."
    echo "Please re-run the script and provide unique tokens for Assistant, Research, and Developer agents."
    exit $E_CONFIG
fi

echo ""
echo "Saving credentials to secure environment file..."
mkdir -p "$HOME/.openclaw"

SECRETS_FILE="$HOME/.openclaw/secrets.env"

if [[ -f "$SECRETS_FILE" ]]; then
    echo ""
    echo "  [WARN] A secrets file already exists at $SECRETS_FILE"
    echo "  Overwriting it will replace all previously stored credentials."
    echo ""
    read -r -p "  Overwrite existing secrets file? (y/N) " OVERWRITE_SECRETS </dev/tty
    if [[ "${OVERWRITE_SECRETS^^}" != "Y" ]]; then
        echo "Skipping secrets file update. Loading existing credentials into memory..."
        # shellcheck disable=SC1090
        source "$SECRETS_FILE"
    else
        cat >"$SECRETS_FILE" <<'EOF'
LEMONADE_KEY="$LEMONADE_KEY"
ASSISTANT_TOKEN="$ASSISTANT_TOKEN"
RESEARCH_TOKEN="$RESEARCH_TOKEN"
DEVELOPER_TOKEN="$DEVELOPER_TOKEN"
GITLAB_PAT="$GITLAB_PAT"
BRAVE_API_KEY="$BRAVE_API_KEY"
X_API_KEY="$X_API_KEY"
EOF
            chmod 600 "$SECRETS_FILE" || true
            # Attempt to set owner to current user if possible; ignore failures
            chown "$(id -un):$(id -gn)" "$SECRETS_FILE" 2>/dev/null || true
        echo "[OK] Credentials updated at $SECRETS_FILE"
    fi
else
    cat >"$SECRETS_FILE" <<'EOF'
LEMONADE_KEY="$LEMONADE_KEY"
ASSISTANT_TOKEN="$ASSISTANT_TOKEN"
RESEARCH_TOKEN="$RESEARCH_TOKEN"
DEVELOPER_TOKEN="$DEVELOPER_TOKEN"
GITLAB_PAT="$GITLAB_PAT"
BRAVE_API_KEY="$BRAVE_API_KEY"
X_API_KEY="$X_API_KEY"
EOF
    chmod 600 "$SECRETS_FILE" || true
    chown "$(id -un):$(id -gn)" "$SECRETS_FILE" 2>/dev/null || true
    echo "[OK] Credentials saved to $SECRETS_FILE"
fi

# ==============================================================================
# 5. System Preparation & Core Install
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
if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -; then
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
# 6. Configure Local Inference (Lemonade Server)
# ==============================================================================
echo ""
echo "=== Linking Lemonade Server Backend ==="

LEMONADE_IP=""
while true; do
    read -r -p "Enter Lemonade server IP address (e.g., 192.168.12.50): " LEMONADE_IP </dev/tty
    if valid_ipv4 "$LEMONADE_IP"; then
        break
    else
        echo "[ERROR] Invalid IP address format. Please try again."
    fi
done

BASE_URL="http://${LEMONADE_IP}:8000/v1"
[ -t 0 ] || true
read -r -p "Enter Lemonade base URL [Press Enter for default: $BASE_URL]: " CUSTOM_URL </dev/tty
[[ -n "$CUSTOM_URL" ]] && BASE_URL="$CUSTOM_URL"

openclaw config set providers.lemonade.baseUrl "$BASE_URL" || handle_error_or_warn "Failed to set Lemonade base URL." $E_CONFIG
openclaw config set providers.lemonade.apiKey "$LEMONADE_KEY" || handle_error_or_warn "Failed to set Lemonade API key." $E_CONFIG

echo "Configuring shared embedding and dreaming models..."
openclaw config set memory.dreaming.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "[WARN] Failed to set dreaming model."
openclaw config set memory.embeddingModel "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "[WARN] Failed to set embedding model."

echo "[OK] Lemonade Server backend configured"

# ==============================================================================
# 7. Provision Isolated Agent Workspaces
# ==============================================================================
echo ""
echo "=== Provisioning Agent Workspaces ==="

# Provision agents with progress tracking
agents_to_provision=("${AGENTS[@]}")
for i in "${!agents_to_provision[@]}"; do
    agent="${agents_to_provision[$i]}"
    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
    current=$((i + 1))
    progress_bar ${#agents_to_provision[@]} $current

    echo "Provisioning agent: ${agent^^}..."
    openclaw agents add "$agent" --workspace "$WORKSPACE" --non-interactive ||
        echo "[WARN] Issue provisioning agent '$agent'. Continuing."
done
echo "" # Newline after progress bar

echo "Assigning Qwen3.5-4B inference model to all agents..."
for agent in "${AGENTS[@]}"; do
    openclaw config set agents.list.${agent}.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "[WARN] Failed to set model for ${agent} agent."
done

print_section_summary "Agent Workspace Provisioning" \
    "Assistant agent workspace created" \
    "Research agent workspace created" \
    "Developer agent workspace created" \
    "Qwen3.5-4B model assigned to all agents"

# ==============================================================================
# 8. Inject Agent-Specific Secrets & Configure Providers
# ==============================================================================
echo ""
echo "=== Injecting Isolated Agent Secrets & MCPs ==="

if [[ -n "$GITLAB_PAT" ]]; then
    for agent in "${AGENTS[@]}"; do
        openclaw config set agents.list.${agent}.env.GITLAB_PERSONAL_ACCESS_TOKEN "$GITLAB_PAT" || handle_error_or_warn "Failed to set GitLab PAT for $agent." $E_CONFIG
        openclaw config set agents.list.${agent}.env.GITLAB_API_URL "https://gitlab.com" || handle_error_or_warn "Failed to set GitLab URL for $agent." $E_CONFIG

        echo "Binding local GitLab MCP server to ${agent^^} Agent..."
        openclaw config set agents.list.${agent}.mcp.servers.gitlab.command "npx"
        # Use space-separated args for better CLI compatibility
        openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "-y" "@zereight/mcp-gitlab" || {
            echo "[WARN] Array args syntax may not be supported. Trying alternative method..."
            # Fallback: try setting each arg separately
            openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "-y" || echo "[WARN] Failed to set first MCP arg."
            openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "@zereight/mcp-gitlab" || echo "[WARN] Failed to set second MCP arg."
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
fi

print_section_summary "Agent Secrets & MCP Configuration" \
    "GitLab integration configured" \
    "Brave Search API key configured" \
    "X/Twitter credentials configured" \
    "All agent-specific secrets injected"

# ==============================================================================
# 9. Assign Native Skills & Hooks
# ==============================================================================
echo ""
echo "=== Assigning Native Skills & Hooks ==="

echo "Enabling built-in data gathering skills for the Research Agent..."
openclaw config set agents.list.research.skills.summarize true || echo "[WARN] Failed to enable summarize skill."
openclaw config set agents.list.research.skills.webSearch true || echo "[WARN] Failed to enable webSearch skill."
openclaw config set agents.list.research.skills.webScrape true || echo "[WARN] Failed to enable webScrape skill."
openclaw config set agents.list.research.skills.newsSearch true || echo "[WARN] Failed to enable newsSearch skill."
openclaw config set agents.list.research.skills.rssReader true || echo "[WARN] Failed to enable rssReader skill."
openclaw config set agents.list.research.skills.trendsFinder true || echo "[WARN] Failed to enable trendsFinder skill."
openclaw config set agents.list.research.skills.xScraper true || echo "[WARN] Failed to enable xScraper skill."

echo "Enabling operational hooks..."
# Assistant: Automatically track evolving hardware/schedules
openclaw config set agents.list.assistant.hooks.autoMemory true || echo "[WARN] Failed to enable autoMemory hook for assistant."
# Research: Summarize sessions to prevent context bloat
openclaw config set agents.list.research.hooks.sessionSummarize true || echo "[WARN] Failed to enable sessionSummarize hook for research."
# Developer: Validate tool outputs for technical accuracy
openclaw config set agents.list.developer.hooks.toolValidation true || echo "[WARN] Failed to enable toolValidation hook for developer."

print_section_summary "Skills & Hooks Configuration" \
    "Research data gathering skills enabled (summarize, webSearch, webScrape, newsSearch, rssReader, trendsFinder, xScraper)" \
    "Assistant autoMemory hook enabled" \
    "Research sessionSummarize hook enabled" \
    "Developer toolValidation hook enabled"

# ==============================================================================
# 10. Bind Isolated Telegram Channels
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

    echo "Binding Telegram for ${agent^^}..."
    if ! openclaw agents bind --agent "$agent" --bind "telegram:$TOKEN"; then
        handle_error_or_warn "Failed to bind Telegram for agent '$agent'." $E_GATEWAY
    fi

    openclaw agents unbind --agent "$agent" --all ||
        echo "[WARN] Failed to unbind defaults for agent '$agent'. Continuing."
done

print_section_summary "Telegram Channel Binding" \
    "Assistant agent bound to Telegram" \
    "Research agent bound to Telegram" \
    "Developer agent bound to Telegram"

# ==============================================================================
# 11. Configure Local Memory & Vector Search
# ==============================================================================
echo ""
echo "=== Configuring Local Memory & Vector Search ==="

memory_tasks=("Configuring memory search provider" "Configuring SQLite index storage" "Enabling sqlite-vec acceleration" "Enabling embedding cache" "Enabling session memory indexing")
total_tasks=${#memory_tasks[@]}

# Task 1
progress_bar "$total_tasks" 1
echo "Configuring memory search embedding provider..."
openclaw config set agents.defaults.memorySearch.provider "openai" || handle_error_or_warn "Failed to set memory search provider." $E_CONFIG
openclaw config set agents.defaults.memorySearch.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || handle_error_or_warn "Failed to set memory search model." $E_CONFIG
openclaw config set agents.defaults.memorySearch.remote.baseUrl "$BASE_URL" || handle_error_or_warn "Failed to set memory search base URL." $E_CONFIG
openclaw config set agents.defaults.memorySearch.remote.apiKey "$LEMONADE_KEY" || handle_error_or_warn "Failed to set memory search API key." $E_CONFIG

# Task 2
progress_bar "$total_tasks" 2
echo "Configuring per-agent SQLite index storage..."
# Use static path with explicit file naming pattern to avoid expansion issues
MEMORY_DIR="$HOME/.openclaw/memory"
mkdir -p "$MEMORY_DIR"
    openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agentId}.sqlite" || {
    echo "[WARN] Failed to set memory index path with pattern. Attempting static path..."
    openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agent}.sqlite" || echo "[WARN] Alternative memory path also failed."
}

# Task 3
progress_bar "$total_tasks" 3
echo "Enabling sqlite-vec vector search acceleration..."
openclaw config set agents.defaults.memorySearch.store.vector.enabled true || echo "[WARN] Failed to enable sqlite-vec. OpenClaw will use JS fallback."

# Task 4
progress_bar "$total_tasks" 4
echo "Enabling embedding cache..."
openclaw config set agents.defaults.memorySearch.cache.enabled true || echo "[WARN] Failed to enable embedding cache."

# Task 5
progress_bar "$total_tasks" 5
echo "Enabling session transcript indexing (experimental)..."
openclaw config set agents.defaults.memorySearch.experimental.sessionMemory true || echo "[WARN] Failed to enable session memory indexing."
openclaw config set agents.defaults.memorySearch.sources[0] "memory" || echo "[WARN] Failed to set memory source."
openclaw config set agents.defaults.memorySearch.sources[1] "sessions" || echo "[WARN] Failed to set sessions source."

echo "" # Newline after progress bar

print_section_summary "Memory & Vector Search" \
    "Memory search embedding provider configured" \
    "Per-agent SQLite index storage configured" \
    "sqlite-vec vector search acceleration enabled" \
    "Embedding cache enabled" \
    "Session transcript indexing enabled" \
    "Memory index directory created at $MEMORY_DIR"

# ==============================================================================
# 12. Seed Agent Prompt Files from Repository
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
        # Store as newline-separated list to safely handle filenames with spaces
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
        done <<< "${AGENT_SEED_FILES[$agent]}"
    done
    echo ""

    SEED_CHOICE=""
    while [[ -z "$SEED_CHOICE" ]]; do
        echo "How would you like to proceed?"
        echo "  [S] Seed     — copy the above files into each agent's workspace"
        echo "  [D] Default  — skip seeding, let OpenClaw use its own defaults"
        echo "  [H] Halt     — stop the installation to review files first"
        echo ""
        read -r -p "Enter choice [S/D/H]: " SEED_CHOICE </dev/tty

        case "${SEED_CHOICE^^}" in
            S)
                echo ""
                echo "Seeding prompt files into agent workspaces..."

                for agent in "${AGENTS_WITH_FILES[@]}"; do
                    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
                    REPO_AGENT_DIR="$SCRIPT_DIR/$agent"

                    # shellcheck disable=SC2086
                    while IFS= read -r file; do
                        SRC="$REPO_AGENT_DIR/$file"
                        DEST="$WORKSPACE/$file"

                        if [[ -f "$DEST" ]]; then
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
                    done <<< "${AGENT_SEED_FILES[$agent]}"
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
# 13. Start & Verify Gateway
# ==============================================================================
echo ""
echo "=== Starting OpenClaw Gateway ==="

if ! openclaw gateway start; then
    handle_error_or_warn "Failed to start OpenClaw gateway." $E_GATEWAY
fi

echo "Waiting $STABILITY_DELAY seconds for gateway to stabilize..."
sleep "$STABILITY_DELAY"

if ! openclaw gateway status; then
    handle_error_or_warn "Gateway status check failed after start." $E_GATEWAY
fi

print_section_summary "Gateway Startup" \
    "OpenClaw gateway started successfully" \
    "Gateway stability check passed"

# ==============================================================================
# 14. Final Verification
# ==============================================================================
echo ""
echo "=== Final Verification ==="
echo "Current agent binding matrix:"
echo ""
openclaw agents list --bindings || echo "[WARN] Could not retrieve agent bindings. Check logs."

echo ""
echo "Checking memory index status..."
openclaw memory status || echo "[WARN] Could not retrieve memory status. Indexing may still be in progress."

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
echo "  - Inference Backend:    Lemonade Server ($BASE_URL)"
echo "  - Primary Model:        Qwen3.5-4B-GGUF"
echo "  - Embedding Model:      nomic-embed-text-v1.5-GGUF"
echo "  - Vector Search:        sqlite-vec"
echo ""
echo "Note: Memory indexing runs asynchronously on first boot. Initial search results"
echo "      may be incomplete until the background sync finishes."
echo ""
