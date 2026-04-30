# User Context - Developer Agent

This file contains technical context to help the Developer Agent understand your infrastructure, coding standards, and project goals.

## Technical Preferences

**Primary Language:** [e.g., Python 3.10+]

**Code Style:**

- [ ] Follow PEP 8 guidelines (Python)
- [ ] Use type hints for all function signatures
- [ ] Prefer functional approaches where possible
- [ ] Use clear variable names and comments

**Version Control (GitHub/GitLab):**

- [ ] Git workflow: feature branches with pull requests
- [ ] Commit messages: Conventional Commits standard
- [ ] CI/CD: [Your CI system - e.g., GitHub Actions]
- [ ] Preferred Git platform: [GitHub/GitLab/Other]

## Infrastructure Overview

**Local Machine:**

- **OS:** [e.g., Ubuntu 24.04]
- **Editor:** [e.g., Visual Studio Code]
- **Shell:** [e.g., Bash]
- **Package Manager:** [e.g., apt, npm, pip]

**Server Environment:**

- **Provider:** [e.g., Self-hosted / AWS / DigitalOcean]
- **Virtualization:** [e.g., No (bare-metal) / Docker / KVM]
- **Primary Tools:** [e.g., OpenClaw, Lemonade Server, GitLab]

## Current Projects & Goals

1. **[Project 1]:**
   - [ ] [Goal or task]
   - [ ] [Goal or task]
   - [ ] [Goal or task]

2. **[Project 2]:**
   - [ ] [Goal or task]
   - [ ] [Goal or task]

3. **[Add your own projects]**

## API Keys & Endpoints

*Note: For security, reference secrets stored in the OpenClaw environment. Do not hardcode them here.*

- **GitLab Instance:** [e.g., `https://gitlab.com` or your self-hosted instance]
- **Lemonade Server:** [e.g., `http://your-lemonade-ip:8000/v1`]
- **Other Services:** [List any other services you use]

## Common Commands & Snippets

*You can store frequently used commands here for the Developer Agent to reference.*

**Starting Lemonade Server:**

```bash
# Example command - adjust for your setup
HSA_OVERRIDE_GFX_VERSION=11.0 python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ./models
```

**Checking OpenClaw Gateway Status:**

```bash
openclaw gateway status
```

**Other Useful Commands:**

```bash
# Add your frequently used commands here
```

## Model Preferences

**For Different Task Types:**

- **General coding:** [e.g., `anthropic/claude-3-5-sonnet-latest`]
- **Quick scripts:** [e.g., `openai/gpt-4o`]
- **Local/private tasks:** [e.g., `lemonade/user.Qwen3.5-4B-GGUF`]
- **Documentation lookups:** [e.g., `openai/gpt-4o`]

## Resource Constraints

**When Recommending Models or Architecture:**

- **GPU VRAM:** [e.g., 8GB - mention if limited]
- **System RAM:** [e.g., 32GB]
- **Storage:** [e.g., 1TB available]
- **Network:** [e.g., Gigabit - consider for large downloads]

## Learning Goals

- [ ] Understanding AI/ML model optimization
- [ ] Improving GitOps workflows
- [ ] Learning Docker containerization
- [ ] [Add your own learning goals]

---

*Note: The Developer Agent can update this file as it learns your preferences and working style. You can also edit manually: `nano ~/.openclaw/workspace-developer/USER.md`*
