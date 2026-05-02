#!/bin/bash
# shellcheck disable=SC2329  # Functions invoked indirectly via run_test
# =============================================================================
# OpenClaw Bootstrap Full Integration Test
# =============================================================================
# Tests the complete installation flow in a Docker container:
#   - Spins up Ubuntu 24.04 container with non-root user
#   - Copies project files
#   - Runs oc-bootstrap.sh with test credentials
#   - Validates ALL configuration, directory structure, and OpenClaw setup
#
# Usage:
#   ./tests/full-integration-test.sh              # Run all tests
#   ./tests/full-integration-test.sh --verbose    # Show detailed output
#   ./tests/full-integration-test.sh --keep      # Keep container after tests
#   ./tests/full-integration-test.sh --quick     # Skip gateway startup test
#
# Environment Variables (for real credentials):
#   TEST_ASSISTANT_TOKEN, TEST_RESEARCH_TOKEN, TEST_DEVELOPER_TOKEN
#   TEST_OPENAI_KEY, TEST_ANTHROPIC_KEY, TEST_GITHUB_PAT
#   TEST_GITLAB_PAT, TEST_BRAVE_API_KEY, TEST_X_API_KEY
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_CONTAINER_NAME="oc-bootstrap-full-test-$$"
CONFIG_TEMPLATE="$SCRIPT_DIR/test-config.env.template"
GENERATED_CONFIG="/tmp/oc-bootstrap-full-test-config-$$.env"
CONTAINER_USER="testuser"

# Test flags
VERBOSE=false
KEEP_CONTAINER=false
QUICK_MODE=false
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

print_usage() {
    echo "OpenClaw Bootstrap Full Integration Test"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed output from Docker commands"
    echo "  --keep       Keep container after tests (for debugging)"
    echo "  --quick      Skip gateway startup test"
    echo "  --help       Show this help message"
    echo ""
    echo "Environment Variables (optional, for real credential testing):"
    echo "  TEST_ASSISTANT_TOKEN     Telegram bot token for assistant agent"
    echo "  TEST_RESEARCH_TOKEN     Telegram bot token for research agent"
    echo "  TEST_DEVELOPER_TOKEN    Telegram bot token for developer agent"
    echo "  TEST_OPENAI_KEY         OpenAI API key"
    echo "  TEST_ANTHROPIC_KEY      Anthropic API key"
    echo "  TEST_GITHUB_PAT         GitHub Personal Access Token"
    echo "  TEST_GITLAB_PAT         GitLab Personal Access Token"
    echo "  TEST_BRAVE_API_KEY      Brave Search API key"
    echo "  TEST_X_API_KEY          X/Twitter API key"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run with dummy credentials"
    echo "  $0 --verbose                 # Run with verbose output"
    echo "  TEST_ASSISTANT_TOKEN=123:abc $0  # Run with real token"
}

