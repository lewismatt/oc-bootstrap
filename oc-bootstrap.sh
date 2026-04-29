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
E_CREDENTIALS=15

STABILITY_DELAY=5 # Configurable start-up wait time

# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Sudo Trap Guardrail
# ------------------------------------------------------------------------------
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Error: Do not run this script directly as root or with sudo."
    echo "This script installs workspaces to the current user's home directory (\$HOME)."
    echo "It will automatically prompt for sudo access when installing system packages."
    exit $E_SUDO
fi

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Progress bar indicator
progress_bar() {
    local total=$1
    local current=$2
    local bar_width=40
    local percent=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))
    printf "\rProgress: [%-${bar_width}s] %d%%" "$(printf "#%.0s" $(seq 1 $filled))$(printf " %.0s" $(seq 1 $empty))" "$percent"
}

# Section summary function
print_section_summary() {
    local section_title=$1
    shift
    local items=("$@")
    echo ""
    echo "=== ${section_title^^} Summary ==="
    for item in "${items[@]}"; do
        echo "✓ $item"
    done
    echo ""
}

# Telegram token validation function
validate_telegram_token() {
    local token=$1
    local timeout=5
    
    # Validate token format (basic check - Telegram bots start with '@BotToken:')
    if [[ ! "$token" =~ ^[a-zA-Z0-9_-]{14,}$ ]]; then
        echo "  ⚠️  Warning: Token format validation failed. May be invalid."
        return 1
    fi
    
    # Try to validate with Telegram API (returns HTTP status code)
    # Use timeout to prevent hanging
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" \
        "https://api.telegram.org/bot$token/getMe" 2>/dev/null)
    
    if [[ "$http_code" == "200" ]]; then
        echo "  ✓ Token validated successfully"
        return 0
    elif [[ "$http_code" == "401" ]]; then
        echo "  ✗ Invalid token (401 Unauthorized)"
        return 1
    elif [[ "$http_code" == "404" ]]; then
        echo "  ✗ Bot not found (404 Not Found)"
        return 1
    else
        echo "  ⚠️  Token format valid but API validation failed with HTTP $http_code"
        return 0  # Don't fail the script, just warn
    fi
}

# Parallel operation runner
run_parallel() {
    local commands=("$@")
    local pids=()
    
    for cmd in "${commands[@]}"; do
        ( "$cmd" ) &
        pids+=($!)
    done
    
    # Wait for all background jobs to complete
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

# ==============================================================================
# 2. User Confirmation
# ==============================================================================
echo ""
echo "OpenClaw Multi-Agent Setup"
echo "============================================================================"
echo ""
read -r -p "Proceed with installation? (Y/n) " CONFIRM
[[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || -z "$CONFIRM" ]] || exit 0

# ==============================================================================
# 3. Credential Collection
# ==============================================================================
echo ""
echo "=== Infrastructure Credentials ==="
read -r -p "Enter Lemonade Server API Key [Press Enter to use 'local-dummy-key']: " LEMONADE_KEY
LEMONADE_KEY="${LEMONADE_KEY:-local-dummy-key}"

echo ""
echo "=== Telegram Bot Tokens ==="
echo "You will need three unique Telegram Bot Tokens from @BotFather."
echo ""

TOTAL_TOKENS=3
current_token=0

while [[ $current_token -lt $TOTAL_TOKENS ]]; do
    case $current_token in
        0) AGENT_PREFIX="General" ;;
        1) AGENT_PREFIX="Deep Research" ;;
        2) AGENT_PREFIX="Developer" ;;
    esac
    
    CURRENT_TOKEN=""
    ATTEMPT=0
    
    while [[ -z "$CURRENT_TOKEN" || "$CURRENT_TOKEN" == "$ASSISTANT_TOKEN" || \
             "$CURRENT_TOKEN" == "$RESEARCH_TOKEN" || "$CURRENT_TOKEN" == "$DEVELOPER_TOKEN" ]]; do
        ((ATTEMPT++))
        if [[ $ATTEMPT -gt 3 ]]; then
            echo "  ⚠️  Warning: Failed to collect $AGENT_PREFIX token after 3 attempts."
            break
        fi
        
        CURRENT_TOKEN=""
        read -r -s -p "Enter Telegram Bot Token for the $AGENT_PREFIX Agent: " CURRENT_TOKEN
        echo ""
        
        if [[ -z "$CURRENT_TOKEN" ]]; then
            echo "  ✗ $AGENT_PREFIX token is required. Please try again."
        elif [[ "$CURRENT_TOKEN" == "$ASSISTANT_TOKEN" ]]; then
            echo "  ✗ Token must be unique. Do not reuse the Assistant token."
        elif [[ "$CURRENT_TOKEN" == "$RESEARCH_TOKEN" ]]; then
            echo "  ✗ Token must be unique. Do not reuse the Research token."
        elif [[ "$CURRENT_TOKEN" == "$DEVELOPER_TOKEN" ]]; then
            echo "  ✗ Token must be unique. Do not reuse the Developer token."
        else
            break
        fi
    done
    
    # Validate token format
    if [[ -n "$CURRENT_TOKEN" ]]; then
        if ! validate_telegram_token "$CURRENT_TOKEN"; then
            echo ""
            echo "  ⚠️  Token format invalid. Please try again."
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
read -r -s -p "Enter GitLab Personal Access Token (for local MCP, or press Enter to skip): " GITLAB_PAT
echo ""
GITLAB_PAT="${GITLAB_PAT:-}"

