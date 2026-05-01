#!/bin/bash
# ==============================================================================
# OpenClaw Docker Test Script
# ==============================================================================
# Validates Docker setup by testing:
#   - Docker image builds successfully
#   - OpenClaw CLI is installed and working
#   - Volume persistence works correctly
#   - Container starts and stops cleanly
#   - Non-interactive bootstrap mode works
#
# Usage:
#   ./tests/docker-test.sh              # Run all tests
#   ./tests/docker-test.sh --quick      # Skip slow tests
#   ./tests/docker-test.sh --verbose    # Show detailed output
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
DOCKERFILE="$PROJECT_ROOT/Dockerfile"
TEST_CONTAINER_NAME="oc-bootstrap-test"
TEST_VOLUME_NAME="oc-bootstrap-test-data"

# Test flags
QUICK_MODE=false
VERBOSE=false
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==============================================================================
# FUNCTIONS
# ==============================================================================

print_usage() {
    echo "OpenClaw Docker Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --quick      Skip slow tests (build, bootstrap)"
    echo "  --verbose    Show detailed output from Docker commands"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 --quick      # Quick validation only"
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
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            fail "$test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if eval "$test_command" >/dev/null 2>&1; then
            pass "$test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            fail "$test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi

    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
        error "Docker Compose is not installed"
        exit 1
    fi
}

# Cleanup test resources
cleanup() {
    log "Cleaning up test resources..."

    # Stop and remove test container
    docker stop "$TEST_CONTAINER_NAME" &>/dev/null 2>&1 || true
    docker rm "$TEST_CONTAINER_NAME" &>/dev/null 2>&1 || true

    # Remove test volume
    docker volume rm "$TEST_VOLUME_NAME" &>/dev/null 2>&1 || true

    # Remove test image (optional)
    # docker rmi oc-bootstrap-test:latest &>/dev/null 2>&1 || true
}

# ==============================================================================
# TESTS
# ==============================================================================

test_dockerfile_exists() {
    [[ -f "$DOCKERFILE" ]]
}

test_compose_file_exists() {
    [[ -f "$DOCKER_COMPOSE_FILE" ]]
}

test_dockerignore_exists() {
    [[ -f "$PROJECT_ROOT/.dockerignore" ]]
}

test_entrypoint_exists() {
    [[ -f "$PROJECT_ROOT/scripts/docker-entrypoint.sh" ]]
}

test_config_template_exists() {
    [[ -f "$PROJECT_ROOT/docker-config.env.template" ]]
}

test_docker_build() {
    if [[ "$QUICK_MODE" == "true" ]]; then
        warn "Skipping Docker build test (quick mode)"
        return 0
    fi

    log "Building Docker image (this may take a few minutes)..."
    docker build -t oc-bootstrap-test:latest "$PROJECT_ROOT"
}

test_openclaw_installed() {
    docker run --rm oc-bootstrap-test:latest bash -c "which openclaw"
}

test_openclaw_version() {
    docker run --rm oc-bootstrap-test:latest bash -c "openclaw --version"
}

test_container_runs() {
    # Start container in background with proper environment variables
    docker run -d \
        --name "$TEST_CONTAINER_NAME" \
        -e ASSISTANT_TOKEN=test \
        -e RESEARCH_TOKEN=test2 \
        -e DEVELOPER_TOKEN=test3 \
        oc-bootstrap-test:latest \
        sleep infinity

    # Wait for container to start
    sleep 5

    # Check if container is running
    docker ps --filter "name=$TEST_CONTAINER_NAME" --format '{{.Names}}' | grep -q "$TEST_CONTAINER_NAME"
}

test_container_stops() {
    docker stop "$TEST_CONTAINER_NAME" &>/dev/null
    docker rm "$TEST_CONTAINER_NAME" &>/dev/null
}

test_volume_persistence() {
    # Create a test volume
    docker volume create "$TEST_VOLUME_NAME" &>/dev/null

    # Write test data to volume as openclaw user
    docker run --rm \
        -v "$TEST_VOLUME_NAME:/home/openclaw/.openclaw" \
        oc-bootstrap-test:latest \
        bash -c "echo 'test-data' > /home/openclaw/.openclaw/test.txt"

    # Read test data back
    local data
    data=$(docker run --rm \
        -v "$TEST_VOLUME_NAME:/home/openclaw/.openclaw" \
        oc-bootstrap-test:latest \
        cat /home/openclaw/.openclaw/test.txt)

    [[ "$data" == "test-data" ]]
}

test_nonroot_user() {
    local user
    user=$(docker run --rm oc-bootstrap-test:latest bash -c "whoami")
    [[ "$user" == "openclaw" ]]
}

test_entrypoint_executable() {
    docker run --rm oc-bootstrap-test:latest bash -c "test -x /usr/local/bin/docker-entrypoint.sh"
}

test_shell_access() {
    docker run --rm oc-bootstrap-test:latest bash -c "echo 'shell works'"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --quick)
        QUICK_MODE=true
        shift
        ;;
    --verbose)
        VERBOSE=true
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
echo "  OpenClaw Docker Test Suite"
echo "=========================================="
echo ""

# Check prerequisites
log "Checking prerequisites..."
check_docker
pass "Docker is available"

# Register cleanup handler
trap cleanup EXIT

# Run tests
log "Starting tests..."
echo ""

# File existence tests
run_test "Dockerfile exists" test_dockerfile_exists
run_test "docker-compose.yml exists" test_compose_file_exists
run_test ".dockerignore exists" test_dockerignore_exists
run_test "docker-entrypoint.sh exists" test_entrypoint_exists
run_test "docker-config.env.template exists" test_config_template_exists

echo ""

# Build test
if [[ "$QUICK_MODE" != "true" ]]; then
    run_test "Docker image builds successfully" test_docker_build
    echo ""
fi

# Container tests
if [[ "$QUICK_MODE" != "true" ]]; then
    run_test "OpenClaw CLI is installed" test_openclaw_installed
    run_test "OpenClaw version check works" test_openclaw_version
    run_test "Container runs as non-root user" test_nonroot_user
    run_test "Entrypoint is executable" test_entrypoint_executable
    run_test "Shell access works" test_shell_access

    echo ""

    run_test "Container starts and stays running" test_container_runs

    if docker ps --filter "name=$TEST_CONTAINER_NAME" --format '{{.Names}}' | grep -q "$TEST_CONTAINER_NAME"; then
        run_test "Container stops cleanly" test_container_stops
    fi

    echo ""

    run_test "Volume persistence works" test_volume_persistence
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
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
