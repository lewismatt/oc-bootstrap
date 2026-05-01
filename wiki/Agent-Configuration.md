# Agent Configuration

OpenClaw uses specialized agents to handle different tasks.

## Agent Types

### Assistant Agent
- **Role**: User support and documentation
- **Config**: `assistant/AGENTS.md`
- **Soul**: `assistant/SOUL.md`
- **User Guide**: `assistant/USER.md`

### Developer Agent
- **Role**: Code development and implementation
- **Config**: `developer/AGENTS.md`
- **Soul**: `developer/SOUL.md`
- **User Guide**: `developer/USER.md`

### Research Agent
- **Role**: Technology research and evaluation
- **Config**: `research/AGENTS.md`
- **Soul**: `research/SOUL.md`
- **User Guide**: `research/USER.md`

### OpenClaw Maintainer
- **Role**: Infrastructure and release management
- **Config**: `.github/agents/openclaw-maintainer.agent.md`
- **Tools**: GitLab MCP, CI/CD, Docker

## Configuration Files

Each agent has three configuration files:

1. **AGENTS.md**: Technical configuration and responsibilities
2. **SOUL.md**: Personality, values, and capabilities
3. **USER.md**: User-facing guide on how to interact

## Customizing Agents

Edit the configuration files to:
- Change agent personality
- Modify responsibilities
- Update tools and capabilities
- Adjust collaboration patterns

## Adding New Agents

1. Create new directory: `mkdir new-agent/`
2. Create config files: `AGENTS.md`, `SOUL.md`, `USER.md`
3. Update OpenClaw main config to recognize new agent
4. Restart OpenClaw services
