#!/bin/bash
set -euo pipefail
set +H # Disable history expansion to prevent issues with '!' characters in secrets

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
#   - Assistant Model:    lemonade/Gemma-4-E4B-it-GGUF
#   - Research Model:     lemonade/Gemma-4-E4B-it-GGUF
#   - Developer Model:    lemonade/user.Qwen3.5-4B-GGUF
#
# AGENT TOPOLOGY & ISOLATION STRATEGY:
#   To strictly conserve context windows and token usage for local inference,
#   this setup bypasses the default central "orchestrator" pattern. Instead,
#   each agent is strictly bound to its own dedicated Telegram bot interface.
#   This guarantees complete context isolation and zero "token bleed" between
#   different functional domains.
#
# REPOSITORY STRUCTURE:
#   This script is designed to live in a git repository alongside per-agent
#   configuration directories. If present, these directories are used to seed
#   each agent's workspace with core prompt files before the gateway starts.
#
#   Expected layout:
#     ./assistant/          # Prompt files for the General Assistant agent
#     ./research/           # Prompt files for the Deep Research agent
#     ./developer/          # Prompt files for the Developer agent
#
#   Recognized prompt files (any subset may be present):
#     SOUL.md               # Agent persona, values, and behavioral rules
#     AGENTS.md             # Multi-agent coordination instructions
#     USER.md               # User context and preferences
#
# ==============================================================================


# ==============================================================================
# 0. Logging & Trap Setup
# ==============================================================================
# Write all stdout and stderr to both the terminal and a persistent log file,
# stored in the user's home directory to avoid requiring root permissions.

SCRIPT_NAME="openclaw-setup"
LOG_FILE="$HOME/.openclaw/logs/${SCRIPT_NAME}.log"

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting OpenClaw Multi-Agent Setup"

# Print a clear message and exit cleanly on Ctrl+C or SIGTERM.
cleanup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setup aborted or interrupted. Check log: $LOG_FILE"
    exit 1
}
trap cleanup INT TERM

# Resolve the directory the script lives in so all repo-relative paths are
# correct regardless of where the user invokes the script from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ==============================================================================
# 1. User Confirmation
# ==============================================================================
echo ""
echo "OpenClaw Multi-Agent Setup"
echo "============================================================================"
echo ""
read -r -p "Proceed with installation? (Y/n) " CONFIRM

# Treat an empty response (pressing Enter) as an implicit yes.
[[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || -z "$CONFIRM" ]] || exit 0


# ==============================================================================
# 2. Credential Collection
# ==============================================================================
# Gather all secrets up front before making any system changes, so the install
# does not stall midway waiting for user input.

echo ""
echo "=== Infrastructure Credentials ==="
read -r -p "Enter Lemonade Server API Key [Press Enter to use 'local-dummy-key']: " LEMONADE_KEY
LEMONADE_KEY="${LEMONADE_KEY:-local-dummy-key}"

echo ""
echo "=== Telegram Bot Tokens ==="
echo "You will need three separate Telegram Bot Tokens from @BotFather."
echo ""

