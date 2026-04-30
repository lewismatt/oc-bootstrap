# API Integrations

OpenClaw supports various external APIs to enhance agent capabilities. This guide covers configuration and usage of supported API integrations.

---

## 📋 Table of Contents

1. [Supported APIs](#supported-apis)
2. [Configuration Overview](#configuration-overview)
3. [OpenAI API](#openai-api)
4. [Anthropic API](#anthropic-api)
5. [Brave Search API](#brave-search-api)
6. [GitHub API](#github-api)
7. [Other Integrations](#other-integrations)
8. [API Usage Tracking](#api-usage-tracking)
9. [Troubleshooting](#troubleshooting)

---

## Supported APIs

### Available Integrations

| API | Purpose | Required For |
|-----|---------|--------------|
| **OpenAI** | LLM inference, embeddings | Assistant, Research, Developer agents (cloud mode) |
| **Anthropic** | Claude LLM inference | Developer agent (optional) |
| **Brave Search** | Web search | Research agent |
| **GitHub** | Repository operations | Developer agent |
| **Lemonade** | Local LLM inference | All agents (local mode) |

---

## Configuration Overview

### Docker Configuration (`docker-config.env`)

```bash
# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Brave Search
BRAVE_SEARCH_API_KEY=BSA...

# GitHub
GITHUB_PAT=ghp_...

# Lemonade (local)
LEMONADE_KEY=local-dummy-key
LEMONADE_IP=192.168.12.50  # Optional
```text

### Bare Metal Configuration (`.env` or environment)

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export BRAVE_SEARCH_API_KEY="BSA..."
export GITHUB_PAT="ghp_..."
```text

---

## OpenAI API

### Overview

OpenAI provides:
- **GPT-4o, GPT-3.5**: Language models for agent responses
- **Text Embeddings**: For memory search and semantic similarity

### Getting API Key

1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to "API Keys"
4. Click "Create new secret key"
5. Copy and save the key securely

### Configuration

**Docker (`docker-config.env`):**

```bash
OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwxyz

# Model selection
ASSISTANT_MODEL=openai/gpt-4o
RESEARCH_MODEL=openai/gpt-4o
DEVELOPER_MODEL=openai/gpt-4o
EMBEDDING_MODEL=openai/text-embedding-3-small
```text

**Bare Metal:**

```bash
export OPENAI_API_KEY="sk-..."
export ASSISTANT_MODEL="openai/gpt-4o"
```text

### Available Models

| Model | Context Window | Use Case |
|-------|----------------|----------|
| `gpt-4o` | 128k tokens | High-quality responses |
| `gpt-4o-mini` | 128k tokens | Fast, cost-effective |
| `gpt-3.5-turbo` | 16k tokens | Legacy, cheaper |
| `text-embedding-3-small` | 8191 tokens | Embeddings (efficient) |
| `text-embedding-3-large` | 8191 tokens | Embeddings (high quality) |

### Testing OpenAI API

```bash
# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Test chat completion
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```text

---

## Anthropic API

### Overview

Anthropic provides Claude models, known for:
- Strong reasoning capabilities
- Long context windows
- Good code understanding

### Getting API Key

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to "API Keys"
4. Click "Create Key"
5. Copy and save securely

### Configuration

**Docker (`docker-config.env`):**

```bash
ANTHROPIC_API_KEY=sk-ant-abcdefghijklmnopqrstuvwxyz

# Use Claude for Developer agent
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
```text

**Bare Metal:**

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export DEVELOPER_MODEL="anthropic/claude-3-5-sonnet-latest"
```text

### Available Models

| Model | Context Window | Use Case |
|-------|----------------|----------|
| `claude-3-5-sonnet-latest` | 200k tokens | Best overall performance |
| `claude-3-opus-latest` | 200k tokens | Most capable (expensive) |
| `claude-3-haiku-latest` | 200k tokens | Fast and cost-effective |

### Testing Anthropic API

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-latest",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```text

---

## Brave Search API

### Overview

Brave Search API provides:
- Web search results
- News search
- Privacy-focused search

### Getting API Key

1. Visit [Brave Search API](https://brave.com/search/api/)
2. Sign up for an account
3. Choose a plan (Free tier available)
4. Get your API key from the dashboard

### Configuration

**Docker (`docker-config.env`):**

```bash
BRAVE_SEARCH_API_KEY=BSAabcdefghijklmnopqrstuvwxyz

# Assign to Research agent
RESEARCH_MODEL=openai/gpt-4o  # Research agent needs an LLM too
```text

**Bare Metal:**

```bash
export BRAVE_SEARCH_API_KEY="BSA..."
```text

### Usage in Research Agent

The Research agent can now perform web searches:

```text
User: "Research the latest news about AI agents"
Research Agent: [Uses Brave Search API to find recent articles]
```text

### Testing Brave Search API

```bash
curl "https://api.search.brave.com/res/v1/web/search" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: $BRAVE_SEARCH_API_KEY" \
  -G --data-urlencode "q=AI agents" \
  --data-urlencode "count=5"
```text

---

## GitHub API

### Overview

GitHub API enables:
- Repository reading and analysis
- File operations (read/write)
- Pull request management
- Issue tracking

### Getting Personal Access Token (PAT)

1. Visit [GitHub Settings](https://github.com/settings/tokens)
2. Click "Generate new token" → "Generate new token (classic)"
3. Select scopes:
   - `repo` (Full control of repositories)
   - `workflow` (Update GitHub Action workflows)
   - `read:org` (Read org membership)
4. Generate and copy the token

### Configuration

**Docker (`docker-config.env`):**

```bash
GITHUB_PAT=ghp_abcdefghijklmnopqrstuvwxyz

# Assign to Developer agent
DEVELOPER_MODEL=anthropic/claude-3-5-sonnet-latest
```text

**Bare Metal:**

```bash
export GITHUB_PAT="ghp_..."
```text

### Using GitHub API with Developer Agent

```text
User: "Analyze the repository structure of oc-bootstrap"
Developer Agent: [Uses GitHub API to fetch repo data]
```text

### Testing GitHub API

```bash
# Test token
curl -H "Authorization: token $GITHUB_PAT" \
  https://api.github.com/user

# List repositories
curl -H "Authorization: token $GITHUB_PAT" \
  https://api.github.com/user/repos
```text

---

## Other Integrations

### Lemonade Server (Local Inference)

See **[Lemonade Configuration](Lemonade-Configuration)** for detailed setup.

Quick config:

```bash
LOCAL_INFERENCE=true
LEMONADE_KEY=local-dummy-key
LEMONADE_IP=192.168.12.50  # If running separately
ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF
```text

### Weather API (Example)

To add custom API integrations:

1. Add API key to environment:
   ```bash
   WEATHER_API_KEY=your_key_here
   ```

2. Configure agent to use it (in `SOUL.md`):
   ```markdown
   ## Capabilities
   - Weather lookup (via wttr.in or custom API)
   ```

---

## API Usage Tracking

### OpenAI Usage

Check your usage:

```bash
# Visit OpenAI platform
https://platform.openai.com/usage
```text

### Setting Budgets

**Docker (`docker-config.env`):**

```bash
# Set monthly budget (USD)
OPENAI_MONTHLY_BUDGET=50.00

# Enable budget tracking
TRACK_API_USAGE=true
```text

**Monitor usage in logs:**

```bash
docker compose logs openclaw | grep -i "usage\|cost\|tokens"
```text

### Anthropic Usage

```bash
# Visit Anthropic console
https://console.anthropic.com/settings/usage
```text

---

## Troubleshooting

### Issue: "Invalid API Key"

**Symptoms:**
```text
Error: 401 Unauthorized
```text

**Solution:**

```bash
# Verify key is set
echo $OPENAI_API_KEY  # Should print the key

# Test key manually (see Testing sections above)

# Re-generate key if needed from provider's dashboard
```text

### Issue: "Rate Limit Exceeded"

**Symptoms:**
```text
Error: 429 Too Many Requests
```text

**Solution:**

1. Wait and retry (OpenClaw handles this automatically with exponential backoff)
2. Upgrade your API plan
3. Switch to different model/provider
4. Implement rate limiting in config:
   ```bash
   export RATE_LIMIT_PER_MINUTE=10
   ```

### Issue: "Model Not Found"

**Symptoms:**
```text
Error: The model 'xyz' does not exist
```text

**Solution:**

```bash
# Check available models
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Update model name in config
ASSISTANT_MODEL=openai/gpt-4o  # Use correct model name
```text

### Issue: "Connection Timeout"

**Symptoms:**
```text
Error: ETIMEDOUT, connect timeout
```text

**Solution:**

```bash
# Check internet connectivity
ping -c 3 api.openai.com

# Check proxy settings (if applicable)
echo $http_proxy
echo $https_proxy

# Increase timeout in config
export API_TIMEOUT_MS=30000  # 30 seconds
```text

---

## Security Best Practices

1. **Never commit API keys** to version control
   ```bash
   # Add to .gitignore
   echo "docker-config.env" >> .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use environment variables** or secret management

3. **Rotate keys regularly** from provider dashboards

4. **Restrict API key permissions** (use minimal scopes)

5. **Monitor usage** for unusual activity

6. **Use separate keys** for development and production

---

## Next Steps

After configuring APIs:

1. Test **[Agent Configuration](Agent-Configuration)** with your APIs
2. Set up **[Lemonade Configuration](Lemonade-Configuration)** for local inference (optional)
3. Review **[Troubleshooting](Troubleshooting)** for API-related issues

---

## Additional Resources

- [OpenAI API Docs](https://platform.openai.com/docs)
- [Anthropic API Docs](https://docs.anthropic.com/)
- [Brave Search API Docs](https://brave.com/search/api/docs/)
- [GitHub API Docs](https://docs.github.com/en/rest)
- [Lemonade Server Guide](Lemonade-Configuration)

---

*Last updated: April 2026*
