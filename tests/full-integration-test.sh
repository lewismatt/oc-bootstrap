#!/bin/bash
# =============================================================================
# Full Integration Test Script
# =============================================================================

set -o errexit
unset -o nounset

# Colors
GREEN='\033[0;32m'
NC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

info "Starting full integration tests..."

# Parse arguments
VERBOSE=0
TEST_FILTER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=1; shift;;
        --test|-t) TEST_FILTER="$2"; shift 2;;
        *) error "Unknown option: $1";;
    esac
done

# Test counters
TOTAL=0
PASSED=0
FAILED=0

# Run test function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    ((TOTAL++))
    
    info "Running test: $test_name"
    if eval "$test_cmd" >/dev/null 2>&1; then
        ((PASSED++))
        info "PASSED: $test_name"
        return 0
    else
        ((FAILED++))
        error "FAILED: $test_name"
        return 1
    fi
}

# Test 1: Check prerequisites
if [[ -z "$TEST_FILTER" || "$TEST_FILTER" == "prereqs" ]]; then
    run_test "Check prerequisites" "command -v docker && command -v git"
fi

# Test 2: Clone repository
if [[ -z "$TEST_FILTER" || "$TEST_FILTER" == "clone" ]]; then
    run_test "Clone repository" "git clone https://github.com/lewismatt/oc-bootstrap.git /tmp/oc-bootstrap-test"
fi

# Test 3: Build Docker image
if [[ -z "$TEST_FILTER" || "$TEST_FILTER" == "build" ]]; then
    run_test "Build Docker image" "cd /tmp/oc-bootstrap-test && docker build -t openclaw-test ."
fi

# Test 4: Run container
if [[ -z "$TEST_FILTER" || "$TEST_FILTER" == "run" ]]; then
    run_test "Run container" "docker run -d --name oc-test -p 8081:8080 openclaw-test"
    sleep 10
fi

# Print summary
info "Test Summary: $PASSED/$TOTAL passed"
if [[ $FAILED -gt 0 ]]; then
    error "$FAILED test(s) failed"
fi

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
success "All integration tests passed!"
