# OpenClaw Multi-Agent Bootstrapper

This repository contains a fully automated bootstrapping script (`oc-bootstrap.sh`) and associated prompt templates to deploy a **strictly isolated, multi-agent OpenClaw environment** on a bare-metal Linux host.

Designed for local privacy and efficiency, this setup completely bypasses traditional cloud inference and hosted orchestration platforms. It utilizes a local inference server, local vector memory, and distinct Telegram bots to enforce absolute context isolation between agents, while utilizing local Model Context Protocol (MCP) servers for third-party integrations.

## 🏗️ Architecture Overview

- **Host Environment**: Ubuntu 24.04 (Bare-metal, native process execution)
- **Inference Backend**: Local "Lemonade" server running GGUF models via AMD ROCm.
- **Agent Topology**:
  - **Assistant**: General-purpose aide (`lemonade/user.Qwen3.5-4B-GGUF`)
  - **Research**: Deep-dive web research agent (`lemonade/user.Qwen3.5-4B-GGUF`)
  - **Developer**: Code and Git workflow agent (`lemonade/user.Qwen3.5-4B-GGUF`)
- **Shared Memory/Embedding Model**: `lemonade/user.nomic-embed-text-v1.5-GGUF`
- **Interface**: 3x independent Telegram bots to prevent context bleeding.
- **Memory**: Local SQLite-backed vector search with `sqlite-vec` acceleration.

## 📂 Repository Structure

The bootstrapping script relies on a specific repository layout to automatically seed each agent's behavioral prompts on startup.

```text
.
├── oc-bootstrap.sh           # The main installation script
├── secrets.env.template      # Boilerplate for required credentials
├── assistant/                # Prompt files for the General Assistant
│   ├── SOUL.md               # Core persona and behavioral rules
│   └── USER.md               # User preferences
├── research/                 # Prompt files for the Research Agent
│   └── SOUL.md
└── developer/                # Prompt files for the Developer Agent
    ├── SOUL.md
    └── AGENTS.md             # Multi-agent coordination instructions
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 with standard user `sudo` access (Node.js/npm will be installed automatically).
- A running Lemonade server on your local network.
- **Three** distinct Telegram Bot tokens from @BotFather.
- (Optional) A GitLab Personal Access Token (PAT) for Git MCP features.
- (Optional) A Brave Search API key for the research agent.

### Installation

1. Clone this repository to your target machine:
   ```bash
   git clone [https://gitlab.com/mattlewis/oc-bootstrap.git](https://gitlab.com/mattlewis/oc-bootstrap.git)
   cd oc-bootstrap
   ```
2. Set up your credentials:
   ```bash
   mkdir -p ~/.openclaw
   cp secrets.env.template ~/.openclaw/secrets.env
   nano ~/.openclaw/secrets.env # Add your keys and tokens here
   chmod 600 ~/.openclaw/secrets.env
   ```
3. Ensure the script is executable:
   ```bash
   chmod +x oc-bootstrap.sh
   ```
4. Run the setup script:
   ```bash
   ./oc-bootstrap.sh
   ```

## ⚙️ How the Installation Works (Step-by-Step)

The `oc-bootstrap.sh` script executes a comprehensive, idempotent setup process. Here is exactly what happens under the hood during installation:

### 1. Credential Collection & Secure Storage
The script begins by looking for the `~/.openclaw/secrets.env` file. If it doesn't exist, it prompts you interactively for your Lemonade API key, Telegram Bot tokens, and optional external API keys (GitLab PAT, Brave). All credentials are saved with strict `chmod 600` permissions so only your user account can read them.

### 2. System Preparation & Core Install
The script requests `sudo` validation once upfront. It updates your package lists (`apt update`), installs required dependencies (`curl`, `git`, `nodejs`), and executes the official OpenClaw installer. Finally, it runs `openclaw doctor --fix` to automatically repair any baseline permission or configuration drift.

### 3. Local Inference Mapping
You are prompted for your Lemonade server's IP address. The script configures the OpenClaw gateway to route all base generation requests to your local endpoint, and specifically assigns the `nomic-embed-text-v1.5-GGUF` model to handle background memory indexing and dreaming sequences.

### 4. Agent Provisioning
Three isolated workspace directories are created (`~/.openclaw/workspace-assistant`, `workspace-research`, and `workspace-developer`). The script standardizes the inference model across all three agents, strictly assigning `lemonade/user.Qwen3.5-4B-GGUF` to handle logic and generation.

### 5. Least-Privilege Secret Injection & Local MCP Server Binding
External API keys are injected natively into the agents' environments. 
- The **GitLab PAT** is injected into the Assistant, Research, and Developer agents. The `@zereight/mcp-gitlab` server is bound directly to all three agents via `npx`, allowing them to execute Git workflows locally without a third-party hosted platform.
- The **Brave API key** is strictly isolated to the Research agent's namespace.

### 6. Native Skills Assignment
Native `summarize` and `webSearch` skills are unlocked specifically for the Research agent.

### 7. Telegram Channel Isolation
Each agent is bound to its respective dedicated Telegram bot. Crucially, the script then strips all default fallback bindings from the agents. This guarantees strict input isolation—messages sent to the Assistant bot will never bleed into the Developer agent's context window.

### 8. Local Vector Memory Configuration
The script provisions isolated `.sqlite` indexes for each agent using `sqlite-vec` for accelerated hybrid search (Vector + BM25). It enables embedding caching to reduce load on the Lemonade server and turns on experimental session transcript indexing so past conversations remain searchable natively.

### 9. Interactive Prompt Seeding
The script scans the repository for `SOUL.md`, `USER.md`, and `AGENTS.md` files. If found, it offers to seed them into the newly created workspaces. If a file already exists in the destination workspace, it outputs a `diff` and asks for explicit confirmation before overwriting, protecting your existing agent personas.

### 10. Gateway Initialization & Verification
The OpenClaw background daemon is started for the first time. The script waits for the RPC endpoint to stabilize, verifies the systemd status, outputs the final agent routing matrix, and checks the status of the background memory indexers.

## 🛡️ Privacy & Security Notes

- **No Docker Overhead**: Runs as a standard system process for maximum resource efficiency on constrained local hardware.
- **Zero Cloud Data**: Embeddings and inference are routed strictly to your local Lemonade server. No conversation data leaves your network unless utilizing the explicit Brave/GitLab integrations. All code review happens point-to-point via the local `stdio` MCP protocol.
- **Isolated State**: Each agent maintains its own `MEMORY.md` file and SQLite index. They cannot "see" each other's state or memories unless explicitly shared via user prompts or MCP workflows.

## 📜 Logs & Troubleshooting

Installation logs are automatically saved to `~/.openclaw/logs/openclaw-setup.log`. If the OpenClaw daemon fails to start, you can check its status manually using:

```bash
openclaw gateway status
openclaw memory status
openclaw agents list --bindings
```