# Each token uses a retry loop so the user can correct mistakes without
# restarting the entire script.
ASSISTANT_TOKEN=""
while [[ -z "$ASSISTANT_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the General Assistant: " ASSISTANT_TOKEN
    echo ""
    [[ -z "$ASSISTANT_TOKEN" ]] && echo "Error: Assistant token is required. Please try again."
done

RESEARCH_TOKEN=""
while [[ -z "$RESEARCH_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the Deep Research Agent: " RESEARCH_TOKEN
    echo ""
    [[ -z "$RESEARCH_TOKEN" ]] && echo "Error: Research token is required. Please try again."
done

DEVELOPER_TOKEN=""
while [[ -z "$DEVELOPER_TOKEN" ]]; do
    read -r -s -p "Enter Telegram Bot Token for the Developer Agent: " DEVELOPER_TOKEN
    echo ""
    [[ -z "$DEVELOPER_TOKEN" ]] && echo "Error: Developer token is required. Please try again."
done

echo ""
echo "=== Agent-Specific External Secrets (optional) ==="

# These keys are optional. The script will skip the relevant configuration
# steps if they are left blank.
read -r -s -p "Enter Composio API Key (for Git workflows, or press Enter to skip): " COMPOSIO_KEY
echo ""
COMPOSIO_KEY="${COMPOSIO_KEY:-}"

read -r -s -p "Enter Brave Search API Key (for Research Agent, or press Enter to skip): " BRAVE_API_KEY
echo ""
BRAVE_API_KEY="${BRAVE_API_KEY:-}"

[[ -z "$COMPOSIO_KEY" ]]  && echo "Warning: No Composio API Key provided. Git workflow features will be unavailable."
[[ -z "$BRAVE_API_KEY" ]] && echo "Warning: No Brave Search API Key provided. Brave search will be unavailable."


# ==============================================================================
# 3. Save Credentials to Secure .env File
# ==============================================================================
# Write all collected secrets to a single file with strict permissions (600)
# so only the owning user can read it. This file is sourced by agents at
# runtime and serves as a reference if manual credential inspection is needed.
#
# If the file already exists from a previous install, warn the user and confirm
# before overwriting. If they decline, the existing file is sourced so the
# remainder of the script uses the preserved credentials rather than the
# newly entered ones.

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
        # Source the existing file so the remainder of the script uses the
        # preserved values rather than those entered at the prompts above.
        # shellcheck disable=SC1090
        source "$SECRETS_FILE"
    else
        cat > "$SECRETS_FILE" <<EOF
LEMONADE_KEY=$LEMONADE_KEY
ASSISTANT_TOKEN=$ASSISTANT_TOKEN
RESEARCH_TOKEN=$RESEARCH_TOKEN
DEVELOPER_TOKEN=$DEVELOPER_TOKEN
COMPOSIO_KEY=$COMPOSIO_KEY
BRAVE_API_KEY=$BRAVE_API_KEY
EOF
        chmod 600 "$SECRETS_FILE"
        echo "✓ Credentials updated at $SECRETS_FILE"
    fi
else
    cat > "$SECRETS_FILE" <<EOF
LEMONADE_KEY=$LEMONADE_KEY
ASSISTANT_TOKEN=$ASSISTANT_TOKEN
RESEARCH_TOKEN=$RESEARCH_TOKEN
DEVELOPER_TOKEN=$DEVELOPER_TOKEN
COMPOSIO_KEY=$COMPOSIO_KEY
BRAVE_API_KEY=$BRAVE_API_KEY
EOF
    chmod 600 "$SECRETS_FILE"
    echo "✓ Credentials saved to $SECRETS_FILE"
fi


# ==============================================================================
# 4. System Preparation & Core Install
# ==============================================================================
# Update the system, install required dependencies, then run the official
# OpenClaw installer. Sudo credentials are validated up front to avoid
# permission prompts appearing mid-install while stdout is being redirected.
# After installation, 'doctor --fix' automatically repairs any configuration
# or permission drift common on a fresh install.

echo ""
echo "=== System Preparation ==="

# Validate sudo access upfront to prevent mid-install credential prompts.
sudo -v || { echo "Error: sudo access is required to install dependencies."; exit 1; }

sudo apt update     || echo "Warning: apt update failed. Continuing."
sudo apt upgrade -y || echo "Warning: apt upgrade failed. Continuing."
sudo apt install -y curl git || { echo "Error: Failed to install curl/git. Cannot continue."; exit 1; }

echo "Running official OpenClaw installer..."
if ! curl -fsSL https://openclaw.ai/install.sh | bash; then
    echo "Error: OpenClaw installation failed."
    exit 1
fi

echo "Running post-install health check and auto-repair..."
openclaw doctor --fix || echo "Warning: OpenClaw doctor reported issues. Continuing."


# ==============================================================================
# 5. Configure Local Inference (Lemonade Server)
# ==============================================================================
# Point OpenClaw at the local Lemonade inference server and configure the
# shared embedding and dreaming models used across all agents for memory
# indexing and context compression.

echo ""
echo "=== Linking Lemonade Server Backend ==="

LEMONADE_IP=""
while [[ -z "$LEMONADE_IP" ]]; do
    read -r -p "Enter Lemonade server IP address (e.g., 192.168.1.100): " LEMONADE_IP
    [[ -z "$LEMONADE_IP" ]] && echo "Error: Lemonade server IP address is required. Please try again."
done

BASE_URL="http://${LEMONADE_IP}:8000/v1"
read -r -p "Enter Lemonade base URL [Press Enter for default: $BASE_URL]: " CUSTOM_URL
[[ -n "$CUSTOM_URL" ]] && BASE_URL="$CUSTOM_URL"

openclaw config set providers.lemonade.baseUrl "$BASE_URL"     || { echo "Error: Failed to set Lemonade base URL."; exit 1; }
openclaw config set providers.lemonade.apiKey  "$LEMONADE_KEY" || { echo "Error: Failed to set Lemonade API key."; exit 1; }

echo "Configuring shared embedding and dreaming models..."
openclaw config set memory.dreaming.model "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set dreaming model."
openclaw config set memory.embeddingModel "lemonade/user.nomic-embed-text-v1.5-GGUF" || echo "Warning: Failed to set embedding model."


# ==============================================================================
# 6. Provision Isolated Agent Workspaces
# ==============================================================================
# Create a dedicated workspace for each agent. Workspaces are isolated
# directories containing each agent's persona files, local notes, and session
# state. After creation, each agent's inference model is assigned separately
# via config, since model assignment is a configuration concern independent
# of workspace provisioning.

echo ""
echo "=== Provisioning Agent Workspaces ==="

for agent in "assistant" "research" "developer"; do
    WORKSPACE="$HOME/.openclaw/workspace-${agent}"
    echo "Provisioning agent: ${agent^^}..."
    openclaw agents add "$agent" --workspace "$WORKSPACE" --non-interactive \
        || echo "Warning: Issue provisioning agent '$agent'. Continuing."
done

echo "Assigning inference models to each agent..."
openclaw config set agents.list.assistant.model "lemonade/Gemma-4-E4B-it-GGUF"  || echo "Warning: Failed to set model for assistant agent."
openclaw config set agents.list.research.model  "lemonade/Gemma-4-E4B-it-GGUF"  || echo "Warning: Failed to set model for research agent."
openclaw config set agents.list.developer.model "lemonade/user.Qwen3.5-4B-GGUF" || echo "Warning: Failed to set model for developer agent."


# ==============================================================================
# 7. Inject Agent-Specific Secrets & Configure Providers
# ==============================================================================
# Inject external API keys into only the agents that require them. This
# enforces the principle of least privilege: the assistant agent receives
# no external API access, the developer agent gets Git/Composio access,
# and only the research agent is configured to use Brave Search.

echo ""
echo "=== Injecting Isolated Agent Secrets ==="

if [[ -n "$COMPOSIO_KEY" ]]; then
    openclaw config set agents.list.developer.env.COMPOSIO_API_KEY "$COMPOSIO_KEY" || { echo "Error: Failed to set Composio key for developer agent."; exit 1; }
    openclaw config set agents.list.research.env.COMPOSIO_API_KEY  "$COMPOSIO_KEY" || { echo "Error: Failed to set Composio key for research agent.";  exit 1; }
else
    echo "Skipping Composio secret injection (no key provided)."
fi

if [[ -n "$BRAVE_API_KEY" ]]; then
    openclaw config set agents.list.research.env.BRAVE_API_KEY "$BRAVE_API_KEY" || { echo "Error: Failed to set Brave API key for research agent."; exit 1; }
    openclaw config set agents.list.research.search.provider   "brave"           || { echo "Error: Failed to set Brave as search provider.";         exit 1; }
else
    echo "Skipping Brave search configuration (no key provided)."
fi


# ==============================================================================
# 8. Install Plugins & Assign Skills
# ==============================================================================
# Install the Composio MCP plugin for external tool access, then grant or
# deny it per-agent. The assistant agent is explicitly denied Composio access
# to keep it sandboxed to conversational tasks only. Built-in summarization
# and web search skills are then enabled exclusively for the research agent.

echo ""
echo "=== Installing Plugins & Assigning Skills ==="

openclaw plugins install @composio/openclaw-plugin || echo "Warning: Failed to install Composio plugin. Continuing."

echo "Assigning plugin permissions per agent..."
openclaw config set agents.list.research.plugins.composio  true  || { echo "Error: Failed to enable Composio for research agent.";  exit 1; }
openclaw config set agents.list.developer.plugins.composio true  || { echo "Error: Failed to enable Composio for developer agent."; exit 1; }
openclaw config set agents.list.assistant.plugins.composio false || { echo "Error: Failed to disable Composio for assistant agent."; exit 1; }

echo "Enabling built-in skills for the Research Agent..."
openclaw config set agents.list.research.skills.summarize true || echo "Warning: Failed to enable summarize skill."
openclaw config set agents.list.research.skills.webSearch  true || echo "Warning: Failed to enable webSearch skill."


# ==============================================================================
# 9. Bind Isolated Telegram Channels
# ==============================================================================
# Bind each agent to its own dedicated Telegram bot token, then immediately
# unbind all default channel bindings. This enforces strict input isolation:
# messages sent to one bot are guaranteed to route only to its designated
# agent, with no cross-agent bleed from shared or fallback channel defaults.

echo ""
echo "=== Binding Telegram Channels ==="

for agent in "assistant" "research" "developer"; do
    TOKEN=""
    case "$agent" in
        "assistant") TOKEN="$ASSISTANT_TOKEN" ;;
        "research")  TOKEN="$RESEARCH_TOKEN"  ;;
        "developer") TOKEN="$DEVELOPER_TOKEN" ;;
    esac

    echo "Binding Telegram for ${agent^^}..."
    if ! openclaw agents bind --agent "$agent" --bind "telegram:$TOKEN"; then
        echo "Error: Failed to bind Telegram for agent '$agent'."
        exit 1
    fi

    # Remove any default channel bindings inherited during agent creation
    # to prevent unintended routing from shared or fallback channels.
    openclaw agents unbind --agent "$agent" --all \
        || echo "Warning: Failed to unbind defaults for agent '$agent'. Continuing."
done


# ==============================================================================
# 10. Configure Local Memory & Vector Search
# ==============================================================================
# Enable OpenClaw's built-in SQLite-backed memory and vector search system.
# Each agent gets its own isolated memory index stored as a .sqlite file.
#
# How it works:
#   - MEMORY.md and daily memory/ notes in each workspace are the source of
#     truth. These plain Markdown files are what the agent writes to and reads
#     from — there is no hidden state.
#   - OpenClaw builds a per-agent SQLite index over these files, combining
#     vector similarity search (70% weight) with BM25 keyword search (30%
#     weight) for hybrid retrieval. This lets agents find relevant memories
#     even when the query wording differs from how they were originally written.
#   - Embeddings are generated via the Lemonade server using the same model
#     already configured for dreaming and embedding in Step 5. This keeps the
#     entire stack local with no data sent to external providers.
#   - The index is kept fresh automatically: a file watcher marks it dirty
#     when MEMORY.md or memory/ files change, and sync runs on session start,
#     on search, and on a background interval.
#   - Embedding caching is enabled so unchanged chunks are never re-embedded
#     on reindex, which keeps reindex fast for large memory stores.
#   - Session transcript indexing is enabled (experimental) so past
#     conversations are also searchable via memory_search, not just
#     manually written memory files.

echo ""
echo "=== Configuring Local Memory & Vector Search ==="

# Set the embedding provider to the Lemonade server using its OpenAI-compatible
# API. This reuses the same provider and model already configured in Step 5,
# keeping the full stack local.
echo "Configuring memory search embedding provider..."
openclaw config set agents.defaults.memorySearch.provider           "openai"                                   || { echo "Error: Failed to set memory search provider.";       exit 1; }
openclaw config set agents.defaults.memorySearch.model              "lemonade/user.nomic-embed-text-v1.5-GGUF" || { echo "Error: Failed to set memory search model.";          exit 1; }
openclaw config set agents.defaults.memorySearch.remote.baseUrl     "$BASE_URL"                                || { echo "Error: Failed to set memory search base URL.";       exit 1; }
openclaw config set agents.defaults.memorySearch.remote.apiKey      "$LEMONADE_KEY"                            || { echo "Error: Failed to set memory search API key.";        exit 1; }

# Configure the per-agent SQLite index storage path. The {agentId} token is
# expanded by OpenClaw at runtime to produce one isolated .sqlite file per
# agent: ~/.openclaw/memory/assistant.sqlite, research.sqlite, etc.
echo "Configuring per-agent SQLite index storage..."
openclaw config set agents.defaults.memorySearch.store.path         "$HOME/.openclaw/memory/{agentId}.sqlite"  || echo "Warning: Failed to set memory index path."

# Enable the sqlite-vec extension for accelerated vector distance queries
# inside SQLite. When available, this performs vector search via a native
# virtual table (vec0) rather than loading all embeddings into JS memory.
# If the extension is missing, OpenClaw falls back to in-process cosine
# similarity automatically with no further configuration needed.
echo "Enabling sqlite-vec vector search acceleration..."
openclaw config set agents.defaults.memorySearch.store.vector.enabled true || echo "Warning: Failed to enable sqlite-vec. OpenClaw will use JS fallback."

# Enable embedding caching so unchanged chunks are not re-embedded on every
# reindex cycle. This significantly reduces Lemonade server load for agents
# with large or frequently updated memory stores.
echo "Enabling embedding cache..."
openclaw config set agents.defaults.memorySearch.cache.enabled       true || echo "Warning: Failed to enable embedding cache."

# Enable experimental session transcript indexing. When active, each agent's
# past conversation logs are indexed alongside memory files, making them
# searchable via memory_search. Indexing is per-agent and asynchronous —
# results may be slightly stale until the background sync completes.
echo "Enabling session transcript indexing (experimental)..."
openclaw config set agents.defaults.memorySearch.experimental.sessionMemory true                               || echo "Warning: Failed to enable session memory indexing."
openclaw config set agents.defaults.memorySearch.sources[0]          "memory"                                  || echo "Warning: Failed to set memory source."
openclaw config set agents.defaults.memorySearch.sources[1]          "sessions"                                || echo "Warning: Failed to set sessions source."

# Create the memory index directory now so it is present before the gateway
# starts its first indexing pass on boot.
mkdir -p "$HOME/.openclaw/memory"
echo "✓ Memory index directory created at $HOME/.openclaw/memory"

echo "✓ Local memory and vector search configured."


# ==============================================================================
# 11. Seed Agent Prompt Files from Repository
# ==============================================================================
# Check whether per-agent configuration directories exist alongside this script
# in the repository. If prompt files are found, offer the user three choices:
#
#   [S] Seed    — copy discovered files into each agent's workspace. Files that
#                 do not already exist are copied silently. Files that would
#                 overwrite an existing workspace file are listed explicitly and
#                 require a per-file confirmation before being written.
#   [D] Default — skip seeding and let OpenClaw generate default prompt files
#                 on first gateway startup.
#   [H] Halt    — stop the installation so the user can review files first.
#
# Seeding happens here, after workspaces are provisioned but before the gateway
# starts, so the gateway reads the correct files on its very first boot.

echo ""
echo "=== Agent Prompt File Seeding ==="

# The prompt files OpenClaw recognizes at the workspace root.
PROMPT_FILES=("SOUL.md" "AGENTS.md" "USER.md")

# Discover which agents have at least one prompt file present in the repo.
declare -A AGENT_SEED_FILES   # agent -> space-separated list of filenames found
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

# If no prompt files were found anywhere in the repo, skip this step entirely.
if [[ ${#AGENTS_WITH_FILES[@]} -eq 0 ]]; then
    echo "No agent prompt files found in repository. Skipping seeding step."
else
    # Print a clear summary of exactly what was found before asking the user
    # to make a decision, so they know precisely what will be copied.
    # Flag any files that would overwrite an existing workspace file so the
    # user can make an informed choice at the prompt below.
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
                            # The destination file already exists. Show a diff
                            # so the user can see exactly what would change,
                            # then ask for explicit confirmation before writing.
                            echo ""
                            echo "  ⚠️  ${agent^^}: $file already exists in workspace."
                            echo "  Diff (workspace → repository):"
                            echo "  ------------------------------------------------------------"
                            diff --unified=2 "$DEST" "$SRC" \
                                | sed 's/^/  /' \
                                || true  # diff exits 1 when files differ; don't abort
                            echo "  ------------------------------------------------------------"
                            echo ""
                            read -r -p "  Overwrite ~/.openclaw/workspace-${agent}/${file}? (y/N) " OVERWRITE_FILE
                            if [[ "${OVERWRITE_FILE^^}" == "Y" ]]; then
                                cp "$SRC" "$DEST" \
                                    && echo "  ✓ ${agent^^}: $file overwritten." \
                                    || echo "  Warning: Failed to copy $file for $agent."
                            else
                                echo "  Skipped ${agent^^}: $file — existing file kept."
                            fi
                        else
                            # No conflict — copy silently.
                            cp "$SRC" "$DEST" \
                                && echo "  ✓ ${agent^^}: $file" \
                                || echo "  Warning: Failed to copy $file for $agent."
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
# 12. Start & Verify Gateway
# ==============================================================================
# Start the OpenClaw gateway service for the first time, then wait for it
# to stabilize before probing its status. The start step is required because
# 'gateway status' probes a live RPC endpoint and will fail if the gateway
# process has not yet been brought up.

echo ""
echo "=== Starting OpenClaw Gateway ==="

if ! openclaw gateway start; then
    echo "Error: Failed to start OpenClaw gateway."
    exit 1
fi

echo "Waiting 5 seconds for gateway to stabilize..."
sleep 5

if ! openclaw gateway status; then
    echo "Error: Gateway status check failed after start."
    exit 1
fi
echo "✓ Gateway started successfully."


# ==============================================================================
# 13. Final Verification
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
echo "Note: If your agents require OAuth (e.g. GitHub/GitLab), run 'composio login' manually."
echo "Note: Memory indexing runs asynchronously on first boot. Initial search results"
echo "      may be incomplete until the background sync finishes."
echo ""
