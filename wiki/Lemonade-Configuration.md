# Lemonade Configuration

Configure Lemonade Server for model serving.

## Installation

### Linux/macOS
```bash
curl -fsSL https://github.com/lemonade-server/lemonade/releases/latest/download/lemonade-linux -o /usr/local/bin/lemonade
chmod +x /usr/local/bin/lemonade
```

## Configuration

### Basic Setup
```bash
# Start server
lemonade serve --port 8080

# Check status
curl http://localhost:8080/health
```

### Environment Variables

- `LEMONADE_PORT`: Server port (default: 8080)
- `LEMONADE_HOST`: Bind address (default: 0.0.0.0)
- `LEMONADE_LOG_LEVEL`: Logging level (debug, info, warn, error)
- `LEMONADE_API_KEY`: Enable API authentication

## API Usage

### List Models
```bash
curl http://localhost:8080/models
```

### Chat Completion
```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Integration with OpenClaw

Set in `docker-config.env`:
```
LEMONADE_URL=http://lemonade-server:8080
OPENCLAW_DEFAULT_MODEL=llama3.2
```

## Troubleshooting

- **Server won't start**: Check port availability
- **Model not found**: Ensure Ollama has model pulled
- **Connection refused**: Verify firewall/network settings
