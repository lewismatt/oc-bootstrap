# OpenClaw Bootstrap - Testing Documentation

## Overview

This directory contains integration tests for the OpenClaw Bootstrap project.
The tests use Docker to spin up a container, run the bootstrap script, and verify that the installation and configuration work correctly.

## Test Files

| File | Description |
|------|-------------|
| `docker-integration-test.sh` | Basic integration test that runs in a Docker container (config validation only) |
| `full-integration-test.sh` | **Full integration test** that validates ALL configuration, directory structure, and OpenClaw setup |
| `telegram-e2e-test.sh` | **Telegram E2E test** - fully automated end-to-end test with real Telegram bots and OpenRouter |
| `e2e-config.env.template` | Template with Telegram bot tokens and OpenRouter API key for E2E testing |
| `test-config.env.template` | Template with dummy API keys for testing |

## Telegram E2E Test (New)

The `telegram-e2e-test.sh` script performs a **fully automated end-to-end test** that validates the entire OpenClaw setup with real Telegram bots.

### What It Tests

1. **Validation Phase:**
   - Validates all 3 Telegram bot tokens (via Telegram API)
   - Validates OpenRouter API key
   - Checks Docker availability

2. **Full Setup Phase:**
   - Starts OpenClaw with Docker Compose
   - Configures all 3 agents with `openrouter/free` models
   - Binds Telegram channels to each agent
   - Waits for gateway to be ready

3. **Bot Response Phase:**
   - Automatically gets chat IDs from Telegram
   - Sends test messages to each bot
   - Polls for bot responses
   - Reports pass/fail for each agent

### Prerequisites

