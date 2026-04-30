# Docker Deployment

Complete guide to running OpenClaw Multi-Agent system using Docker containers. Docker deployment provides isolation, easy updates, and consistent environments.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Building the Image](#building-the-image)
6. [Running with Docker Compose](#running-with-docker-compose)
7. [Volume Persistence](#volume-persistence)
8. [Development Mode](#development-mode)
9. [Docker Commands Reference](#docker-commands-reference)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### Why Docker?

| Benefit | Description |
|---------|-------------|
| **Isolation** | Each component runs in its own container |
| **Portability** | Runs the same on any system with Docker |
| **Easy Updates** | Pull new image, restart container |
| **Resource Control** | Limit CPU, memory per container |
| **Rollback** | Keep previous images for quick rollback |

### Architecture

```
┌─────────────────────────────────────────────────┐
│              Docker Host                         │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │         oc-bootstrap container           │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐  │   │
│  │  │Assistant│ │Research │ │Developer│  │   │
│  │  │  Agent  │ │  Agent  │ │  Agent  │  │   │
│  │  └─────────┘ └─────────┘ └─────────┘  │   │
│  │          OpenClaw Gateway               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │      lemonade-server container           │   │
│  │      (Optional - for local inference)   │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Prerequisites

### Install Docker

```bash
# Automated install script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Verify Docker is Running

```bash
# Check Docker service
sudo systemctl status docker

# Test with hello-world
docker run hello-world
```

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap
```

### 2. Configure Environment

```bash
# Copy template
cp docker-config.env.template docker-config.env

# Edit configuration
nano docker-config.env
```

**Minimum configuration:**

```bash
# Telegram bot tokens
TELEGRAM_ASSISTANT_BOT_TOKEN=your_token_here
TELEGRAM_RESEARCH_BOT_TOKEN=your_token_here
TELEGRAM_DEVELOPER_BOT_TOKEN=your_token_here

# Model selection
ASSISTANT_MODEL=openai/gpt-4o
EMBEDDING_MODEL=openai/text-embedding-3-small
```

### 3. Start Services

```bash
docker compose up -d
```

### 4. Verify

```bash
docker compose ps
docker compose logs -f
```

---

## Configuration

### Environment Variables

Complete list of configuration options in `docker-config.env`:

#### Core Settings

```bash
# Run bootstrap on container start
RUN_BOOTSTRAP=false

# Config file path
# CONFIG_FILE=/home/openclaw/oc-bootstrap/.env

# Environment
NODE_ENV=production
OPENCLAW_HOME=/home/openclaw/.openclaw
NON_INTERACTIVE=true
```

#### Inference Backend

```bash
# Use local inference (Lemonade Server)
LOCAL_INFERENCE=false

# Lemonade API Key
LEMONADE_KEY=local-dummy-key

# Lemonade Server IP (if external)
# LEMONADE_IP=192.168.12.50
```

#### Model Selection

```bash
# Embedding model
EMBEDDING_MODEL=openai/text-embedding-3-small

# Agent models
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
```

#### API Keys

```bash
# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Brave Search (for Research agent)
BRAVE_SEARCH_API_KEY=...

# GitHub (for Developer agent)
GITHUB_PAT=ghp_...
```

---

## Building the Image

### Build with Docker Compose (Recommended)

```bash
docker compose build
```

### Build with Docker CLI

```bash
docker build -t oc-bootstrap:latest .
```

### Build Arguments

Customize the build with arguments:

```bash
docker build \
  --build-arg NODE_VERSION=22 \
  --build-arg USER_HOME=/home/openclaw \
  -t oc-bootstrap:custom .
```

### Multi-Architecture Build

```bash
# Install buildx
docker buildx create --use

# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t oc-bootstrap:latest \
  --push .
```

---

## Running with Docker Compose

### Start All Services

```bash
docker compose up -d
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f openclaw

# Last 50 lines
docker compose logs --tail=50 openclaw
```

### Stop Services

```bash
docker compose down
```

### Restart Services

```bash
docker compose restart
```

### Update and Restart

```bash
git pull
docker compose up -d --force-recreate --build
```

---

## Volume Persistence

### Named Volumes (Recommended)

The `docker-compose.yml` uses named volumes for persistence:

```yaml
volumes:
  openclaw-data:
    driver: local
```

Data is stored in:
- **OpenClaw config**: `/var/lib/docker/volumes/oc-bootstrap_openclaw-data/_data`

### Bind Mounts (Development)

For development, mount the host directory:

```yaml
services:
  openclaw:
    volumes:
      - ./:/home/openclaw/oc-bootstrap:ro
      - openclaw-data:/home/openclaw/.openclaw
```

### Backup Volumes

```bash
# Create backup
docker run --rm -v oc-bootstrap_openclaw-data:/data \
  -v $(pwd):/backup ubuntu \
  tar czf /backup/openclaw-backup.tar.gz /data

# Restore backup
docker run --rm -v oc-bootstrap_openclaw-data:/data \
  -v $(pwd):/backup ubuntu \
  tar xzf /backup/openclaw-backup.tar.gz -C /
```

---

## Development Mode

### Running with Live Code Reload

Mount the source code and use development flags:

```yaml
# In docker-compose.yml
services:
  openclaw:
    volumes:
      - ./:/home/openclaw/oc-bootstrap:rw
    environment:
      - NODE_ENV=development
      - OPENCLAW_DEV_MODE=true
    command: npm run dev
```

### Debugging

```bash
# Access container shell
docker compose exec openclaw bash

# Run commands inside container
docker compose exec openclaw openclaw --version

# View process list
docker compose exec openclaw ps aux
```

---

## Docker Commands Reference

### Container Management

```bash
# List running containers
docker compose ps

# Start specific service
docker compose up -d openclaw

# Stop specific service
docker compose stop openclaw

# Restart with fresh container
docker compose up -d --force-recreate openclaw

# Remove containers
docker compose down
```

### Image Management

```bash
# List images
docker images | grep oc-bootstrap

# Remove old images
docker image prune -a

# Tag image
docker tag oc-bootstrap:latest oc-bootstrap:v1.0

# Push to registry
docker tag oc-bootstrap:latest myregistry.com/oc-bootstrap:latest
docker push myregistry.com/oc-bootstrap:latest
```

### Network Inspection

```bash
# List networks
docker network ls

# Inspect network
docker network inspect oc-bootstrap_openclaw-network

# Connect container to network
docker network connect oc-bootstrap_openclaw-network container_name
```

---

## Resource Limits

### Configure in docker-compose.yml

```yaml
services:
  openclaw:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

### Apply Limits

```bash
docker compose up -d --force-recreate
```

---

## Lemonade Server Integration

### Enable Lemonade in Docker

Uncomment the Lemonade service in `docker-compose.yml`:

```yaml
services:
  lemonade:
    image: python:3.11-slim
    container_name: lemonade-server
    restart: unless-stopped
    environment:
      - MODEL_PATH=/models
    volumes:
      - ./models:/models:ro
      - lemonade-data:/data
    ports:
      - "8000:8000"
    command: >
      bash -c "pip install lemonade-server && 
               python -m lemonade serve --host 0.0.0.0"
    networks:
      - openclaw-network
```

### Configure OpenClaw to Use Lemonade

In `docker-config.env`:

```bash
LOCAL_INFERENCE=true
LEMONADE_KEY=local-dummy-key
ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF
```

---

## Troubleshooting

### Container Fails to Start

```bash
# Check logs
docker compose logs openclaw

# Inspect container
docker inspect oc-bootstrap

# Check resource usage
docker stats
```

### Permission Denied Errors

```bash
# Fix volume permissions
sudo chown -R 1000:1000 /var/lib/docker/volumes/oc-bootstrap_openclaw-data/_data

# Or run container as root (not recommended for production)
# In docker-compose.yml, add:
# user: root
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :3000

# Change port in docker-compose.yml
ports:
  - "3001:3000"
```

### Out of Disk Space

```bash
# Clean up Docker
docker system df
docker system prune -a --volumes
```

### Network Connectivity Issues

```bash
# Test from inside container
docker compose exec openclaw ping -c 3 8.8.8.8

# Check DNS
docker compose exec openclaw nslookup github.com

# Restart Docker network
docker compose down
docker network prune
docker compose up -d
```

---

## Best Practices

1. **Use .dockerignore**: Exclude unnecessary files from build context
2. **Pin Versions**: Use specific image tags, not `latest`
3. **Secrets Management**: Use Docker secrets or external secret stores
4. **Health Checks**: Implement health checks for all services
5. **Log Rotation**: Configure log limits in `docker-compose.yml`
6. **Regular Updates**: Periodically update base images
7. **Monitor Resources**: Use `docker stats` to monitor container resource usage

---

## Next Steps

- Configure **[Agent Configuration](Agent-Configuration)** for your agents
- Set up **[Lemonade Configuration](Lemonade-Configuration)** for local inference
- Review **[Troubleshooting](Troubleshooting)** for common issues
- Explore **[Chat Channel Isolation](Chat-Channel-Isolation)** for Telegram setup

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [OpenClaw DOCKER.md](../DOCKER.md)
- [Bare Metal Installation](Bare-Metal-Installation)

---

*Last updated: April 2026*
