# OpenClaw Multi-Agent Bootstrap Wiki

Welcome to the OpenClaw Multi-Agent Bootstrap documentation wiki! This wiki provides detailed guides and references for setting up, configuring, and managing your OpenClaw multi-agent system.

## 📚 Wiki Pages

### Getting Started
- **[Home](Home)** - This page (you are here)
- **[Quick Start Guide](Quick-Start)** - Get up and running in 5 minutes
- **[Installation](Installation)** - Detailed installation instructions

### Configuration Guides
- **[Lemonade Configuration](Lemonade-Configuration)** - Set up local LLM inference with Lemonade Server
- **[Linux Server Configuration](Linux-Server-Configuration)** - Configure your Ubuntu 24.04 server
- **[Agent Configuration](Agent-Configuration)** - Customize agent personalities and behaviors
- **[Chat Channel Isolation](Chat-Channel-Isolation)** - Set up isolated Telegram channels for each agent

### Deployment Options
- **[Docker Deployment](Docker-Deployment)** - Run OpenClaw in Docker containers
- **[Bare Metal Installation](Bare-Metal-Installation)** - Direct installation on Ubuntu

### Advanced Topics
- **[Troubleshooting](Troubleshooting)** - Common issues and solutions
- **[Architecture Overview](Architecture-Overview)** - System design and components
- **[Memory Management](Memory-Management)** - How agents store and retrieve information
- **[API Integrations](API-Integrations)** - Configure OpenAI, Anthropic, and other services

---

## 🚀 Quick Links

| Resource | Link |
|----------|------|
| Main Repository | [github.com/lewismatt/oc-bootstrap](https://github.com/lewismatt/oc-bootstrap) |
| Issue Tracker | [Report a Bug](https://github.com/lewismatt/oc-bootstrap/issues) |
| Discussions | [Community Discussions](https://github.com/lewismatt/oc-bootstrap/discussions) |
| Releases | [Download Latest](https://github.com/lewismatt/oc-bootstrap/releases) |

---

## 🤖 Available Agents

| Agent | Purpose | Documentation |
|-------|---------|----------------|
| **Assistant** | General-purpose AI helper | [Configure Assistant](Agent-Configuration#assistant-agent) |
| **Research** | Web research specialist | [Configure Research](Agent-Configuration#research-agent) |
| **Developer** | Coding expert | [Configure Developer](Agent-Configuration#developer-agent) |

---

## 📖 Recommended Reading Order

1. Start with **[Quick Start Guide](Quick-Start)** to get OpenClaw running
2. Read **[Architecture Overview](Architecture-Overview)** to understand the system
3. Configure your **[Agent Configuration](Agent-Configuration)** preferences
4. Set up **[Lemonade Configuration](Lemonade-Configuration)** for local inference (optional)
5. Review **[Chat Channel Isolation](Chat-Channel-Isolation)** for multi-user setups
6. Check **[Troubleshooting](Troubleshooting)** if you encounter issues

---

## 🛠️ System Requirements

- **OS**: Ubuntu 24.04 (recommended)
- **RAM**: 8GB minimum (16GB+ recommended)
- **Storage**: 20GB free space minimum
- **Network**: Internet access for initial setup
- **Optional**: GPU for local inference (AMD/NVIDIA supported)

---

## 📝 Contributing to the Wiki

This wiki is maintained alongside the main repository. To contribute:

1. Clone the wiki repository:
   ```bash
   git clone https://github.com/lewismatt/oc-bootstrap.wiki.git
   ```

2. Make your changes and commit:
   ```bash
   cd oc-bootstrap.wiki
   # Edit .md files
   git add .
   git commit -m "Update documentation"
   git push
   ```

3. See [Contributing Guide](../CONTRIBUTING.md) for more details.

---

## 🆘 Need Help?

- Check **[Troubleshooting](Troubleshooting)** page first
- Search existing [Issues](https://github.com/lewismatt/oc-bootstrap/issues)
- Ask in [Discussions](https://github.com/lewismatt/oc-bootstrap/discussions)
- Review [README.md](../README.md) for basic information

---

*Last updated: April 2026*