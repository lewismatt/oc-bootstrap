# Memory Management

OpenClaw agents use a sophisticated memory system to remember conversations, user preferences, and learned facts. This guide explains how memory works and how to manage it effectively.

---

## 📋 Table of Contents

1. [Memory Overview](#memory-overview)
2. [Memory Types](#memory-types)
3. [Storage Locations](#storage-locations)
4. [Auto-Memory Feature](#auto-memory-feature)
5. [Manual Memory Management](#manual-memory-management)
6. [Memory Search](#memory-search)
7. [Backup and Restore](#backup-and-restore)
8. [Troubleshooting](#troubleshooting)

---

## Memory Overview

### How Agents Remember

OpenClaw uses a multi-layered memory system:

```
┌─────────────────────────────────────────────────┐
│                   Memory System                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │      Short-Term Memory (Session)         │   │
│  │  • Current conversation context          │   │
│  │  • Temporary variables                   │   │
│  │  • Last N messages                      │   │
│  └─────────────────────────────────────────┘   │
│                 │                               │
│                 ▼                               │
│  ┌─────────────────────────────────────────┐   │
│  │      Long-Term Memory (Persistent)       │   │
│  │  • Vector database (embeddings)         │   │
│  │  • USER.md files (preferences)          │   │
│  │  • Conversation history (summarized)    │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Memory Benefits

- **Personalization**: Agents remember your preferences
- **Context Awareness**: Past conversations inform current responses
- **Learning**: Agents improve over time
- **Continuity**: Pick up where you left off

---

## Memory Types

### 1. Episodic Memory (Conversations)

Stores past conversations for context retrieval.

**Storage**: Vector database with embeddings

**Retention**: Configurable (default: 30 days)

**Example**:
```
User: "What's the weather in New York?"
Agent: "I don't have real-time weather access, but..."
[Stored in episodic memory]
```

### 2. Semantic Memory (Facts)

Stores learned facts about the user and world.

**Storage**: USER.md files + vector database

**Retention**: Permanent until explicitly deleted

**Example**:
```markdown
# In USER.md
## Personal Background
- User prefers Python over bash for scripting
- User has AMD GPU with 12GB VRAM
- User's server IP: 192.168.12.100
```

### 3. Procedural Memory (Skills)

Stores learned procedures and workflows.

**Storage**: Agent's SOUL.md + memory store

**Retention**: Permanent

**Example**:
```
Agent learns: "When user asks for file listing, use 'ls -la' format"
[Stored as procedural memory]
```

---

## Storage Locations

### Directory Structure

```
~/.openclaw/
├── agents/
│   ├── assistant/
│   │   ├── memory/
│   │   │   ├── vector-db/       # Vector embeddings
│   │   │   ├── conversations/   # Conversation history
│   │   │   └── facts/           # Learned facts
│   │   ├── USER.md              # User preferences
│   │   ├── SOUL.md              # Agent persona
│   │   └── AGENTS.md            # Permissions
│   │
│   ├── research/
│   │   └── (same structure)
│   │
│   └── developer/
│       └── (same structure)
```

### File Types

| File/Directory | Purpose | Editable |
|----------------|---------|----------|
| `USER.md` | User preferences and context | ✅ Yes |
| `memory/vector-db/` | Vector embeddings (binary) | ❌ No |
| `memory/conversations/` | Conversation logs (JSON) | ⚠️ Advanced |
| `memory/facts/*.json` | Learned facts | ⚠️ Advanced |

---

## Auto-Memory Feature

### What is Auto-Memory?

When enabled, agents automatically update `USER.md` with important information they learn about you.

### Enabling Auto-Memory

**Docker (`docker-config.env`):**

```bash
AUTO_MEMORY=true
```

**Bare Metal (`.env` or environment):**

```bash
export AUTO_MEMORY=true
```

### What Auto-Memory Captures

| Category | Examples |
|----------|----------|
| **Hardware** | GPU model, RAM amount, CPU cores |
| **Preferences** | Response style, language, tools |
| **Projects** | Current work, goals, deadlines |
| **Workflows** | Common tasks, preferred methods |
| **Constraints** | Privacy requirements, limitations |

### Example Auto-Update

**Before:**
```markdown
# USER.md
## Hardware Setup
- GPU: Unknown
```

**Agent learns from conversation:**
```
User: "I just upgraded to an RTX 4070 with 12GB VRAM"
Agent: "Great upgrade! I'll remember that."
[Auto-Memory triggers]
```

**After:**
```markdown
# USER.md
## Hardware Setup
- GPU: NVIDIA RTX 4070 (12GB VRAM)
- Updated: 2026-04-30
```

---

## Manual Memory Management

### Viewing Memory

**List all memories (Docker):**

```bash
docker compose exec openclaw openclaw memory list --agent assistant
```

**List all memories (Bare Metal):**

```bash
openclaw memory list --agent assistant
```

### Searching Memory

**Search for specific information:**

```bash
# Search assistant's memory
openclaw memory search "GPU" --agent assistant

# Search across all agents
openclaw memory search "project deadline"
```

### Adding Memory Manually

**Add a fact directly:**

```bash
openclaw memory add --agent assistant \
  --key "preferred_language" \
  --value "Python" \
  --category "preferences"
```

### Editing USER.md

You can directly edit `USER.md` files:

```bash
# Assistant
nano assistant/USER.md

# Research
nano research/USER.md

# Developer
nano developer/USER.md
```

**Example edit:**

```markdown
## Communication Preferences
**Preferred Language:** English (US)
**Response Style:** Concise, technical

**New Addition:**
- Always provide code examples with comments
- Use markdown tables for comparisons
```

### Deleting Memories

**Delete specific memory:**

```bash
openclaw memory delete --agent assistant --key "old_preference"
```

**Clear all memories (caution!):**

```bash
# Clear assistant memory
openclaw memory clear --agent assistant

# Clear all agents
openclaw memory clear --all
```

---

## Memory Search

### How Semantic Search Works

```
User asks: "What GPU do I have?"
    │
    ▼
Agent creates embedding of query
    │
    ▼
Search vector database for similar embeddings
    │
    ▼
Retrieve top-k most relevant memories
    │
    ▼
Include in agent's context
    │
    ▼
Agent responds: "You have an NVIDIA RTX 4070 with 12GB VRAM"
```

### Search Configuration

**Adjust search parameters in config:**

```bash
# Number of results to retrieve
export MEMORY_SEARCH_TOP_K=5

# Similarity threshold (0.0 to 1.0)
export MEMORY_SIMILARITY_THRESHOLD=0.7

# Search scope
export MEMORY_SEARCH_SCOPE="all"  # or "recent", "facts", etc.
```

### Search Examples

```bash
# Search for hardware-related memories
openclaw memory search "hardware GPU RAM" --agent assistant

# Search for project memories
openclaw memory search "project deadline timeline"

# Search with date range
openclaw memory search "meeting notes" --after 2026-04-01 --before 2026-04-30
```

---

## Backup and Restore

### Backup Memory

**Docker:**

```bash
# Create backup
docker run --rm \
  -v oc-bootstrap_openclaw-data:/data \
  -v $(pwd):/backup ubuntu \
  tar czf /backup/openclaw-memory-backup-$(date +%Y%m%d).tar.gz /data

# Verify
ls -lh openclaw-memory-backup-*.tar.gz
```

**Bare Metal:**

```bash
# Backup ~/.openclaw directory
tar czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz -C ~ .openclaw

# Backup repository (including USER.md files)
tar czf ~/oc-bootstrap-backup-$(date +%Y%m%d).tar.gz \
  -C ~/repos oc-bootstrap
```

### Restore Memory

**Docker:**

```bash
# Stop container
docker compose down

# Restore backup
docker run --rm \
  -v oc-bootstrap_openclaw-data:/data \
  -v $(pwd):/backup ubuntu \
  tar xzf /backup/openclaw-memory-backup-20260430.tar.gz -C /

# Restart
docker compose up -d
```

**Bare Metal:**

```bash
# Restore .openclaw directory
tar xzf ~/openclaw-backup-20260430.tar.gz -C ~

# Restore repository
tar xzf ~/oc-bootstrap-backup-20260430.tar.gz -C ~/repos
```

### Automated Backups

**Create backup script:**

```bash
nano ~/backup-openclaw.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR=~/backups
mkdir -p $BACKUP_DIR

# Backup memory
tar czf $BACKUP_DIR/openclaw-$(date +%Y%m%d-%H%M%S).tar.gz -C ~ .openclaw

# Keep only last 7 days
find $BACKUP_DIR -name "openclaw-*.tar.gz" -mtime +7 -delete

echo "Backup completed: $(ls -t $BACKUP_DIR | head -1)"
```

Make executable and schedule:

```bash
chmod +x ~/backup-openclaw.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add: 0 2 * * * ~/backup-openclaw.sh
```

---

## Troubleshooting

### Issue: Memory Not Persisting

**Symptoms:**
- Agent doesn't remember past conversations
- USER.md changes lost after restart

**Solution:**

```bash
# Check volume mounts (Docker)
docker inspect oc-bootstrap | grep -A 10 "Mounts"

# Should show: openclaw-data mounted to /home/openclaw/.openclaw

# Fix permissions (Bare Metal)
chmod -R u+w ~/.openclaw
chown -R $USER:$USER ~/.openclaw
```

### Issue: Memory Search Not Working

**Symptoms:**
- Search returns no results
- Irrelevant results

**Solution:**

```bash
# Check embedding model
echo $EMBEDDING_MODEL

# Should be set correctly:
# openai/text-embedding-3-small (for OpenAI)
# lemonade/user.Qwen3.5-4B-GGUF (for local)

# Test embedding API
curl https://api.openai.com/v1/embeddings \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"input": "test", "model": "text-embedding-3-small"}'
```

### Issue: USER.md Not Updating

**Symptoms:**
- Auto-Memory enabled but USER.md not changing

**Solution:**

```bash
# Verify AUTO_MEMORY is enabled
echo $AUTO_MEMORY  # Should be "true"

# Check agent permissions (AGENTS.md)
cat assistant/AGENTS.md | grep -i "user.md"

# Should allow: "Update USER.md" or similar

# Restart agent
docker compose restart openclaw
```

### Issue: Memory Database Corrupted

**Symptoms:**
- Errors when searching memory
- Agent crashes on memory operations

**Solution:**

```bash
# Backup first!
cp -r ~/.openclaw ~/.openclaw.backup

# Delete and rebuild vector database
rm -rf ~/.openclaw/agents/*/memory/vector-db/

# Restart (will rebuild on next use)
docker compose restart openclaw
```

---

## Best Practices

1. **Regular Backups**: Schedule automated backups of `~/.openclaw`
2. **Review USER.md**: Periodically review and clean up USER.md files
3. **Meaningful Conversations**: The more context you provide, the better the memory
4. **Explicit Instructions**: Tell agents to "remember this" for important facts
5. **Search Before Asking**: Use `openclaw memory search` to recall information
6. **Version Control**: Commit USER.md changes to track evolution

---

## Memory Configuration Reference

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `AUTO_MEMORY` | `false` | Enable automatic memory updates |
| `MEMORY_SEARCH_TOP_K` | `5` | Number of search results |
| `MEMORY_SIMILARITY_THRESHOLD` | `0.7` | Minimum similarity score |
| `MEMORY_RETENTION_DAYS` | `30` | Days to keep conversation history |
| `EMBEDDING_MODEL` | `openai/text-embedding-3-small` | Model for creating embeddings |

---

## Next Steps

After configuring memory:

1. Test **[Agent Configuration](Agent-Configuration)** with memory enabled
2. Set up **[Chat Channel Isolation](Chat-Channel-Isolation)** for organized conversations
3. Review **[Troubleshooting](Troubleshooting)** for memory-related issues

---

## Additional Resources

- [OpenClaw Documentation](../README.md#memory)
- [Agent Configuration](Agent-Configuration#memory-management)
- [Docker Deployment](Docker-Deployment)
- [API Integrations](API-Integrations)

---

*Last updated: April 2026*
