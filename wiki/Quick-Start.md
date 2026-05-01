# Quick Start

Get OpenClaw running in minutes.

## Prerequisites

- Docker installed
- 8GB+ RAM
- 20GB+ disk space
- Internet connection

## Docker Deployment (Recommended)

### 1. Clone Repository
```bash
git clone https://github.com/lewismatt/oc-bootstrap.git
cd oc-bootstrap
```

### 2. Configure Environment
```bash
cp docker-config.env.template docker-config.env
# Edit docker-config.env with your settings
nano docker-config.env
```

### 3. Start Services
```bash
docker-compose up -d
```

### 4. Verify Installation
```bash
# Check container status
docker-compose ps

# Test Ollama API
curl http://localhost:11434/api/tags

# Test OpenClaw
curl http://localhost:8080/health
```

## Bare Metal Installation

### 1. Clone Repository
```bash
git clone https://github.com/lewismatt/oc-bootstrap.git
cd oc-bootstrap
```

### 2. Run Installer
```bash
chmod +x oc-bootstrap.sh
./oc-bootstrap.sh --install
```

### 3. Start Services
```bash
# Start Ollama
ollama serve &

# Pull default model
ollama pull llama3.2

# Start OpenClaw
./oc-bootstrap.sh --start
```

## Next Steps

- [Configuration](Agent-Configuration.md)
- [Docker Deployment](Docker-Deployment.md)
- [Troubleshooting](Troubleshooting.md)
