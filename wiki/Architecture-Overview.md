# Architecture Overview

Understanding the OpenClaw Multi-Agent system architecture helps with configuration, troubleshooting, and customization.

---

## 📋 Table of Contents

1. [System Architecture](#system-architecture)
2. [Core Components](#core-components)
3. [Agent System](#agent-system)
4. [Communication Flow](#communication-flow)
5. [Data Flow](#data-flow)
6. [Security Architecture](#security-architecture)
7. [Deployment Models](#deployment-models)

---

## System Architecture

### High-Level Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Telegram   │  │   Telegram   │  │   Telegram   │    │
│  │  Assistant   │  │  Research    │  │  Developer   │    │
│  │     Bot      │  │     Bot      │  │     Bot      │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  OpenClaw Gateway                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  • Message Routing                                  │    │
│  │  • Authentication & Authorization                   │    │
│  │  • Agent Orchestration                              │    │
│  │  • Memory Indexing                                  │    │
│  │  • Configuration Management                         │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                     Agent Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Assistant  │  │  Research   │  │  Developer  │       │
│  │    Agent    │  │    Agent    │  │    Agent    │       │
│  │             │  │             │  │             │       │
│  │ • General   │  │ • Web      │  │ • Code      │       │
│  │   Purpose   │  │   Research │  │   Writing   │       │
│  │ • Task      │  │ • Data     │  │ • Debugging │       │
│  │   Planning  │  │   Analysis │  │ • CI/CD     │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   LLM API    │  │   Lemonade  │  │   Memory    │       │
│  │  (OpenAI/    │  │   Server    │  │   Store     │       │
│  │   Anthropic) │  │  (Local)    │  │             │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   Vector    │  │   Search    │  │   GitHub    │       │
│  │   Database  │  │   API       │  │   API       │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```text

---

## Core Components

### 1. OpenClaw Gateway

**Purpose**: Central orchestration hub

**Responsibilities**:
- Route messages between users and agents
- Manage agent lifecycle
- Handle authentication (Telegram bot tokens)
- Index and search memory
- Manage configuration

**Key Files**:
- `oc-bootstrap.sh` - Installation script
- Configuration stored in `~/.openclaw/config/`

### 2. Agent Runtime

**Purpose**: Execute agent logic

**Each agent includes**:
- **SOUL.md** - Agent persona and behavior
- **USER.md** - User context and preferences
- **AGENTS.md** - Git protocol and permissions
- **Memory Store** - Persistent memory (vector database)

**Isolation**: Each agent runs in its own workspace with separate:
- Memory storage
- Configuration
- Telegram chat channel

### 3. Inference Backend

**Cloud APIs**:
- OpenAI API (GPT-4o, GPT-3.5, embeddings)
- Anthropic API (Claude 3.5 Sonnet, etc.)
- Other LLM providers

**Local Inference**:
- Lemonade Server
- Supports GGUF models (Qwen, Llama, Mistral, etc.)
- GPU acceleration (CUDA/ROCm)

### 4. Memory System

**Components**:
- **Vector Database** - Stores embeddings for semantic search
- **File-based Memory** - USER.md, conversation history
- **Auto-Memory** - Automatic learning and updates

**Storage Location**: `~/.openclaw/agents/<agent>/memory/`

---

## Agent System

### Agent Hierarchy

```text
Assistant Agent (Team Lead)
    ├── Research Agent (Subordinate - Web Research)
    └── Developer Agent (Subordinate - Code & Infrastructure)
```text

### Agent Specializations

| Agent | Primary Role | Key Capabilities |
|-------|--------------|------------------|
| **Assistant** | General-purpose helper | • Answer questions<br>• Task planning<br>• Personal assistance<br>• Agent orchestration |
| **Research** | Web research specialist | • Web search<br>• Data scraping<br>• News aggregation<br>• Source verification |
| **Developer** | Coding expert | • Code writing/debugging<br>• Repository analysis<br>• CI/CD management<br>• Shell scripting |

### Inter-Agent Communication

```text
User → Assistant Bot → Assistant Agent
                              │
                              ├─→ Delegates to Research Agent (web research)
                              │
                              └─→ Delegates to Developer Agent (code tasks)
```text

**Delegation Criteria**:
- Task complexity
- Required expertise
- Time estimation
- Resource requirements

---

## Communication Flow

### Incoming Message Flow

```text
1. User sends message in Telegram
   │
2. Telegram Bot API receives message
   │
3. OpenClaw Gateway receives webhook/update
   │
4. Gateway authenticates bot token
   │
5. Gateway routes to correct agent
   │
6. Agent processes message
   │
7. Agent generates response
   │
8. Gateway sends response via Telegram API
   │
9. User receives response in Telegram
```text

### Outgoing Request Flow (Agent to API)

```text
1. Agent needs to call external API (e.g., OpenAI)
   │
2. Agent checks configuration for API key
   │
3. Agent constructs API request
   │
4. Request sent through Gateway (optional proxy)
   │
5. External API processes request
   │
6. Response returned to Agent
   │
7. Agent processes response
   │
8. Agent updates memory (if needed)
   │
9. Agent prepares user response
```text

---

## Data Flow

### Memory Write Path

```text
Agent generates response
    │
    ├─→ Short-term: Conversation history (session)
    │
    └─→ Long-term: Vector database (persistent)
            │
            ├─→ Create embedding (using embedding model)
            │
            └─→ Store in vector DB with metadata
```text

### Memory Read Path (Retrieval)

```text
User asks question
    │
Agent needs context
    │
    ├─→ Generate query embedding
    │
    ├─→ Search vector DB for similar memories
    │
    ├─→ Retrieve top-k relevant memories
    │
    └─→ Include in agent prompt context
```text

### Configuration Data Flow

```text
docker-config.env (or .env)
    │
    ▼
OpenClaw Gateway loads environment
    │
    ├─→ Passes to Agent Runtime
    │
    ├─→ Configures API clients
    │
    └─→ Sets agent parameters (model, temperature, etc.)
```text

---

## Security Architecture

### Authentication Layers

```text
┌─────────────────────────────────────────┐
│         Telegram Bot Token               │  ← Layer 1: Bot Authentication
│  (Validates bot-to-Gateway communication)│
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         API Keys (OpenAI, Anthropic)     │  ← Layer 2: Backend API Authentication
│  (Stored in environment, never logged)  │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         User Whitelist (Optional)        │  ← Layer 3: User Authorization
│  (TELEGRAM_ALLOWED_USERS_* variables)   │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         Agent Permissions (AGENTS.md)    │  ← Layer 4: Agent Capability Restrictions
│  (What each agent can read/write)       │
└─────────────────────────────────────────┘
```text

### Data Isolation

| Data Type | Isolation Level | Storage |
|-----------|-----------------|---------|
| Agent Memory | Per-agent | `~/.openclaw/agents/<agent>/memory/` |
| User Context | Per-agent | `<agent>/USER.md` |
| Conversation History | Per-chat | In-memory (session) + persistent |
| Configuration | Shared (Gateway) | `~/.openclaw/config/` |

### Network Security

**Docker Deployment**:
- Containers on isolated bridge network
- Only necessary ports exposed
- Environment variables not accessible from outside

**Bare Metal Deployment**:
- Firewall (UFW) restricts access
- Services bind to localhost when possible
- SSH key-based authentication

---

## Deployment Models

### Model 1: Docker Deployment (Recommended)

**Characteristics**:
- All components in containers
- Easy scaling and updates
- Isolated environments
- Volume-based persistence

**Best For**:
- Production deployments
- Multi-user setups
- Easy maintenance

**Architecture**:
```text
Docker Host
├── oc-bootstrap container (Gateway + Agents)
├── lemonade-server container (optional)
└── Shared volumes for persistence
```text

### Model 2: Bare Metal Installation

**Characteristics**:
- Direct installation on host OS
- Full system access
- Better performance (no container overhead)
- Manual dependency management

**Best For**:
- Single-user setups
- Development environments
- Maximum performance requirements

**Architecture**:
```text
Ubuntu 24.04 Host
├── OpenClaw Gateway (systemd service)
├── Agent processes
└── Local file system storage
```text

### Model 3: Hybrid (Development)

**Characteristics**:
- Gateway in Docker
- Lemonade on host (for GPU access)
- Bind mounts for live code editing

**Best For**:
- Development and testing
- Debugging agent behavior
- Custom agent development

---

## Scalability Considerations

### Horizontal Scaling

```text
Load Balancer
    │
    ├─→ Gateway Instance 1 (with Agent subset)
    ├─→ Gateway Instance 2 (with Agent subset)
    └─→ Gateway Instance 3 (with Agent subset)
```text

**Note**: Current implementation is vertical scaling (single instance).

### Vertical Scaling

| Resource | Minimum | Recommended | High Performance |
|----------|----------|-------------|------------------|
| CPU | 4 cores | 8 cores | 16+ cores |
| RAM | 8GB | 32GB | 64GB+ |
| GPU | Optional | 12GB VRAM | 24GB+ VRAM |
| Storage | 20GB SSD | 100GB NVMe | 500GB+ NVMe |

---

## Technology Stack

### Runtime
- **Node.js 22.x** - Gateway and agent runtime
- **Python 3.11+** - Lemonade Server (optional)

### Frameworks & Libraries
- **OpenClaw Core** - Agent framework
- **Telegram Bot API** - Messaging interface
- **Vector DB** - Memory storage (embeddings)

### Containerization
- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration

### Supported LLM Providers
- OpenAI (GPT-4o, GPT-3.5, embeddings)
- Anthropic (Claude 3.5 Sonnet, etc.)
- Local (Lemonade Server with GGUF models)

---

## Next Steps

Now that you understand the architecture:

1. Choose your **[Deployment Model](Docker-Deployment)** (Docker or Bare Metal)
2. Configure **[Agent Personas](Agent-Configuration)**
3. Set up **[Telegram Bots](Chat-Channel-Isolation)**
4. Optionally configure **[Lemonade Server](Lemonade-Configuration)** for local inference

---

## Additional Resources

- [OpenClaw GitHub Repository](https://github.com/openclaw/oc-bootstrap)
- [README.md](../README.md) - Project overview
- [DOCKER.md](../DOCKER.md) - Docker-specific documentation
- [Contributing Guide](../CONTRIBUTING.md)

---

*Last updated: April 2026*
