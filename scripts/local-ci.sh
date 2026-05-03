#!/bin/bash
# Local CI Script - Runs the same checks as GitLab and GitHub pipelines locally
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ==========================================
# LINT STAGE
# ==========================================
run_lint() {
    print_header "LINT STAGE"

    # 1. Bash Syntax Check
    print_header "Bash Syntax Check (bash -n)"
    if bash -n oc-bootstrap.sh 2>&1; then
        print_success "bash-syntax: oc-bootstrap.sh passed"
    else
        print_failure "bash-syntax: oc-bootstrap.sh failed"
    fi

    # 2. ShellCheck
    print_header "ShellCheck"
    if command_exists shellcheck; then
        if shellcheck oc-bootstrap.sh lib/helpers.sh 2>&1; then
            print_success "shellcheck: oc-bootstrap.sh lib/helpers.sh passed"
        else
            print_failure "shellcheck: oc-bootstrap.sh lib/helpers.sh failed"
        fi
    else
        print_warning "shellcheck: not installed, skipping (install with: apt install shellcheck)"
    fi

    # 3. shfmt
    print_header "shfmt (formatting check)"
    if command_exists shfmt; then
        if shfmt -d -i 4 -ci oc-bootstrap.sh lib/helpers.sh scripts/install-lemonade.sh 2>&1; then
            print_success "shfmt: formatting check passed"
        else
            print_failure "shfmt: formatting check failed (run 'shfmt -w -i 4 -ci <file>' to fix)"
        fi
    else
        print_warning "shfmt: not installed, skipping (install with: go install mvdan.cc/sh/cmd/shfmt@latest)"
    fi

    # 4. MarkdownLint
    print_header "MarkdownLint"
    if command_exists markdownlint-cli2; then
        # markdownlint-cli2 uses different syntax
        if markdownlint-cli2 "**/*.md" 2>&1; then
            print_success "markdownlint-cli2: passed"
        else
            print_failure "markdownlint-cli2: failed"
        fi
    elif command_exists markdownlint; then
        if markdownlint -c .markdownlint.json . 2>&1; then
            print_success "markdownlint: passed"
        else
            print_failure "markdownlint: failed"
        fi
    else
        print_warning "markdownlint: not installed, skipping (install with: npm install -g markdownlint-cli or markdownlint-cli2)"
    fi

    # 5. Yamllint
    print_header "Yamllint"
    if command_exists yamllint; then
        if yamllint -c .yamllint.yaml .gitlab-ci.yml .yamllint.yaml .markdownlint.json .github/workflows/ 2>&1; then
            print_success "yamllint: passed"
        else
            print_failure "yamllint: failed"
        fi
    else
        print_warning "yamllint: not installed, skipping (install with: pip install yamllint)"
    fi
}

# ==========================================
# TEST STAGE
# ==========================================
run_test() {
    print_header "TEST STAGE"

    # Docker Integration Test
    print_header "Docker Integration Test"
    if command_exists docker; then
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

# ==========================================
# SECRET DETECTION STAGE
# ==========================================
run_secret_detection() {
    print_header "SECRET DETECTION STAGE"

    if command_exists trufflehog; then
        if trufflehog git file://. --only-verified 2>&1; then
            print_success "trufflehog: no secrets detected"
        else
            print_failure "trufflehog: potential secrets found"
        fi
    else
        print_warning "trufflehog: not installed, skipping (install from: https://github.com/trufflesecurity/trufflehog)"
    fi
}

# ==========================================
# MAIN EXECUTION
# ==========================================

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