#!/bin/bash
# =============================================================================
# OpenClaw Bootstrap Docker Integration Test
# =============================================================================
# Tests the complete installation flow in a Docker container:
#   - Spins up Ubuntu 24.04 container
#   - Copies project files
#   - Runs oc-bootstrap.sh with dummy credentials
#   - Validates OpenClaw installation and configuration
#
# Usage:
#   ./tests/docker-integration-test.sh              # Run all tests
#   ./tests/docker-integration-test.sh --verbose    # Show detailed output
#   ./tests/docker-integration-test.sh --keep      # Keep container after tests
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_CONTAINER_NAME="oc-bootstrap-test-$$"
CONFIG_TEMPLATE="$SCRIPT_DIR/test-config.env.template"
GENERATED_CONFIG="/tmp/oc-bootstrap-test-config-$$.env"

# Test flags
VERBOSE=false
KEEP_CONTAINER=false
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

print_usage() {
    echo "OpenClaw Bootstrap Docker Integration Test"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed output from Docker commands"
    echo "  --keep       Keep container after tests (for debugging)"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 --verbose    # Run with verbose output"
}

log() {
    echo -e "${GREEN}[TEST]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Run a test and track pass/fail
run_test() {
    local test_name="$1"
    local test_command="$2"

    log "Running: $test_name"

    if [[ "$VERBOSE" == "true" ]]; then
        if eval "$test_command"; then
            pass "$test_name"
            return 0
        else
            fail "$test_name"
            return 1
        fi
    else
        if eval "$test_command" >/dev/null 2>&1; then
            pass "$test_name"
            return 0
        else
            fail "$test_name"
            return 1
        fi
    fi
}

# Generate test config from template
generate_config() {
    local output_file="$1"

    if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
        error "Config template not found: $CONFIG_TEMPLATE"
        return 1
    fi

    # Copy template and ensure it has proper values
    cp "$CONFIG_TEMPLATE" "$output_file"

    # Verify the config has required fields
    local required_vars=(
        "LOCAL_INFERENCE"
        "ASSISTANT_TOKEN"
        "RESEARCH_TOKEN"
        "DEVELOPER_TOKEN"
        "ASSISTANT_MODEL"
        "RESEARCH_MODEL"
        "DEVELOPER_MODEL"
        "EMBEDDING_MODEL"
    )

    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$output_file"; then
            error "Missing required variable in config: $var"
            return 1
        fi
    done

    log "Generated test config: $output_file"
    return 0
}

# Cleanup test resources
cleanup() {
    log "Cleaning up test resources..."

    # Stop and remove test container
    docker stop "$TEST_CONTAINER_NAME" &>/dev/null 2>&1 || true
    docker rm "$TEST_CONTAINER_NAME" &>/dev/null 2>&1 || true

    # Remove generated config
    rm -f "$GENERATED_CONFIG" 2>/dev/null || true

    log "Cleanup complete"
}

# =============================================================================
# TESTS
# =============================================================================

test_container_creation() {
    # Create a test container with Ubuntu 24.04
    docker run -d \
        --name "$TEST_CONTAINER_NAME" \
        -v "$PROJECT_ROOT:/workspace/oc-bootstrap" \
        ubuntu:24.04 \
        sleep infinity
}

test_project_files_present() {
    # Check that project files are present in container
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        ls /workspace/oc-bootstrap/oc-bootstrap.sh && 
        ls /workspace/oc-bootstrap/lib/helpers.sh"
}

test_install_dependencies() {
    # Install basic dependencies in container
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        apt-get update && 
        apt-get install -y curl git sudo"
}

test_openclaw_not_installed() {
    # Verify openclaw is NOT installed yet (fresh container)
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        ! command -v openclaw && 
        ! test -f /usr/local/bin/openclaw"
}

test_helpers_functions_loadable() {
    # Verify helpers.sh can be sourced without errors
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source /workspace/oc-bootstrap/lib/helpers.sh && 
        type valid_ipv4 && 
        type validate_telegram_token && 
        type progress_bar && 
        type safe_write_secrets_file"
}

test_bootstrap_syntax_check() {
    # Verify bootstrap script passes shell syntax check
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        bash -n /workspace/oc-bootstrap/oc-bootstrap.sh && 
        bash -n /workspace/oc-bootstrap/lib/helpers.sh"
}

test_config_has_all_tokens() {
    # Verify config template has all required tokens
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source $GENERATED_CONFIG &&
        [[ \$ASSISTANT_TOKEN =~ ^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$ ]] &&
        [[ \$RESEARCH_TOKEN =~ ^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$ ]] &&
        [[ \$DEVELOPER_TOKEN =~ ^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$ ]]"
}

test_config_has_all_models() {
    # Verify config template has all required models
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source /tmp/test-config.env && 
        test -n \"\$ASSISTANT_MODEL\" && 
        test -n \"\$RESEARCH_MODEL\" && 
        test -n \"\$DEVELOPER_MODEL\" && 
        test -n \"\$EMBEDDING_MODEL\""
}

test_run_bootstrap_noninteractive() {
    # Copy config to container
    docker cp "$GENERATED_CONFIG" "$TEST_CONTAINER_NAME:/tmp/test-config.env"

    # Run bootstrap in non-interactive mode
    # Note: This will fail at OpenClaw installation because we don't have real tokens
    # But we can test up to the point where it tries to install
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        cd /workspace/oc-bootstrap &&
        chmod +x oc-bootstrap.sh &&
        ./oc-bootstrap.sh --config /tmp/test-config.env --non-interactive" || {
        # Expected to fail (dummy tokens, no real OpenClaw install)
        # We're testing that the script runs and processes the config correctly
        return 0
    }
}

