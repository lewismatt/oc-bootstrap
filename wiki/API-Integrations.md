# API Integrations

OpenClaw supports multiple API integrations for enhanced functionality.

## GitLab Integration

### Setup

1. Create a GitLab personal access token with scopes: `api`, `read_repository`, `write_repository`
2. Add token to your environment:
   ```bash
   export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
   ```
3. Configure project (optional):
   ```bash
   export GITLAB_PROJECT_ID=12345678
   # or
   export GITLAB_PROJECT_PATH=username/project-name
   ```

### Usage

- **Issues**: Create, list, update issues via GitLab API
- **Merge Requests**: Manage MRs programmatically
- **Wiki**: Update documentation via API
- **CI/CD**: Trigger pipelines, check status

## GitHub Integration

### Setup

1. Create a GitHub personal access token with scopes: `repo`, `workflow`
2. Add token to environment:
   ```bash
   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
   ```

### Usage

- **Issues**: Manage issues via GitHub API
- **Pull Requests**: Create and review PRs
- **Actions**: Trigger and monitor workflows
- **Wiki**: Update GitHub wiki programmatically

## Lemonade Server

### Configuration

```bash
LEMONADE_URL=http://localhost:8080
LEMONADE_API_KEY=your-api-key  # optional
```

### Endpoints

- `GET /models` - List available models
- `POST /v1/chat/completions` - Chat completions
- `POST /v1/completions` - Text completions

## Ollama API

OpenClaw uses Ollama for local model serving.

### Endpoints

- `GET http://localhost:11434/api/tags` - List models
- `POST http://localhost:11434/api/generate` - Generate text
- `POST http://localhost:11434/api/chat` - Chat endpoint
