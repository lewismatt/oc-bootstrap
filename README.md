Here’s a revised version of **README.md** that adds clearer visual hierarchy, better spacing, and more helpful emojis while keeping all the original information.

---  

# OpenClaw Multi‑Agent Bootstrapper  

> An automated script (`oc‑setup.sh`) that provisions a **strictly isolated**, multi‑agent OpenClaw environment on a bare‑metal Linux host.

---

## 📐 Architecture Overview  

| Component | Description |
|-----------|-------------|
| **Host** | Ubuntu 24.04 (bare‑metal) |
| **Inference Backend** | Local *Lemonade* server running GGUF models via AMD ROCm (optimized for 12 GB VRAM) |
| **Agents** | • **Assistant** – General‑purpose aide (`lemonade/user.Qwen3.5-4B‑GGUF`) <br>• **Research** – Deep‑dive web research (`lemonade/user.Qwen3.5-4B‑GGUF`) <br>• **Developer** – Code & Git workflow (`lemonade/user.Qwen3.5-4B‑GGUF`) |
| **Shared Memory Model** | `lemonade/user.nomic‑embed‑text‑v1.5‑GGUF` |
| **Vector Store** | Local SQLite‑backed search with `sqlite‑vec` acceleration |

---

## 🔑 Required Integrations & API Keys  

| Integration | Why it’s needed | How to obtain |
|-------------|----------------|---------------|
| **Telegram** (required) | Three distinct bots keep each agent’s context isolated. | Message **@BotFather** → `/newbot` three times → copy the HTTP API tokens. |
| **Lemonade Server** (required) | Provides local inference. | Run a Lemonade instance, note its IP and API key. **CRITICAL:** Ensure both `Qwen3.5‑4B‑GGUF` **and** `nomic‑embed‑text‑v1.5‑GGUF` are downloaded and staged. |
| **GitLab PAT** (optional) | Allows the Developer agent to read/write code. | Create a Personal Access Token with `api` + `read_repository` scopes in GitLab → *User Settings → Access Tokens*. |
| **Brave Search** (optional) | Powers live web searches for the Research agent. | Get a free API key from the [Brave Search Developer Portal](https://brave.com/search/api/). |
| **X/Twitter** (optional) | Enables real‑time trend scraping for the Research agent. | Obtain an API key from the [X Developer Portal](https://developer.twitter.com/en/portal/dashboard). |

---

## 🚀 Quick‑Start & Installation  

### Prerequisites  

* Ubuntu 24.04 with a regular (non‑root) user.  
* `git` installed (`sudo apt install git`).  

> **⚠️ Do not run the script as root.** The installer will request `sudo` only when necessary.

### Steps  

```bash
# 1️⃣ Clone the repo
git clone <your-repo-url> openclaw-setup
cd openclaw-setup

# 2️⃣ Make the script executable
chmod +x oc-setup.sh

# 3️⃣ Run the installer (follow the prompts)
./oc-setup.sh
```

---

## ⚙️ What the Script Does  

1. **Installs Dependencies** – Safely provisions Node 20.x, `curl`, and the OpenClaw core daemon.  
2. **Secures Credentials** – Stores API keys in a `chmod 600`‑protected local env file and prevents duplicate Telegram tokens.  
3. **Provisions Agents** – Creates isolated workspaces (`~/.openclaw/workspace‑*`) for Assistant, Research, and Developer agents.  
4. **Binds Skills & Hooks** –  
   * Adds live‑scraping skills to the Research agent.  
   * Sets up auto‑memory summarisation.  
   * Connects the open‑source `@zereight/mcp‑gitlab` server for local Git operations.  
5. **Seeds Context** – Copies the prompt files (`SOUL.md`, `USER.md`, `AGENTS.md`) from this repo directly into each agent’s operational memory.

---

## 🛠️ Troubleshooting  

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| **Agents unresponsive via Telegram** | Lemonade server missing models or not reachable. | Verify the server is running and both `Qwen3.5‑4B‑GGUF` **and** `nomic‑embed‑text‑v1.5‑GGUF` are downloaded. |
| **“Conflict: terminated by other getUpdates request”** | Same Telegram token used for multiple agents. | Re‑run the setup and provide three **unique** bot tokens. |
| **Ghost daemon processes** | Previous run left a PM2 daemon alive. | ```bash\nopenclaw gateway stop\nnpx pm2 kill\n``` then restart the installer. |
| **MCP server errors** | Node version too old for `@zereight/mcp‑gitlab`. | Ensure Node ≥ 18 (`node -v`). The script will try to install Node 20 automatically, but you may need to resolve version conflicts manually. |

---

## 🛡️ Privacy & Security  

* **Zero Cloud Data** – All embeddings and inference stay on‑premises. Data leaves the network only if you explicitly enable Brave, X, or GitLab integrations.  
* **Isolated State** – Each agent maintains its own `.sqlite` index, preventing cross‑agent data leakage.  

---  

*Happy bootstrapping! 🎉*  gateway stop\nnpx pm2 kill\n``` then restart the installer. |
| **MCP server errors** | Node version too old for `@zereight/mcp‑gitlab`. | Ensure Node ≥ 18 (`node -v`). The script will try to install Node 20 automatically, but you may need to resolve version conflicts manually. |

---

## 🛡️ Privacy & Security  

* **Zero Cloud Data** – All embeddings and inference stay on‑premises. Data leaves the network only if you explicitly enable Brave, X, or GitLab integrations.  
* **Isolated State** – Each agent maintains its own `.sqlite` index, preventing cross‑agent data leakage.  

---  

*Happy bootstrapping! 🎉*  