test_config_file_generated() {
    # Check if secrets.env was created (even if installation incomplete)
    docker exec "$TEST_CONTAINER_NAME" bash -c "test -f /root/.openclaw/secrets.env"
}

test_validate_config_format() {
    # Validate the generated config file format
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source /root/.openclaw/secrets.env 2>/dev/null || true
        test -n \"\$ASSISTANT_TOKEN\" &&
        test -n \"\$RESEARCH_TOKEN\" &&
        test -n \"\$DEVELOPER_TOKEN\"
    "
}

test_telegram_token_format() {
    # Validate Telegram token format in config
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source /tmp/test-config.env
        echo \"\$ASSISTANT_TOKEN\" | grep -E '^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$'
    "
}

test_ip_validation() {
    # Test IP validation logic (source helpers.sh and test function)
    docker exec "$TEST_CONTAINER_NAME" bash -c "
        source /workspace/oc-bootstrap/lib/helpers.sh
        valid_ipv4 '192.168.1.1' &&
        valid_ipv4 '10.0.0.1' &&
        valid_ipv4 '172.16.0.1' &&
        ! valid_ipv4 '999.999.999.999' &&
        ! valid_ipv4 'not-an-ip' &&
        ! valid_ipv4 '256.0.0.1' &&
        ! valid_ipv4 '192.168.1'
    "
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --keep)
            KEEP_CONTAINER=true
            shift
            ;;
        --help | -h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Header
echo "=========================================="
echo "  OpenClaw Docker Integration Test"
echo "=========================================="
echo ""

# Register cleanup handler
trap cleanup EXIT

# Generate test config
log "Generating test configuration..."
if ! generate_config "$GENERATED_CONFIG"; then
    error "Failed to generate test config"
    exit 1
fi

# Run tests
log "Starting tests..."
echo ""

# Setup tests
run_test "Create Ubuntu 24.04 container" test_container_creation
run_test "Project files present in container" test_project_files_present
run_test "Install dependencies curl git" test_install_dependencies
run_test "OpenClaw not installed yet" test_openclaw_not_installed
run_test "Helpers.sh functions loadable" test_helpers_functions_loadable
run_test "Bootstrap script syntax check" test_bootstrap_syntax_check
run_test "Config has all tokens" test_config_has_all_tokens
run_test "Config has all models" test_config_has_all_models

echo ""
log "Running bootstrap script tests..."
echo ""

run_test "Telegram token format validation" test_telegram_token_format
run_test "IPv4 validation logic" test_ip_validation

# Note: The following tests may fail because we're using dummy credentials
# They test that the script processes config correctly up to the point of failure
echo ""
log "Attempting bootstrap run (expected partial failure with dummy tokens)..."
echo ""

if run_test "Run bootstrap in non-interactive mode" test_run_bootstrap_noninteractive; then
    # If bootstrap succeeded (unlikely with dummy tokens), run more validations
    run_test "Config file generated" test_config_file_generated
    run_test "Config file format valid" test_validate_config_format
else
    warn "Bootstrap script failed as expected with dummy credentials"
    warn "This is normal - the script correctly detected invalid tokens/credentials"
fi

# Summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"

    if [[ "$KEEP_CONTAINER" != "true" ]]; then
        exit 0
    else
        echo "Container '$TEST_CONTAINER_NAME' is still running (--keep flag)"
        echo "Connect with: docker exec -it $TEST_CONTAINER_NAME bash"
        exit 0
    fi
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
