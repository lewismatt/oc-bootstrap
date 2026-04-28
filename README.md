# OpenClaw Multi-Agent Bootstrapper

This repository contains a fully automated bootstrapping script
(`oc-bootstrap.sh`) and associated prompt templates to deploy a **strictly
isolated, multi-agent OpenClaw environment** on a bare-metal Linux host
.

Designed for local privacy and efficiency, this setup completely bypasses
traditional cloud inference and hosted orchestration platforms.
It utilizes a local inference server, local vector memory, and distinct
Telegram bots to enforce absolute context isolation between agents, while
utilizing local Model Context Protocol (MCP) servers for third-party
integrations.

## 🏗️ Architecture Overview

- **Host Environment**: Ubuntu 24.04 (Bare-metal, native process execution)
 .
- **Inference Backend**: Local "Lemonade" server running GGUF models via AMD
  ROCm.
- **Agent Topology**:
  - **Assistant**: General-purpose aide (`lemonade/user.Qwen3.5-4B-GGUF`)
   .
  - **Research**: Deep-dive web research agent (`lemonade/user.Qwen3.5-4B-GGUF`)
   .
  - **Developer**: Code and Git workflow agent (`lemonade/user.Qwen3.5-4B-GGUF`)
   .
- **Shared Memory/Embedding Model**: `lemonade/user.nomic-embed-text-v1.5-GGUF`
 .
- **Interface**: 3x independent Telegram bots to prevent context bleeding
 .
- **Memory**: Local SQLite-backed vector search with `sqlite-vec` acceleration
 .

## 📂 Repository Structure

The bootstrapping script relies on a specific repository layout to
automatically seed each agent's behavioral prompts on startup
.

### Root Directory

- **`oc-bootstrap.sh`**: The main automated, idempotent installer that
  provisions agents, binds MCP servers, and configures memory.

- **`.gitlab-ci.yml`**: CI/CD pipeline that executes ShellCheck, MarkdownLint,
  and Yamllint alongside security tests (SAST and Secret Detection).
- **`LLM.md`**: Foundational project context used to ensure AI agents
  maintain architectural alignment during development.
- **`.secrets`**: Template for infrastructure credentials and API tokens
  (Telegram, GitLab, Brave, X).

### Agent-Specific Directories (`assistant/`, `research/`, `developer/`)

- **`SOUL.md`**: Defines an agent's persona and communication tone (e.g.,
  CLI-priority).

- **`USER.md`**: Provides agent-specific user context, such as Nederland
  location data or NBA monitoring targets.
- **`AGENTS.md`**: Outlines multi-agent coordination protocols and GitOps
  procedures for local repository interaction.

## 🤖 Telegram Bot Setup

To maintain strict context isolation, this system requires three independent
Telegram bots.

1. Open the Telegram app and search for **@BotFather**.
2. Send the `/newbot` command and follow the prompts to create your first bot
   (e.g., "Assistant-Agent").
3. Repeat this process twice more to create unique bots for "Research-Agent"
   and "Developer-Agent".
4. @BotFather will provide a unique **HTTP API Token** for each bot; copy these
   immediately.
5. You will be prompted to enter these three separate tokens during the
   execution of `oc-bootstrap.sh`.
6. Alternatively, you can pre-populate the `ASSISTANT_TOKEN`, `RESEARCH_TOKEN`,
   and `DEVELOPER_TOKEN` variables in your `~/.openclaw/secrets.env` file
  .
7. Once configured, the gateway will unbind all default fallbacks and
   strictly map each token to its specific agent workspace.

## 🚀 Quick Start

### Prerequisites

- Ubuntu 24.04 with standard user `sudo` access.
- A running Lemonade server on your local network.
- **Three** distinct Telegram Bot tokens (see setup above).
- (Optional) A GitLab Personal Access Token (PAT) for Git features.
- (Optional) A Brave Search API key for research.
- (Optional) An X/Twitter API key or Auth Cookie for scraping.

### Installation

1. Clone this repository to your target machine.
2. Set up your credentials in `~/.openclaw/secrets.env` based on the
   `.secrets` template.
3. Ensure the script is executable: `chmod +x oc-bootstrap.sh`.
4. Run the setup script: `./oc-bootstrap.sh`.

## ⚙️ How the Installation Works

The `oc-bootstrap.sh` script executes a comprehensive setup process:

1. **Credential Collection**: Prompts for or sources infrastructure and API
   secrets.
2. **System Preparation**: Installs `curl`, `git`, `nodejs`, and the OpenClaw
   core.
3. **Local Inference Mapping**: Configures the gateway to route all calls to
   the local Lemonade server.
4. **Agent Provisioning**: Creates isolated workspaces and standardizes the
   Qwen3.5-4B model.
5. **Local MCP Binding**: Binds the `@zereight/mcp-gitlab` server via `npx`
   to all agents for Git operations over `stdio`.
6. **Advanced Research Skills**: Enables `webScrape`, `newsSearch`,
   `rssReader`, `trendsFinder`, and `xScraper` for Research.
7. **Operational Hooks**: Activates `autoMemory` for Assistant,
   `sessionSummarize` for Research, and `toolValidation` for Developer.
8. **Telegram Isolation**: Maps each agent to its dedicated bot and strips
   default fallbacks.
9. **Vector Memory Setup**: Provisions isolated `.sqlite` indexes with
   `sqlite-vec` acceleration.
10. **Prompt Seeding**: Interactively seeds `SOUL.md`, `USER.md`, and
    `AGENTS.md` into workspaces.

## 🛡️ Privacy & Security Notes

- **Zero Cloud Data**: Embeddings and inference remain local.
  No data leaves your network unless using explicit Brave, X, or GitLab
  integrations.
- **Isolated State**: Each agent maintains its own `MEMORY.md` and SQLite
  index.

## 📜 Logs & Troubleshooting

Logs are saved to `~/.openclaw/logs/openclaw-setup.log`. Verify your installation with:

```bash
openclaw gateway status
openclaw memory status
openclaw agents list --bindings
```
