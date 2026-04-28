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

# ------------------------------------------------------------------------------
# 0. Sudo Trap Guardrail
# ------------------------------------------------------------------------------
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Error: Do not run this script directly as root or with sudo."
    echo "This script installs workspaces to the current user's home directory (\$HOME)."
    echo "It will automatically prompt for sudo access when installing system packages."
    exit 1
fi

STABILITY_DELAY=5 # Configurable start-up wait time

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

ASSISTANT_TOKEN=""
while [[ -z "$ASSISTANT_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the General Assistant: " ASSISTANT_TOKEN
    echo ""
    [[ -z "$ASSISTANT_TOKEN" ]] && echo "Error: Assistant token is required. Please try again."
done

RESEARCH_TOKEN=""
while [[ -z "$RESEARCH_TOKEN" || "$RESEARCH_TOKEN" == "$ASSISTANT_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the Deep Research Agent: " RESEARCH_TOKEN
    echo ""
    [[ -z "$RESEARCH_TOKEN" ]] && echo "Error: Research token is required. Please try again."
    [[ "$RESEARCH_TOKEN" == "$ASSISTANT_TOKEN" ]] && echo "Error: Token must be unique. Do not reuse the Assistant token."
done

DEVELOPER_TOKEN=""
while [[ -z "$DEVELOPER_TOKEN" || "$DEVELOPER_TOKEN" == "$ASSISTANT_TOKEN" || "$DEVELOPER_TOKEN" == "$RESEARCH_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the Developer Agent: " DEVELOPER_TOKEN
    echo ""
    [[ -z "$DEVELOPER_TOKEN" ]] && echo "Error: Developer token is required. Please try again."
    if [[ "$DEVELOPER_TOKEN" == "$ASSISTANT_TOKEN" || "$DEVELOPER_TOKEN" == "$RESEARCH_TOKEN" ]]; then
        echo "Error: Token must be unique. Do not reuse existing tokens."
        DEVELOPER_TOKEN=""
    fi
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

sudo -v || {
    echo "Error: sudo access is required to install dependencies."
    exit 1
}

echo "Configuring NodeSource PPA to ensure modern Node.js installation..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || echo "Warning: Failed to setup NodeSource. Using default repositories."

sudo apt update || echo "Warning: apt update failed. Continuing."
sudo apt upgrade -y || echo "Warning: apt upgrade failed. Continuing."
sudo apt install -y curl git nodejs || {
    echo "Error: Failed to install curl/git/nodejs. Cannot continue."
    exit 1
}

echo "Running official OpenClaw installer..."
if ! curl -fsSL https://openclaw.ai/install.sh | bash; then
    echo "Error: OpenClaw installation failed."
    exit 1
fi

if ! command -v openclaw &>/dev/null; then
    echo "Error: OpenClaw binary not found in PATH after installation."
    exit 1
fi

echo "Running post-install health check and auto-repair..."
openclaw doctor --fix || echo "Warning: OpenClaw doctor reported issues. Continuing."

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
    exit 1
}
openclaw config set providers.lemonade.apiKey "$LEMONADE_KEY" || {
    echo "Error: Failed to set Lemonade API key."
    exit 1
}

echo "Configuring shared embedding and dreaming models..."
openclaw config set memory.dreaming.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set dreaming model."
openclaw config set memory.embeddingModel "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set embedding model."

# ==============================================================================
# 7. Provision Isolated Agent Workspaces
# ==============================================================================
echo ""
echo "=== Provisioning Agent Workspaces ==="

for agent in "assistant" "research" "developer"; do
    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
    echo "Provisioning agent: ${agent^^}..."
    openclaw agents add "$agent" --workspace "$WORKSPACE" --non-interactive ||
        echo "Warning: Issue provisioning agent '$agent'. Continuing."
done

echo "Assigning Qwen3.5-4B inference model to all agents..."
openclaw config set agents.list.assistant.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for assistant agent."
openclaw config set agents.list.research.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for research agent."
openclaw config set agents.list.developer.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for developer agent."

# ==============================================================================
# 8. Inject Agent-Specific Secrets & Configure Providers
# ==============================================================================
echo ""
echo "=== Injecting Isolated Agent Secrets & MCPs ==="

if [[ -n "$GITLAB_PAT" ]]; then
    for agent in "assistant" "research" "developer"; do
        openclaw config set agents.list.${agent}.env.GITLAB_PERSONAL_ACCESS_TOKEN "$GITLAB_PAT" || {
            echo "Error: Failed to set GitLab PAT for $agent."
            exit 1
        }
        openclaw config set agents.list.${agent}.env.GITLAB_API_URL "https://gitlab.com" || {
            echo "Error: Failed to set GitLab URL for $agent."
            exit 1
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
        exit 1
    }
    openclaw config set agents.list.research.search.provider "brave" || {
        echo "Error: Failed to set Brave as search provider."
        exit 1
    }
else
    echo "Skipping Brave search configuration (no key provided)."
fi

if [[ -n "$X_API_KEY" ]]; then
    openclaw config set agents.list.research.env.X_API_KEY "$X_API_KEY" || {
        echo "Error: Failed to set X credentials for research agent."
        exit 1
    }
fi

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
        exit 1
    fi

    openclaw agents unbind --agent "$agent" --all ||
        echo "Warning: Failed to unbind defaults for agent '$agent'. Continuing."
done

# ==============================================================================
# 11. Configure Local Memory & Vector Search
# ==============================================================================
echo ""
echo "=== Configuring Local Memory & Vector Search ==="

echo "Configuring memory search embedding provider..."
openclaw config set agents.defaults.memorySearch.provider "openai" || {
    echo "Error: Failed to set memory search provider."
    exit 1
}
openclaw config set agents.defaults.memorySearch.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || {
    echo "Error: Failed to set memory search model."
    exit 1
}
openclaw config set agents.defaults.memorySearch.remote.baseUrl "$BASE_URL" || {
    echo "Error: Failed to set memory search base URL."
    exit 1
}
openclaw config set agents.defaults.memorySearch.remote.apiKey "$LEMONADE_KEY" || {
    echo "Error: Failed to set memory search API key."
    exit 1
}

echo "Configuring per-agent SQLite index storage..."
# Use static path with explicit file naming pattern to avoid expansion issues
MEMORY_DIR="$HOME/.openclaw/memory"
mkdir -p "$MEMORY_DIR"
openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agentId}.sqlite" || {
    echo "Warning: Failed to set memory index path with pattern. Attempting static path..."
    openclaw config set agents.defaults.memorySearch.store.path "$MEMORY_DIR/{agent}.sqlite" || echo "Warning: Alternative memory path also failed."
}

echo "Enabling sqlite-vec vector search acceleration..."
openclaw config set agents.defaults.memorySearch.store.vector.enabled true || echo "Warning: Failed to enable sqlite-vec. OpenClaw will use JS fallback."

echo "Enabling embedding cache..."
openclaw config set agents.defaults.memorySearch.cache.enabled true || echo "Warning: Failed to enable embedding cache."

echo "Enabling session transcript indexing (experimental)..."
openclaw config set agents.defaults.memorySearch.experimental.sessionMemory true || echo "Warning: Failed to enable session memory indexing."
openclaw config set agents.defaults.memorySearch.sources[0] "memory" || echo "Warning: Failed to set memory source."
openclaw config set agents.defaults.memorySearch.sources[1] "sessions" || echo "Warning: Failed to set sessions source."

echo "✓ Memory index directory created at $MEMORY_DIR"
echo "✓ Local memory and vector search configured."

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
                ;;
            D)
                echo "Skipping seeding. OpenClaw will generate default prompt files on first start."
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
    exit 1
fi

echo "Waiting $STABILITY_DELAY seconds for gateway to stabilize..."
sleep "$STABILITY_DELAY"

if ! openclaw gateway status; then
    echo "Error: Gateway status check failed after start."
    exit 1
fi
echo "✓ Gateway started successfully."

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

echo ""
echo "✓ OpenClaw Multi-Agent Setup Complete!"
echo "============================================================================"
echo "Log file:     $LOG_FILE"
echo "Secrets file: $HOME/.openclaw/secrets.env"
echo "Memory index: $HOME/.openclaw/memory/"
echo ""
echo "Note: Memory indexing runs asynchronously on first boot. Initial search results"
echo "      may be incomplete until the background sync finishes."
echo ""
