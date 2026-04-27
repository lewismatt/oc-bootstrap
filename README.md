# OpenClaw Multi-Agent Bootstrapper

This repository contains a fully automated bootstrapping script (`oc-install-sonnet46.sh`) and associated prompt templates to deploy a **strictly isolated, multi-agent OpenClaw environment** on a bare-metal Linux host.

Designed for local privacy and efficiency, this setup completely bypasses traditional cloud inference and central orchestrators. Instead, it utilizes a local inference server, local vector memory, and distinct Telegram bots to enforce absolute context isolation between agents.

## 🏗️ Architecture Overview

- **Host Environment**: Ubuntu 24.04 (Bare-metal, native daemon execution)
- **Inference Backend**: Local "Lemonade" server running GGUF models.
- **Agent Topology**:
  - **Assistant**: General-purpose aide (`Gemma-4-E4B-it-GGUF`)
  - **Research**: Deep-dive web research agent (`Gemma-4-E4B-it-GGUF`)
  - **Developer**: Code and Git workflow agent (`Qwen3.5-4B-GGUF`)
- **Interface**: 3x independent Telegram bots to prevent context bleeding.
- **Memory**: Local SQLite-backed vector search with `sqlite-vec` acceleration.

## 📂 Repository Structure

The bootstrapping script relies on a specific repository layout to automatically seed each agent's behavioral prompts on startup.

```text
.
├── oc-install-sonnet46.sh    # The main installation script
├── assistant/                # Prompt files for the General Assistant
│   ├── SOUL.md               # Core persona and behavioral rules
│   └── USER.md               # User preferences
├── research/                 # Prompt files for the Research Agent
│   └── SOUL.md
└── developer/                # Prompt files for the Developer Agent
    ├── SOUL.md
    └── AGENTS.md             # Multi-agent coordination instructions
```

## ⚙️ What the Script Does

When executed, the script performs a robust, end-to-end installation of the OpenClaw gateway:

1. **Credential Collection**: Prompts for your Lemonade API key, three separate Telegram Bot tokens, and optional Composio/Brave API keys.
2. **Secure Storage**: Saves all collected credentials to a heavily restricted (`chmod 600`) `.env` file at `~/.openclaw/secrets.env`.
3. **System Setup**: Updates `apt`, installs `curl` and `git`, runs the official OpenClaw installer, and automatically applies `openclaw doctor --fix` to repair permissions.
4. **Local Inference Mapping**: Configures the OpenClaw gateway to route memory and inference calls to the local Lemonade server.
5. **Agent Provisioning**: Generates three isolated directories (`~/.openclaw/workspace-<agent>`) and assigns specific local LLMs to each agent.
6. **Least-Privilege Secrets**: Injects external API keys securely. (e.g., The Developer agent gets Composio access, but the Assistant remains strictly sandboxed).
7. **Plugin & Skill Configuration**: Installs the Composio MCP plugin and grants the Research agent access to built-in summarization and web search.
8. **Telegram Binding**: Maps each agent to its dedicated Telegram bot and strips all default channel bindings to guarantee strict input isolation.
9. **Vector Memory Setup**: Provisions isolated `.sqlite` indexes for each agent. Enables `sqlite-vec` for accelerated hybrid search (Vector + BM25), embedding caching, and experimental session transcript indexing.
10. **Prompt Seeding**: Detects `SOUL.md`, `USER.md`, and `AGENTS.md` files in the repository and interactively seeds them into the newly created workspaces, complete with diff-checks to prevent accidental overwrites.
11. **Gateway Initialization**: Starts the OpenClaw background daemon, verifies its status, and checks background memory indexers.

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 with standard user `sudo` access.
- A running Lemonade server on your local network.
- **Three** distinct Telegram Bot tokens from @BotFather.
- (Optional) A Composio API key for git/code MCP features.
- (Optional) A Brave Search API key for the research agent.

### Installation

1. Clone this repository to your target machine.
2. Ensure the script is executable:
   ```bash
   chmod +x oc-install-sonnet46.sh
   ```
3. Run the setup script:
   ```bash
   ./oc-install-sonnet46.sh
   ```
4. Follow the interactive prompts to supply your credentials and confirm prompt-file seeding.

## 🛡️ Privacy & Security Notes

- **No Docker Overhead**: Runs as a standard system process for maximum resource efficiency on constrained hardware.
- **Zero Cloud Data**: Embeddings and inference are routed strictly to the local server. No conversation data leaves your network unless using the explicit Brave/Composio integrations on specific agents.
- **Isolated State**: Each agent maintains its own `MEMORY.md` file and SQLite index. They cannot "see" each other's state unless explicitly shared.

## 📜 Logs & Troubleshooting

Installation logs are automatically saved to `~/.openclaw/logs/openclaw-setup.log`. If the OpenClaw daemon fails to start, you can check its status using:

```bash
openclaw gateway status
openclaw memory status
openclaw agents list --bindings
```
