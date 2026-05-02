# Bare Metal Installation

Install OpenClaw directly on your server or local machine.

## Prerequisites

- Linux server (Ubuntu 24.04 recommended)
- 8GB+ RAM
- 20GB+ disk space
- Internet connection

## Installation Steps

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

### 3. Configure Environment

```bash
# Copy and edit configuration
cp docker-config.env.template docker-config.env
nano docker-config.env
```

### 4. Start Services

```bash
# Start Ollama
ollama serve &

# Pull default model
ollama pull llama3.2

# Start OpenClaw
./oc-bootstrap.sh --start
```

## Post-Installation

- Check services: `ps aux | grep -E 'ollama|openclaw'`
- View logs: `tail -f /var/log/openclaw/openclaw.log`
- Test API: `curl http://localhost:8080/health`

## Troubleshooting

See [Troubleshooting](Troubleshooting.md) for common issues.
