# Installation Guide

Complete guide to installing OpenClaw.

## Prerequisites

- Linux/macOS/WSL2
- 8GB+ RAM
- 20GB+ disk space
- Internet connection

## Method 1: Docker (Recommended)

```bash
# Clone repository
git clone https://github.com/lewismatt/oc-bootstrap.git
cd oc-bootstrap

# Configure
cp docker-config.env.template docker-config.env
# Edit docker-config.env

# Start services
docker-compose up -d
```

## Method 2: Bare Metal

```bash
# Clone repository
git clone https://github.com/lewismatt/oc-bootstrap.git
cd oc-bootstrap

# Run installer
chmod +x oc-bootstrap.sh
./oc-bootstrap.sh --install

# Start services
./oc-bootstrap.sh --start
```

## Post-Installation

1. **Verify Ollama**: `curl http://localhost:11434/api/tags`
2. **Check OpenClaw**: `curl http://localhost:8080/health`
3. **View Logs**: `tail -f /var/log/openclaw/openclaw.log`

## Next Steps

- [Quick Start](Quick-Start.md)
- [Configuration](Agent-Configuration.md)
- [Troubleshooting](Troubleshooting.md)
