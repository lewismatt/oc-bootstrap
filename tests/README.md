# OpenClaw Bootstrap - Testing Documentation

## Overview

This directory contains integration tests for the OpenClaw Bootstrap
project. The tests use Docker to spin up a container, run the bootstrap
script with dummy credentials, and verify that the installation and
configuration work correctly.

## Test Files

| File | Description |
|------|-------------|
| `docker-integration-test.sh` | Main integration test script that runs in a Docker container |
| `test-config.env.template` | Template with dummy API keys for testing |

## Prerequisites

- Docker installed and running
- Bash shell
- Ubuntu 24.04 base image (pulled automatically)

## Running Tests

### Run All Tests

```bash
./tests/docker-integration-test.sh
```

### Run with Verbose Output

```bash
./tests/docker-integration-test.sh --verbose
```

### Keep Container After Tests (for debugging)

```bash
./tests/docker-integration-test.sh --keep
```

This will keep the container running after tests, so you can inspect the state:

```bash
docker exec -it oc-bootstrap-test-<PID> bash
```

### View Help

```bash
./tests/docker-integration-test.sh --help
```

## What Gets Tested

1. **Container Setup**
   - Creates Ubuntu 24.04 container
   - Verifies project files are present
   - Installs dependencies (curl, git)

2. **Script Validation**
   - Verifies OpenClaw is NOT installed (fresh container)
   - Validates helpers.sh functions are loadable
   - Checks bootstrap script syntax (`bash -n`)

3. **Configuration Validation**
   - Verifies config template has all required tokens
   - Verifies config template has all required models
   - Validates Telegram token format (regex check)

4. **IP Validation Logic**
   - Tests valid IP addresses (192.168.1.1, 10.0.0.1, 172.16.0.1)
   - Tests invalid IP addresses (999.999.999.999, not-an-ip, 256.0.0.1)

5. **Bootstrap Script Execution**
   - Runs `oc-bootstrap.sh --config <file> --non-interactive`
   - Verifies script processes config correctly
   - Checks secrets.env generation (even with dummy tokens)

## Expected Behavior with Dummy Credentials

The bootstrap script is expected to **fail** when run with dummy credentials because:
- Telegram tokens are not valid (format is correct, but API will reject them)
- API keys (GitHub, GitLab, Brave, X) are not real
- OpenClaw cannot be installed without proper setup

**This is normal!** The tests verify that:
- The script correctly validates input
- Configuration files are generated properly
- Error handling works as expected

## Test Output Example

```text
==========================================
  OpenClaw Docker Integration Test
==========================================

[TEST] Generating test configuration...
[TEST] Starting tests...

[TEST] Running: Create Ubuntu 24.04 container
[PASS] Create Ubuntu 24.04 container

[TEST] Running: Project files present in container
[PASS] Project files present in container

...

==========================================
  Test Summary
==========================================
Passed: 8
Failed: 0

All tests passed!
```

## CI Integration

The tests are automatically run in GitHub Actions via `.github/workflows/lint-and-test.yml`:

- **lint** job: Runs ShellCheck, shfmt, markdownlint, yamllint
- **secret-detection** job: Scans for leaked secrets
- **integration-test** job: Runs `tests/docker-integration-test.sh`

## Adding New Tests

To add a new test to `docker-integration-test.sh`:

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

2. Add the test call in the "Run tests" section:

```bash
run_test "New feature description" test_new_feature
```

3. Run the tests locally to verify:

```bash
./tests/docker-integration-test.sh --verbose
```

## Troubleshooting

### Container Not Starting

```bash
# Check Docker is running
docker ps

# View Docker logs
docker logs oc-bootstrap-test-<PID>
```

### Tests Failing

```bash
# Run with verbose mode
./tests/docker-integration-test.sh --verbose

# Keep container for debugging
./tests/docker-integration-test.sh --keep
```

### Clean Up Stale Containers

```bash
# List test containers
docker ps -a | grep oc-bootstrap-test

# Remove them
docker stop oc-bootstrap-test-<PID>
docker rm oc-bootstrap-test-<PID>
```

## Notes

- Tests use `set -euo pipefail` for strict error handling
- The test script cleans up containers automatically (unless `--keep` is used)
- Dummy credentials are NOT real - never use them in production
- The test config template is in `tests/test-config.env.template`
