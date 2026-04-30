# User Context - Developer Agent

This file contains technical context to help the Developer Agent understand your infrastructure, coding standards, and project goals.

## Technical Preferences

**Primary Language:** Python 3.10+

**Code Style:**

- Follow PEP 8 guidelines
- Use type hints for all function signatures
- Prefer functional approaches where possible

**Version Control (GitHub/GitLab):**

- Git workflow: feature branches with pull requests
- Commit messages: Conventional Commits standard
- CI/CD: GitHub Actions

## Infrastructure Overview

**Local Machine:**

- **OS:** Ubuntu 24.04
- **Editor:** Visual Studio Code
- **Shell:** Bash

**Server Environment:**

- **Provider:** Self-hosted
- **Virtualization:** No (bare-metal)
- **Primary Tools:** OpenClaw, Lemonade Server, GitLab

## Current Projects & Goals

1.  **OpenClaw Optimization:**
    - Fine-tuning memory and vector search settings
    - Improving agent response times
    - Exploring new MCP integrations

2.  **Automation Scripts:**
    - Developing Python scripts for data processing
    - Automating system maintenance tasks with Bash

## API Keys & Endpoints

*Note: For security, reference secrets stored in the OpenClaw environment. Do not hardcode them here.*

- **GitLab Instance:** `https://gitlab.com`
- **Lemonade Server:** `http://<your-lemonade-ip>:8000/v1`

## Common Commands & Snippets

*You can store frequently used commands here for the Developer Agent to reference.*

**Starting Lemonade Server:**
```bash
HSA_OVERRIDE_GFX_VERSION=11.0 python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ./models
```

**Checking OpenClaw Gateway Status:**
```bash
openclaw gateway status
```
