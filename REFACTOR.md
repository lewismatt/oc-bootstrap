# OpenClaw Bootstrap Refactoring Summary

**Date**: April 2026  
**Branch**: `docker`  
**Purpose**: Transform personal bootstrap tool into public-friendly project

---

## 🎯 Objective

This repository began as a personal bootstrap mechanism for OpenClaw, tailored to the
original creator's home server setup. The goal of this refactoring was to
transform it into a project that **anyone with basic computer skills
can clone and use** to bootstrap an OpenClaw instance on a Linux
server, VM, or Docker container.

---

## 🔄 What Changed

### 1. README.md - Complete Rewrite

**Before**: Personal notes with references to creator's specific setup  
**After**: Comprehensive, public-friendly documentation

**Key Improvements**:
- Added "Who Is This For?" section targeting self-hosting enthusiasts
- Added copy-paste Quick Start commands for immediate use
- Reorganized into clear sections (Docker vs Bare Metal)
- Emphasized local inference with Lemonade Server
- Added project goals explaining the single gateway + multiple isolated agents design
- Updated all repository URLs to `openclaw/oc-bootstrap`
- Added troubleshooting section with common issues and solutions

### 2. Agent SOUL.md Files - Made Generic

**Before**: Personalized agent personalities with specific hardware/usage assumptions  
**After**: Generic templates adaptable to any user

| File | Before | After |
|------|--------|-------|
| `assistant/SOUL.md` | "Local-first technical assistant" with creator's preferences | "Helpful, general-purpose AI assistant" that adapts to user |
| `research/SOUL.md` | Specific research interests and sources | Generic "meticulous data synthesis agent" template |
| `developer/SOUL.md` | Creator's infrastructure details | Generic "expert software developer" template |

### 3. Agent USER.md Files - Created Templates

**Before**: Personal USER.md files with creator's specific hardware and preferences  
**After**: Checklist-style templates with placeholders

**Features**:
- `[ ]` checkboxes for easy customization
- `[e.g., ...]` placeholders for user-specific values
- Sections for: Technical Experience, Hardware Setup, Use Cases, Communication Preferences
- Agents can update these files automatically when learning user preferences

### 4. Wiki Documentation - Updated

**Files Updated**:
- `wiki/Agent-Configuration.md` - Removed embedded personal examples, now references generic templates
- `wiki/Home.md` - Already had correct URLs
- `wiki/Quick-Start.md` - Already public-friendly
- All wiki files now reference updated repository structure

### 5. oc-bootstrap.sh - Beginner-Friendly Prompts

**Before**: Minimal prompts assuming technical expertise  
**After**: Step-by-step guidance with explanations

**Improvements by Step**:

| Step | Improvement |
|------|--------------|
| **Step 1: Inference Backend** | Clear comparison of Local vs Remote with bullet points, costs ($0.001-$0.06/request), setup times |
| **Step 2: Telegram Setup** | Instructions for @BotFather, example bot names (openclaw_assistant_bot), token format examples |
| **Step 3: Model Selection** | Explains what each model does, pricing estimates, tips for mixing local/cloud |
| **Step 4: Integrations** | Describes each service (GitHub, GitLab, Brave, X), where to get keys, required scopes |

**Added Features**:
- `[OK]` confirmations after each step
- Helpful tips throughout (e.g., "Tip: The token should look like: 123456789:ABCdef...")
- Progress indicators for system preparation
- Clear error messages with actionable solutions

### 6. Repository URLs - Verified & Updated

**Files Checked**:
- ✅ `CONTRIBUTING.md` - Already had correct `openclaw/oc-bootstrap` URLs
- ✅ `wiki/*.md` - All reference correct repository links
- ✅ `DOCKER.md` - Uses proper URLs

---

## 🏗️ New Design Paradigm

The refactored repository emphasizes:

### 1. Single OpenClaw Gateway + Multiple Isolated Agents

```
┌─────────────────────────────────────────────────┐
│         Your Linux Server (Ubuntu 24.04)       │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐    │
│  │     OpenClaw Gateway (Single Instance)  │    │
│  │  • Central routing                      │    │
│  │  • Memory indexing                    │    │
│  └──────────────────────────────────────┘    │
│           ↓            ↓            ↓             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │Assistant│ │Research │ │Developer│  │
│  │  Agent  │ │  Agent  │ │  Agent  │  │
│  │          │ │          │ │          │  │
│  │Isolated │ │Isolated │ │Isolated │  │
│  │Workspace│ │Workspace│ │Workspace│  │
│  └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────────────────────────────┘
         ↕                         ↕
    Telegram Bots          AI Model Providers
    (1 per agent)       (Local: Lemonade / Cloud)
```

