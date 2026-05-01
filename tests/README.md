# OpenClaw Bootstrap - Test Suite

This directory contains the test suite for OpenClaw Bootstrap.

## Test Types

### Unit Tests
- Test individual functions and components
- Fast execution, no external dependencies
- Located in `tests/unit/`

### Integration Tests
- Test interaction between components
- May require Docker or external services
- Located in `tests/integration/`

### Docker Tests
- Test Docker build and deployment
- Validate container configuration
- See `docker-test.sh`

### Full Integration Tests
- End-to-end testing
- Test complete installation and functionality
- See `full-integration-test.sh`

## Running Tests

```bash
# Make tests executable
chmod +x tests/*.sh

# Run Docker tests
./tests/docker-test.sh

# Run full integration test
./tests/full-integration-test.sh --verbose

# Run specific test
./tests/docker-integration-test.sh --test install
```

## Test Configuration

Copy `test-config.env.template` to `test-config.env` and customize for your environment.

## CI/CD

Tests are automatically run via GitHub Actions:
- **Lint and Test** workflow runs on push/PR
- **Docker Integration** tests run in container
- **Secret Detection** scans for exposed credentials
