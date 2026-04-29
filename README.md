# OpenClaw Multi-Agent Bootstrapper

> An automated script (`oc-bootstrap.sh`) that provisions a **strictly isolated**,
> multi-agent OpenClaw environment on a bare-metal Linux host.

---

## Architecture Overview

| Component               | Description                                                                         |
|:------------------------|:--------------------------------------------------------------------------------------|
| **Host**                | Ubuntu 24.04 (bare-metal)                                                             |
| **Inference Backend**   | Local Lemonade server running GGUF models via AMD ROCm (designed for 12 GB VRAM minimum)   |
| **Agent: Assistant**    | General-purpose aide (`lemonade/user.Qwen3.5-4B-GGUF`)                                |
| **Agent: Research**     | Deep-dive web research (`lemonade/user.Qwen3.5-4B-GGUF`)                              |
| **Agent: Developer**    | Code and Git workflow (`lemonade/user.Qwen3.5-4B-GGUF`)                               |
| **Shared Memory Model** | `lemonade/user.nomic-embed-text-v1.5-GGUF`                                            |
| **Vector Store**        | Local SQLite-backed search with `sqlite-vec` acceleration using OpenAI-compatible API (backed by Lemonade) |

---

## Required Integrations and API Keys

| Integration                  | Why it's needed                                          | How to obtain                                                                                                                                                       |
|:-----------------------------|:---------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Telegram** (required)      | Three distinct bots keep each agent's context isolated.  | Message **@BotFather** -> `/newbot` three times -> copy the HTTP API tokens.                                                                                        |
| **Lemonade Server** (required) | Provides local inference.                                | Run a Lemonade instance. The script will prompt you for the server IP (with validation), and will use it to configure the OpenAI-compatible API endpoint. **CRITICAL:** Ensure both `Qwen3.5-4B-GGUF` **and** `nomic-embed-text-v1.5-GGUF` are downloaded and staged on the server. |
| **GitLab PAT** (optional)    | Allows all agents to read/write to a shared codebase.   | Create a Personal Access Token with `api` + `read_repository` scopes in GitLab under *User Settings -> Access Tokens*.                                                 |
| **Brave Search** (optional)  | Powers live web searches for the Research agent.         | Get a free API key from the [Brave Search Developer Portal](https://brave.com/search/api/).                                                                         |
| **X/Twitter** (optional)     | Enables real-time trend scraping for the Research agent. | Obtain an API key from the [X Developer Portal](https://developer.twitter.com/en/portal/dashboard).                                                                 |

---

## Lemonade Server Setup

### What is Lemonade Server?

**Lemonade Server** is a local inference backend that runs GGUF quantized models (LLMs and embedding models) 
on your hardware. It provides an OpenAI-compatible REST API, allowing all three agents to perform inference 
without relying on cloud services.

**Key features:**
- OpenAI-compatible `/v1` API endpoints for easy integration
- Supports quantized GGUF models optimized for consumer GPUs (AMD ROCm, NVIDIA CUDA)
- Runs entirely on-premises with zero cloud data leakage
- Designed to run efficiently on systems with 12 GB VRAM minimum; additional VRAM enables improved performance and larger models

### Prerequisites

- **System:** AMD GPU with 12+ GB VRAM (tested with AMD ROCm) or NVIDIA GPU with CUDA support
- **Memory:** At least 16 GB system RAM recommended
- **Disk Space:** ~15 GB for model storage (Qwen3.5-4B + nomic-embed-text)
- **Network:** Accessible on local network at a fixed IP address

### Setup on Linux (Ubuntu 24.04)

1. **Clone the Lemonade repository:**
   ```bash
   git clone https://github.com/lemonade-ai/lemonade-server.git
   cd lemonade-server
   ```

2. **Install dependencies:**
   ```bash
   # For AMD ROCm support
   sudo apt install -y rocm-core rocm-libs
   export HSA_OVERRIDE_GFX_VERSION=11.0  # Adjust based on your GPU
   
   # For general Python environment
   pip install -r requirements.txt
   ```

3. **Download required models:**
   ```bash
   # Create models directory
   mkdir -p models/huggingface.co/user.model-name/

   # Download Qwen3.5-4B (quantized GGUF format)
   # Example using Hugging Face CLI or manual download
   huggingface-cli download Qwen/Qwen2.5-4B-Instruct-GGUF qwen2.5-4b-instruct-q4_k_m.gguf \
     --local-dir models/huggingface.co/user.Qwen3.5-4B-GGUF/

   # Download nomic-embed-text (quantized GGUF format)
   huggingface-cli download nomic-ai/nomic-embed-text-v1.5-GGUF \
     nomic-embed-text-v1.5.f16.gguf \
     --local-dir models/huggingface.co/user.nomic-embed-text-v1.5-GGUF/
   ```

4. **Start Lemonade Server:**
   ```bash
   # Run in foreground (or use systemd/screen for background)
   HSA_OVERRIDE_GFX_VERSION=11.0 python -m lemonade.server \
     --host 0.0.0.0 \
     --port 8000 \
     --models-path ./models
   ```

5. **Verify it's running:**
   ```bash
   curl http://localhost:8000/v1/models
   ```

### Setup on Windows

1. **Install prerequisites:**
   - Download and install [Python 3.10+](https://www.python.org/downloads/)
   - Install [Git for Windows](https://git-scm.com/)
   - For AMD: Install [AMD ROCm for Windows](https://rocmdocs.amd.com/en/docs/deploy/windows/quick_start.html)
   - For NVIDIA: Install [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)

2. **Clone and setup:**
   ```powershell
   git clone https://github.com/lemonade-ai/lemonade-server.git
   cd lemonade-server
   pip install -r requirements.txt
   ```

3. **Download models:**
   ```powershell
   # Create models directory
   New-Item -Type Directory -Path "models\huggingface.co" -Force

   # Download using Hugging Face CLI (install first: pip install huggingface-hub)
   huggingface-cli download Qwen/Qwen2.5-4B-Instruct-GGUF qwen2.5-4b-instruct-q4_k_m.gguf `
     --local-dir "models\huggingface.co\user.Qwen3.5-4B-GGUF"

   huggingface-cli download nomic-ai/nomic-embed-text-v1.5-GGUF `
     nomic-embed-text-v1.5.f16.gguf `
     --local-dir "models\huggingface.co\user.nomic-embed-text-v1.5-GGUF"
   ```

4. **Start Lemonade Server:**
   ```powershell
   # For AMD ROCm (may need environment variable)
   $env:HSA_OVERRIDE_GFX_VERSION = "11.0"  # Adjust for your GPU
   python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ".\models"

   # Or simply:
   python -m lemonade.server
   ```

5. **Verify it's running:**
   ```powershell
   Invoke-WebRequest http://localhost:8000/v1/models
   ```

6. **Optional: Create a batch file for easy startup:**
   ```batch
   @echo off
   cd /d %~dp0
   set HSA_OVERRIDE_GFX_VERSION=11.0
   python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ".\models"
   pause
   ```
   Save as `start-lemonade.bat` and double-click to run.

### Important Notes

- **Model Paths:** Ensure model directory structure matches `models/huggingface.co/{model-namespace}/{model-name}/`. The script looks for files in this exact format.
- **Network Access:** Lemonade must be accessible from your OpenClaw host. Note its IP address (e.g., `192.168.1.100`) for the bootstrap script.
- **Port Mapping:** Default port is `8000`. If changed, remember to use `http://<IP>:PORT/v1` when running `oc-bootstrap.sh`.
- **Performance:** First inference request may be slow as models load into VRAM. Subsequent requests are faster.

---

## Quick-Start and Installation

### Prerequisites

- Ubuntu 24.04 with a regular (non-root) user.
- `git` installed (`sudo apt install git`).

> **Do not run the script as root.** The installer will request `sudo` only when
> necessary.

### Steps

```bash
# 1. Clone the repo
git clone <your-repo-url> openclaw-setup
cd openclaw-setup

# 2. Make the script executable
chmod +x oc-bootstrap.sh

# 3. Run the installer (follow the prompts)
./oc-bootstrap.sh
```

---

## What the Script Does

1. **Installs Dependencies & Runs Health Check** - Safely provisions Node 20.x, 
   `curl`, the OpenClaw core daemon, and runs `openclaw doctor --fix` to 
   auto-repair common issues.
2. **Secures Credentials** - Stores API keys in a `chmod 600`-protected local env file,
   validates Telegram tokens against the Telegram API, and prevents duplicate token usage.
   Checks for existing secrets file and prompts before overwriting.
3. **Provisions Agents** - Creates isolated workspaces (`~/.openclaw/workspace-*`) for
   Assistant, Research, and Developer agents, then prompts for the Lemonade server IP
   and configures all inference endpoints.
4. **Binds Skills and Hooks**:
    - Adds live-scraping skills to the Research agent (webSearch, webScrape, newsSearch,
      rssReader, trendsFinder, xScraper).
    - Enables `autoMemory` on the Assistant, `sessionSummarize` on the Research agent,
      and `toolValidation` on the Developer agent.
    - Binds the open-source `@zereight/mcp-gitlab` server to **all three agents**
      for unified version-controlled project memory.
5. **Seeds Context** - Discovers prompt files (`SOUL.md`, `USER.md`, `AGENTS.md`)
   from agent subdirectories in the repository, then interactively prompts the user to
   choose between [S]eed (copy files), [D]efault (skip seeding), or [H]alt (review first).
   If files exist in the workspace, shows a diff before overwriting.

---

## Troubleshooting

| Symptom                                                  | Likely Cause                                     | Fix                                                                                                                                        |
|:---------------------------------------------------------|:-------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------|
| **Agents unresponsive via Telegram**                     | Lemonade server missing models or not reachable. | Verify the server is running and both `Qwen3.5-4B-GGUF` and `nomic-embed-text-v1.5-GGUF` are downloaded.                                  |
| **"Conflict: terminated by other getUpdates request"**   | Same Telegram token used for multiple agents.    | Re-run the setup and provide three **unique** bot tokens.                                                                                  |
| **Ghost daemon processes**                               | Previous run left a PM2 daemon alive.            | Run `openclaw gateway stop && npx pm2 kill`, then restart the installer.                                                                   |
| **MCP server errors**                                    | Node version too old for `@zereight/mcp-gitlab`. | Ensure Node >= 18 (`node -v`). The script will try to install Node 20 automatically, but you may need to resolve version conflicts manually. |

---

## Privacy and Security

- **Zero Cloud Data** - All embeddings and inference stay on-premises. Data leaves the
  network only if you explicitly enable Brave, X, or GitLab integrations.
- **Isolated State** - Each agent maintains its own `.sqlite` index, preventing
  cross-agent data leakage.

---

*Happy bootstrapping!*
