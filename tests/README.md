# OpenClaw Bootstrap - Testing Documentation

## Overview

This directory contains integration tests for the OpenClaw Bootstrap project. The tests use Docker to spin up a container, run the bootstrap script with test credentials, and verify that the installation and configuration work correctly.

## Test Files

| File | Description |
|------|-------------|
| `docker-integration-test.sh` | Basic integration test that runs in a Docker container (config validation only) |
| `full-integration-test.sh` | **Full integration test** that validates ALL configuration, directory structure, and OpenClaw setup |
| `test-config.env.template` | Template with dummy API keys for testing |

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