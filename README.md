# OpenClaw Multi-Agent Bootstrapper

This repository contains a fully automated bootstrapping script (`oc-bootstrap.sh`) and associated prompt templates to deploy a **strictly isolated, multi-agent OpenClaw environment** on a bare-metal Linux host.

Designed for local privacy and efficiency, this setup completely bypasses traditional cloud inference and hosted orchestration platforms. It utilizes a local inference server, local vector memory, and distinct Telegram bots to enforce absolute context isolation between agents, while utilizing local Model Context Protocol (MCP) servers for third-party integrations.

## 🏗️ Architecture Overview

- **Host Environment**: Ubuntu 24.04 (Bare-metal, native process execution).
- **Inference Backend**: Local "Lemonade" server running GGUF models via AMD ROCm.
- **Agent Topology**:
  - **Assistant**: General-purpose aide (`lemonade/user.Qwen3.5-4B-GGUF`).
  - **Research**: Deep-dive web research agent (`lemonade/user.Qwen3.5-4B-GGUF`).
  - **Developer**: Code and Git workflow agent (`lemonade/user.Qwen3.5-4B-GGUF`).
- **Shared Memory/Embedding Model**: `lemonade/user.nomic-embed-text-v1.5-GGUF`.
- **Interface**: 3x independent Telegram bots to prevent context bleeding.
- **Memory**: Local SQLite-backed vector search with `sqlite-vec` acceleration.

## 📂 Repository Structure

The bootstrapping script relies on a specific repository layout to automatically seed each agent's behavioral prompts on startup.

```text
.
├── oc-bootstrap.sh           # The main installation script
├── assistant/                # Prompt files for the General Assistant
│   ├── SOUL.md               # Core persona and behavioral rules
│   ├── AGENTS.md             # GitOps coordination instructions
│   └── USER.md               # User preferences
├── research/                 # Prompt files for the Research Agent
│   ├── SOUL.md
│   └── AGENTS.md
└── developer/                # Prompt files for the Developer Agent
    ├── SOUL.md
    ├── AGENTS.md
    └── USER.md
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 with standard user `sudo` access (Node.js/npm will be installed automatically).
- A running Lemonade server on your local network.
- **Three** distinct Telegram Bot tokens from @BotFather.
- (Optional) A GitLab Personal Access Token (PAT) for Git MCP features.
- (Optional) A Brave Search API key for the research agent.
- (Optional) An X/Twitter API key or Auth Cookie for social media scraping.

### Installation

1. Clone this repository to your target machine.
2. Set up your credentials in `~/.openclaw/secrets.env`.
3. Ensure the script is executable: `chmod +x oc-bootstrap.sh`.
4. Run the setup script: `./oc-bootstrap.sh`.

## ⚙️ How the Installation Works

The `oc-bootstrap.sh` script executes a comprehensive setup process:

1. **Credential Collection**: Prompts for or sources infrastructure and API secrets.
2. **System Preparation**: Installs `curl`, `git`, `nodejs`, and the OpenClaw core.
3. **Local Inference Mapping**: Configures the gateway to route all inference and memory calls to the local Lemonade server.
4. **Agent Provisioning**: Creates isolated workspaces and standardizes the Qwen3.5-4B model across the stack.
5. **Local MCP Binding**: Binds the `@zereight/mcp-gitlab` server via `npx` to all agents for native Git operations over `stdio`.
6. **Advanced Research Skills**: Enables `webScrape`, `newsSearch`, `rssReader`, `trendsFinder`, and `xScraper` for the Research agent.
7. **Operational Hooks**: Activates `autoMemory` for the Assistant, `sessionSummarize` for Research, and `toolValidation` for the Developer.
8. **Telegram Channel Isolation**: Maps each agent to its dedicated bot and strips default fallback bindings.
9. **Vector Memory Setup**: Provisions isolated `.sqlite` indexes with `sqlite-vec` acceleration and embedding caching.
10. **Prompt Seeding**: Interactively seeds `SOUL.md`, `USER.md`, and `AGENTS.md` into workspaces with diff-checks.

## 🛡️ Privacy & Security Notes

- **Zero Cloud Data**: Embeddings and inference remain local. No data leaves your network unless using explicit Brave, X, or GitLab integrations.
- **Isolated State**: Each agent maintains its own `MEMORY.md` and SQLite index.

## 📜 Logs & Troubleshooting

Logs are saved to `~/.openclaw/logs/openclaw-setup.log`. Verify your installation with:

```bash
openclaw gateway status
openclaw memory status
openclaw agents list --bindings
```
