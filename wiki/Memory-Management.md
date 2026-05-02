# Memory Management

OpenClaw supports multiple memory backends for agent state.

## Memory Backends

### File-Based (Default)
- **Pros**: Simple, no dependencies
- **Cons**: Slower access, not scalable
- **Config**: `OPENCLAW_MEMORY_BACKEND=file`
- **Path**: `$OPENCLAW_HOME/memory/`

### Redis
- **Pros**: Fast, in-memory, scalable
- **Cons**: Requires Redis server
- **Config**: `OPENCLAW_MEMORY_BACKEND=redis`
- **Connection**: Configured via Redis client

### PostgreSQL
- **Pros**: Persistent, relational, ACID
- **Cons**: Heavier setup, requires DB
- **Config**: `OPENCLAW_MEMORY_BACKEND=postgres`
- **Connection**: Configure DB connection string

## Configuration

### File Backend
```bash
OPENCLAW_MEMORY_BACKEND=file
OPENCLAW_MEMORY_PATH=/opt/openclaw/memory
```

### Redis Backend
```bash
OPENCLAW_MEMORY_BACKEND=redis
OPENCLAW_REDIS_HOST=localhost
OPENCLAW_REDIS_PORT=6379
```

### PostgreSQL Backend
```bash
OPENCLAW_MEMORY_BACKEND=postgres
OPENCLAW_PG_HOST=localhost
OPENCLAW_PG_PORT=5432
OPENCLAW_PG_DB=openclaw
OPENCLAW_PG_USER=openclaw
OPENCLAW_PG_PASS=secret
```

## Migration

To migrate between backends:
1. Export from current backend
2. Change configuration
3. Import to new backend
4. Verify data integrity
