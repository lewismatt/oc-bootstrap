# OpenClaw Multi-Agent Bootstrapper: Project Context & Architecture

This document serves as the foundational context for the `oc-bootstrap` project. It outlines the project's goals, architectural decisions, and the evolutionary steps that led to the current state of the codebase. Provide this document, along with `oc-bootstrap.sh` and `README.md`, to any LLM to ensure consistent and aligned future development.

## 1. Project Overview & Desired Outcomes

**Project Name:** OpenClaw Multi-Agent Bootstrapper (`oc-bootstrap`)
**Target Environment:** Bare-metal Ubuntu 24.04

**Primary Goal:** To create an automated, idempotent, GitOps-style deployment script that provisions a strictly isolated, local-first, multi-agent OpenClaw environment. 

**Core Philosophies:**
1.  **Absolute Privacy:** Zero cloud data leakage. All inference, memory indexing, and tool execution must remain on the local network or establish direct, point-to-point connections with external services (no middleman hubs).
2.  **Resource Efficiency:** Operating within the constraints of an AMD GPU with 12GB of VRAM requires strict token conservation, lightweight models, and offloading heavy vector operations to native database integrations.
3.  **Idempotency & CLI Supremacy:** The deployment script must be safely re-runnable without destroying existing workspaces, and all configuration must be executed via OpenClaw's official CLI (`openclaw config set`) rather than relying on brittle JSON parsing or manual script overrides.

## 2. Agent Topology & Architecture

The system utilizes three distinct agents, all standardized to use the `lemonade/user.Qwen3.5-4B-GGUF` model to optimize VRAM utilization.

1.  **The General Assistant:** Handles ad-hoc queries and general tasks.
2.  **The Deep Research Agent:** Empowered with extensive native data-gathering skills (`webSearch`, `webScrape`, `newsSearch`, `rssReader`, `trendsFinder`, `xScraper`) via Brave and X APIs to monitor ongoing events and synthesize reports.
3.  **The Developer Agent:** Focused on codebase management and CI/CD pipelines.

**Inference & Memory:**
* **Backend:** Local "Lemonade" server (e.g., `192.168.1.5:8000/v1`).
* **Embedding/Dreaming:** Offloaded to `lemonade/user.nomic-embed-text-v1.5-GGUF`.
* **Vector Search:** Accelerated locally via `sqlite-vec` to preserve compute cycles.

## 3. Key Design Decisions: The "Why"

Throughout development, several pivots were made to adhere to the core philosophies:

### A. Telegram Channel Isolation over Default Orchestrator
OpenClaw ships with a default "orchestrator" routing pattern. This was deliberately disabled in favor of binding each agent to its own dedicated Telegram Bot token. 
* **Why:** Routing multiple agents through a single channel causes severe "token bleed," where irrelevant context is passed back and forth, quickly exhausting the local context window and bogging down inference speeds. Strict channel isolation guarantees pristine, domain-specific context.

### B. Local `stdio` MCP over Hosted Platforms (Composio)
Initially, the project utilized Composio for Git integration. This was entirely stripped out and replaced with the open-source `@zereight/mcp-gitlab` server executed natively via `npx`.
* **Why:** Hosted platforms like Composio route tool requests through third-party cloud infrastructure, violating the privacy requirement and introducing potential subscription costs. 

### C. Open-Source MCP over the Official GitLab Server
We explicitly chose a community-maintained GitLab MCP server over GitLab's official first-party server.
* **Why:** The official server relies on experimental OAuth 2.0 Dynamic Client Registration, which is currently broken on GitLab.com, and it refuses standard Personal Access Tokens (PATs). The open-source alternative robustly supports PATs, ensuring the script executes reliably without failing during authentication.

### D. Intelligent Prompt Seeding (GitOps Workflow)
The script includes a robust loop to detect `SOUL.md`, `USER.md`, and `AGENTS.md` files in the repository and seed them into the agent workspaces (`~/.openclaw/workspace-*`).
* **Why:** This allows the user to version-control agent personas alongside the infrastructure code. A `diff --unified=2` check is implemented to prevent accidental overwrites of live workspace memory if the script is re-run.

## 4. Current State of the Codebase

The `oc-bootstrap.sh` script is fully functional and production-ready for the target environment. It executes the following lifecycle:
1.  **Credential Management:** Safely prompts for and securely stores (`chmod 600`) Telegram tokens, Lemonade IPs, GitLab PATs, and search APIs in a local `.env` file.
2.  **System Prep:** Installs dependencies (`curl`, `git`, `nodejs`, `npm`) and the OpenClaw core.
3.  **Provisioning:** Adds agents, standardizes the Qwen models, and routes embedding to the local Lemonade server.
4.  **Skill & MCP Binding:** Injects keys, enables native scraping skills, and binds the GitLab MCP server globally.
5.  **Channel Isolation:** Binds specific Telegram bots and unbinds defaults.
6.  **Memory Optimization:** Configures SQLite-backed vector search and enables caching.
7.  **Seeding:** Interactively diffs and copies prompt templates.
8.  **Verification:** Starts the gateway and outputs the routing matrix.

## 5. Directives for Future LLM Development

When proposing modifications to this project, adhere strictly to the following constraints:
* **Maintain Bash Rigor:** Ensure `set -euo pipefail` and `set +H` remain intact. Trap errors cleanly.
* **CLI Configuration Only:** Do not introduce `sed`, `awk`, or `jq` to modify OpenClaw JSON files. Always use `openclaw config set`. This was a critical user correction in the past and must be honored.
* **No Cloud Middlemen:** If introducing new tools, prioritize native OpenClaw skills or local `stdio` MCP servers over hosted SaaS integration platforms.
* **Resource Awareness:** Maintain awareness that the target environment relies on local hardware with fixed VRAM constraints. Avoid architectural choices that heavily inflate context window usage.
