# 🚀 OpenClaw Multi-Agent Bootstrap

Automated setup for OpenClaw AI agents on Ubuntu 24.04. Deploy three specialized AI assistants that work securely on your server and communicate with you privately through Telegram.

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Architecture](#%EF%B8%8F-architecture)
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

**OpenClaw** is a self-hosted multi-agent AI platform. This bootstrap script automates the complex setup process so you can get started in minutes.

### What You Get

| Agent | Purpose | Example Tasks |
|-------|---------|----------------|
| **Assistant** | General-purpose AI helper | Answer questions, brainstorm, summarize text |
| **Research** | Web research specialist | Search the internet, scrape news, analyze trends |
| **Developer** | Coding expert | Write code, debug, read repositories |

All three agents:
- Run securely on your own server (no data sent to external services unless you configure APIs)
- Communicate privately via Telegram
- Use isolated workspaces with separate memories
- Support both local and cloud-based AI models

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────┐
│         Your Ubuntu 24.04 Server                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │         OpenClaw Gateway                           │  │
│  │  (Central routing, memory indexing, config)        │  │
│  └────────────────────────────────────────────────────┘  │
│           ↓            ↓            ↓                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ Assistant    │ │ Research     │ │ Developer    │      │
│  │ Agent        │ │ Agent        │ │ Agent        │      │
│  │              │ │              │ │              │      │
│  │ Model: GPT4o │ │ Model: GPT4o │ │ Claude 3.5   │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│           ↓            ↓            ↓                     │
│  ┌──────────────────────────────────────────────────┐    │
│  │        SQLite Memory Indexes + Vector Search      │    │
│  │        (~/.openclaw/memory/)                      │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
         ↕                                    ↕
    Telegram Bot                         API Providers
    (You)                           (OpenAI, Anthropic, etc.)
```

### Directory Structure

```
~/.openclaw/
├── logs/                          # Installation and runtime logs
│   └── openclaw-setup.log
├── secrets.env                    # Encrypted credentials (chmod 600)
├── memory/                        # SQLite vector indexes
│   ├── assistant.sqlite
│   ├── research.sqlite
│   └── developer.sqlite
└── workspace-{agent}/             # Agent-specific workspaces
    ├── SOUL.md                    # Agent personality & instructions
    ├── USER.md                    # User preferences & context
    ├── AGENTS.md                  # Multi-agent collaboration rules
    └── config/
```

---

## 📋 Prerequisites Checklist

### 1. System Requirements

- **OS**: Ubuntu 24.04 (bare-metal or WSL2)
- **User**: Non-root user with `sudo` access
- **Network**: Stable internet connection (required for setup; agents can work offline after)

### 2. Telegram Bots (Required)

You need **three unique Telegram bot tokens** (one for each agent).

**To create a bot:**

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the **HTTP API Token** (looks like: `110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw`)
4. Repeat 2 more times for total of 3 unique tokens

### 3. Choose Your AI Models (Required)

For beginners, we recommend **Remote APIs** (cloud-based, no GPU needed):

| Provider | Recommended Model | Cost | Setup Time |
|----------|-------------------|------|------------|
| **OpenAI** | `openai/gpt-4o` | ~$0.03 per 1K tokens | 5 min (get API key) |
| **Anthropic** | `anthropic/claude-3-5-sonnet-latest` | ~$0.003 per 1K tokens | 5 min (get API key) |
| **Local (Lemonade)** | `lemonade/user.Qwen3.5-4B-GGUF` | Free (but needs GPU) | 30 min (setup server) |

> 📌 **Default Configuration**: Assistant and Research use OpenAI GPT-4o; Developer uses Anthropic Claude. You can change these during setup.

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
git clone https://github.com/openclaw/oc-bootstrap.git openclaw-setup
cd openclaw-setup

# 2. Make scripts executable
chmod +x oc-bootstrap.sh install-lemonade.sh

# 3. Run the installer
./oc-bootstrap.sh
```

The script will interactively prompt you for:
- Whether to use local or remote inference
- Telegram bot tokens
- Model preferences
- Optional API keys

**Installation time**: ~5–10 minutes (depending on internet speed)

### Automated Setup (Non-Interactive Mode)

**For advanced users or CI/CD pipelines.**

```bash
# 1. Prepare your configuration
cp .env.template .env
nano .env
# Fill in your tokens, models, and API keys

# 2. Run non-interactively
./oc-bootstrap.sh --config .env --non-interactive
```

---

## � Docker Setup

**Run OpenClaw in a containerized environment** - perfect for testing, isolation, or users who prefer Docker.

### Quick Start with Docker Compose

```bash
# 1. Create and configure environment file
cp docker-config.env.template docker-config.env
nano docker-config.env  # Add your Telegram bot tokens

# 2. Build and start the container
docker-compose up -d

# 3. View logs
docker-compose logs -f

# 4. Stop when done
docker-compose down
```

### Docker Management Quick Reference

| Operation | Command |
|-----------|---------|
| Start services | `docker-compose up -d` |
| Stop services | `docker-compose down` |
| View logs (follow) | `docker-compose logs -f` |
| Check status | `docker-compose ps` |
| Restart services | `docker-compose restart` |
| Shell access | `docker-compose exec openclaw bash` |
| Rebuild images | `docker-compose build` |
| Stop & remove volumes | `docker-compose down -v` |

> 📌 For complete Docker documentation including advanced configuration, volume management, and troubleshooting, see [DOCKER.md](DOCKER.md).

### Building the Docker Image

```bash
# Build with Docker Compose (recommended)
docker-compose build

# Or build with Docker CLI
docker build -t oc-bootstrap:latest .
```

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
```

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
```

### Local Inference with Lemonade Server

Enable the optional Lemonade Server service in `docker-compose.yml` for local LLM inference (no cloud APIs needed):

1. Uncomment the `lemonade` service section in `docker-compose.yml`
2. Set `LOCAL_INFERENCE=true` in `docker-config.env`
3. Start services: `docker-compose up -d`

### Documentation

For detailed Docker documentation, see [DOCKER.md](DOCKER.md) which covers:
- Building and running containers
- Volume management and backups
- Development mode with hot-reload
- Troubleshooting common issues
- Advanced configuration options

---

## �🛠️ Configuration

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
```

### Environment Variables

You can set these before running the script to pre-populate configuration:

```bash
export ASSISTANT_TOKEN="..."
export RESEARCH_TOKEN="..."
export DEVELOPER_TOKEN="..."
./oc-bootstrap.sh
```

---

## 🎯 After Installation

### Standard Installation (Bare Metal)

#### Starting the Gateway

If the installer didn't start the gateway for you:

```bash
openclaw gateway start
```

Check the status:

```bash
openclaw gateway status
```

#### Configuring API Keys (if not done during setup)

```bash
openclaw onboarding
```

This interactive wizard will walk you through entering:
- OpenAI API key
- Anthropic API key
- Other provider credentials

#### Communicating with Your Agents

Once the gateway is running, message your agents on Telegram:

**Example conversation with Assistant:**

```
You:        "What's the capital of France?"
Assistant:  "The capital of France is Paris..."

You:        "Search the web for latest AI news"
You:        "@research_bot search: latest AI trends 2025"
Research:   "Here are the latest developments in AI..."

You:        "@developer_bot write a Python function to sort a list"
Developer:  "Here's a Python function..."
```

#### Checking Agent Status

```bash
openclaw agents list --bindings
```

#### Viewing Memory & Search

```bash
openclaw memory status
```

Shows:
- Number of indexed memories per agent
- Vector search index size
- Last indexing time

### Docker Installation

If you installed using Docker, here are the essential management commands:

#### Starting/Stopping Services

```bash
# Start all services in background
docker-compose up -d

# Stop services (keeps volumes)
docker-compose down

# Stop services and remove volumes (DESTRUCTIVE - deletes data)
docker-compose down -v
```

#### Viewing Logs

```bash
# Follow logs in real-time
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50 openclaw

# View specific service logs
docker-compose logs -f openclaw
```

#### Checking Status

```bash
# List running containers
docker-compose ps

# Check OpenClaw health in container
docker exec oc-bootstrap openclaw doctor

# Inspect container details
docker inspect oc-bootstrap
```

#### Restarting Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart openclaw
```

#### Accessing the Container Shell

```bash
# Open interactive shell in running container
docker-compose exec openclaw bash

# Run new temporary container with shell
docker run -it --rm --env-file docker-config.env oc-bootstrap:latest shell
```

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
```

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
```

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
```

---

### Docker-Specific Issues

#### Container Won't Start

**Problem**: `docker-compose up -d` fails or container exits immediately

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
docker-compose logs openclaw

# Inspect container for errors
docker inspect oc-bootstrap
```

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
```

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
```

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
./install-lemonade.sh
# Follow prompts to select model and GPU

# Once server is running, bootstrap agents:
./oc-bootstrap.sh --config .env
# When prompted, set LOCAL_INFERENCE=true
```

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
```

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
```

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
```

Check status:
```bash
sudo systemctl status openclaw
```

---

### Backing Up Your Configuration

Your agents' memories and settings are stored locally:

```bash
# Backup everything
tar -czf openclaw-backup.tar.gz ~/.openclaw/

# Restore from backup
tar -xzf openclaw-backup.tar.gz -C ~/
```

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
```

---

## 📁 Project Structure

```
oc-bootstrap/
├── README.md                    # This file
├── oc-bootstrap.sh              # Main installation script (refactored)
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
├── .env.template                # Config file template
├── .gitignore                   # Don't commit .env or logs
├── LICENSE                      # MIT License
└── CHANGELOG                    # Version history
```

---

## 🤝 Contributing

Found a bug? Have a suggestion? We'd love your help!

1. Check [open issues](https://github.com/openclaw/oc-bootstrap/issues)
2. Create a new issue with details
3. Submit a pull request with improvements

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

### Uninstalling OpenClaw

If you want to remove OpenClaw and all its data, use the provided uninstall script:

```bash
# Basic uninstall (interactive - will ask for confirmation)
./uninstall-oc-bootstrap.sh

# Skip all confirmations (use with caution!)
./uninstall-oc-bootstrap.sh --yes

# Keep agent workspaces (SOUL.md, AGENTS.md, etc.)
./uninstall-oc-bootstrap.sh --preserve-workspaces
```

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
