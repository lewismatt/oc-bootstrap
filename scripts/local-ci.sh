#!/bin/bash
# Local CI Script - Runs the same checks as GitLab and GitHub pipelines locally using Docker
# This script mimics the exact same Docker images and commands as the remote pipelines
# Usage: ./scripts/local-ci.sh [stage...]
# Stages: lint, test, secret-detection, all (default: all)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall status
OVERALL_EXIT=0
STAGES_TO_RUN=()

# Parse arguments
if [ $# -eq 0 ]; then
    STAGES_TO_RUN=("lint" "test" "secret-detection")
else
    for arg in "$@"; do
        case "$arg" in
            lint|test|secret-detection|all)
                if [ "$arg" = "all" ]; then
                    STAGES_TO_RUN=("lint" "test" "secret-detection")
                    break
                else
                    STAGES_TO_RUN+=("$arg")
                fi
                ;;
            *)
                echo "Unknown stage: $arg"
                echo "Valid stages: lint, test, secret-detection, all"
                exit 1
                ;;
        esac
    done
fi

# Function to print section header
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print failure
print_failure() {
    echo -e "${RED}✗ $1${NC}"
    OVERALL_EXIT=1
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to check if Docker exists
docker_exists() {
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

# Function to run a command in a Docker container
run_in_docker() {
    local image="$1"
    local cmd="$2"
    local workdir="${3:-/app}"
    local volume="${4:-$(pwd):/app}"
    
    if ! docker_exists; then
        print_warning "Docker not available, skipping check that requires: $image"
        return 2
    fi
    
    docker run --rm -v "$volume" -w "$workdir" "$image" sh -c "$cmd" 2>&1
    return $?
}

# =========================================
# LINT STAGE
# =========================================
run_lint() {
    print_header "LINT STAGE"

    # 1. Bash Syntax Check (using bash:latest like GitLab)
    print_header "Bash Syntax Check (bash -n)"
    if docker_exists; then
        if run_in_docker "bash:latest" "bash -n oc-bootstrap.sh"; then
            print_success "bash-syntax: oc-bootstrap.sh passed"
        else
            print_failure "bash-syntax: oc-bootstrap.sh failed"
        fi
    else
        # Fallback to local bash if Docker not available
        if bash -n oc-bootstrap.sh 2>&1; then
            print_success "bash-syntax: oc-bootstrap.sh passed (local)"
        else
            print_failure "bash-syntax: oc-bootstrap.sh failed (local)"
        fi
    fi

    # 2. ShellCheck (using koalaman/shellcheck-alpine:stable like GitLab)
    print_header "ShellCheck"
    if docker_exists; then
        if run_in_docker "koalaman/shellcheck-alpine:stable" "shellcheck oc-bootstrap.sh lib/helpers.sh tests/full-integration-test.sh"; then
            print_success "shellcheck: passed"
        else
            print_failure "shellcheck: failed"
        fi
    else
        print_warning "Docker not available, skipping shellcheck (install with: apt install shellcheck)"
    fi

    # 3. shfmt (using golang:alpine like GitLab CI)
    print_header "shfmt (formatting check)"
    if docker_exists; then
        # Install shfmt in the golang container and run check
        if run_in_docker "golang:alpine" "GOBIN=/usr/local/bin go install mvdan.cc/sh/cmd/shfmt@latest && shfmt -d -i 4 -ci oc-bootstrap.sh lib/helpers.sh scripts/install-lemonade.sh"; then
            print_success "shfmt: formatting check passed"
        else
            print_failure "shfmt: formatting check failed (run 'docker run --rm -v \$(pwd):/app -w /app golang:alpine sh -c \"GOBIN=/usr/local/bin go install mvdan.cc/sh/cmd/shfmt@latest && shfmt -w -i 4 -ci oc-bootstrap.sh lib/helpers.sh scripts/install-lemonade.sh\"' to fix)"
        fi
    else
        # Fallback to local shfmt if available
        if command -v shfmt >/dev/null 2>&1; then
            if shfmt -d -i 4 -ci oc-bootstrap.sh lib/helpers.sh scripts/install-lemonade.sh 2>&1; then
                print_success "shfmt: formatting check passed (local)"
            else
                print_failure "shfmt: formatting check failed (local)"
            fi
        else
            print_warning "shfmt not available locally and Docker not available, skipping"
        fi
    fi

    # 4. MarkdownLint (using node:alpine like GitLab)
    print_header "MarkdownLint"
    if docker_exists; then
        if run_in_docker "node:alpine" "npm install -g markdownlint-cli && markdownlint -c .markdownlint.json ."; then
            print_success "markdownlint: passed"
        else
            print_failure "markdownlint: failed"
        fi
    else
        # Fallback to local markdownlint if available
        if command -v markdownlint >/dev/null 2>&1; then
            if markdownlint -c .markdownlint.json . 2>&1; then
                print_success "markdownlint: passed (local)"
            else
                print_failure "markdownlint: failed (local)"
            fi
        else
            print_warning "markdownlint not available locally and Docker not available, skipping"
        fi
    fi

    # 5. Yamllint (using python:alpine like GitLab)
    print_header "Yamllint"
    if docker_exists; then
        if run_in_docker "python:alpine" "pip install yamllint && yamllint -c .yamllint.yaml .gitlab-ci.yml .yamllint.yaml .markdownlint.json .github/workflows/"; then
            print_success "yamllint: passed"
        else
            print_failure "yamllint: failed"
        fi
    else
        # Fallback to local yamllint if available
        if command -v yamllint >/dev/null 2>&1; then
            if yamllint -c .yamllint.yaml .gitlab-ci.yml .yamllint.yaml .markdownlint.json .github/workflows/ 2>&1; then
                print_success "yamllint: passed (local)"
            else
                print_failure "yamllint: failed (local)"
            fi
        else
            print_warning "yamllint not available locally and Docker not available, skipping"
        fi
    fi
}

# =========================================
# TEST STAGE
# =========================================
run_test() {
    print_header "TEST STAGE"

    # Docker Integration Test
    print_header "Docker Integration Test"
    if docker_exists; then
        if [ -x "./tests/docker-test.sh" ]; then
            if ./tests/docker-test.sh --verbose 2>&1; then
                print_success "docker-test: passed"
            else
                print_failure "docker-test: failed"
            fi
        else
            print_warning "docker-test.sh: not executable, skipping"
        fi
    else
        print_warning "docker: not installed, skipping Docker integration test"
    fi
}

# =========================================
# SECRET DETECTION STAGE
# =========================================
run_secret_detection() {
    print_header "SECRET DETECTION STAGE"

    if docker_exists; then
        # Use trufflehog Docker image like GitHub Actions
        # Must run trufflehog directly without sh -c wrapper
        print_header "Running trufflehog secret scan..."
        if docker run --rm -v "$(pwd):/app:ro" "trufflesecurity/trufflehog:latest" git file:///app --only-verified 2>&1; then
            print_success "trufflehog: no secrets detected"
        else
            print_failure "trufflehog: potential secrets found"
        fi
    else
        # Fallback to local trufflehog if available
        if command -v trufflehog >/dev/null 2>&1; then
            if trufflehog git file://. --only-verified 2>&1; then
                print_success "trufflehog: no secrets detected (local)"
            else
                print_failure "trufflehog: potential secrets found (local)"
            fi
        else
            print_warning "trufflehog not available locally and Docker not available, skipping"
        fi
    fi
}

# =========================================
# MAIN EXECUTION
# =========================================

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Local CI/CD Pipeline Runner       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"

for stage in "${STAGES_TO_RUN[@]}"; do
    case "$stage" in
        lint)
            run_lint
            ;;
        test)
            run_test
            ;;
        secret-detection)
            run_secret_detection
            ;;
    esac
done

# Final summary
print_header "SUMMARY"
if [ $OVERALL_EXIT -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
else
    echo -e "${RED}Some checks failed. Please fix the issues above.${NC}"
fi

exit $OVERALL_EXIT