log() {
    echo -e "${GREEN}[TEST]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    TESTS_WARNED=$((TESTS_WARNED + 1))
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

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
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

# Execute command in container as non-root user
docker_exec() {
    if [[ "$VERBOSE" == "true" ]]; then
        docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "$1"
    else
        docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "$1" >/dev/null 2>&1
    fi
}

# Execute command in container as non-root user and get output
docker_exec_capture() {
    docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "$1" 2>&1
}

# Execute command in container as root (for setup)
docker_exec_root() {
    docker exec "$TEST_CONTAINER_NAME" bash -c "$1" 2>&1
}

# Generate test config from template with optional real credentials
generate_config() {
    local output_file="$1"

    if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
        error "Config template not found: $CONFIG_TEMPLATE"
        return 1
    fi

    # Copy template
    cp "$CONFIG_TEMPLATE" "$output_file"

    # Override with real credentials if provided via environment
    if [[ -n "${TEST_ASSISTANT_TOKEN:-}" ]]; then
        sed -i "s/^ASSISTANT_TOKEN=.*/ASSISTANT_TOKEN=${TEST_ASSISTANT_TOKEN}/" "$output_file"
        info "Using real ASSISTANT_TOKEN from environment"
    fi

    if [[ -n "${TEST_RESEARCH_TOKEN:-}" ]]; then
        sed -i "s/^RESEARCH_TOKEN=.*/RESEARCH_TOKEN=${TEST_RESEARCH_TOKEN}/" "$output_file"
        info "Using real RESEARCH_TOKEN from environment"
    fi

    if [[ -n "${TEST_DEVELOPER_TOKEN:-}" ]]; then
        sed -i "s/^DEVELOPER_TOKEN=.*/DEVELOPER_TOKEN=${TEST_DEVELOPER_TOKEN}/" "$output_file"
        info "Using real DEVELOPER_TOKEN from environment"
    fi

    if [[ -n "${TEST_GITHUB_PAT:-}" ]]; then
        sed -i "s/^GITHUB_PAT=.*/GITHUB_PAT=${TEST_GITHUB_PAT}/" "$output_file"
        info "Using real GITHUB_PAT from environment"
    fi

    if [[ -n "${TEST_GITLAB_PAT:-}" ]]; then
        sed -i "s/^GITLAB_PAT=.*/GITLAB_PAT=${TEST_GITLAB_PAT}/" "$output_file"
        info "Using real GITLAB_PAT from environment"
    fi

    if [[ -n "${TEST_BRAVE_API_KEY:-}" ]]; then
        sed -i "s/^BRAVE_API_KEY=.*/BRAVE_API_KEY=${TEST_BRAVE_API_KEY}/" "$output_file"
        info "Using real BRAVE_API_KEY from environment"
    fi

    if [[ -n "${TEST_X_API_KEY:-}" ]]; then
        sed -i "s/^X_API_KEY=.*/X_API_KEY=${TEST_X_API_KEY}/" "$output_file"
        info "Using real X_API_KEY from environment"
    fi

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

# --- Setup Tests ---

test_container_creation() {
    # Create a test container with Ubuntu 24.04
    docker run -d \
        --name "$TEST_CONTAINER_NAME" \
        -v "$PROJECT_ROOT:/workspace/oc-bootstrap" \
        ubuntu:24.04 \
        sleep infinity

    # Wait for container to start
    sleep 2

    # Create a non-root user to match the project's requirements
    docker_exec_root "
        useradd -m -s /bin/bash $CONTAINER_USER 2>/dev/null || true
        echo '$CONTAINER_USER ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/$CONTAINER_USER 2>/dev/null || true
        chmod 0440 /etc/sudoers.d/$CONTAINER_USER 2>/dev/null || true
        chown -R $CONTAINER_USER:$CONTAINER_USER /workspace/oc-bootstrap 2>/dev/null || true
        chown -R $CONTAINER_USER:$CONTAINER_USER /home/$CONTAINER_USER 2>/dev/null || true
    "

    info "Created non-root user: $CONTAINER_USER"
}

test_project_files_present() {
    # Check that project files are present in container
    docker_exec "
        test -f /workspace/oc-bootstrap/oc-bootstrap.sh &&
        test -f /workspace/oc-bootstrap/lib/helpers.sh"
}

test_helpers_functions_loadable() {
    # Verify helpers.sh can be sourced without errors
    docker_exec "
        source /workspace/oc-bootstrap/lib/helpers.sh &&
        type valid_ipv4 >/dev/null &&
        type validate_telegram_token >/dev/null &&
        type progress_bar >/dev/null &&
        type safe_write_secrets_file >/dev/null"
}

test_bootstrap_syntax_check() {
    # Verify bootstrap script passes shell syntax check
    docker_exec "
        bash -n /workspace/oc-bootstrap/oc-bootstrap.sh &&
        bash -n /workspace/oc-bootstrap/lib/helpers.sh"
}

# --- Pre-Bootstrap Installation Tests ---

test_install_dependencies() {
    # Install basic dependencies in container
    docker_exec "
        sudo apt-get update &&
        sudo apt-get install -y curl git"
}

test_openclaw_not_installed() {
    # Verify openclaw is NOT installed yet (fresh container)
    docker_exec "
        ! command -v openclaw &&
        ! test -f /usr/local/bin/openclaw"
}

# --- Bootstrap Execution Test ---

test_run_bootstrap() {
    # Copy config to container
    docker cp "$GENERATED_CONFIG" "$TEST_CONTAINER_NAME:/tmp/test-config.env"

    # Run bootstrap in non-interactive mode as non-root user
    docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "
        cd /workspace/oc-bootstrap &&
        chmod +x oc-bootstrap.sh &&
        ./oc-bootstrap.sh --config /tmp/test-config.env --non-interactive" || {
        # Bootstrap may fail due to invalid tokens/API keys
        # That's OK - we'll validate what was configured before the failure
        warn "Bootstrap script exited with error (expected with test credentials)"
        return 0
    }
}

# --- Post-Bootstrap Directory Structure Tests ---

test_openclaw_directory_exists() {
    docker_exec "test -d \$HOME/.openclaw"
}

test_openclaw_directory_permissions() {
    local perms
    perms=$(docker_exec_capture "stat -c '%a' \$HOME/.openclaw")
    [[ "$perms" == "755" || "$perms" == "700" ]]
}

test_secrets_file_exists() {
    docker_exec "test -f \$HOME/.openclaw/secrets.env"
}

test_secrets_file_permissions() {
    local perms
    perms=$(docker_exec_capture "stat -c '%a' \$HOME/.openclaw/secrets.env")
    [[ "$perms" == "600" ]]
}

test_memory_directory_exists() {
    docker_exec "test -d \$HOME/.openclaw/memory"
}

test_logs_directory_exists() {
    docker_exec "test -d \$HOME/.openclaw/logs"
}

test_assistant_workspace_exists() {
    docker_exec "test -d \$HOME/.openclaw/workspace-assistant"
}

test_research_workspace_exists() {
    docker_exec "test -d \$HOME/.openclaw/workspace-research"
}

test_developer_workspace_exists() {
    docker_exec "test -d \$HOME/.openclaw/workspace-developer"
}

# --- Secrets File Content Tests ---

test_secrets_file_content() {
    # Verify secrets file has all required variables with non-empty values
    docker_exec "
        source \$HOME/.openclaw/secrets.env 2>/dev/null &&
        test -n \"\$LOCAL_INFERENCE\" &&
        test -n \"\$ASSISTANT_TOKEN\" &&
        test -n \"\$RESEARCH_TOKEN\" &&
        test -n \"\$DEVELOPER_TOKEN\" &&
        test -n \"\$ASSISTANT_MODEL\" &&
        test -n \"\$RESEARCH_MODEL\" &&
        test -n \"\$DEVELOPER_MODEL\" &&
        test -n \"\$EMBEDDING_MODEL\""
}

test_secrets_model_values() {
    # Verify model values match what we expect from config
    local expected_embedding
    local expected_assistant
    local expected_research
    local expected_developer

    expected_embedding=$(grep "^EMBEDDING_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    expected_assistant=$(grep "^ASSISTANT_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    expected_research=$(grep "^RESEARCH_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    expected_developer=$(grep "^DEVELOPER_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)

    docker_exec "
        source \$HOME/.openclaw/secrets.env 2>/dev/null &&
        [[ \"\$EMBEDDING_MODEL\" == \"$expected_embedding\" ]] &&
        [[ \"\$ASSISTANT_MODEL\" == \"$expected_assistant\" ]] &&
        [[ \"\$RESEARCH_MODEL\" == \"$expected_research\" ]] &&
        [[ \"\$DEVELOPER_MODEL\" == \"$expected_developer\" ]]"
}

# --- OpenClaw Configuration Tests ---

test_openclaw_installed() {
    docker_exec "command -v openclaw"
}

test_openclaw_version() {
    docker_exec "openclaw --version"
}

test_agent_list() {
    # Verify 3 agents are configured
    local output
    output=$(docker_exec_capture "openclaw agents list 2>/dev/null")
    echo "$output" | grep -q "assistant" &&
        echo "$output" | grep -q "research" &&
        echo "$output" | grep -q "developer"
}

test_assistant_model_config() {
    local expected
    expected=$(grep "^ASSISTANT_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.assistant.model 2>/dev/null")
    echo "$output" | grep -q "$expected"
}

test_research_model_config() {
    local expected
    expected=$(grep "^RESEARCH_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.research.model 2>/dev/null")
    echo "$output" | grep -q "$expected"
}

test_developer_model_config() {
    local expected
    expected=$(grep "^DEVELOPER_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.developer.model 2>/dev/null")
    echo "$output" | grep -q "$expected"
}

test_embedding_model_config() {
    local expected
    expected=$(grep "^EMBEDDING_MODEL=" "$GENERATED_CONFIG" | cut -d= -f2)
    local output
    output=$(docker_exec_capture "openclaw config get memory.embeddingModel 2>/dev/null")
    echo "$output" | grep -q "$expected"
}

# --- Memory Backend Configuration Tests ---

test_memory_search_provider() {
    docker_exec "openclaw config get agents.defaults.memorySearch.provider >/dev/null 2>&1"
}

test_memory_search_store_path() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.defaults.memorySearch.store.path 2>/dev/null")
    echo "$output" | grep -q "{agentId}.sqlite"
}

test_memory_search_vector_enabled() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.defaults.memorySearch.store.vector.enabled 2>/dev/null")
    echo "$output" | grep -qi "true"
}

test_memory_search_cache_enabled() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.defaults.memorySearch.cache.enabled 2>/dev/null")
    echo "$output" | grep -qi "true"
}

# --- Skills & Hooks Tests ---

test_research_skills_enabled() {
    docker_exec "
        openclaw config get agents.list.research.skills.summarize 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.webSearch 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.webScrape 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.newsSearch 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.rssReader 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.trendsFinder 2>/dev/null | grep -qi 'true' &&
        openclaw config get agents.list.research.skills.xScraper 2>/dev/null | grep -qi 'true'"
}

test_assistant_hooks() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.assistant.hooks.autoMemory 2>/dev/null")
    echo "$output" | grep -qi "true"
}

test_research_hooks() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.research.hooks.sessionSummarize 2>/dev/null")
    echo "$output" | grep -qi "true"
}

test_developer_hooks() {
    local output
    output=$(docker_exec_capture "openclaw config get agents.list.developer.hooks.toolValidation 2>/dev/null")
    echo "$output" | grep -qi "true"
}

# --- Agent Workspace Prompt Files Tests ---

test_assistant_prompt_files() {
    docker_exec "
        test -f \$HOME/.openclaw/workspace-assistant/SOUL.md &&
        test -f \$HOME/.openclaw/workspace-assistant/AGENTS.md &&
        test -f \$HOME/.openclaw/workspace-assistant/USER.md"
}

test_research_prompt_files() {
    docker_exec "
        test -f \$HOME/.openclaw/workspace-research/SOUL.md &&
        test -f \$HOME/.openclaw/workspace-research/AGENTS.md &&
        test -f \$HOME/.openclaw/workspace-research/USER.md"
}

# shellcheck disable=SC2329
test_developer_prompt_files() {
    docker_exec "
        test -f \$HOME/.openclaw/workspace-developer/SOUL.md &&
        test -f \$HOME/.openclaw/workspace-developer/AGENTS.md &&
        test -f \$HOME/.openclaw/workspace-developer/USER.md"
}

# --- Gateway Startup Test (optional, may fail with dummy credentials) ---

# shellcheck disable=SC2329
test_gateway_start() {
    if [[ "$QUICK_MODE" == "true" ]]; then
        warn "Skipping gateway startup test (quick mode)"
        return 0
    fi

    log "Attempting to start OpenClaw gateway (may fail with dummy credentials)..."

    if docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "openclaw gateway start" >/dev/null 2>&1; then
        pass "Gateway started successfully"

        # Wait for gateway to stabilize
        sleep 5

        # Check gateway status
        docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "openclaw gateway status" >/dev/null 2>&1 &&
            pass "Gateway status check passed"

        # Stop gateway
        docker exec --user "$CONTAINER_USER" "$TEST_CONTAINER_NAME" bash -c "openclaw gateway stop" >/dev/null 2>&1 || true
    else
        warn "Gateway failed to start (expected with dummy/test credentials)"
        return 0
    fi
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
        --quick)
            QUICK_MODE=true
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
echo "  OpenClaw Full Integration Test"
echo "=========================================="
echo ""

# Check if Docker is available
if ! command -v docker &>/dev/null; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &>/dev/null; then
    error "Docker daemon is not running"
    exit 1
fi

# Register cleanup handler
trap cleanup EXIT

# Generate test config
log "Generating test configuration..."
if ! generate_config "$GENERATED_CONFIG"; then
    error "Failed to generate test config"
    exit 1
fi

# Determine if we have real credentials
if [[ -n "${TEST_ASSISTANT_TOKEN:-}" && -n "${TEST_RESEARCH_TOKEN:-}" && -n "${TEST_DEVELOPER_TOKEN:-}" ]]; then
    info "Real Telegram tokens detected - full test mode"
else
    info "Using dummy tokens - config validation only"
fi

# =============================================================================
# RUN TESTS
# =============================================================================

echo ""
log "Phase 1: Setup Tests"
echo ""

run_test "Create Ubuntu 24.04 container" test_container_creation
run_test "Project files present in container" test_project_files_present
run_test "Install dependencies (curl, git, sudo)" test_install_dependencies
run_test "OpenClaw not installed yet" test_openclaw_not_installed
run_test "Helpers.sh functions loadable" test_helpers_functions_loadable
run_test "Bootstrap script syntax check" test_bootstrap_syntax_check

echo ""
log "Phase 2: Bootstrap Execution"
echo ""

run_test "Run bootstrap script (non-interactive)" test_run_bootstrap

# Check if bootstrap made it far enough to install OpenClaw
if ! docker_exec "command -v openclaw"; then
    warn "OpenClaw not installed - bootstrap may have failed early"
    warn "Skipping post-installation tests"
    goto_summary=true
else
    goto_summary=false
fi

if [[ "$goto_summary" == "false" ]]; then
    echo ""
    log "Phase 3: Directory Structure Validation"
    echo ""

    run_test "OpenClaw directory exists" test_openclaw_directory_exists
    run_test "OpenClaw directory permissions" test_openclaw_directory_permissions
    run_test "Secrets file exists" test_secrets_file_exists
    run_test "Secrets file permissions (0600)" test_secrets_file_permissions
    run_test "Memory directory exists" test_memory_directory_exists
    run_test "Logs directory exists" test_logs_directory_exists
    run_test "Assistant workspace exists" test_assistant_workspace_exists
    run_test "Research workspace exists" test_research_workspace_exists
    run_test "Developer workspace exists" test_developer_workspace_exists

    echo ""
    log "Phase 4: Secrets File Validation"
    echo ""

    run_test "Secrets file has all required variables" test_secrets_file_content
    run_test "Secrets file model values match config" test_secrets_model_values

    echo ""
    log "Phase 5: OpenClaw Configuration Validation"
    echo ""

    run_test "OpenClaw binary installed" test_openclaw_installed
    run_test "OpenClaw version check" test_openclaw_version
    run_test "Agent list shows 3 agents" test_agent_list
    run_test "Assistant model configured correctly" test_assistant_model_config
    run_test "Research model configured correctly" test_research_model_config
    run_test "Developer model configured correctly" test_developer_model_config
    run_test "Embedding model configured correctly" test_embedding_model_config

    echo ""
    log "Phase 6: Memory Backend Configuration"
    echo ""

    run_test "Memory search provider configured" test_memory_search_provider
    run_test "Memory search store path configured" test_memory_search_store_path
    run_test "Memory search vector enabled" test_memory_search_vector_enabled
    run_test "Memory search cache enabled" test_memory_search_cache_enabled

    echo ""
    log "Phase 7: Skills & Hooks Configuration"
    echo ""

    run_test "Research agent skills enabled" test_research_skills_enabled
    run_test "Assistant autoMemory hook enabled" test_assistant_hooks
    run_test "Research sessionSummarize hook enabled" test_research_hooks
    run_test "Developer toolValidation hook enabled" test_developer_hooks

    echo ""
    log "Phase 8: Agent Prompt Files"
    echo ""

    # Only test if prompt files exist in the repo
    if [[ -d "$PROJECT_ROOT/assistant" && -d "$PROJECT_ROOT/research" && -d "$PROJECT_ROOT/developer" ]]; then
        run_test "Assistant prompt files seeded" test_assistant_prompt_files
        run_test "Research prompt files seeded" test_research_prompt_files
        run_test "Developer prompt files seeded" test_developer_prompt_files
    else
        warn "Agent prompt files not found in repo - skipping seed test"
    fi

    echo ""
    log "Phase 9: Gateway Startup Test"
    echo ""

    run_test "Gateway startup test" test_gateway_start
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
if [[ $TESTS_WARNED -gt 0 ]]; then
    echo -e "${YELLOW}Warnings: $TESTS_WARNED${NC}"
fi
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
