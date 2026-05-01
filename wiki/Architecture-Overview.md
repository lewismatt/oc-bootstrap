# Architecture Overview

OpenClaw Bootstrap provides a multi-agent AI system architecture.

## System Components

### Core Components

1. **OpenClaw Core**
   - Main application logic
   - Agent orchestration
   - Memory management

2. **Ollama**
   - Local model serving
   - Supports multiple model types
   - REST API for inference

3. **Lemonade Server**
   - Alternative model serving
   - API-compatible with OpenAI
   - Scalable deployment

### Agent System

```
┌─────────────────────────────────────┐
│                    OpenClaw Core                    │
├─────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │Assistant│  │Developer│  │Research │ ...  │
│  └──────────┘  └──────────┘  └──────────┘      │
└──────────────────────┬────────────────────────────┘
                       │
        ┌──────────┴──────────┐
        │                         │
  ┌─────▼─────┐        ┌─────▼─────┐
  │  Ollama   │        │Lemonade   │
  │  Server   │        │  Server   │
  └───────────┘        └───────────┘
```

## Data Flow

1. User input → OpenClaw Core
2. Core routes to appropriate agent
3. Agent processes and may query models
4. Model inference via Ollama/Lemonade
5. Response returned to user

## Memory Backends

- **File**: Simple file-based storage (default)
- **Redis**: In-memory cache, fast access
- **PostgreSQL**: Persistent, relational storage

## Network Architecture

All components communicate via REST APIs over HTTP.
Docker networking uses bridge network for isolation.
