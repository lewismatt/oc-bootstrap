# 🚀 OpenClaw Multi-Agent Bootstrap

<div align="center">

Automated setup for [OpenClaw](https://openclaw.ai) multi-agent AI system. Deploy three specialized AI agents that run on your own server and communicate privately through Telegram.

> **📢 Refactored for Public Use (April 2026):** This repository has been
> refactored from a personal bootstrap tool into a public-friendly project.
> All personal references have been removed, agent templates are now generic,
> and the interactive setup is designed for users with basic
> Linux/command-line skills. See [REFACTOR.md](REFACTOR.md) for details.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Ubuntu 24.04](https://img.shields.io/badge/Platform-Ubuntu%2024.04-orange.svg)](https://ubuntu.com/download/server)
[![Node.js 22.x](https://img.shields.io/badge/Node.js-22.x-green.svg)](https://nodejs.org/)
[![Docker Ready](https://img.shields.io/badge/Docker-Ready-blue.svg)](DOCKER.md)
[![Telegram Bots](https://img.shields.io/badge/Telegram-Bots-2CA5E0.svg)](https://core.telegram.org/bots)
[![Build Status](https://img.shields.io/github/actions/workflow/status/openclaw/oc-bootstrap/ci.yml)](https://github.com/openclaw/oc-bootstrap/actions)

</div>

---

## 🎯 Who Is This For?

This project is designed for:

- **Self-hosting enthusiasts** who want to run AI agents on their own hardware
- **Privacy-conscious users** who prefer local inference over cloud APIs
- **Developers and researchers** needing isolated agent workspaces for different tasks
- **Anyone with basic Linux/command-line skills** who wants to set up a multi-agent AI system

**What you'll need:**
- A Linux server, VM, or Docker host (Ubuntu 24.04 recommended)
- Three Telegram bot tokens (free to create via [@BotFather](https://t.me/BotFather))
- Basic familiarity with terminal commands

---

## 🚀 Quick Start

Get OpenClaw running in under 5 minutes:

### Option 1: Interactive Script (Bare Metal)

```bash
# 1. Clone the repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap

# 2. Make scripts executable
chmod +x *.sh

# 3. Run the interactive installer
./oc-bootstrap.sh
```text

The script will guide you through:
- Choosing between local (Lemonade) or cloud-based AI models
- Entering your Telegram bot tokens
- Selecting models for each agent
- Optionally adding API keys for enhanced features

### Option 2: Docker Deployment (Recommended for Beginners)

```bash
# 1. Configure your environment
cp docker-config.env.template docker-config.env
nano docker-config.env  # Add your Telegram bot tokens

# 2. Start with Docker Compose
docker compose up -d

# 3. View logs
docker compose logs -f
```text

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Architecture](#️-architecture)
3. [Prerequisites Checklist](#-prerequisites-checklist)
4. [Installation](#-installation)
5. [Docker Setup](#-docker-setup)
   - [Docker Management Quick Reference](#docker-management-quick-reference)
6. [Configuration](#-configuration)
7. [After Installation](#-after-installation)
   - [Standard Installation (Bare Metal)](#standard-installation-bare-metal)
   - [Docker Installation](#docker-installation)
8. [Troubleshooting](#-troubleshooting)
9. [Advanced Topics](#-advanced-topics)
10. [Project Structure](#-project-structure)

---

## 🎯 Overview

**OpenClaw** is a self-hosted multi-agent AI platform. This bootstrap project automates the complex setup process so you can get started in minutes.

### What You Get

| Agent | Purpose | Example Tasks |
|-------|---------|----------------|
| **Assistant** | General-purpose AI helper | Answer questions, brainstorm, summarize text |
| **Research** | Web research specialist | Search the internet, scrape news, analyze trends |
| **Developer** | Coding expert | Write code, debug, read repositories |

### Key Features

All three agents:
- **Run on your own server** (you control your data)
- **Communicate privately via Telegram** (one bot per agent)
- **Use isolated workspaces** with separate memories and configurations
- **Support local AI models** (no cloud APIs required)
- **Can use cloud APIs** (OpenAI, Anthropic) if preferred

### 🍋 Local Inference Focus

This project emphasizes **self-hosting with local models** using [Lemonade Server](https://lemonade.ai):
- **Privacy**: No data sent to external services
- **Cost**: No per-token fees for local models
- **Control**: You choose which models to run

Cloud APIs (OpenAI, Anthropic) are also supported for convenience.

---

## 🏗️ Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────┐
│         Your Linux Server (Ubuntu 24.04)               │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │         OpenClaw Gateway (Single Instance)         │  │
│  │  • Central routing                                │  │
│  │  • Memory indexing                                │  │
│  │  • Configuration management                        │  │
│  └────────────────────────────────────────────────────┘  │
│           ↓            ↓            ↓                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ Assistant    │ │ Research     │ │ Developer    │      │
│  │ Agent        │ │ Agent        │ │ Agent        │      │
│  │              │ │              │ │              │      │
│  │ Isolated     │ │ Isolated     │ │ Isolated     │      │
│  │ Workspace    │ │ Workspace    │ │ Workspace    │      │
│  │ Separate     │ │ Separate     │ │ Separate     │      │
│  │ Memory       │ │ Memory       │ │ Memory       │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│           ↓            ↓            ↓                     │
│  ┌──────────────────────────────────────────────────┐    │
│  │        SQLite Memory Indexes + Vector Search      │    │
│  │        (~/.openclaw/memory/)                      │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
         ↕                                    ↕
    Telegram Bots                      AI Model Providers
    (1 per agent)                 (Local: Lemonade / Cloud: OpenAI, etc.)
```text

### Agent Isolation via Telegram

Each agent has its own:
- **Telegram bot** (unique token from @BotFather)
- **Workspace directory** (`~/.openclaw/workspace-{agent}/`)
- **Memory index** (separate SQLite database)
- **Configuration** (model, skills, hooks)

This isolation ensures:
- Clean separation of concerns
- No cross-contamination of memories
- Independent model selection per agent
- Specialized personalities and capabilities

### Directory Structure

```text
~/.openclaw/
├── logs/                          # Installation and runtime logs
│   └── openclaw-setup.log
├── secrets.env                    # Credentials (chmod 600)
├── memory/                        # SQLite vector indexes
│   ├── assistant.sqlite
│   ├── research.sqlite
│   └── developer.sqlite
└── workspace-{agent}/             # Agent-specific workspaces
    ├── SOUL.md                    # Agent personality & instructions
    ├── USER.md                    # User preferences & context
    ├── AGENTS.md                  # Multi-agent collaboration rules
    └── config/
```text

---

## 📋 Prerequisites Checklist

### 1. System Requirements

- **OS**: Ubuntu 24.04 (bare-metal, VM, or WSL2)
- **User**: Non-root user with `sudo` access
- **Network**: Stable internet connection (required for setup; agents can work offline after)
- **For local inference**: NVIDIA GPU with 8GB+ VRAM (optional but recommended)

### 2. Telegram Bots (Required)

You need **three unique Telegram bot tokens** (one for each agent).

**To create a bot:**

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the **HTTP API Token** (looks like: `110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw`)
4. Repeat 2 more times for total of 3 unique tokens

### 3. Choose Your AI Models

| Type | Provider | Example Model | Cost | Requirements |
|------|----------|---------------|------|-------------|
| **Local** | Lemonade Server | `lemonade/user.Qwen3.5-4B-GGUF` | Free | GPU recommended |
| **Cloud** | OpenAI | `openai/gpt-4o` | Pay per use | API key |
| **Cloud** | Anthropic | `anthropic/claude-3-5-sonnet-latest` | Pay per use | API key |

> 📌 **Recommendation for beginners**: Start with cloud APIs (easier setup, no GPU needed). Switch to local inference later for privacy and cost savings.

### 4. Optional API Keys

These unlock additional features:

| Service | Feature | Cost | Required? |
|---------|---------|------|-----------|
| **Brave Search** | Live web search for Research agent | Free tier available | No |
| **GitHub PAT** | Developer agent can read/write repos | Free | No |
| **GitLab PAT** | Developer agent can access GitLab | Free | No |
| **X/Twitter API** | Research agent can scrape posts | $100/month | No |

---

## ⚡ Installation

### Quick Start (Interactive Mode)

**Recommended for first-time users.**

```bash
# 1. Clone this repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap

# 2. Make scripts executable
chmod +x oc-bootstrap.sh

# 3. Run the installer
./oc-bootstrap.sh
```text

The script will interactively prompt you for:
- Whether to use local or remote inference
- Telegram bot tokens (you can paste them when prompted)
- Model preferences for each agent
- Optional API keys

**Installation time**: ~5-10 minutes (depending on internet speed)

### Automated Setup (Non-Interactive Mode)

**For advanced users or CI/CD pipelines.**

```bash
# 1. Create your configuration file
nano ~/.openclaw/secrets.env
# Add your tokens, models, and API keys in the format:
# ASSISTANT_TOKEN=your_token_here
# RESEARCH_TOKEN=your_token_here
# DEVELOPER_TOKEN=your_token_here
# ASSISTANT_MODEL=openai/gpt-4o
# RESEARCH_MODEL=openai/gpt-4o
# DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
# EMBEDDING_MODEL=openai/text-embedding-3-small

# 2. Run non-interactively
./oc-bootstrap.sh --config ~/.openclaw/secrets.env --non-interactive
```text

> **Note**: The script also supports reading from a custom config file location:
> ```bash
> # Create custom config
> nano /path/to/your/config.env
> # Run with custom config
> ./oc-bootstrap.sh --config /path/to/your/config.env --non-interactive
> ```

---

## 🐳 Docker Setup

**Run OpenClaw in a containerized environment** - perfect for testing, isolation, or users who prefer Docker.

> **📢 Non-Root User**: The container runs as `openclaw` user (not root) for security. This works on both Linux and Windows (Docker Desktop).

### Storage Options: Docker Volume vs Bind Mount

You have two options for persisting data (`/home/openclaw/.openclaw` inside container). Configure using `OPENCLAW_VOLUME` in `docker-config.env`.

| Option | Type | Pros | Cons |
|--------|------|------|------|
| **Named Volume** (default) | Docker managed | Easy to backup, portable across OS | Harder to access files directly |
| **Bind Mount** | Host directory | Easy to edit files, see logs directly | Path must exist, permissions matter |

#### Option 1: Named Volume (Default - Recommended)

Uses Docker's named volume `openclaw-data`. Best for production/long-term use.

```bash
# 1. Create and configure environment file
cp docker-config.env.template docker-config.env
nano docker-config.env  # Add your Telegram bot tokens
# Ensure OPENCLAW_VOLUME is set to: openclaw-data:/home/openclaw/.openclaw

# 2. Start with named volume
docker compose up -d

# 3. View logs
docker compose logs -f
```text

**Data location**: Docker manages this volume. To inspect:
```bash
# List volumes
docker volume ls | grep openclaw

# Inspect volume location (Linux)
docker volume inspect oc-bootstrap_openclaw-data
```text

#### Option 2: Bind Mount (Easier File Access)

Mount a directory from your host machine directly into the container. Great for development or easy file access.

**Step 1: Create host directory**

Linux/macOS:
```bash
mkdir -p ~/.openclaw
```text

Windows (Docker Desktop) - PowerShell:
```powershell
New-Item -Path "$env:USERPROFILE\.openclaw" -ItemType Directory -Force
```text

**Step 2: Configure `docker-config.env`**

Edit `docker-config.env` and set `OPENCLAW_VOLUME` to your host path:

Linux example:
```text
OPENCLAW_VOLUME=/home/youruser/.openclaw:/home/openclaw/.openclaw
```text

macOS example:
```text
OPENCLAW_VOLUME=/Users/youruser/.openclaw:/home/openclaw/.openclaw
```text

Windows example:
```text
OPENCLAW_VOLUME=/c/Users/YourUsername/.openclaw:/home/openclaw/.openclaw
```text

**Step 3: Fix permissions (Linux only)**

The container runs as `openclaw` user (UID 1000). Ensure the host directory is writable:
```bash
sudo chown -R 1000:1000 ~/.openclaw
```text

**Step 4: Start with bind mount**
```bash
docker compose up -d
```text

> **⚠️ Permissions**: On Linux, the container user (`openclaw`, UID 1000) must be able to write to the host directory.
> Windows (Docker Desktop) handles permissions automatically.

### Quick Reference Commands

```bash
# Start services
docker compose up -d

# Stop services (keeps volumes)
docker compose down

# Stop and REMOVE volumes (DESTRUCTIVE - deletes data)
docker compose down -v

# View logs
docker compose logs -f

# Check status
docker compose ps

# Shell access (as non-root openclaw user)
docker compose exec openclaw bash

# Restart services
docker compose restart
```text

### Docker Management Quick Reference

| Operation | Command |
|-----------|---------|
| Start services | `docker compose up -d` |
| Stop services | `docker compose down` |
| View logs (follow) | `docker compose logs -f` |
| Check status | `docker compose ps` |
| Restart services | `docker compose restart` |
| Shell access | `docker compose exec openclaw bash` |
| Rebuild images | `docker compose build` |
| Stop & remove volumes | `docker compose down -v` |

> 📌 For complete Docker documentation including advanced configuration, volume management, and troubleshooting, see [DOCKER.md](DOCKER.md).

### Building the Docker Image

```bash
# Build with Docker Compose (recommended)
docker compose build

# Or build with Docker CLI
docker build -t oc-bootstrap:latest .
```text

### Running with Docker CLI

```bash
# Basic run with environment variables
docker run -d \
  --name oc-bootstrap \
  --env-file docker-config.env \
  -v openclaw-data:/home/openclaw/.openclaw \
  oc-bootstrap:latest

# Interactive shell (for debugging)
docker run -it --rm \
  --env-file docker-config.env \
  oc-bootstrap:latest \
  shell
```text

### Configuration

Edit `docker-config.env` (created from template) with your settings:

| Variable | Required | Description |
|----------|----------|-------------|
| `ASSISTANT_TOKEN` | ✅ | Telegram bot token for Assistant agent |
| `RESEARCH_TOKEN` | ✅ | Telegram bot token for Research agent |
| `DEVELOPER_TOKEN` | ✅ | Telegram bot token for Developer agent |
| `ASSISTANT_MODEL` | No | Model for Assistant (default: `openai/gpt-4o`) |
| `RESEARCH_MODEL` | No | Model for Research (default: `openai/gpt-4o`) |
| `DEVELOPER_MODEL` | No | Model for Developer (default: `anthropic/claude-3-5-sonnet-latest`) |
| `LOCAL_INFERENCE` | No | Use local Lemonade Server (`true`/`false`) |
| `GITHUB_PAT` | No | GitHub Personal Access Token |
| `BRAVE_API_KEY` | No | Brave Search API Key |

### Volume Persistence

OpenClaw data persists in Docker volumes:

```bash
# List volumes
docker volume ls | grep openclaw

# Data location in container: /home/openclaw/.openclaw
# Contains: config, memory (SQLite), agent workspaces
```text

### Local Inference with Lemonade Server

Enable the optional Lemonade Server service in `docker-compose.yml` for local LLM inference (no cloud APIs needed):

1. Uncomment the `lemonade` service section in `docker-compose.yml`
2. Set `LOCAL_INFERENCE=true` in `docker-config.env`
3. Start services: `docker compose up -d`

> **Note:** The project uses modern `docker compose` (V2) syntax. If you're using an older version, the command may be `docker-compose` instead.

### Documentation

For detailed Docker documentation, see [DOCKER.md](DOCKER.md) which covers:
- Building and running containers
- Volume management and backups
- Development mode with hot-reload
- Troubleshooting common issues
- Advanced configuration options

---

## 🛠️ Configuration

### Configuration File Format (.env)

The `--config` file uses standard bash variable syntax:

```bash
# === Inference Backend ===
LOCAL_INFERENCE=false                    # Use local Lemonade (true/false)
LEMONADE_KEY="local-dummy-key"           # Only needed if LOCAL_INFERENCE=true
LEMONADE_IP="192.168.1.100"              # IP of Lemonade server (if local)

# === Model Selection ===
EMBEDDING_MODEL="openai/text-embedding-3-small"
ASSISTANT_MODEL="openai/gpt-4o"
RESEARCH_MODEL="openai/gpt-4o"
DEVELOPER_MODEL="anthropic/claude-3-5-sonnet-latest"

# === Telegram Bot Tokens ===
ASSISTANT_TOKEN="110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw"
RESEARCH_TOKEN="110201544:BBIjfRhfDG2jHXKyGDjkrBbtbDL1MAkLbx"
DEVELOPER_TOKEN="110201545:CChJkSlhEJ3kJYLzHEklsCcuCEM2NBmMcy"

# === API Credentials (Optional) ===
GITHUB_PAT="ghp_YOUR_GITHUB_TOKEN_HERE"
GITLAB_PAT="glpat-YOUR_GITLAB_TOKEN_HERE"
BRAVE_API_KEY="YOUR_BRAVE_API_KEY_HERE"
X_API_KEY="YOUR_X_BEARER_TOKEN_HERE"
```text

### Environment Variables

You can set these before running the script to pre-populate configuration:

```bash
export ASSISTANT_TOKEN="..."
export RESEARCH_TOKEN="..."
export DEVELOPER_TOKEN="..."
./oc-bootstrap.sh
```text

---

## 🎯 After Installation

### Standard Installation (Bare Metal)

#### Starting the Gateway

If the installer didn't start the gateway for you:

```bash
openclaw gateway start
```text

Check the status:

```bash
openclaw gateway status
```text

#### Configuring API Keys (if not done during setup)

```bash
openclaw onboarding
```text

This interactive wizard will walk you through entering:
- OpenAI API key
- Anthropic API key
- Other provider credentials

#### Communicating with Your Agents

Once the gateway is running, message your agents on Telegram:

**Example conversation with Assistant:**

```text
You:        "What's the capital of France?"
Assistant:  "The capital of France is Paris..."

You:        "Search the web for latest AI news"
You:        "@research_bot search: latest AI trends 2026"
Research:   "Here are the latest developments in AI..."

You:        "@developer_bot write a Python function to sort a list"
Developer:  "Here's a Python function..."
```text

#### Checking Agent Status

```bash
openclaw agents list --bindings
```text

#### Viewing Memory & Search

```bash
openclaw memory status
```text

Shows:
- Number of indexed memories per agent
- Vector search index size
- Last indexing time

### Docker Installation

If you installed using Docker, here are the essential management commands:

#### Starting/Stopping Services

```bash
# Start all services in background
docker compose up -d

# Stop services (keeps volumes)
docker compose down

# Stop services and remove volumes (DESTRUCTIVE - deletes data)
docker compose down -v
```text

#### Viewing Logs

```bash
# Follow logs in real-time
docker compose logs -f

# View last 50 lines
docker compose logs --tail=50 openclaw

# View specific service logs
docker compose logs -f openclaw
```text

#### Checking Status

```bash
# List running containers
docker compose ps

# Check OpenClaw health in container
docker exec oc-bootstrap openclaw doctor

# Inspect container details
docker inspect oc-bootstrap
```text

#### Restarting Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart openclaw
```text

#### Accessing the Container Shell

```bash
# Open interactive shell in running container
docker compose exec openclaw bash

# Run new temporary container with shell
docker run -it --rm --env-file docker-config.env oc-bootstrap:latest shell
```text

#### Advanced Docker Operations

For more advanced Docker operations, see [DOCKER.md](DOCKER.md):
- Volume management and backups
- Development mode with hot-reload
- Local inference with Lemonade Server
- Troubleshooting and debugging

---

## ❓ Troubleshooting

### Script Fails During Installation

**Problem**: `[ERROR] Missing required system tools`

**Solution**:
```bash
sudo apt update
sudo apt install -y curl git build-essential
./oc-bootstrap.sh
```text

---

### Telegram Token Validation Fails

**Problem**: `[ERROR] Invalid token (401 Unauthorized)`

**Causes**:
- Token is typo'd or incomplete
- Token was already revoked (copy a new one from @BotFather)
- Internet connectivity issue

**Solution**:
1. Open Telegram → @BotFather
2. Send `/mybots` and select your bot
3. Choose "API Token" → "Regenerate token"
4. Copy the new token and re-run the script

---

### Gateway Won't Start

**Problem**: `openclaw gateway start` times out

**Causes**:
- API keys are misconfigured
- Port 8080 is already in use
- Firewall blocking localhost connections

**Solution**:
```bash
# Check for port conflicts
sudo lsof -i :8080

# Reconfigure API keys
openclaw onboarding

# Check logs
cat ~/.openclaw/logs/openclaw-setup.log

# Try starting with verbose output
openclaw gateway start --verbose
```text

---

### Agents Not Responding on Telegram

**Problem**: Telegram bots receive messages but don't reply

**Causes**:
- Gateway is not running
- Telegram tokens were not bound correctly
- Agent workspace has no SOUL.md (personality instructions)

**Solution**:
```bash
# Verify gateway is running
openclaw gateway status

# Re-bind Telegram channels
openclaw agents unbind --agent assistant --all
openclaw agents bind --agent assistant --bind "telegram:YOUR_TOKEN_HERE"

# Check agent logs
openclaw agents logs assistant
```text

---

### Docker-Specific Issues

#### Container Won't Start

**Problem**: `docker compose up -d` fails or container exits immediately

**Causes**:
- Port 3000 (or configured port) already in use
- Missing or invalid `docker-config.env` file
- Insufficient permissions on volume mount

**Solution**:
```bash
# Check for port conflicts
sudo lsof -i :3000

# Verify environment file exists and has required tokens
cat docker-config.env | grep TOKEN

# Check container logs
docker compose logs openclaw

# Inspect container for errors
docker inspect oc-bootstrap
```text

#### Telegram Bots Not Connecting (Docker)

**Problem**: Bots don't respond when running in Docker

**Causes**:
- Tokens not passed correctly to container
- Container can't reach `api.telegram.org`
- Network mode issues

**Solution**:
```bash
# Verify tokens are loaded in container
docker exec oc-bootstrap env | grep TOKEN

# Test connectivity from inside container
docker exec oc-bootstrap curl -I https://api.telegram.org

# Check OpenClaw doctor inside container
docker exec oc-bootstrap openclaw doctor
```text

#### Volume Permission Issues

**Problem**: `Permission denied` errors when OpenClaw tries to write to volumes

**Solution**:
```bash
# Fix permissions on volume data
docker exec oc-bootstrap sudo chown -R openclaw:openclaw /home/openclaw/.openclaw

# Or rebuild without cache
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```text

> 📌 For more Docker troubleshooting, see [DOCKER.md - Troubleshooting section](DOCKER.md#troubleshooting).

---

## 🍋 Advanced Topics

### Using Local Inference (Lemonade Server)

For complete privacy, run OpenClaw with a local Lemonade Server instead of cloud APIs.

**Requirements**:
- NVIDIA GPU (RTX 4060 or better recommended)
- 20+ GB disk space
- 8+ GB VRAM

**Setup**:
```bash
./scripts/install-lemonade.sh
# Follow prompts to select model and GPU

# Once server is running, bootstrap agents:
./oc-bootstrap.sh --config .env
# When prompted, set LOCAL_INFERENCE=true
```text

See [Lemonade Server Documentation](https://lemonade.ai/docs) for details.

---

### Managing Agent Personalities

Each agent's behavior is controlled by prompt files in its workspace:

- **SOUL.md** — Agent's core instructions and personality
- **USER.md** — Your preferences and context
- **AGENTS.md** — Multi-agent collaboration rules

To customize an agent:

```bash
nano ~/.openclaw/workspace-assistant/SOUL.md
# Edit and save

# Reload configuration
openclaw agents reload assistant
```text

---

### Accessing Agent Memories

Vector memories are stored in SQLite with embeddings:

```bash
# View memory statistics
openclaw memory status

# Search agent memory
openclaw memory search --agent assistant --query "previous conversations about Python"

# Export memory for backup
openclaw memory export --agent assistant > assistant-memory.json
```text

---

### Systemd Service (Optional)

To auto-start the gateway on boot:

```bash
sudo tee /etc/systemd/system/openclaw.service > /dev/null <<EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=$(which openclaw) gateway start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
```text

Check status:
```bash
sudo systemctl status openclaw
```text

---

### Backing Up Your Configuration

Your agents' memories and settings are stored locally:

```bash
# Backup everything
tar -czf openclaw-backup.tar.gz ~/.openclaw/

# Restore from backup
tar -xzf openclaw-backup.tar.gz -C ~/
```text

> ⚠️ **Important**: The `secrets.env` file contains credentials. Keep it secure and never commit it to version control.

---

### Monitoring Agent Activity

View real-time logs:

```bash
# Overall gateway logs
tail -f ~/.openclaw/logs/openclaw-setup.log

# Agent-specific logs
openclaw agents logs assistant --follow
openclaw agents logs research --follow
openclaw agents logs developer --follow
```text

---

## 📁 Project Structure

```text
oc-bootstrap/
├── README.md                    # This file
├── oc-bootstrap.sh              # Main installation script
├── install-lemonade.sh          # Optional: Local LLM setup
├── lib/
│   └── helpers.sh               # Reusable bash functions library
├── assistant/
│   ├── SOUL.md                  # Assistant personality template
│   ├── USER.md                  # User preferences template
│   └── AGENTS.md                # Collaboration rules template
├── research/
│   ├── SOUL.md
│   ├── USER.md
│   └── AGENTS.md
├── developer/
│   ├── SOUL.md
│   ├── USER.md
│   └── AGENTS.md
├── docker-config.env.template   # Config file template
├── docker-compose.yml           # Docker Compose configuration
├── Dockerfile                   # Docker image definition
├── .gitignore                   # Don't commit .env or logs
├── LICENSE                      # MIT License
├── CHANGELOG                    # Version history
├── CONTRIBUTING.md              # Contribution guidelines
├── CODE_OF_CONDUCT.md           # Code of conduct
├── DOCKER.md                    # Docker documentation
├── Makefile                     # Build automation
├── scripts/                     # Utility scripts
│   ├── docker-entrypoint.sh
│   ├── docker-cleanup.sh
│   └── uninstall-oc-bootstrap.sh
├── tests/                       # Test scripts
│   └── docker-test.sh
└── wiki/                        # Documentation wiki
    ├── Home.md
    ├── Quick-Start.md
    └── ... (additional guides)
```text

---

## 📦 Dependencies & Attributions

This project builds upon these excellent open source projects:

### Core Dependencies

| Project | Purpose | License | Version |
|---------|---------|---------|---------|
| [OpenClaw](https://github.com/openclaw/openclaw) | Self-hosted multi-agent AI platform | [MIT](https://github.com/openclaw/openclaw/blob/main/LICENSE) | Latest |
| [Node.js](https://nodejs.org/) | JavaScript runtime for OpenClaw CLI | [MIT](https://github.com/nodejs/node/blob/main/LICENSE) | 22.x |
| [Ubuntu](https://ubuntu.com/) | Base operating system | [Various](https://ubuntu.com/licensing) | 24.04 LTS |
| [Docker](https://www.docker.com/) | Container platform for isolated deployment | [Apache 2.0](https://github.com/docker/docker/blob/master/LICENSE) | Latest |

### AI Model Providers

| Provider | Usage | License |
|----------|-------|---------|
| [OpenAI](https://openai.com/) | GPT-4o models for Assistant & Research agents | [Terms](https://openai.com/policies/terms-of-use) |
| [Anthropic](https://anthropic.com/) | Claude models for Developer agent | [Terms](https://www.anthropic.com/legal/terms) |
| [Lemonade Server](https://lemonade.ai/) | Local LLM inference (optional) | [License](https://lemonade.ai/license) |

### Tools & Libraries

| Tool | Purpose | License |
|------|---------|---------|
| [Telegram Bot API](https://core.telegram.org/bots) | Agent communication interface | [Terms](https://core.telegram.org/bots/terms) |
| [SQLite](https://www.sqlite.org/) | Vector memory storage | [Public Domain](https://www.sqlite.org/copyright.html) |
| [Brave Search API](https://brave.com/search/api/) | Web search for Research agent | [Terms](https://brave.com/privacy/browser/legal/) |

### Special Thanks

- **OpenClaw Team** - For creating the amazing multi-agent AI platform
- **Telegram** - For providing a secure, private messaging platform for agent communication
- **NodeSource** - For maintaining the Node.js package repository
- **The Open Source Community** - For the countless tools and libraries that make projects like this possible

---

## 🤝 Contributing

Found a bug? Have a suggestion? We'd love your help!

1. Check [open issues](https://github.com/openclaw/oc-bootstrap/issues)
2. Create a new issue with details
3. Submit a pull request with improvements

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

MIT License — See [LICENSE](LICENSE) file for details.

---

## ❤️ Support

- **Documentation**: [docs.openclaw.ai](https://docs.openclaw.ai)
- **Discord Community**: [discord.gg/openclaw](https://discord.gg/openclaw)
- **GitHub Issues**: [Report a bug](https://github.com/openclaw/oc-bootstrap/issues)

---

## 🗂️ Additional Resources

- [Model Comparison Guide](https://docs.openclaw.ai/models)
- [API Provider Setup (OpenAI, Anthropic, etc.)](https://docs.openclaw.ai/providers)
- [Security & Privacy Best Practices](https://docs.openclaw.ai/security)
- [Performance Tuning](https://docs.openclaw.ai/performance)

---

**Happy bootstrapping! 🚀**

---

### Uninstalling OpenClaw

If you want to remove OpenClaw and all its data, use the provided uninstall script:

```bash
# Basic uninstall (interactive - will ask for confirmation)
./scripts/uninstall-oc-bootstrap.sh

# Skip all confirmations (use with caution!)
./scripts/uninstall-oc-bootstrap.sh --yes

# Keep agent workspaces (SOUL.md, AGENTS.md, etc.)
./scripts/uninstall-oc-bootstrap.sh --preserve-workspaces
```text

**What the uninstall script removes:**

| Component | Removed? | Notes |
|-----------|----------|-------|
| Gateway process | ✅ | Stops if running |
| Agent workspaces | ✅ | `~/.openclaw/workspace-*` (unless `--preserve-workspaces`) |
| Secrets file | ✅ | `~/.openclaw/secrets.env` (contains API keys & tokens) |
| Memory index | ✅ | `~/.openclaw/memory/` (vector search data) |
| Log files | ✅ | `~/.openclaw/logs/` |
| OpenClaw config | ✅ | `~/.config/openclaw/` |
| OpenClaw binary | ⚠️ | Optional - script will ask |
| System packages | ❌ | curl, git, nodejs - NOT removed (may be used by other apps) |

> ⚠️ **Warning**: The uninstall script will ask before deleting each component. Use `--yes` to skip confirmations, but be careful—this will delete all your agent data and configurations!

> 💡 **Tip**: If you just want to reset the configuration but keep your workspaces, use `--preserve-workspaces`.

---