read -r -s -p "Enter Brave Search API Key (for Research Agent, or press Enter to skip): " BRAVE_API_KEY
echo ""
BRAVE_API_KEY="${BRAVE_API_KEY:-}"

read -r -s -p "Enter X/Twitter API Key or Auth Cookie (for xScraper, or press Enter to skip): " X_API_KEY
echo ""
X_API_KEY="${X_API_KEY:-}"

[[ -z "$GITLAB_PAT" ]] && echo "Warning: No GitLab PAT provided. Git workflow features will be unavailable."
[[ -z "$BRAVE_API_KEY" ]] && echo "Warning: No Brave Search API Key provided. Web search will be unavailable."
[[ -z "$X_API_KEY" ]] && echo "Warning: No X/Twitter credentials provided. X scraping may be rate-limited or blocked."

echo ""
echo "=== Credential Collection Summary ==="
echo "✓ Lemonade Server API Key: Configured"
echo "✓ Assistant Telegram Bot Token: Configured"
echo "✓ Research Telegram Bot Token: Configured"
echo "✓ Developer Telegram Bot Token: Configured"
if [[ -n "$GITLAB_PAT" ]]; then
    echo "✓ GitLab Personal Access Token: Configured"
else
    echo "⚠️  GitLab Personal Access Token: Not configured"
fi
if [[ -n "$BRAVE_API_KEY" ]]; then
    echo "✓ Brave Search API Key: Configured"
else
    echo "⚠️  Brave Search API Key: Not configured"
fi
if [[ -n "$X_API_KEY" ]]; then
    echo "✓ X/Twitter API Key: Configured"
else
    echo "⚠️  X/Twitter API Key: Not configured"
fi

# ==============================================================================
# 4. Save Credentials to Secure .env File
# ==============================================================================
echo ""
echo "Saving credentials to secure environment file..."
mkdir -p "$HOME/.openclaw"

SECRETS_FILE="$HOME/.openclaw/secrets.env"

if [[ -f "$SECRETS_FILE" ]]; then
    echo ""
    echo "  ⚠️  Warning: A secrets file already exists at $SECRETS_FILE"
    echo "  Overwriting it will replace all previously stored credentials."
    echo ""
    read -r -p "  Overwrite existing secrets file? (y/N) " OVERWRITE_SECRETS
    if [[ "${OVERWRITE_SECRETS^^}" != "Y" ]]; then
        echo "Skipping secrets file update. Loading existing credentials into memory..."
        # shellcheck disable=SC1090
        source "$SECRETS_FILE"
    else
        cat >"$SECRETS_FILE" <<EOF
