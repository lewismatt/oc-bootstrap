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

1.  **The General Assistant:** Handles ad-hoc queries, general tasks, and daily life scheduling for the user in Nederland, CO.
2.  **The Deep Research Agent:** Empowered with extensive native data-gathering skills (`webSearch`, `webScrape`, `newsSearch`, `rssReader`, `trendsFinder`, `xScraper`) via Brave and X APIs to monitor ongoing events (NBA, Ski Resorts, local concerts) and synthesize reports.
3.  **The Developer Agent:** Focused on codebase management, local MCP orchestration, and CI/CD pipelines.

**Inference & Memory:**
* **Backend:** Local "Lemonade" server.
* **Embedding/Dreaming:** Offloaded to `lemonade/user.nomic-embed-text-v1.5-GGUF`.
* **Vector Search:** Accelerated locally via `sqlite-vec` to preserve compute cycles.

## 3. Key Design Decisions: The "Why"

### A. Telegram Channel Isolation over Default Orchestrator
OpenClaw's default "orchestrator" pattern was disabled in favor of binding each agent to its own dedicated Telegram Bot token. 
* **Why:** Prevents "token bleed" where irrelevant context is passed between agents, which would otherwise exhaust the limited local context window and slow down inference on the AMD hardware.

### B. Universal Local GitLab MCP Integration
Initially limited to the Developer, Git access via the open-source `@zereight/mcp-gitlab` server has been expanded to **all three agents**. 
* **Why:** This creates a universal, version-controlled "Project Memory." The Research agent commits logs, and the Assistant can update user context files (`USER.md`) natively over `stdio`.

### C. Autonomous Operational Hooks
The project now implements native OpenClaw hooks to reduce manual overhead.
* **autoMemory (Assistant):** Automatically records evolving hardware preferences or ski schedules.
* **sessionSummarize (Research):** Condenses deep research sessions to prevent context bloat.
* **toolValidation (Developer):** Ensures technical accuracy for Git-based code modifications.

### D. Intelligent Prompt Seeding (GitOps Workflow)
The script seeds `SOUL.md`, `USER.md`, and `AGENTS.md` files into agent workspaces (`~/.openclaw/workspace-*`).
* **Why:** Allows version-controlling agent personas alongside infrastructure. A `diff --unified=2` check prevents accidental overwrites of existing workspace data.

## 4. Current State of the Codebase

The `oc-bootstrap.sh` script is a production-ready deployment tool that manages the full agent lifecycle:
1.  **Credential Management:** Securely stores (`chmod 600`) tokens for Telegram, Lemonade, GitLab, Brave, and X.
2.  **Infrastructure Provisioning:** Standardizes models, maps local inference, and configures `sqlite-vec` memory.
3.  **Skill & Hook Deployment:** Unlocks advanced scraping skills and autonomous operational hooks.
4.  **Binding & Isolation:** Enforces strict Telegram channel isolation.

## 5. Directives for Future LLM Development

When proposing modifications, adhere strictly to these constraints:
* **Maintain Bash Rigor:** Ensure `set -euo pipefail` and `set +H` remain intact.
* **CLI Configuration Only:** Always use `openclaw config set`. Do not suggest manual JSON parsing.
* **Zero Cloud Middlemen:** Prioritize native skills or local `stdio` MCP servers over hosted SaaS platforms.
* **Resource Awareness:** Honor the 12GB VRAM constraint and optimize for token conservation.
