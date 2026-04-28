# OpenClaw Multi-Agent Bootstrapper

This repository contains an automated bootstrapping script (`oc-setup.sh`) to deploy a strictly isolated, multi-agent OpenClaw environment on a bare-metal Linux host.

Designed for local privacy and efficiency, this setup bypasses traditional cloud inference. It uses a local inference server, local vector memory, and distinct Telegram bots to enforce absolute context isolation between agents, while using local Model Context Protocol (MCP) servers for secure third-party integrations.

## 🏗️ Architecture Overview

- **Host Environment**: Ubuntu 24.04 (Bare-metal)
- **Inference Backend**: Local "Lemonade" server running GGUF models via AMD ROCm (optimized for 12GB VRAM limits).
- **Agent Topology**:
  - **Assistant**: General-purpose aide (`lemonade/user.Qwen3.5-4B-GGUF`)
  - **Research**: Deep-dive web research agent (`lemonade/user.Qwen3.5-4B-GGUF`)
  - **Developer**: Code and Git workflow agent (`lemonade/user.Qwen3.5-4B-GGUF`)
- **Shared Memory Model**: `lemonade/user.nomic-embed-text-v1.5-GGUF`
- **Memory**: Local SQLite-backed vector search with `sqlite-vec` acceleration.

## 🔗 Integrations & API Keys

To get the most out of this multi-agent setup, you will need to gather a few API keys before running the installer.

- **Telegram (Required):** You need three distinct bots to keep agent contexts isolated. Message [@BotFather on Telegram](https://t.me/botfather), send the `/newbot` command three separate times, and copy the provided HTTP API Tokens.
- **Lemonade Server (Required):** You must have a running instance of a Lemonade inference server on your network. Have your IP address and API key ready.
- **GitLab PAT (Optional):** Required for the Developer agent to read/write code. Create a Personal Access Token with `api` and `read_repository` scopes in your [GitLab Access Tokens settings](https://gitlab.com/-/user_settings/personal_access_tokens).
- **Brave Search (Optional):** Empowers the Research agent to search the live web. Get a free API key from the [Brave Search Developer Portal](https://brave.com/search/api/).
- **X/Twitter (Optional):** Allows the Research agent to scrape real-time trends. Requires an API key from the [X Developer Portal](https://developer.twitter.com/en/portal/dashboard).

## 🚀 Quick Start & Installation

### Prerequisites

- Ubuntu 24.04 with standard user `sudo` access.
- `git` installed (`sudo apt install git`).

### Setup Steps

1. Clone this repository to your target machine:

   ```bash
   git clone <your-repo-url> openclaw-setup
   cd openclaw-setup
   ```

2. Make the script executable:

   ```bash
   chmod +x oc-setup.sh
   ```

3. Run the installer and follow the interactive prompts:

   ```bash
   ./oc-setup.sh
   ```

## ⚙️ What the Script Does

Running `oc-setup.sh` automates the entire provisioning process:

1. **Installs Dependencies:** Ensures Node.js, npm, curl, and the OpenClaw core daemon are installed.
2. **Secures Credentials:** Safely stores your API keys in a restricted (`chmod 600`) local environment file.
3. **Provisions Agents:** Creates isolated workspaces (`~/.openclaw/workspace-*`) for the Assistant, Research, and Developer agents.
4. **Binds Skills & Hooks:** Equips the Research agent with live scraping skills, sets up auto-memory summarization, and binds the open-source `@zereight/mcp-gitlab` server for local Git operations.
5. **Seeds Context:** Interactively copies the prompt files (`SOUL.md`, `USER.md`, `AGENTS.md`) from this repository directly into the agents' operational memory.

## 🛡️ Privacy & Security Notes

- **Zero Cloud Data**: Embeddings and inference remain local. No data leaves your network unless using explicit Brave, X, or GitLab integrations.
- **Isolated State**: Each agent maintains its own localized `.sqlite` index to prevent data bleeding between workflows.