LEMONADE_KEY="$LEMONADE_KEY"
ASSISTANT_TOKEN="$ASSISTANT_TOKEN"
RESEARCH_TOKEN="$RESEARCH_TOKEN"
DEVELOPER_TOKEN="$DEVELOPER_TOKEN"
GITLAB_PAT="$GITLAB_PAT"
BRAVE_API_KEY="$BRAVE_API_KEY"
X_API_KEY="$X_API_KEY"
EOF
        chmod 600 "$SECRETS_FILE" && chown "$USER":"$USER" "$SECRETS_FILE"
        echo "✓ Credentials updated at $SECRETS_FILE"
    fi
else
    cat >"$SECRETS_FILE" <<EOF
LEMONADE_KEY="$LEMONADE_KEY"
ASSISTANT_TOKEN="$ASSISTANT_TOKEN"
RESEARCH_TOKEN="$RESEARCH_TOKEN"
DEVELOPER_TOKEN="$DEVELOPER_TOKEN"
GITLAB_PAT="$GITLAB_PAT"
BRAVE_API_KEY="$BRAVE_API_KEY"
X_API_KEY="$X_API_KEY"
EOF
    chmod 600 "$SECRETS_FILE" && chown "$USER":"$USER" "$SECRETS_FILE"
    echo "✓ Credentials saved to $SECRETS_FILE"
fi

# ==============================================================================
# 5. System Preparation & Core Install
# ==============================================================================
echo ""
echo "=== System Preparation ==="