- 3 Telegram bots created via [@BotFather](https://t.me/BotFather)
- OpenRouter API key (free tier available at [openrouter.ai](https://openrouter.ai))
- Docker and Docker Compose installed and running

### Setup

1. **Copy the template:**
   ```bash
   cp tests/e2e-config.env.template tests/e2e-config.env
   ```

2. **Fill in your credentials:**
    ```bash
    nano tests/e2e-config.env
    ```

    Add your:
   - 3 Telegram bot tokens (from @BotFather)
   - OpenRouter API key
   - Optional: GitLab PAT, Brave API key, etc.

3. **Start a chat with each bot:**
   - Open Telegram
   - Search for each of your 3 bots
   - Send any message to each bot (this allows the test to get the chat_id)

### Running the E2E Test

```bash
# Run full E2E test
./tests/telegram-e2e-test.sh

# Run with verbose output
./tests/telegram-e2e-test.sh --verbose

# Keep containers after test (for debugging)
./tests/telegram-e2e-test.sh --keep

# Skip full setup, test existing deployment
./tests/telegram-e2e-test.sh --quick
```

### Expected Output

```text
  OpenClaw Telegram E2E Test

[TEST] Loading configuration...
[INFO] Configuration loaded from tests/e2e-config.env

[TEST] Phase 1: Validation Tests

[TEST] Running: Assistant bot token valid
[PASS] Assistant bot token valid
[INFO] Assistant bot username: @your_assistant_bot

[TEST] Running: Research bot token valid
[PASS] Research bot token valid
[INFO] Research bot username: @your_research_bot

[TEST] Running: Developer bot token valid
[PASS] Developer bot token valid
[INFO] Developer bot username: @your_developer_bot

[TEST] Running: OpenRouter API key valid
[PASS] OpenRouter API key valid

...

[TEST] Phase 4: Bot Response Tests

[TEST] Running: Assistant bot responds to message
[PASS] Assistant bot responds to message

[TEST] Running: Research bot responds to message
[PASS] Research bot responds to message

[TEST] Running: Developer bot responds to message
[PASS] Developer bot responds to message

  Test Summary
Passed: 12
Failed: 0

All tests passed!
```

### Troubleshooting

**Bot chat_id not found:**
- Make sure you've started a chat with each bot on Telegram
- Send any message to each bot before running the test

**Bots not responding:**
- Check that OpenRouter API key is valid
- Verify bots are running: `docker logs oc-bootstrap`
- Check test output with `--verbose` flag

**Cleanup:**
```bash
# Stop and remove test containers
docker stop oc-bootstrap
docker rm oc-bootstrap

# Remove test volumes
docker volume prune

# Remove docker-compose override
rm -f docker-compose.e2e-test.yml
```

## Prerequisites

- Docker installed and running
- Bash shell
- Ubuntu 24.04 base image (pulled automatically)

## Running Tests

### Quick Docker Test (Config Validation Only)

Tests that the script processes config correctly without actually installing OpenClaw:

```bash
./tests/docker-integration-test.sh
```

### Full Integration Test (Comprehensive Validation)

Tests the **complete** installation flow and validates all configuration:

```bash
./tests/full-integration-test.sh
```

### Run with Verbose Output

```bash
./tests/full-integration-test.sh --verbose
```

### Keep Container After Tests (for debugging)

```bash
./tests/full-integration-test.sh --keep
```

This will keep the container running after tests, so you can inspect the state:

```bash
docker exec -it oc-bootstrap-full-test-<PID> bash
```

### Quick Mode (Skip Gateway Startup)

```bash
./tests/full-integration-test.sh --quick
```

### View Help

```bash
./tests/full-integration-test.sh --help
```

## Full Integration Test Details

The `full-integration-test.sh` script performs comprehensive validation:

### Test Phases

1. **Setup Tests**
   - Creates Ubuntu 24.04 container
   - Verifies project files are present
   - Installs dependencies (curl, git, sudo)
   - Validates helpers.sh functions are loadable
   - Checks bootstrap script syntax (`bash -n`)

2. **Bootstrap Execution**
   - Runs `oc-bootstrap.sh --config <file> --non-interactive`
   - Processes all configuration

3. **Directory Structure Validation**
   - `~/.openclaw/` exists with correct permissions
   - `~/.openclaw/secrets.env` exists (0600 permissions)
   - `~/.openclaw/memory/` directory exists
   - `~/.openclaw/logs/` directory exists
   - `~/.openclaw/workspace-{agent}/` for all 3 agents

4. **Secrets File Validation**
   - Verifies all required variables are set
   - Validates model values match configuration

5. **OpenClaw Configuration Validation**
   - Verifies `openclaw` binary is installed
   - Checks agent list shows 3 agents
   - Validates model configurations (assistant, research, developer, embedding)
   - Checks memory search provider and settings

6. **Memory Backend Configuration**
   - Validates memory search provider is set
   - Checks sqlite-vec vector search is enabled
   - Verifies embedding cache is enabled

7. **Skills & Hooks Configuration**
   - Validates research agent skills (summarize, webSearch, webScrape, etc.)
   - Checks autoMemory hook for assistant
   - Validates sessionSummarize hook for research
   - Verifies toolValidation hook for developer

8. **Agent Prompt Files**
   - Checks SOUL.md, AGENTS.md, USER.md are seeded

9. **Gateway Startup Test** (skipped in quick mode)
   - Attempts to start OpenClaw gateway
   - Validates it starts (or fails with expected API key errors)

## Using Real Credentials

To run a **true** integration test that validates the entire flow works:

### Set Environment Variables

```bash
export TEST_ASSISTANT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export TEST_RESEARCH_TOKEN="987654321:BCDeFGhIjklMNOpqrsTUVwxyz"
export TEST_DEVELOPER_TOKEN="112233445:DEfGhIjklMNOpqrsTUVwxyz"
export TEST_OPENAI_KEY="sk-..."
export TEST_ANTHROPIC_KEY="sk-ant-..."
export TEST_GITHUB_PAT="ghp_..."
export TEST_GITLAB_PAT="glpat-..."
export TEST_BRAVE_API_KEY="BSA..."
export TEST_X_API_KEY="..."
```

### Run Test with Real Credentials

```bash
./tests/full-integration-test.sh --verbose
```

Or use make:

```bash
make test-full-real
```

## Expected Behavior with Dummy Credentials

The bootstrap script is expected to **fail** when run with dummy credentials because:
- Telegram tokens are not valid (format is correct, but API will reject them)
- API keys (GitHub, GitLab, Brave, X) are not real
- OpenClaw cannot be installed without proper setup

**This is normal!** The tests verify that:
- The script correctly validates input
- Configuration files are generated properly
- Directory structures are created correctly
- Error handling works as expected

## Test Output Example

```text
==========================================
  OpenClaw Full Integration Test
==========================================

[TEST] Generating test configuration...
[INFO] Using dummy tokens - config validation only

[TEST] Phase 1: Setup Tests

[TEST] Running: Create Ubuntu 24.04 container
[PASS] Create Ubuntu 24.04 container

[TEST] Running: Project files present in container
[PASS] Project files present in container

...

[TEST] Phase 5: OpenClaw Configuration Validation

[TEST] Running: OpenClaw binary installed
[PASS] OpenClaw binary installed

[TEST] Running: Assistant model configured correctly
[PASS] Assistant model configured correctly

...

==========================================
  Test Summary
==========================================
Passed: 25
Failed: 0

All tests passed!
```

## Using Make

```bash
make test          # Run basic Docker tests
make test-quick    # Run quick tests (skip build)
make test-full     # Run full integration test
make test-full-real # Run full test with real credentials (set env vars first)
```

## CI Integration

The tests are automatically run in GitHub Actions via `.github/workflows/lint-and-test.yml`:

- **lint** job: Runs ShellCheck, shfmt, markdownlint, yamllint
- **secret-detection** job: Scans for leaked secrets
- **integration-test** job: Runs `tests/docker-integration-test.sh`

## Adding New Tests

To add a new test to `full-integration-test.sh`:

1. Define a test function:

```bash
test_new_feature() {
    # Description of what this tests
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        # Your test logic here
        command_that_should_pass
    "
}
```

2. Add the test call in the appropriate "Phase" section:

```bash
run_test "New feature description" test_new_feature
```

3. Run the tests locally to verify:

```bash
./tests/full-integration-test.sh --verbose
```

## Troubleshooting

### Container Not Starting

```bash
# Check Docker is running
docker ps

# View Docker logs
docker logs oc-bootstrap-full-test-<PID>
```

### Tests Failing

```bash
# Run with verbose mode
./tests/full-integration-test.sh --verbose

# Keep container for debugging
./tests/full-integration-test.sh --keep
```

### Clean Up Stale Containers

```bash
# List test containers
docker ps -a | grep oc-bootstrap

# Remove them
docker stop oc-bootstrap-full-test-<PID>
docker rm oc-bootstrap-full-test-<PID>
```

## Notes

- Tests use `set -euo pipefail` for strict error handling
- The test script cleans up containers automatically (unless `--keep` is used)
- Dummy credentials are NOT real - never use them in production
- The test config template is in `tests/test-config.env.template`
- With real credentials, the test validates **actual** OpenClaw functionality
