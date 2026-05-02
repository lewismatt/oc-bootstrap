# OpenClaw Multi-Agent Bootstrapper: Project Context & Architecture

This document serves as the foundational context for the `oc-bootstrap` project.
It outlines the project's goals, architectural decisions, and the evolutionary
steps that led to the current state of the codebase. Provide this document, along
with `oc-bootstrap.sh` and `README.md`, to any LLM to ensure consistent and
aligned future development.

## 1. Project Overview & Desired Outcomes

**Project Name:** OpenClaw Multi-Agent Bootstrapper (`oc-bootstrap`)
**Target Environment:** Bare-metal Ubuntu 24.04

**Primary Goal:** To create an automated, idempotent, GitOps-style deployment
script that provisions a strictly isolated, local-first, multi-agent OpenClaw
environment.

**Core Philosophies:**

1. **Absolute Privacy:** Zero cloud data leakage. All inference, memory
    indexing, and tool execution must remain on the local network or establish
    direct, point-to-point connections with external services (no middleman hubs).
2. **Resource Efficiency:** The project is designed to work effectively with
    12 GB of GPU VRAM as a recommended minimum through strict token conservation, lightweight
    models, and offloading heavy vector operations to native database integrations. It can be
    deployed on systems with less VRAM, though performance will be reduced; additional VRAM
    enables larger models and better responsiveness.
3. **Idempotency & CLI Supremacy:** The deployment script must be safely
    re-runnable without destroying existing workspaces, and all configuration
    must be executed via OpenClaw's official CLI (`openclaw config set`) rather
    than relying on brittle JSON parsing or manual script overrides.

## 2. Agent Topology & Architecture

The system utilizes three distinct agents, each configurable with the user's choice
of local LLMs (e.g., `lemonade/user.Qwen3.5-4B-GGUF`) to optimize performance and
VRAM utilization.

1. **The General Assistant:** Handles ad-hoc queries, general tasks, and daily
    life scheduling for the user.
2. **The Deep Research Agent:** Empowered with extensive native data-gathering
    skills (`webSearch`, `webScrape`, `newsSearch`, `rssReader`, `trendsFinder`,
    `xScraper`) via Brave and X APIs to monitor ongoing events and synthesize reports.
3. **The Developer Agent:** Focused on codebase management, local MCP
    orchestration, and CI/CD pipelines.

**Inference & Memory:**

* **Backend:** Local "Lemonade" server.
* **Embedding:** User-defined (e.g.,
    `lemonade/user.nomic-embed-text-v1.5-GGUF`).
* **Dreaming:** Uses the User-defined Assistant Model.
* **Vector Search:** Accelerated locally via `sqlite-vec` to preserve compute
    cycles.

## 3. Key Design Decisions: The "Why"

### A. Telegram Channel Isolation over Default Orchestrator

OpenClaw's default "orchestrator" pattern was disabled in favor of binding each
agent to its own dedicated Telegram Bot token.

* **Why:** Prevents "token bleed" where irrelevant context is passed between
    agents, which would otherwise exhaust the limited local context window and
    slow down inference on the AMD hardware.

### B. Universal Local GitLab MCP Integration

Initially limited to the Developer, Git access via the open-source
`@zereight/mcp-gitlab` server has been expanded to **all three agents**.

* **Why:** This creates a universal, version-controlled "Project Memory." The
    Research agent commits logs, and the Assistant can update user context files
    (`USER.md`) natively over `stdio`.

### C. Autonomous Operational Hooks

The project now implements native OpenClaw hooks to reduce manual overhead.

* **autoMemory (Assistant):** Automatically records evolving hardware
    preferences or ski schedules.
* **sessionSummarize (Research):** Condenses deep research sessions to prevent
    context bloat.
* **toolValidation (Developer):** Ensures technical accuracy for Git-based code
    modifications.

### D. Intelligent Prompt Seeding (GitOps Workflow)

The script seeds `SOUL.md`, `USER.md`, and `AGENTS.md` files into agent
workspaces (`~/.openclaw/workspace-*`), but only for agents that have a matching
subdirectory in the repository.

* **Why:** Allows version-controlling agent personas alongside infrastructure. A
    `diff -u` check prevents accidental overwrites of existing workspace data.

## 4. Current State of the Codebase

The `oc-bootstrap.sh` script is a production-ready deployment tool that manages
the full agent lifecycle:

1. **Credential Management:** Securely stores (`chmod 600`) tokens for Telegram,
    Lemonade, GitLab, Brave, and X. Validates Telegram tokens against the Telegram
    API and checks for existing secrets files with overwrite protection.
2. **Infrastructure Provisioning:** Configures user-selected models, maps local
    inference with OpenAI-compatible API interface (backed by Lemonade), and
    configures `sqlite-vec` memory with embedding cache and session indexing.
3. **Skill & Hook Deployment:** Unlocks advanced scraping skills on Research agent
    and autonomous operational hooks on all three agents.
4. **Binding & Isolation:** Enforces strict Telegram channel isolation, binds GitLab
    MCP server to all agents for shared version control, and provisions isolated
    workspace directories for each agent.

## 5. Directives for Future LLM Development

When proposing modifications, adhere strictly to these constraints:

* **Maintain Bash Rigor:** Ensure `set -euo pipefail` and `set +o histexpand`
    remain intact.
* **CLI Configuration Only:** Always use `openclaw config set`. Do not suggest
    manual JSON parsing.
* **Zero Cloud Middlemen:** Prioritize native skills or local `stdio` MCP
    servers over hosted SaaS platforms.
* **Resource Awareness:** Optimize for systems with 12 GB VRAM minimum, balancing token
    conservation and model selection. Designs should scale gracefully for both constrained
    and resource-rich deployments.
