# Agent Configuration

OpenClaw uses three specialized AI agents, each with their own configuration files. This guide explains how to customize agent personalities, behaviors, and capabilities.

---

## 📋 Table of Contents

1. [Agent Overview](#agent-overview)
2. [Configuration Files](#configuration-files)
3. [Assistant Agent](#assistant-agent)
4. [Research Agent](#research-agent)
5. [Developer Agent](#developer-agent)
6. [Customizing Agent Personas](#customizing-agent-personas)
7. [Memory Management](#memory-management)
8. [Inter-Agent Communication](#inter-agent-communication)

---

## Agent Overview

OpenClaw includes three pre-configured agents, each designed for specific tasks:

| Agent | Directory | Primary Role | Model Default |
|-------|-----------|--------------|---------------|
| **Assistant** | `assistant/` | General-purpose helper | openai/gpt-4o |
| **Research** | `research/` | Web research specialist | openai/gpt-4o |
| **Developer** | `developer/` | Coding expert | anthropic/claude-3-5-sonnet-latest |

Each agent runs in an isolated workspace with:
- Separate memory storage
- Independent configuration
- Isolated Telegram chat channel
- Custom system prompts

---

## Configuration Files

Each agent has three configuration files in their respective directory:

### File Structure

```
assistant/
├── AGENTS.md      # Git protocol and update permissions
├── SOUL.md        # Agent persona and behavior
└── USER.md        # User context and preferences
```

### File Purposes

| File | Purpose | Editable |
|------|---------|----------|
| `AGENTS.md` | Defines what the agent can update in the repository | ⚠️ Advanced |
| `SOUL.md` | Agent's personality, capabilities, and communication style | ✅ Yes |
| `USER.md` | Your preferences and context for this agent | ✅ Yes |

---

## Assistant Agent

The Assistant is your general-purpose AI helper and team lead.

### Default SOUL.md

```markdown
# Agent Persona: The Assistant

## Core Identity
You are a highly efficient, local-first technical assistant. Your primary
purpose is to provide direct, actionable help while respecting the user's
hardware constraints and preference for privacy.

## Communication Style
* **Concise & Practical:** Avoid verbose explanations unless specifically requested
* **Privacy-Aware:** Never suggest cloud services unless explicitly requested
* **Resource-Conscious:** Consider hardware limitations

## Capabilities
* **General Knowledge:** Answer questions on various topics
* **Task Planning:** Help organize and prioritize activities
* **File Management:** Assist with local file operations
* **Personal Assistant:** Track preferences and reminders

## Collaboration with Other Agents
* **Research Agent:** Request web research and data gathering
* **Developer Agent:** Escalate complex coding tasks
```

### Customizing Assistant

Edit `assistant/SOUL.md` to change the agent's personality:

```bash
nano assistant/SOUL.md
```

**Example customization:**

```markdown
## Communication Style
* **Detailed Explanations:** Provide thorough explanations with examples
* **Proactive Suggestions:** Offer recommendations before being asked
* **Learning Mode:** Adapt responses based on user's growing expertise
```

### USER.md Configuration

The `assistant/USER.md` file stores your personal context:

```markdown
# User Context

## Communication Preferences
**Preferred Language:** English (US)
**Response Style:** Concise, technical

## Personal Background
**Hardware Setup:**
- GPU: AMD Radeon (12 GB VRAM)
- RAM: 32 GB
- Storage: 1 TB NVMe SSD

**Primary Use Cases:**
1. Managing local AI inference server
2. Automating file processing
3. Personal task management
```

Update this file as your needs evolve - the Assistant will reference it automatically.

---

## Research Agent

The Research agent specializes in web research, data gathering, and analysis.

### Key Capabilities

- Web search and scraping
- News aggregation
- Data analysis and trend identification
- Source verification and citation

### Configuration Example

Edit `research/SOUL.md`:

```markdown
# Agent Persona: The Research Specialist

## Core Identity
You are a thorough research specialist focused on accuracy and source verification.

## Research Methodology
* **Source Diversity:** Always consult multiple sources
* **Citation Required:** Provide sources for all factual claims
* **Date Awareness:** Note when information might be outdated

## Specialized Tools
* Web search APIs (Brave Search)
* News aggregation services
* Data scraping with ethical boundaries

## Output Format
* Executive summary first
* Detailed findings with sources
* Confidence levels for each claim
```

### Research-Specific Settings

In your environment configuration:

```bash
# Enable web search
BRAVE_SEARCH_API_KEY=your_brave_api_key

# Research agent model (requires web access capability)
RESEARCH_MODEL=openai/gpt-4o
```

---

## Developer Agent

The Developer agent handles coding tasks, infrastructure changes, and technical implementation.

### Key Capabilities

- Code writing and debugging
- Repository analysis
- CI/CD pipeline management
- Infrastructure as Code (IaC)
- Shell scripting

### Configuration Example

Edit `developer/SOUL.md`:

```markdown
# Agent Persona: The Developer

## Core Identity
You are an expert software developer with focus on clean, maintainable code.

## Coding Standards
* **Language:** Prefer Python for scripts, Shell for system tasks
* **Documentation:** Include docstrings and comments
* **Error Handling:** Always include proper exception handling
* **Testing:** Suggest tests for critical functionality

## Specialized Knowledge
* Ubuntu/Linux system administration
* Docker and containerization
* Git version control best practices
* Shell scripting (bash)

## Collaboration
* Review code before suggesting changes
* Explain architectural decisions
* Consider backward compatibility
```

### Developer-Specific Settings

```bash
# GitHub integration for repository access
GITHUB_PAT=your_github_personal_access_token

# Developer agent model (benefits from larger context)
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
```

---

## Customizing Agent Personas

### Step 1: Choose an Agent to Modify

```bash
cd /path/to/oc-bootstrap
# Options: assistant/, research/, developer/
```

### Step 2: Edit the SOUL.md File

```bash
nano assistant/SOUL.md
```

### Step 3: Modify Sections

**Common sections to customize:**

| Section | Description |
|---------|-------------|
| `Core Identity` | Agent's role and purpose |
| `Communication Style` | How the agent communicates |
| `Capabilities` | What the agent can do |
| `Personality Traits` | Tone, formality, proactivity |

### Step 4: Commit Changes

```bash
git add assistant/SOUL.md
git commit -m "Customize Assistant agent persona"
git push origin main
```

---

## Memory Management

### How Agent Memory Works

Agents use a memory system to remember:
- User preferences
- Past conversations
- Task history
- Learned facts

### Memory Storage Locations

| Agent | Memory Path |
|-------|-------------|
| Assistant | `~/.openclaw/agents/assistant/memory/` |
| Research | `~/.openclaw/agents/research/memory/` |
| Developer | `~/.openclaw/agents/developer/memory/` |

### Auto-Memory Feature

When enabled, agents automatically update `USER.md` with important information:

```bash
# Enable auto-memory in configuration
export AUTO_MEMORY=true
```

Agents will proactively update:
- Hardware changes
- New preferences
- Recurring tasks
- Important facts

### Manual Memory Updates

Agents can also update their `USER.md` files when they learn something important:

```markdown
## Recent Updates (by Agent)
* [2026-04-30] User prefers Python over bash for data processing
* [2026-04-29] Added new project: Log analysis automation
```

---

## Inter-Agent Communication

### Delegation Pattern

The Assistant acts as team lead and can delegate tasks:

**Example delegation:**

```
User: "Research the latest Python web frameworks and create a comparison table"

Assistant:
  1. Delegates to Research Agent: "Research Python web frameworks 2026"
  2. Research Agent returns findings
  3. Assistant delegates to Developer Agent: "Create comparison table"
  4. Developer Agent formats and returns table
  5. Assistant presents final result to user
```

### Configuring Agent Collaboration

In `assistant/SOUL.md`, define collaboration rules:

```markdown
## Collaboration with Other Agents

**When to delegate to Research:**
- Real-time information needed
- Multiple source verification required
- News or trend analysis

**When to delegate to Developer:**
- Code writing/editing needed
- Infrastructure changes
- Complex technical implementation

**Escalation criteria:**
- Task requires >10 minutes
- Multiple steps involved
- External API integration needed
```

---

## Advanced Configuration

### Custom System Prompts

For advanced users, you can override the default system prompt:

```bash
# In agent's environment or config
export SYSTEM_PROMPT_OVERRIDE="You are a specialized agent for..."
```

### Model Selection per Agent

Configure different models for each agent in `docker-config.env` or `.env`:

```bash
# Powerful model for complex tasks
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest

# Cost-effective model for simple tasks
ASSISTANT_MODEL=openai/gpt-4o-mini

# Fast model for research
RESEARCH_MODEL=openai/gpt-4o-mini
```

### Tool Access Control

Control which tools each agent can access via `AGENTS.md`:

```markdown
# developer/AGENTS.md

## Allowed Operations
* Read/write repository files
* Execute shell commands
* Access GitHub API
* Modify CI/CD pipelines

## Restricted Operations
* Delete repository files (require user confirmation)
* Modify other agents' workspaces
* Change system configuration outside workspace
```

---

## Troubleshooting

### Agent Not Responding

```bash
# Check agent status (Docker)
docker compose logs openclaw | grep -i "assistant"

# Check agent status (Bare Metal)
openclaw status
```

### Agent Personality Not Applied

```bash
# Verify SOUL.md exists and is valid
cat assistant/SOUL.md

# Restart agent to reload configuration
docker compose restart openclaw
```

### Memory Not Persisting

```bash
# Check volume mounts (Docker)
docker inspect oc-bootstrap | grep openclaw-data

# Check permissions (Bare Metal)
ls -la ~/.openclaw/agents/
```

### Agent Using Wrong Model

```bash
# Verify environment variables
echo $ASSISTANT_MODEL
echo $RESEARCH_MODEL
echo $DEVELOPER_MODEL

# Check docker-config.env
cat docker-config.env | grep MODEL
```

---

## Best Practices

1. **Keep USER.md Updated**: Regularly review and update user context files
2. **Version Control**: Commit SOUL.md changes to track persona evolution
3. **Test Changes**: Apply small changes and verify agent behavior
4. **Document Customizations**: Add comments explaining why you customized something
5. **Backup Configs**: Keep copies of working configurations before major changes

---

## Example: Complete Custom Configuration

See `assistant/SOUL.md`, `research/SOUL.md`, and `developer/SOUL.md` in the repository for complete examples.

---

## Next Steps

After configuring your agents:

1. Set up **[Chat Channel Isolation](Chat-Channel-Isolation)** for separate Telegram channels
2. Configure **[Lemonade Configuration](Lemonade-Configuration)** for local inference
3. Review **[Troubleshooting](Troubleshooting)** for common issues

---

## Additional Resources

- [OpenClaw Architecture](../README.md#architecture)
- [Agent Protocol Documentation](../assistant/AGENTS.md)
- [Docker Deployment](Docker-Deployment)
- [Telegram Bot Setup](#chat-channel-isolation)

---

*Last updated: April 2026*
