# Troubleshooting

Comprehensive guide to diagnosing and resolving common issues with OpenClaw Multi-Agent system.

---

## 📋 Table of Contents

1. [Diagnostic Commands](#diagnostic-commands)
2. [Installation Issues](#installation-issues)
3. [Docker Issues](#docker-issues)
4. [Agent Issues](#agent-issues)
5. [Telegram Bot Issues](#telegram-bot-issues)
6. [Model/API Issues](#modelapi-issues)
7. [Lemonade Server Issues](#lemonade-server-issues)
8. [Network Issues](#network-issues)
9. [Performance Issues](#performance-issues)
10. [Getting Help](#getting-help)

---

## Diagnostic Commands

### Quick Health Check

Run these commands to quickly assess system health:

```bash
# Check OpenClaw status
openclaw status  # or: docker compose ps

# View recent logs
openclaw logs --tail 50  # or: docker compose logs --tail=50

# Check system resources
free -h   # Memory
df -h     # Disk space
nproc     # CPU cores
```text

### Log Locations

| Component | Docker Location | Bare Metal Location |
|-----------|-----------------|---------------------|
| Gateway | `docker compose logs openclaw` | `~/.openclaw/logs/gateway.log` |
| Assistant | Container logs | `~/.openclaw/agents/assistant/logs/` |
| Research | Container logs | `~/.openclaw/agents/research/logs/` |
| Developer | Container logs | `~/.openclaw/agents/developer/logs/` |

### Enable Debug Logging

**Docker:**

```bash
# Add to docker-config.env
LOG_LEVEL=debug

# Restart
docker compose restart openclaw
```text

**Bare Metal:**

```bash
export LOG_LEVEL=debug
openclaw gateway restart
```text

---

## Installation Issues

### Issue: "Node.js version not supported"

**Symptoms:**
```text
Error: OpenClaw requires Node.js 22.x or higher
```text

**Solution:**

```bash
# Check current version
node --version

# Install Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version  # Should be v22.x
```text

### Issue: "Permission denied" during installation

**Symptoms:**
```text
Error: EACCES: permission denied, mkdir '/home/openclaw'
```text

**Solution:**

```bash
# Option 1: Run with sudo (not recommended for production)
sudo ./oc-bootstrap.sh

# Option 2: Fix permissions (recommended)
sudo useradd -m -s /bin/bash openclaw
sudo chown -R openclaw:openclaw /path/to/oc-bootstrap
su - openclaw
./oc-bootstrap.sh
```text

### Issue: "Git clone fails"

**Symptoms:**
```text
fatal: unable to access 'https://github.com/...': Failed to connect
```text

**Solution:**

```bash
# Check internet connectivity
ping -c 3 github.com

# Check proxy settings (if applicable)
echo $http_proxy
echo $https_proxy

# Try with SSH instead
git clone git@github.com:openclaw/oc-bootstrap.git
```text

---

## Docker Issues

### Issue: "docker: command not found"

**Solution:**

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```text

### Issue: "docker compose not found"

**Solution:**

```bash
# Install docker-compose-plugin
sudo apt update
sudo apt install -y docker-compose-plugin

# Verify
docker compose version
```text

### Issue: Container keeps restarting

**Diagnosis:**

```bash
# Check logs
docker compose logs openclaw

# Check container status
docker inspect oc-bootstrap | grep -A 10 "State"
```text

**Common Causes:**
1. Invalid environment variables
2. Missing bot tokens
3. Port conflicts

**Solution:**

```bash
# Verify docker-config.env
cat docker-config.env | grep -v "^#" | grep -v "^$"

# Check for port conflicts
sudo lsof -i :3000

# Fix and restart
nano docker-config.env
docker compose up -d --force-recreate
```text

### Issue: "No space left on device"

**Solution:**

```bash
# Clean up Docker
docker system df
docker system prune -a --volumes

# Check disk space
df -h

# Remove old images
docker images | grep "none" | awk '{print $3}' | xargs docker rmi
```text

---

## Agent Issues

### Issue: Agent not responding in Telegram

**Diagnosis:**

```bash
# Check if agent is running
docker compose logs openclaw | grep -i "assistant"

# Check Telegram connection
docker compose logs openclaw | grep -i "telegram\|bot"
```text

**Solution:**

1. Verify bot tokens in `docker-config.env`
2. Check bot is not blocked in Telegram
3. Send `/start` to the bot
4. Restart the service: `docker compose restart openclaw`

### Issue: Agent using wrong model

**Diagnosis:**

```bash
# Check environment variables
docker compose exec openclaw env | grep MODEL
```text

**Solution:**

```bash
# Update docker-config.env
ASSISTANT_MODEL=correct_model_name

# Restart
docker compose up -d --force-recreate
```text

### Issue: Agent memory not persisting

**Diagnosis:**

```bash
# Check volume mounts (Docker)
docker inspect oc-bootstrap | grep -A 5 "Mounts"

# Check directory permissions (Bare Metal)
ls -la ~/.openclaw/agents/
```text

**Solution:**

```bash
# Docker: Ensure volume is mounted
# In docker-compose.yml, verify:
volumes:
  - openclaw-data:/home/openclaw/.openclaw

# Bare Metal: Fix permissions
chmod -R u+w ~/.openclaw/agents/
```text

---

## Telegram Bot Issues

### Issue: "Bot token invalid"

**Symptoms:**
```text
Error: 401 Unauthorized - Invalid bot token
```text

**Solution:**

1. Open Telegram, message `@BotFather`
2. Send `/mybots`
3. Select your bot → API Token
4. Copy the new token
5. Update `docker-config.env`:
   ```bash
   ASSISTANT_TOKEN=new_token_here
   ```
6. Restart: `docker compose restart openclaw`

### Issue: Bot not receiving messages

**Diagnosis:**

```bash
# Check if bot is initialized
docker compose logs openclaw | grep "bot initialized"

# Test bot token manually
curl "https://api.Telegram.org/bot<YOUR_TOKEN>/getMe"
```text

**Solution:**

1. Ensure you sent `/start` to the bot
2. Check bot privacy settings in BotFather (`/setprivacy` → Disable)
3. Verify bot is not in privacy mode for groups
4. Restart the bot service

### Issue: "Chat not found" error

**Solution:**

```bash
# Verify channel ID format (should start with -100 for channels)
ASSISTANT_CHANNEL_ID=-1001234567890

# Get correct channel ID:
# 1. Add bot to channel as admin
# 2. Send a message in channel
# 3. Check logs: docker compose logs openclaw | grep "chat_id"
```text

---

## Model/API Issues

### Issue: "OpenAI API error: Invalid API Key"

**Solution:**

```bash
# Verify API key
echo $OPENAI_API_KEY

# Test API key manually
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Update if needed in docker-config.env
OPENAI_API_KEY=sk-new_key_here

# Restart
docker compose restart openclaw
```text

### Issue: "Rate limit exceeded"

**Solution:**

```bash
# Wait and retry (exponential backoff is automatic)
# Or switch to different model/provider

# In docker-config.env, change model:
ASSISTANT_MODEL=anthropic/claude-3-5-sonnet-latest

# Add rate limit settings
export RATE_LIMIT_PER_MINUTE=10
```text

### Issue: "Model not found" error

**Solution:**

```bash
# Verify model name format
# Correct format: provider/model-name
ASSISTANT_MODEL=openai/gpt-4o  # ✓ Correct
ASSISTANT_MODEL=gpt-4o          # ✗ Wrong

# List available models (OpenAI example)
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```text

---

## Lemonade Server Issues

### Issue: "Connection refused" to Lemonade Server

**Diagnosis:**

```bash
# Check if Lemonade is running
docker compose ps lemonade
docker compose logs lemonade

# Test connection
curl http://localhost:8000/v1/models
```text

**Solution:**

```bash
# Start Lemonade service
docker compose up -d lemonade

# Verify in docker-config.env
LOCAL_INFERENCE=true
LEMONADE_KEY=local-dummy-key

# Restart OpenClaw
docker compose restart openclaw
```text

### Issue: "CUDA out of memory"

**Solution:**

```bash
# Use smaller model
# In docker-config.env:
ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF  # Smaller model

# Or reduce GPU layers in Lemonade config
# Edit ~/lemonade-server/config.yaml:
# gpu_layers: 20  # Reduce from 32
```text

### Issue: Slow inference speed

**Solutions:**

1. Ensure GPU is being used:
   ```bash
   # NVIDIA
   docker compose exec lemonade nvidia-smi
   
   # AMD
   docker compose exec lemonade rocm-smi
   ```

2. Use quantized models (Q4_K_M instead of Q8_0)

3. Increase batch size in Lemonade config

---

## Network Issues

### Issue: "Could not resolve host"

**Solution:**

```bash
# Check DNS
nslookup github.com

# Try different DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# For Docker, configure DNS in daemon.json:
sudo nano /etc/docker/daemon.json
# Add: { "dns": ["8.8.8.8", "1.1.1.1"] }
sudo systemctl restart docker
```text

### Issue: Firewall blocking connections

**Solution:**

```bash
# Check firewall status
sudo ufw status

# Allow necessary ports
sudo ufw allow 3000/tcp  # OpenClaw Gateway
sudo ufw allow 8000/tcp  # Lemonade Server (if needed externally)
sudo ufw allow 22/tcp    # SSH

# For Docker, ensure Docker network is not blocked
```text

---

## Performance Issues

### Issue: High memory usage

**Diagnosis:**

```bash
# Check memory usage
free -h
docker stats
```text

**Solutions:**

1. Limit container memory in `docker-compose.yml`:
   ```yaml
   services:
     openclaw:
       deploy:
         resources:
           limits:
             memory: 8G
   ```

2. Reduce agent concurrency

3. Use smaller models

4. Enable swap (temporary solution):
   ```bash
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

### Issue: High CPU usage

**Solutions:**

1. Limit CPU in `docker-compose.yml`:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '4'
   ```

2. Reduce polling frequency

3. Use hardware acceleration (GPU) for inference

---

## Getting Help

### 1. Check Logs First

Always start with logs:

```bash
# Docker
docker compose logs --tail=100 openclaw > debug.log

# Bare Metal
tail -n 100 ~/.openclaw/logs/gateway.log > debug.log
```text

### 2. Search Existing Issues

- [GitHub Issues](https://github.com/openclaw/oc-bootstrap/issues)
- [GitHub Discussions](https://github.com/openclaw/oc-bootstrap/discussions)
- [Wiki Troubleshooting](Troubleshooting) (this page)

### 3. Create a New Issue

When creating an issue, include:

```markdown
**Environment:**
- OS: Ubuntu 24.04
- OpenClaw Version: [from `openclaw --version`]
- Deployment: Docker/Bare Metal
- Hardware: [CPU/RAM/GPU]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**

**Actual Behavior:**

**Logs:**
```text
[paste relevant log excerpts]
```text

**Screenshots:**
[if applicable]
```text

### 4. Community Support

- Join [GitHub Discussions](https://github.com/openclaw/oc-bootstrap/discussions)
- Check [README.md](../README.md) for documentation
- Review other [Wiki pages](Home) for guides

---

## Quick Fixes Checklist

Before diving deep, try these quick fixes:

- [ ] Restart the service: `docker compose restart` or `openclaw gateway restart`
- [ ] Pull latest changes: `git pull`
- [ ] Rebuild containers: `docker compose up -d --force-recreate --build`
- [ ] Check bot tokens in `docker-config.env`
- [ ] Verify API keys are valid
- [ ] Ensure internet connectivity
- [ ] Check disk space: `df -h`
- [ ] Check memory: `free -h`
- [ ] View logs: `docker compose logs -f`

---

*Last updated: April 2026*
