# Quick Start Guide

Get OpenClaw Multi-Agent system up and running in under 5 minutes. This guide covers the fastest path to a working installation.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Method 1: Docker Deployment (Recommended)](#method-1-docker-deployment-recommended)
3. [Method 2: Bare Metal Installation](#method-2-bare-metal-installation)
4. [Verification](#verification)
5. [Next Steps](#next-steps)

---

## Prerequisites

Before starting, ensure you have:

- **Ubuntu 24.04 LTS** server (or compatible Linux distribution)
- **Telegram account** for bot communication
- **Git** installed (`sudo apt install git`)
- **Internet access** for initial setup

### Quick Prerequisite Check

```bash
# Check Ubuntu version
lsb_release -a

# Check if git is installed
git --version

# Check internet connectivity
ping -c 3 github.com
```text

---

## Method 1: Docker Deployment (Recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
```text

### Step 2: Configure Environment

```bash
# Copy template
cp docker-config.env.template docker-config.env

# Edit with your values
nano docker-config.env
```text

**Minimum configuration needed:**

```bash
# Add your Telegram bot tokens (get from @BotFather)
TELEGRAM_ASSISTANT_BOT_TOKEN=your_token_here
TELEGRAM_RESEARCH_BOT_TOKEN=your_token_here
TELEGRAM_DEVELOPER_BOT_TOKEN=your_token_here

# Choose your models
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
```text

### Step 3: Start the Container

```bash
# Build and start
docker compose up -d

# View logs
docker compose logs -f
```text

### Step 4: Test the Bots

1. Open Telegram
2. Search for your bot usernames (e.g., `@openclaw_assistant_bot`)
3. Send `/start` to each bot
4. Verify they respond

---

## Method 2: Bare Metal Installation

### Step 1: Clone and Prepare

```bash
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
chmod +x *.sh
```text

### Step 2: Run the Installer

```bash
./oc-bootstrap.sh
```text

The interactive installer will:
1. Detect your system configuration
2. Install dependencies (Node.js, Python, etc.)
3. Configure OpenClaw Gateway
4. Set up the three agents
5. Guide you through Telegram bot setup

### Step 3: Start OpenClaw

```bash
# Start the gateway
openclaw gateway start

# Verify it's running
openclaw status
```text

---

## Verification

### Check Services are Running

**Docker:**

```bash
docker compose ps
# Should show "oc-bootstrap" as "Up"
```text

**Bare Metal:**

```bash
openclaw status
# Should show all agents as "Running"
```text

### Test Agent Responses

Send these test messages in Telegram:

**To Assistant Bot:**
```text
Hello! Can you tell me what you can do?
```text

**To Research Bot:**
```text
Research the latest news about AI agents.
```text

**To Developer Bot:**
```text
Write a simple Python script to list files in a directory.
```text

### Check Logs

**Docker:**

```bash
docker compose logs -f openclaw
```text

**Bare Metal:**

```bash
tail -f ~/.openclaw/logs/gateway.log
```text

---

## Common Quick Start Issues

### Issue: "Bot token invalid"

**Solution:**
1. Verify tokens with BotFather (`/mybots` command)
2. Ensure no extra spaces in `docker-config.env`
3. Restart containers: `docker compose restart`

### Issue: "Node.js version not supported"

**Solution:**
```bash
# Install Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Should be v22.x
```text

### Issue: Docker compose not found

**Solution:**
```bash
# Install Docker Compose V2
sudo apt update
sudo apt install -y docker-compose-plugin
docker compose version
```text

---

## Next Steps

Now that you have OpenClaw running, explore these topics:

1. **[Agent Configuration](Agent-Configuration)** - Customize agent personalities
2. **[Lemonade Configuration](Lemonade-Configuration)** - Set up local LLM inference
3. **[Chat Channel Isolation](Chat-Channel-Isolation)** - Organize Telegram channels
4. **[Linux Server Configuration](Linux-Server-Configuration)** - Optimize your server

### Quick Customization

**Change Agent Personality:**

```bash
nano assistant/SOUL.md
# Edit the persona, then restart
docker compose restart
```text

**Switch to Local Inference:**

```bash
# Install Lemonade Server
./scripts/install-lemonade.sh

# Update docker-config.env
LOCAL_INFERENCE=true
ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF

# Restart
docker compose up -d --force-recreate
```text

---

## Video Tutorial (Coming Soon)

We're working on a video walkthrough. In the meantime, check:
- [Main README](../README.md) for detailed documentation
- [Docker Guide](Docker-Deployment) for container-specific info
- [Troubleshooting](Troubleshooting) for common issues

---

## Quick Reference

### Essential Commands (Docker)

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart a service
docker compose restart openclaw

# Update to latest version
git pull && docker compose up -d --build
```text

### Essential Commands (Bare Metal)

```bash
# Start OpenClaw
openclaw gateway start

# Stop OpenClaw
openclaw gateway stop

# Check status
openclaw status

# View logs
openclaw logs

# Update
git pull && ./oc-bootstrap.sh --update
```text

---

## Getting Help

- **Wiki**: Browse other [wiki pages](Home) for detailed guides
- **Issues**: Report problems on [GitHub Issues](https://github.com/openclaw/oc-bootstrap/issues)
- **Discussions**: Join the conversation on [GitHub Discussions](https://github.com/openclaw/oc-bootstrap/discussions)

---

*Last updated: April 2026*
