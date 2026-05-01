# Linux Server Configuration

Configure your Linux server for OpenClaw deployment.

## System Requirements

- **OS**: Ubuntu 24.04 LTS (recommended)
- **RAM**: 8GB minimum, 16GB recommended
- **CPU**: 4 cores minimum
- **Disk**: 20GB minimum, SSD preferred
- **Network**: Stable internet connection

## Initial Setup

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Prerequisites
```bash
sudo apt install -y \
    curl \
    wget \
    git \
    jq \
    vim \
    htop
```

### Configure Firewall
```bash
sudo ufw enable
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 8080/tcp # OpenClaw
sudo ufw allow 11434/tcp # Ollama
```

## User Setup

### Create OpenClaw User
```bash
sudo useradd -m -s /bin/bash openclaw
sudo usermod -aG docker openclaw
```

### Configure Sudo (Optional)
```bash
echo "openclaw ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/openclaw
```

## Docker Installation

### Install Docker
```bash
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
chmod +x /tmp/get-docker.sh
/tmp/get-docker.sh
rm /tmp/get-docker.sh
```

### Enable Docker Service
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

## Security

- Keep system updated
- Use SSH keys instead of passwords
- Configure fail2ban
- Regular security audits