### 2. Agent Isolation via Telegram

Each agent has:
- **Unique Telegram bot** (token from @BotFather)
- **Separate workspace** (`~/.openclaw/workspace-{agent}/`)
- **Independent memory** (SQLite database per agent)
- **Customizable personality** (SOUL.md, USER.md, AGENTS.md)

### 3. Local Inference Focus

**Primary Goal**: Enable self-hosting with privacy

- **Lemonade Server** for local LLM inference
- **No data sent to external services** (when using local models)
- **Cloud APIs supported** (OpenAI, Anthropic) for convenience
- **Mix and match** - Use local for simple tasks, cloud for complex ones

### 4. Interactive & Template-Based Setup

**Two Setup Methods**:

| Method | Audience | Time |
|--------|----------|------|
| **Interactive Script** (`./oc-bootstrap.sh`) | Beginners, general public | 5-10 min |
| **Docker Deployment** (`docker compose up -d`) | Docker users, testing | 2-3 min |

**Template System**:
- SOUL.md files are generic starting points
- USER.md files are checklists to customize
- Users fill in their own hardware/usage details

---

## 📋 For Users: How to Use This Repository

### Quick Start (Bare Metal)

```bash
# 1. Clone the repository
git clone https://github.com/openclaw/oc-bootstrap.git
cd oc-bootstrap

# 2. Make scripts executable
chmod +x *.sh

# 3. Run the interactive installer
./oc-bootstrap.sh
```

The script will guide you through:
1. Choosing local (Lemonade) or cloud AI models
2. Entering Telegram bot tokens (with instructions)
3. Selecting models for each agent
4. Optionally adding API keys for enhanced features

### Quick Start (Docker - Recommended for Beginners)

```bash
# 1. Configure your environment
cp docker-config.env.template docker-config.env
nano docker-config.env  # Add your Telegram bot tokens

# 2. Start with Docker Compose
docker compose up -d

# 3. View logs
docker compose logs -f
```

### Customizing Your Agents

After installation, edit the template files:

```bash
# Customize Assistant agent
nano ~/.openclaw/workspace-assistant/SOUL.md
nano ~/.openclaw/workspace-assistant/USER.md

# Customize Research agent
nano ~/.openclaw/workspace-research/SOUL.md

# Customize Developer agent
nano ~/.openclaw/workspace-developer/SOUL.md

# Reload configuration
openclaw agents reload assistant
```

---

## 🎯 Project Goals (Refactored)

1. **Accessibility**: Anyone with basic Linux/command-line skills can use this
2. **Privacy**: Emphasis on local inference with Lemonade Server
3. **Isolation**: Single gateway managing multiple isolated Telegram bots/agents
4. **Flexibility**: Support both local models and cloud APIs
5. **Templates**: Generic starting points that adapt to user needs
6. **Documentation**: Clear, public-friendly guides with examples

---

## 📊 Files Changed Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `README.md` | Complete rewrite | Public-friendly documentation |
| `assistant/SOUL.md` | Generic template | Removed personal references |
| `research/SOUL.md` | Generic template | Removed personal references |
| `developer/SOUL.md` | Generic template | Removed personal references |
| `assistant/USER.md` | New template | Checklist-style with placeholders |
| `research/USER.md` | New template | Checklist-style with placeholders |
| `developer/USER.md` | New template | Checklist-style with placeholders |
| `wiki/Agent-Configuration.md` | Updated | References new generic templates |
| `oc-bootstrap.sh` | Improved prompts | Beginner-friendly with explanations |
| `CONTRIBUTING.md` | Verified | URLs already correct |
| `docker-config.env.template` | Verified | Already public-friendly |

---

## 🤝 Contributing

This refactoring makes it easier for others to contribute:

1. **Clear documentation** - Users understand the design paradigm
2. **Generic templates** - Contributors can adapt to their needs
3. **Public URLs** - Issues/PRs go to the correct repository
4. **Beginner-friendly** - Lower barrier to entry

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

**Happy bootstrapping! 🚀**
