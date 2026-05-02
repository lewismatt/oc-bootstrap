# Bare Metal Installation

Complete guide to installing OpenClaw Multi-Agent system directly on Ubuntu 24.04 (without Docker). Bare metal installation provides maximum performance and full system access.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation Steps](#installation-steps)
4. [Post-Installation Setup](#post-installation-setup)
5. [Running OpenClaw](#running-openclaw)
6. [Updating](#updating)
7. [Uninstallation](#uninstallation)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### When to Choose Bare Metal

| Choose Bare Metal If... | Choose Docker If... |
|------------------------|---------------------|
| You want maximum performance | You want easy deployment |
| You need full system access | You want isolation |
| Single-user setup | Multi-user setup |
| Direct GPU access needed | Easy scaling needed |
| Custom system modifications | Consistent environments |

### Installation Methods

1. **Interactive Installer** (Recommended) - `oc-bootstrap.sh`
2. **Manual Installation** - Step-by-step manual setup

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|----------|-------------|
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |
| CPU | 4 cores | 8+ cores |
| RAM | 8GB | 32GB |
| Storage | 20GB free | 100GB+ SSD |
| GPU | Optional | 12GB+ VRAM (for local inference) |

### Verify Prerequisites

```bash
# Check OS version
lsb_release -a

# Check CPU cores
nproc

# Check RAM
free -h

# Check disk space
df -h

# Check for GPU (optional)
lspci | grep -i vga
nvidia-smi 2>/dev/null || rocm-smi 2>/dev/null || echo "No GPU detected"
```text

---

## Installation Steps

### Method 1: Interactive Installer (Recommended)

#### Step 1: Clone Repository

```bash
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
```text

#### Step 2: Run Installer

```bash
chmod +x oc-bootstrap.sh
./oc-bootstrap.sh
```text

The installer will:
1. Detect system configuration
2. Install Node.js 22.x
3. Install Python 3 and pip
4. Install OpenClaw Gateway
5. Configure the three agents
6. Guide you through Telegram bot setup
7. Optionally install Lemonade Server

#### Step 3: Follow Interactive Prompts

The installer will ask:
- **Telegram bot tokens** - Create bots via @BotFather first
- **Model selection** - Choose cloud APIs or local inference
- **API keys** - OpenAI, Anthropic, etc. (if using cloud models)
- **Lemonade installation** - Yes/No for local inference

### Method 2: Manual Installation

#### Step 1: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
  curl \
  wget \
  git \
  python3 \
  python3-pip \
  python3-venv \
  build-essential \
  ca-certificates \
  gnupg \
  lsb-release
```text

#### Step 2: Install Node.js 22.x

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify
node --version  # Should be v22.x
npm --version
```text

#### Step 3: Create OpenClaw User (Recommended)

```bash
# Create dedicated user
sudo useradd -m -s /bin/bash openclaw
sudo usermod -aG sudo openclaw

# Switch to openclaw user
su - openclaw
```text

#### Step 4: Clone and Configure

```bash
# Clone repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
chmod +x *.sh

# Create configuration
cp .env.example .env  # If exists, otherwise create manually
nano .env
```text

#### Step 5: Configure Environment

Create `.env` file:

```bash
# Telegram Bot Tokens
ASSISTANT_TOKEN=your_token_here
RESEARCH_TOKEN=your_token_here
DEVELOPER_TOKEN=your_token_here

# Model Selection
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
EMBEDDING_MODEL=openai/text-embedding-3-small

# API Keys (if using cloud models)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Local Inference (optional)
LOCAL_INFERENCE=false
LEMONADE_KEY=local-dummy-key
```text

#### Step 6: Install OpenClaw

```bash
# Run installation
./oc-bootstrap.sh --non-interactive

# Or manually:
npm install -g openclaw
```text

---

## Post-Installation Setup

### Configure as Systemd Service

Create systemd service for auto-start:

```bash
sudo nano /etc/systemd/system/openclaw.service
```text

Add:

```ini
[Unit]
Description=OpenClaw Multi-Agent System
After=network.target

[Service]
Type=simple
User=openclaw
WorkingDirectory=/home/openclaw/oc-bootstrap
Environment="NODE_ENV=production"
Environment="OPENCLAW_HOME=/home/openclaw/.openclaw"
ExecStart=/usr/bin/openclaw gateway start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```text

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw
```text

### Configure Log Rotation

```bash
sudo nano /etc/logrotate.d/openclaw
```text

Add:

```text
/home/openclaw/.openclaw/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 openclaw openclaw
    postrotate
        systemctl reload openclaw
    endscript
}
```text

---

## Running OpenClaw

### Start OpenClaw

**Using Systemd (Recommended):**

```bash
sudo systemctl start openclaw
sudo systemctl status openclaw
```text

**Manual Start:**

```bash
# As openclaw user
su - openclaw
openclaw gateway start
```text

### Stop OpenClaw

```bash
# Systemd
sudo systemctl stop openclaw

# Manual
openclaw gateway stop
```text

### View Logs

```bash
# Systemd
sudo journalctl -u openclaw -f

# Manual
tail -f ~/.openclaw/logs/gateway.log
```text

### Check Status

```bash
openclaw status
```text

---

## Updating

### Update Using Script

```bash
cd /path/to/oc-bootstrap
git pull
./oc-bootstrap.sh --update

# Restart service
sudo systemctl restart openclaw
```text

### Manual Update

```bash
# Stop service
sudo systemctl stop openclaw

# Backup configuration
cp -r ~/.openclaw ~/.openclaw.backup

# Update repository
cd /path/to/oc-bootstrap
git pull

# Update OpenClaw
npm update -g openclaw

# Restart
sudo systemctl start openclaw
```text

---

## Uninstallation

### Using Uninstall Script

```bash
cd /path/to/oc-bootstrap
./scripts/uninstall-oc-bootstrap.sh
```text

### Manual Uninstallation

```bash
# Stop and disable service
sudo systemctl stop openclaw
sudo systemctl disable openclaw
sudo rm /etc/systemd/system/openclaw.service
sudo systemctl daemon-reload

# Remove OpenClaw
npm uninstall -g openclaw

# Remove user (optional)
sudo deluser --remove-home openclaw

# Remove repository
rm -rf /path/to/oc-bootstrap

# Remove configuration (optional - backup first!)
# rm -rf ~/.openclaw
```text

---

## Troubleshooting

### Issue: "Permission denied"

**Solution:**

```bash
# Ensure running as openclaw user (not root)
whoami  # Should be 'openclaw'

# Fix permissions
sudo chown -R openclaw:openclaw /home/openclaw/oc-bootstrap
sudo chown -R openclaw:openclaw /home/openclaw/.openclaw
```text

### Issue: "Port already in use"

**Solution:**

```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill process or change OpenClaw port
# In .env:
export OPENCLAW_PORT=3001
```text

### Issue: "Agent not responding"

**Solution:**

```bash
# Check service status
sudo systemctl status openclaw

# Check logs
sudo journalctl -u openclaw -n 50

# Verify bot tokens
grep TELEGRAM_ /home/openclaw/oc-bootstrap/.env

# Restart service
sudo systemctl restart openclaw
```text

### Issue: "Out of memory"

**Solution:**

```bash
# Check memory usage
free -h

# Add swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```text

---

## Performance Optimization

### Enable GPU Acceleration (NVIDIA)

```bash
# Install NVIDIA drivers
sudo apt install -y nvidia-driver-535

# Install CUDA
sudo apt install -y nvidia-cuda-toolkit

# Verify
nvidia-smi
```text

### Enable GPU Acceleration (AMD)

```bash
# Install ROCm
sudo apt update
sudo apt install -y rocm-hip-runtime rocm-opencl-runtime

# Add user to render group
sudo usermod -aG render $USER

# Verify
rocm-smi
```text

### Optimize for Local Inference

Edit `~/lemonade-server/config.yaml`:

```yaml
inference:
  threads: 8  # Match CPU core count
  batch_size: 512  # Adjust based on RAM
  gpu_layers: 32  # Adjust based on VRAM
```text

---

## Security Considerations

1. **Run as non-root user** - Use dedicated `openclaw` user
2. **Firewall** - Enable UFW and only open necessary ports
3. **API Keys** - Store securely, never commit to version control
4. **Updates** - Regularly update system and dependencies
5. **SSH** - Use key-based authentication, disable password login

---

## Next Steps

After installation:

1. Configure **[Agent Personas](Agent-Configuration)**
2. Set up **[Telegram Bots](Chat-Channel-Isolation)**
3. Optionally configure **[Lemonade Server](Lemonade-Configuration)** for local inference
4. Review **[Troubleshooting](Troubleshooting)** for common issues

---

## Additional Resources

- [Docker Deployment](Docker-Deployment) - Alternative installation method
- [Linux Server Configuration](Linux-Server-Configuration) - Server setup guide
- [Quick Start Guide](Quick-Start) - Get running quickly
- [Main README](../README.md) - Project documentation

---

*Last updated: April 2026*
