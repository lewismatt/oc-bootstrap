# Installation

Complete installation guide for OpenClaw Multi-Agent system. Choose the method that best fits your needs.

---

## 📋 Table of Contents

1. [Quick Decision Guide](#quick-decision-guide)
2. [Prerequisites](#prerequisites)
3. [Method 1: Docker Deployment](#method-1-docker-deployment)
4. [Method 2: Bare Metal Installation](#method-2-bare-metal-installation)
5. [Post-Installation Steps](#post-installation-steps)
6. [Verification](#verification)
7. [Next Steps](#next-steps)

---

## Quick Decision Guide

### Which Installation Method Should I Choose?

| Consideration | Docker | Bare Metal |
|---------------|--------|------------|
| **Ease of Setup** | ⭐⭐⭐⭐⭐ Very Easy | ⭐⭐⭐ Moderate |
| **Performance** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Isolation** | ⭐⭐⭐⭐⭐ Full | ⭐⭐ Limited |
| **Portability** | ⭐⭐⭐⭐⭐ High | ⭐⭐ Low |
| **Updates** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ Moderate |
| **GPU Access** | ⭐⭐⭐ Possible | ⭐⭐⭐⭐⭐ Direct |
| **Multi-User** | ⭐⭐⭐⭐⭐ Ideal | ⭐⭐ Challenging |

**Recommendation**: New users should start with **Docker Deployment**.

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 8GB | 32GB |
| **Storage** | 20GB free | 100GB+ SSD |
| **Network** | Internet access | High-speed broadband |
| **GPU** | Optional | 12GB+ VRAM (for local inference) |

### Required Software

**For Docker Deployment:**
- Docker 20.10+
- Docker Compose 2.x

**For Bare Metal:**
- Node.js 22.x
- Python 3.8+
- Git

### Verify Prerequisites

```bash
# Check OS
lsb_release -a

# Check CPU
nproc

# Check RAM
free -h

# Check disk space
df -h

# Check internet
ping -c 3 github.com
```

---

## Method 1: Docker Deployment

### Step 1: Install Docker

```bash
# Download and run Docker install script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose plugin
sudo apt update
sudo apt install -y docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Step 2: Clone Repository

```bash
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
```

### Step 3: Configure Environment

```bash
# Copy template
cp docker-config.env.template docker-config.env

# Edit configuration
nano docker-config.env
```

**Minimum configuration:**

```bash
# Telegram Bot Tokens (get from @BotFather)
TELEGRAM_ASSISTANT_BOT_TOKEN=your_token_here
TELEGRAM_RESEARCH_BOT_TOKEN=your_token_here
TELEGRAM_DEVELOPER_BOT_TOKEN=your_token_here

# Model selection
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
EMBEDDING_MODEL=openai/text-embedding-3-small

# API Keys (if using cloud models)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

### Step 4: Start Services

```bash
# Build and start
docker compose up -d

# View logs
docker compose logs -f
```

### Step 5: Verify

```bash
# Check container status
docker compose ps

# Should show "oc-bootstrap" as "Up"
```

**Full guide**: **[Docker Deployment](Docker-Deployment)**

---

## Method 2: Bare Metal Installation

### Step 1: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essentials
sudo apt install -y \
  curl wget git python3 python3-pip \
  build-essential ca-certificates \
  gnupg lsb-release
```

### Step 2: Install Node.js 22.x

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify
node --version  # Should be v22.x
```

### Step 3: Clone and Configure

```bash
# Clone repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
chmod +x *.sh

# Create configuration
cp .env.example .env  # If exists
nano .env
```

### Step 4: Run Installer

```bash
./oc-bootstrap.sh
```

The interactive installer will guide you through:
- Telegram bot setup
- Model selection
- API key configuration
- Optional Lemonade Server installation

### Step 5: Start OpenClaw

```bash
# Start gateway
openclaw gateway start

# Check status
openclaw status
```

**Full guide**: **[Bare Metal Installation](Bare-Metal-Installation)**

---

## Post-Installation Steps

### 1. Create Telegram Bots

If you haven't already:

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow prompts
3. Create three bots (Assistant, Research, Developer)
4. Copy the tokens and add to your configuration

**Detailed guide**: **[Chat Channel Isolation](Chat-Channel-Isolation)**

### 2. Test Bot Connections

```bash
# Send /start to each bot in Telegram
# Verify they respond
```

### 3. Configure Agent Personas (Optional)

```bash
# Customize agent behavior
nano assistant/SOUL.md
nano research/SOUL.md
nano developer/SOUL.md

# Restart to apply changes
docker compose restart  # Docker
openclaw gateway restart  # Bare Metal
```

**Detailed guide**: **[Agent Configuration](Agent-Configuration)**

### 4. Set Up Local Inference (Optional)

```bash
# Install Lemonade Server
./scripts/install-lemonade.sh

# Update configuration
# Set LOCAL_INFERENCE=true in docker-config.env or .env
```

**Detailed guide**: **[Lemonade Configuration](Lemonade-Configuration)**

---

## Verification

### Checklist

- [ ] OpenClaw is running (`docker compose ps` or `openclaw status`)
- [ ] All three bots respond to `/start` in Telegram
- [ ] Agents use correct models (check logs)
- [ ] Memory is persisting (test with a conversation)
- [ ] API keys are valid (no authentication errors in logs)

### Test Commands

**Docker:**

```bash
# Check service health
docker compose ps

# View recent logs
docker compose logs --tail=50 openclaw

# Test bot connection
docker compose exec openclaw openclaw --version
```

**Bare Metal:**

```bash
# Check service status
openclaw status

# View logs
tail -f ~/.openclaw/logs/gateway.log

# Test installation
openclaw --version
```

### Sample Conversation Test

**In Telegram (to Assistant Bot):**

```
You: Hello! What can you do?
Assistant: I'm your general-purpose AI assistant...

You: Remember that I prefer Python over bash
Assistant: Noted! I'll remember that you prefer Python...

[Restart OpenClaw]

You: What language do I prefer?
Assistant: You prefer Python over bash, as you mentioned earlier.
```

---

## Next Steps

Now that OpenClaw is installed:

1. **[Configure Agents](Agent-Configuration)** - Customize agent personalities
2. **[Set Up Telegram](Chat-Channel-Isolation)** - Organize chat channels
3. **[Configure APIs](API-Integrations)** - Set up OpenAI, Anthropic, etc.
4. **[Set Up Local Inference](Lemonade-Configuration)** - Optional Lemonade Server
5. **[Optimize Server](Linux-Server-Configuration)** - Tune your server
6. **[Understand Architecture](Architecture-Overview)** - Learn how it works

---

## Quick Reference

### Docker Commands

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart

# View logs
docker compose logs -f

# Update
git pull && docker compose up -d --force-recreate --build
```

### Bare Metal Commands

```bash
# Start
openclaw gateway start

# Stop
openclaw gateway stop

# Restart
openclaw gateway restart

# Status
openclaw status

# Update
git pull && ./oc-bootstrap.sh --update
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Bot not responding | Check bot tokens in config, restart service |
| "Node.js version not supported" | Install Node.js 22.x (see Bare Metal guide) |
| "Docker command not found" | Install Docker (see Docker guide) |
| "Permission denied" | Check file permissions, run as correct user |
| "Out of memory" | Add swap or upgrade RAM |

**Full troubleshooting**: **[Troubleshooting](Troubleshooting)**

---

## Getting Help

- **Wiki Home**: **[Home](Home)**
- **Quick Start**: **[Quick Start Guide](Quick-Start)**
- **Issues**: [GitHub Issues](https://github.com/openclaw/oc-bootstrap/issues)
- **Discussions**: [GitHub Discussions](https://github.com/openclaw/oc-bootstrap/discussions)

---

*Last updated: April 2026*
