# Linux Server Configuration

This guide covers the complete configuration of your Ubuntu 24.04 LTS server for running OpenClaw Multi-Agent system. Follow these steps to prepare your server environment.

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Initial Server Setup](#initial-server-setup)
3. [User Account Configuration](#user-account-configuration)
4. [Network Configuration](#network-configuration)
5. [Security Hardening](#security-hardening)
6. [Software Installation](#software-installation)
7. [Resource Limits](#resource-limits)
8. [Monitoring and Logging](#monitoring-and-logging)

---

## System Requirements

### Minimum Requirements

| Component | Specification |
|-----------|---------------|
| OS | Ubuntu 24.04 LTS (Noble Numbat) |
| CPU | 4 cores (x86_64) |
| RAM | 8GB |
| Storage | 20GB free space (SSD recommended) |
| Network | 1Gbps Ethernet (Internet access required) |

### Recommended Specifications

| Component | Specification |
|-----------|---------------|
| CPU | 8+ cores (Intel/AMD 64-bit) |
| RAM | 32GB |
| Storage | 100GB+ NVMe SSD |
| GPU | AMD Radeon or NVIDIA with 12GB+ VRAM |
| Network | 1Gbps+ with low latency |

---

## Initial Server Setup

### 1. System Update

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Remove unnecessary packages
sudo apt autoremove -y

# Reboot if kernel was updated
sudo reboot
```

### 2. Set Hostname

```bash
# Set a meaningful hostname
sudo hostnamectl set-hostname openclaw-server

# Verify
hostnamectl
```

### 3. Configure Timezone

```bash
# Set timezone (adjust to your location)
sudo timedatectl set-timezone America/New_York

# Enable NTP synchronization
sudo timedatectl set-ntp true

# Verify
timedatectl status
```

---

## User Account Configuration

### 1. Create Dedicated User (Recommended)

```bash
# Create user for running OpenClaw
sudo useradd -m -s /bin/bash openclaw

# Add to sudo group (optional, for initial setup)
sudo usermod -aG sudo openclaw

# Set password
sudo passwd openclaw
```

### 2. Configure SSH Access

```bash
# Switch to openclaw user
su - openclaw

# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key (paste your public key content)
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Exit back to original user
exit
```

### 3. Disable Root SSH Login (Security)

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Ensure these settings:
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

---

## Network Configuration

### 1. Static IP Configuration (Optional but Recommended)

Edit Netplan configuration:

```bash
# Find your netplan file
ls /etc/netplan/

# Edit configuration
sudo nano /etc/netplan/01-netcfg.yaml
```

Example configuration:

```yaml
network:
  version: 2
  ethernets:
    enp3s0:  # Replace with your interface name
      dhcp4: no
      addresses:
        - 192.168.12.100/24
      gateway4: 192.168.12.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

Apply changes:

```bash
sudo netplan apply
```

### 2. Firewall Configuration

```bash
# Enable UFW firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow OpenClaw ports (if needed externally)
sudo ufw allow 3000/tcp  # OpenClaw Gateway
sudo ufw allow 8000/tcp  # Lemonade Server (if remote access needed)

# Check status
sudo ufw status verbose
```

### 3. Verify Network Connectivity

```bash
# Check IP address
ip addr show

# Test internet connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
nslookup github.com
```

---

## Security Hardening

### 1. Automatic Security Updates

```bash
# Install unattended-upgrades
sudo apt install -y unattended-upgrades

# Enable automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Edit configuration
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

### 2. Fail2ban Installation

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit to protect SSH
sudo nano /etc/fail2ban/jail.local
```

Add this section:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

Start fail2ban:

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status
```

### 3. Disable Unnecessary Services

```bash
# List running services
systemctl list-units --type=service --state=running

# Disable unnecessary services (example)
sudo systemctl disable bluetooth  # If not needed
sudo systemctl disable cups       # If no printer
```

---

## Software Installation

### 1. Essential Packages

```bash
sudo apt update
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release
```

### 2. Install Node.js 22.x

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version  # Should be v22.x
npm --version
```

### 3. Install Docker (Optional - for Docker Deployment)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify (may need to logout/login first)
docker --version
docker compose version
```

### 4. Install Python 3 and pip

```bash
# Install Python 3
sudo apt install -y python3 python3-pip python3-venv

# Verify
python3 --version
pip3 --version

# Upgrade pip
pip3 install --upgrade pip
```

---

## Resource Limits

### 1. Increase File Descriptors

```bash
# Edit limits.conf
sudo nano /etc/security/limits.conf
```

Add these lines:

```
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
```

### 2. Configure Systemd Limits (for Docker)

```bash
# Create override for Docker service
sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo nano /etc/systemd/system/docker.service.d/limits.conf
```

Add:

```ini
[Service]
LimitNOFILE=65536
LimitNPROC=65536
```

Apply:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 3. Swap Configuration (Optional)

```bash
# Check current swap
swapon --show

# Create swap file (4GB example)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Monitoring and Logging

### 1. System Monitoring Tools

```bash
# Install monitoring tools
sudo apt install -y \
  htop \
  iotop \
  nethogs \
  sysstat

# Enable sysstat collection
sudo nano /etc/default/sysstat
# Set: ENABLED="true"

sudo systemctl enable sysstat
sudo systemctl start sysstat
```

### 2. Log Rotation

```bash
# Edit logrotate configuration for OpenClaw
sudo nano /etc/logrotate.d/openclaw
```

Add:

```
/home/openclaw/.openclaw/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 openclaw openclaw
}
```

### 3. Journalctl Configuration

```bash
# Limit journal size
sudo nano /etc/systemd/journald.conf
```

Set:

```ini
[Journal]
Storage=persistent
SystemMaxUse=100M
RuntimeMaxUse=50M
```

Apply:

```bash
sudo systemctl restart systemd-journald
```

---

## Verification Checklist

Run through this checklist to ensure your server is properly configured:

- [ ] System updated to latest packages
- [ ] Hostname and timezone configured
- [ ] Dedicated user account created
- [ ] SSH key-based authentication configured
- [ ] Firewall enabled and configured
- [ ] Automatic security updates enabled
- [ ] Fail2ban running
- [ ] Node.js 22.x installed
- [ ] Docker installed (if using Docker deployment)
- [ ] Python 3 and pip installed
- [ ] File descriptor limits increased
- [ ] Log rotation configured
- [ ] Monitoring tools installed

---

## Next Steps

After completing server configuration:

1. Proceed to **[Lemonade Configuration](Lemonade-Configuration)** if using local inference
2. Follow **[Agent Configuration](Agent-Configuration)** to set up your agents
3. Choose your deployment method:
   - **[Docker Deployment](Docker-Deployment)** (recommended)
   - **[Bare Metal Installation](Bare-Metal-Installation)**

---

## Troubleshooting

### Cannot Connect via SSH

```bash
# Check SSH service status
sudo systemctl status sshd

# Check firewall
sudo ufw status

# Check if port 22 is listening
sudo ss -tlnp | grep 22
```

### Permission Denied Errors

```bash
# Verify user is in correct groups
groups $USER

# Add to docker group if needed
sudo usermod -aG docker $USER
# Logout and login again
```

### Out of Memory Errors

```bash
# Check memory usage
free -h

# Check swap
swapon --show

# Add swap if needed (see Swap Configuration above)
```

---

## Additional Resources

- [Ubuntu 24.04 Server Guide](https://ubuntu.com/server/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Official Documentation](https://nodejs.org/docs/)
- [OpenClaw README](../README.md)

---

*Last updated: April 2026*
