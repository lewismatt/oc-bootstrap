# 🚀 OpenClaw Multi-Agent Bootstrapper

Welcome to OpenClaw! This tool automatically sets up a team of AI assistants on your computer. They will live securely on your server but communicate with you directly and privately through Telegram.

If you are new to self-hosted AI, don't worry. This guide is designed for anyone with basic command-line experience. The setup script does the heavy lifting for you!

---

## 🗺️ Table of Contents

- [🧠 AI Concepts (Jargon Buster)](#-ai-concepts-jargon-buster)
- [📋 Checklist: What You Need Before Starting](#-checklist-what-you-need-before-starting)
- [⚡ Quick-Start and Installation](#-quick-start-and-installation)
- [🛠️ What the Script Actually Does](#%EF%B8%8F-what-the-script-actually-does)
- [🎯 Next Steps: Using Your Agents](#-next-steps-using-your-agents)
- [❓ Troubleshooting](#-troubleshooting)
- [🍋 Advanced: Local AI with Lemonade Server](#-advanced-local-ai-with-lemonade-server)

---

## 🧠 AI Concepts (Jargon Buster)

Before we start, here are a few terms you'll see in the installer:

- **Agents**: Think of these as your digital employees. You will have three: an **Assistant** (general tasks), a **Research Agent** (web searching), and a **Developer** (coding).
- **LLM / Model**: The "brain" powering the agent. Examples are OpenAI's GPT-4o or Anthropic's Claude.
- **Embedding Model**: A special AI tool that helps your agents search through their memory of your past conversations.
- **Remote vs. Local**:
  - *Remote APIs*: Your agents use cloud services like OpenAI or Anthropic (**Recommended for beginners**).
  - *Local Inference*: Your agents use a powerful graphics card (GPU) on your own server to run the AI completely privately (Advanced).

---

## 📋 Checklist: What You Need Before Starting

### 1. Telegram Bots (Required)

Each of your three agents needs its own Telegram bot so it can message you securely.

1. Open Telegram and search for [**@BotFather**](https://t.me/BotFather).
2. Send the message `/newbot` and follow the prompts to create your first bot (e.g., "My Assistant").
3. Copy the **HTTP API Token** it gives you.
4. Repeat this two more times for your "Research Agent" and "Developer" bots. Keep these three unique tokens handy!

### 2. Choose Your AI "Brains" (Remote APIs)

For beginners, we highly recommend using Remote APIs. You will need an API key from at least one of these providers:

- **OpenAI** (platform.openai.com)
- **Anthropic** (console.anthropic.com)

*Note: The setup script will ask for model tags. We provide default tags (like `openai/gpt-4o`) that you can just accept by pressing Enter during the script.*

### 3. Optional Extras

- **Brave Search API Key**: Lets your Research agent search the live internet (Free at brave.com/search/api).
- **GitLab Token**: Lets your Developer agent read/write code from GitLab.

---

## ⚡ Quick-Start and Installation

### 📋 Prerequisites

- Ubuntu 24.04 with a regular (non-root) user.
- `git` installed (`sudo apt install git`).

> ⚠️ **Do not run the script as root.** The installer will request `sudo` only when
> necessary.

### 👣 Steps

```bash
# 1. Clone the repo
git clone https://github.com/openclaw/oc-bootstrap.git openclaw-setup
cd openclaw-setup

# 2. Make the script executable
chmod +x oc-bootstrap.sh

# 3. Run the installer (follow the prompts)
./oc-bootstrap.sh
```

### 🌍 After Installation: Remote API Providers

If you chose to use Remote API providers (OpenAI, Anthropic) instead of local inference during setup, you'll need to provide your API keys before starting the gateway.

Run the OpenClaw onboarding wizard to enter your keys:

```bash
openclaw onboarding
```

Once configured, start the gateway:

```bash
openclaw gateway start
```

---

## 🛠️ What the Script Actually Does

Behind the scenes, the installer handles the complicated parts for you:

1. **Installs Requirements**: Safely downloads Node.js, `curl`, and the OpenClaw software.
2. **Secures Passwords**: Saves your Telegram tokens safely on your machine.
3. **Builds Workspaces**: Creates isolated folders (`~/.openclaw/workspace-*`) so your agents don't accidentally mix up their files or memories.
4. **Teaches Skills**: Gives your Research agent the ability to read websites and your Developer agent the ability to write code.

---

## 🎯 Next Steps: Using Your Agents

Congratulations! Your OpenClaw agents are now set up. Here's how to start using them:

### 1. Start Chatting on Telegram

Open Telegram and find the three bots you created earlier. Each bot represents one of your agents:

- **Assistant Bot** - Your general-purpose helper for daily tasks
- **Research Bot** - Your web research specialist
- **Developer Bot** - Your coding and technical expert

Just send a message to any bot to start! Try:

- "What can you help me with?"
- "Search for the latest news about AI"
- "Help me write a Python script to..."

### 2. Customize Agent Personalities

You can personalize each agent by editing their prompt files:

```bash
# Edit the Assistant's personality
nano ~/.openclaw/workspace-assistant/SOUL.md

# Add your personal context
nano ~/.openclaw/workspace-assistant/USER.md
```

See the example files in this repository's subdirectories (assistant/, research/, developer/) for ideas.

### 3. Monitor Agent Activity

Check what your agents are doing:

```bash
# View gateway status
openclaw gateway status

# View agent logs
openclaw logs --agent assistant

# Check memory indexing progress
openclaw memory status
```

### 4. Manage Your Setup

```bash
# Restart the gateway
openclaw gateway restart

# Stop the gateway
openclaw gateway stop

# Update agent configuration
openclaw config set agents.list.assistant.model "anthropic/claude-3-5-sonnet-latest"

# Re-run onboarding to update API keys
openclaw onboarding
```

---

## ❓ Troubleshooting

| Problem | Likely Cause | How to Fix |
|:---|:---|:---|
| **Agents won't reply on Telegram** | Missing API keys or gateway isn't running. | Run `openclaw onboarding` to add API keys, then `openclaw gateway start`. Check status with `openclaw gateway status`. |
| **"Conflict: terminated by other getUpdates request"** | You gave the exact same Telegram token to multiple agents. | Each agent needs a unique bot token. Re-run `./oc-bootstrap.sh` and create three different bots in @BotFather. |
| **"Model not found" error** | Invalid model tag or missing API key for that provider. | Check your model tags with `openclaw config get agents.list.<agent>.model`. Ensure API keys are set with `openclaw onboarding`. |
| **Slow or no responses** | Memory indexing still in progress, or local model overloaded. | Check `openclaw memory status`. For local inference, reduce concurrent requests or upgrade model. |
| **Gateway won't start** | Port conflict or configuration error. | Check logs at `~/.openclaw/logs/`. Try `openclaw gateway stop` then restart. Verify config with `openclaw config list`. |
| **Agent forgot conversation context** | Session memory not yet indexed. | Wait for background indexing to complete. Check `openclaw memory status` for progress. |
| **Permission denied errors** | Script run as root or workspace permissions incorrect. | Never run as root. Fix permissions: `chown -R $USER:$USER ~/.openclaw` |
| **Cannot connect to Lemonade server** | Server not running or wrong IP/port. | Verify Lemonade is running: `curl http://YOUR_IP:8000/v1/models`. Check IP in config: `openclaw config get providers.lemonade.baseUrl` |

---

## 🍋 Advanced: Local AI with Lemonade Server

*Skip this section unless you have a dedicated server with a powerful graphics card (12+ GB VRAM).*

If you want 100% privacy and zero cloud usage, you can run the AI brains on your own hardware using **Lemonade Server**. Lemonade Server is a tool that runs AI models on your own graphics card and provides an OpenAI-compatible API that your agents can use.

### Setup on Linux (Ubuntu 24.04)

1. **Clone the Lemonade repository:**

   ```bash
   git clone https://github.com/lemonade-ai/lemonade-server.git
   cd lemonade-server
   ```

2. **Install dependencies:**

   ```bash
   # For AMD ROCm support (adjust for NVIDIA if needed)
   sudo apt install -y rocm-core rocm-libs
   export HSA_OVERRIDE_GFX_VERSION=11.0  # Adjust based on your GPU
   pip install -r requirements.txt
   ```

3. **Download a model:**

   ```bash
   mkdir -p models/huggingface.co/user.model-name/

   # Example: Download Qwen3.5-4B
   huggingface-cli download Qwen/Qwen2.5-4B-Instruct-GGUF qwen2.5-4b-instruct-q4_k_m.gguf \
     --local-dir models/huggingface.co/user.Qwen3.5-4B-GGUF/
   ```

4. **Start the server:**

   ```bash
   HSA_OVERRIDE_GFX_VERSION=11.0 python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ./models
   ```

When you run `./oc-bootstrap.sh`, answer "Yes" when it asks if you want to use Local Inference, and provide your server's IP address and the tag `lemonade/user.Qwen3.5-4B-GGUF`.

---

*Happy bootstrapping! ✨*