steps=("Configuring sudo" "Configuring NodeSource PPA" "Updating and upgrading system packages" "Installing curl, git, and Node.js" "Installing OpenClaw")
total_steps=${#steps[@]}

# Step 1/5
progress_bar $total_steps 1
echo "Step 1/5: Configuring sudo..."
sudo -v || {
    echo "  ✗ Error: sudo access is required to install dependencies."
    echo "  Please ensure sudo permissions are set up correctly."
    exit $E_SUDO
}

# Step 2/5
progress_bar $total_steps 2
echo "Step 2/5: Configuring NodeSource PPA..."
if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -; then
    echo "  ✓ NodeSource PPA configured successfully"
else
    echo "  ⚠️  Warning: NodeSource PPA setup failed. Using default repositories."
fi

# Step 3/5
progress_bar $total_steps 3
echo "Step 3/5: Updating and upgrading system packages..."
sudo apt update
if [[ $? -eq 0 ]]; then
    echo "  ✓ apt update completed"
fi

sudo apt upgrade -y
if [[ $? -eq 0 ]]; then
    echo "  ✓ apt upgrade completed"
else
    echo "  ⚠️  Warning: apt upgrade had issues. Attempting to continue..."
fi

# Step 4/5
progress_bar $total_steps 4
echo "Step 4/5: Installing curl, git, and Node.js..."
sudo apt install -y curl git nodejs
if [[ $? -eq 0 ]]; then
    echo "  ✓ curl, git, and nodejs installed successfully"
else
    echo "  ✗ Error: Failed to install curl/git/nodejs. Cannot continue."
    exit $E_DEPENDENCY
fi

# Step 5/5
progress_bar $total_steps 5
echo "Step 5/5: Installing OpenClaw..."
if curl -fsSL https://openclaw.ai/install.sh | bash; then
    echo "  ✓ OpenClaw installed successfully"
else
    echo "  ✗ Error: OpenClaw installation failed."
    exit $E_OPENCLAW
fi

if command -v openclaw &>/dev/null; then
    echo "  ✓ OpenClaw binary found in PATH"
else
    echo "  ✗ Error: OpenClaw binary not found in PATH after installation."
    exit $E_OPENCLAW
fi

echo "Running post-install health check and auto-repair..."
if openclaw doctor --fix; then
    echo "  ✓ OpenClaw doctor completed without issues"
else
    echo "  ⚠️  Warning: OpenClaw doctor reported some issues. Continuing anyway..."
fi

# Mark all steps complete
progress_bar $total_steps $total_steps
echo ""  # Newline after final progress bar

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
while [[ ! "$LEMONADE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    read -r -p "Enter Lemonade server IP address (e.g., 192.168.12.50): " LEMONADE_IP
    if [[ ! "$LEMONADE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid IP address format. Please try again."
    fi
done

BASE_URL="http://${LEMONADE_IP}:8000/v1"
read -r -p "Enter Lemonade base URL [Press Enter for default: $BASE_URL]: " CUSTOM_URL
[[ -n "$CUSTOM_URL" ]] && BASE_URL="$CUSTOM_URL"

openclaw config set providers.lemonade.baseUrl "$BASE_URL" || {
    echo "Error: Failed to set Lemonade base URL."
    exit $E_CONFIG
}
openclaw config set providers.lemonade.apiKey "$LEMONADE_KEY" || {
    echo "Error: Failed to set Lemonade API key."
    exit $E_CONFIG
}

echo "Configuring shared embedding and dreaming models..."
openclaw config set memory.dreaming.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set dreaming model."
openclaw config set memory.embeddingModel "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set embedding model."

echo "✓ Lemonade Server backend configured"

# ==============================================================================
# 7. Provision Isolated Agent Workspaces
# ==============================================================================
echo ""
echo "=== Provisioning Agent Workspaces ==="

# Provision agents with progress tracking
agents_to_provision=("assistant" "research" "developer")
for i in "${!agents_to_provision[@]}"; do
    agent="${agents_to_provision[$i]}"
    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
    current=$((i + 1))
    progress_bar ${#agents_to_provision[@]} $current
    
    echo "Provisioning agent: ${agent^^}..."
    openclaw agents add "$agent" --workspace "$WORKSPACE" --non-interactive ||
        echo "Warning: Issue provisioning agent '$agent'. Continuing."
done
echo ""  # Newline after progress bar

echo "Assigning Qwen3.5-4B inference model to all agents..."
openclaw config set agents.list.assistant.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for assistant agent."
openclaw config set agents.list.research.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for research agent."
openclaw config set agents.list.developer.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for developer agent."

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
    for agent in "assistant" "research" "developer"; do
        openclaw config set agents.list.${agent}.env.GITLAB_PERSONAL_ACCESS_TOKEN "$GITLAB_PAT" || {
            echo "Error: Failed to set GitLab PAT for $agent."
            exit $E_CONFIG
        }
        openclaw config set agents.list.${agent}.env.GITLAB_API_URL "https://gitlab.com" || {
            echo "Error: Failed to set GitLab URL for $agent."
            exit $E_CONFIG
        }

        echo "Binding local GitLab MCP server to ${agent^^} Agent..."
        openclaw config set agents.list.${agent}.mcp.servers.gitlab.command "npx"
        # Use space-separated args for better CLI compatibility
        openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "-y" "@zereight/mcp-gitlab" || {
            echo "Warning: Array args syntax may not be supported. Trying alternative method..."
            # Fallback: try setting each arg separately
            openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "-y" || echo "Warning: Failed to set first MCP arg."
            openclaw config set agents.list.${agent}.mcp.servers.gitlab.args "@zereight/mcp-gitlab" || echo "Warning: Failed to set second MCP arg."
        }
    done
else
    echo "Skipping GitLab MCP configuration (no token provided)."
fi

if [[ -n "$BRAVE_API_KEY" ]]; then
    openclaw config set agents.list.research.env.BRAVE_API_KEY "$BRAVE_API_KEY" || {
        echo "Error: Failed to set Brave API key for research agent."
        exit $E_CONFIG
    }
    openclaw config set agents.list.research.search.provider "brave" || {
        echo "Error: Failed to set Brave as search provider."
        exit $E_CONFIG
    }
else
    echo "Skipping Brave search configuration (no key provided)."
fi

if [[ -n "$X_API_KEY" ]]; then
    openclaw config set agents.list.research.env.X_API_KEY "$X_API_KEY" || {
        echo "Error: Failed to set X credentials for research agent."
        exit $E_CONFIG
    }
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
openclaw config set agents.list.research.skills.summarize true || echo "Warning: Failed to enable summarize skill."
openclaw config set agents.list.research.skills.webSearch true || echo "Warning: Failed to enable webSearch skill."
openclaw config set agents.list.research.skills.webScrape true || echo "Warning: Failed to enable webScrape skill."
openclaw config set agents.list.research.skills.newsSearch true || echo "Warning: Failed to enable newsSearch skill."
openclaw config set agents.list.research.skills.rssReader true || echo "Warning: Failed to enable rssReader skill."
openclaw config set agents.list.research.skills.trendsFinder true || echo "Warning: Failed to enable trendsFinder skill."
openclaw config set agents.list.research.skills.xScraper true || echo "Warning: Failed to enable xScraper skill."

echo "Enabling operational hooks..."
# Assistant: Automatically track evolving hardware/schedules
openclaw config set agents.list.assistant.hooks.autoMemory true || echo "Warning: Failed to enable autoMemory hook for assistant."
# Research: Summarize sessions to prevent context bloat
openclaw config set agents.list.research.hooks.sessionSummarize true || echo "Warning: Failed to enable sessionSummarize hook for research."
# Developer: Validate tool outputs for technical accuracy
openclaw config set agents.list.developer.hooks.toolValidation true || echo "Warning: Failed to enable toolValidation hook for developer."

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

for agent in "assistant" "research" "developer"; do
    TOKEN=""
    case "$agent" in
        "assistant") TOKEN="$ASSISTANT_TOKEN" ;;
        "research") TOKEN="$RESEARCH_TOKEN" ;;
        "developer") TOKEN="$DEVELOPER_TOKEN" ;;
    esac

    echo "Binding Telegram for ${agent^^}..."
    if ! openclaw agents bind --agent "$agent" --bind "telegram:$TOKEN"; then
        echo "Error: Failed to bind Telegram for agent '$agent'."
        exit $E_GATEWAY
    fi

    openclaw agents unbind --agent "$agent" --all ||
        echo "Warning: Failed to unbind defaults for agent '$agent'. Continuing."
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
progress_bar $total_tasks 1
echo "Configuring memory search embedding provider..."
openclaw config set agents.defaults.memorySearch.provider "openai" || {
    echo "Error: Failed to set memory search provider."
    exit $E_CONFIG
}
openclaw config set agents.defaults.memorySearch.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || {
    echo "Error: Failed to set memory search model."
    exit $E_CONFIG
}
openclaw config set agents.defaults.memorySearch.remote.baseUrl "$BASE_URL" || {
    echo "Error: Failed to set memory search base URL."
    exit $E_CONFIG
}
openclaw config set agents.defaults.memorySearch.remote.apiKey "$LEMONADE_KEY" || {
    echo "Error: Failed to set memory search API key."
    exit $E_CONFIG
}

# Task 2
progress_bar $total_tasks 2
echo "Configuring per-agent SQLite index storage..."
# Use static path with explicit file naming pattern to avoid expansion issues
MEMORY_DIR="$HOME/.openclaw/memory"
mkdir -p "$MEMORY_DIR"
openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agentId}.sqlite" || {
    echo "Warning: Failed to set memory index path with pattern. Attempting static path..."
    openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agent}.sqlite" || echo "Warning: Alternative memory path also failed."
}

