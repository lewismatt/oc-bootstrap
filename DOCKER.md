# OpenClaw Docker Documentation

Complete guide to running OpenClaw Multi-Agent system in Docker containers.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Building the Image](#building-the-image)
4. [Configuration](#configuration)
5. [Running with Docker Compose](#running-with-docker-compose)
6. [Running with Docker CLI](#running-with-docker-cli)
7. [Volume Persistence](#volume-persistence)
8. [Local Inference with Lemonade Server](#local-inference-with-lemonade-server)
9. [Development Mode](#development-mode)
10. [Troubleshooting](#troubleshooting)
11. [Advanced Topics](#advanced-topics)

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap

# Create and configure environment file
cp docker-config.env.template docker-config.env
# Edit docker-config.env and add your Telegram bot tokens

# Build and start the container
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```text

---

## Prerequisites

- **Docker**: Version 20.10+ installed and running
- **Docker Compose**: Version 2.x (V2) installed
- **Telegram Bot Tokens**: Create three bots via [@BotFather](https://t.me/BotFather)
- **API Keys** (optional): OpenAI, Anthropic, Brave Search, GitHub PAT, etc.

### Installing Docker (Ubuntu 24.04)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose V2 (usually included with modern Docker installations)
# If needed: sudo apt install -y docker-compose-plugin
```text

---

## Building the Image

### Build with Docker Compose (Recommended)

```bash
docker compose build
```text

### Build with Docker CLI

```bash
docker build -t oc-bootstrap:latest .
```text

### Build Arguments (Optional)

Currently, the Dockerfile uses Node.js 22.x by default. To customize:

```bash
docker build \
  --build-arg NODE_VERSION=22 \
  -t oc-bootstrap:custom .
```text

---

## Configuration

### 1. Create Environment File

```bash
cp docker-config.env.template docker-config.env
```text

### 2. Edit `docker-config.env`

**Required Settings:**

```env
# Telegram Bot Tokens (REQUIRED - get from @BotFather)
ASSISTANT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
RESEARCH_TOKEN=987654321:ZYXwvuTSRqponMLKjihGFEdcba
DEVELOPER_TOKEN=1122334455:AAbbCCDDdeEfFGGhhIIjJKklLMmNOopP

# Model Selection
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
EMBEDDING_MODEL=openai/text-embedding-3-small
```text

**Optional Settings:**

```env
# API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
BRAVE_API_KEY=BSA...
GITHUB_PAT=ghp_...

# Local Inference (Lemonade Server)
LOCAL_INFERENCE=false
LEMONADE_KEY=local-dummy-key
# LEMONADE_IP=192.168.12.50
```text

---

## Running with Docker Compose

### Start Services

```bash
# Start in background
docker compose up -d

# Start with build (first time or after changes)
docker compose up -d --build

# Start with local inference (uncomment lemonade service first)
docker compose up -d --profile lemonade
```text

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f openclaw

# Last 50 lines
docker compose logs --tail=50 openclaw
```text

### Stop Services

```bash
# Stop and remove containers
docker compose down

# Stop and remove containers + volumes (DESTRUCTIVE)
docker compose down -v

# Stop and remove everything (containers, volumes, images)
docker compose down -v --rmi all
```text

### Check Status

```bash
docker compose ps
```text

---

## Running with Docker CLI

### Basic Run

```bash
docker run -d \
  --name oc-bootstrap \
  -v openclaw-data:/home/openclaw/.openclaw \
  -e ASSISTANT_TOKEN=your_token \
  -e RESEARCH_TOKEN=your_token \
  -e DEVELOPER_TOKEN=your_token \
  oc-bootstrap:latest
```text

### Run with Environment File

```bash
docker run -d \
  --name oc-bootstrap \
  --env-file docker-config.env \
  -v openclaw-data:/home/openclaw/.openclaw \
  oc-bootstrap:latest
```text

### Interactive Shell (Debugging)

```bash
docker run -it --rm \
  --env-file docker-config.env \
  oc-bootstrap:latest \
  shell
```text

### Run Bootstrap Script

```bash
docker run -it --rm \
  --env-file docker-config.env \
  -v $(pwd):/home/openclaw/oc-bootstrap:ro \
  oc-bootstrap:latest \
  bootstrap
```text

---

## Volume Persistence

OpenClaw data persists in Docker volumes:

| Volume | Host Location | Container Location | Purpose |
|--------|---------------|-------------------|---------|
| `openclaw-data` | Docker managed | `/home/openclaw/.openclaw` | Config, memory, workspaces |

### List Volumes

```bash
docker volume ls | grep openclaw
```text

### Inspect Volume

```bash
docker volume inspect oc-bootstrap_openclaw-data
```text

### Backup Volume

```bash
docker run --rm \
  -v openclaw-data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/openclaw-backup.tar.gz -C /data .
```text

### Restore Volume

```bash
docker run --rm \
  -v openclaw-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/openclaw-backup.tar.gz -C /data
```text

---

## Local Inference with Lemonade Server

Lemonade Server provides local LLM inference (no cloud APIs needed).

### Enable Lemonade Service

1. Edit `docker-compose.yml`
2. Uncomment the `lemonade` service section
3. Uncomment the `lemonade-data` volume at the bottom
4. Set `LOCAL_INFERENCE=true` in `docker-config.env`
5. Configure `LEMONADE_IP` if running separately

### Start with Lemonade

```bash
docker-compose up -d
```text

### Lemonade Configuration

```env
LOCAL_INFERENCE=true
LEMONADE_KEY=local-dummy-key
LEMONADE_IP=lemonade  # Service name in docker-compose.yml
```text

---

## Development Mode

Mount the local repository inside the container for testing changes:

```bash
docker run -it --rm \
  --env-file docker-config.env \
  -v $(pwd):/home/openclaw/oc-bootstrap \
  -v openclaw-data:/home/openclaw/.openclaw \
  oc-bootstrap:latest \
  shell
```text

### Hot-Reload Development

```bash
# Terminal 1: Start container with mounted code
docker run -it --rm \
  --env-file docker-config.env \
  -v $(pwd):/home/openclaw/oc-bootstrap \
  -v openclaw-data:/home/openclaw/.openclaw \
  oc-bootstrap:latest \
  shell

# Terminal 2: Edit files on host, test in container
vim oc-bootstrap.sh
```text

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs openclaw

# Inspect container
docker inspect oc-bootstrap

# Check OpenClaw health
docker exec oc-bootstrap openclaw doctor
```text

### Telegram Bots Not Connecting

1. Verify tokens in `docker-config.env`
2. Check bot status with [@BotFather](https://t.me/BotFather)
3. Ensure containers can reach `api.telegram.org`:
   ```bash
   docker exec oc-bootstrap curl -I https://api.telegram.org
   ```

### Volume Permission Issues

```bash
# Fix permissions
docker exec oc-bootstrap sudo chown -R openclaw:openclaw /home/openclaw/.openclaw
```text

### OpenClaw CLI Not Found

```bash
# Rebuild image
docker compose build --no-cache

# Check installation
docker exec oc-bootstrap which openclaw
```text

### Memory/Performance Issues

Adjust resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```text

---

## Advanced Topics

### Custom Network Configuration

```yaml
networks:
  openclaw-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```text

### Using External Secrets Management

Instead of env file, use Docker secrets or external tools:

```bash
# With pass (password manager)
docker run -d \
  --name oc-bootstrap \
  -e ASSISTANT_TOKEN=$(pass show telegram/assistant) \
  oc-bootstrap:latest
```text

### Multi-Architecture Builds

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t oc-bootstrap:multi-arch \
  --push .
```text

### Health Checks

The container includes a health check:

```bash
# View health status
docker inspect --format='{{json .State.Health}}' oc-bootstrap | jq

# Wait for healthy
docker wait-for-it oc-bootstrap:3000 -t 60
```text

---

## Cleanup

Use the provided cleanup script:

```bash
# Stop containers (keep volumes)
./scripts/docker-cleanup.sh

# Stop containers and remove volumes (DESTRUCTIVE)
./scripts/docker-cleanup.sh --prune

# Full cleanup (containers, volumes, images)
./scripts/docker-cleanup.sh --all
```text

Or use Docker Compose:

```bash
docker-compose down -v --rmi all
```text

---

## Support

- **Documentation**: See [README.md](../README.md)
- **Issues**: Report bugs via GitHub Issues
- **OpenClaw**: Visit [openclaw.ai](https://openclaw.ai)