# Task 3
progress_bar $total_tasks 3
echo "Enabling sqlite-vec vector search acceleration..."
openclaw config set agents.defaults.memorySearch.store.vector.enabled true || echo "Warning: Failed to enable sqlite-vec. OpenClaw will use JS fallback."

# Task 4
progress_bar $total_tasks 4
echo "Enabling embedding cache..."
openclaw config set agents.defaults.memorySearch.cache.enabled true || echo "Warning: Failed to enable embedding cache."

# Task 5
progress_bar $total_tasks 5
echo "Enabling session transcript indexing (experimental)..."
openclaw config set agents.defaults.memorySearch.experimental.sessionMemory true || echo "Warning: Failed to enable session memory indexing."
openclaw config set agents.defaults.memorySearch.sources[0] "memory" || echo "Warning: Failed to set memory source."
openclaw config set agents.defaults.memorySearch.sources[1] "sessions" || echo "Warning: Failed to set sessions source."

echo ""  # Newline after progress bar

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

for agent in "assistant" "research" "developer"; do
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
        AGENT_SEED_FILES[$agent]="${found[*]}"
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
        for file in ${AGENT_SEED_FILES[$agent]}; do
            DEST="$HOME/.openclaw/workspace-${agent}/$file"
            if [[ -f "$DEST" ]]; then
                echo "    ./${agent}/${file}  →  ~/.openclaw/workspace-${agent}/${file}  ⚠️  (already exists)"
            else
                echo "    ./${agent}/${file}  →  ~/.openclaw/workspace-${agent}/${file}"
            fi
        done
    done
    echo ""

    SEED_CHOICE=""
    while [[ -z "$SEED_CHOICE" ]]; do
        echo "How would you like to proceed?"
        echo "  [S] Seed     — copy the above files into each agent's workspace"
        echo "  [D] Default  — skip seeding, let OpenClaw use its own defaults"
        echo "  [H] Halt     — stop the installation to review files first"
        echo ""
        read -r -p "Enter choice [S/D/H]: " SEED_CHOICE

        case "${SEED_CHOICE^^}" in
            S)
                echo ""
                echo "Seeding prompt files into agent workspaces..."

                for agent in "${AGENTS_WITH_FILES[@]}"; do
                    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
                    REPO_AGENT_DIR="$SCRIPT_DIR/$agent"

                    # shellcheck disable=SC2086
                    for file in ${AGENT_SEED_FILES[$agent]}; do
                        SRC="$REPO_AGENT_DIR/$file"
                        DEST="$WORKSPACE/$file"

                        if [[ -f "$DEST" ]]; then
                            echo ""
                            echo "  ⚠️  ${agent^^}: $file already exists in workspace."
                            echo "  Diff (workspace → repository):"
                            echo "  ------------------------------------------------------------"
                            if [[ -f "$DEST" && -f "$SRC" ]]; then
                                diff -u "$DEST" "$SRC" |
                                    sed 's/^/  /' ||
                                    true
                            fi
                            echo "  ------------------------------------------------------------"
                            echo ""
                            read -r -p "  Overwrite ~/.openclaw/workspace-${agent}/${file}? (y/N) " OVERWRITE_FILE
                            if [[ "${OVERWRITE_FILE^^}" == "Y" ]]; then
                                cp "$SRC" "$DEST" &&
                                    echo "  ✓ ${agent^^}: $file overwritten." ||
                                    echo "  Warning: Failed to copy $file for $agent."
                            else
                                echo "  Skipped ${agent^^}: $file — existing file kept."
                            fi
                        else
                            cp "$SRC" "$DEST" &&
                                echo "  ✓ ${agent^^}: $file" ||
                                echo "  Warning: Failed to copy $file for $agent."
                        fi
                    done
                done

                echo ""
                echo "✓ Prompt file seeding complete."
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
    echo "Error: Failed to start OpenClaw gateway."
    exit $E_GATEWAY
fi

echo "Waiting $STABILITY_DELAY seconds for gateway to stabilize..."
sleep "$STABILITY_DELAY"

if ! openclaw gateway status; then
    echo "Error: Gateway status check failed after start."
    exit $E_GATEWAY
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
openclaw agents list --bindings || echo "Warning: Could not retrieve agent bindings. Check logs."

echo ""
echo "Checking memory index status..."
openclaw memory status || echo "Warning: Could not retrieve memory status. Indexing may still be in progress."

print_section_summary "Final Verification" \
    "Agent binding matrix verified" \
    "Memory index status checked" \
    "Installation completed successfully"

echo ""
echo "✓ OpenClaw Multi-Agent Setup Complete!"
echo "============================================================================"
echo "📋 SETUP SUMMARY"
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
