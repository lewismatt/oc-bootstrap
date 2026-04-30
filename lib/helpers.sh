#!/bin/bash
# ==============================================================================
# OpenClaw Bootstrap Helper Functions Library
# ==============================================================================
# This file contains reusable functions for the OpenClaw setup script.
# Source this file at the beginning of oc-bootstrap.sh:
#   source "$(dirname "$0")/lib/helpers.sh"
#
# Functions are organized into logical groups:
#   - Validation
#   - Progress/Output
#   - Error Handling
#   - Configuration
#   - System Operations
# ==============================================================================

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

##
# valid_ipv4(ip)
# Validates that a string is a valid IPv4 address (0-255 per octet).
#
# Arguments:
#   $1 - IP address string to validate
#
# Returns:
#   0 if valid, 1 if invalid
#
# Example:
#   if valid_ipv4 "192.168.1.1"; then echo "Valid IP"; fi
##
valid_ipv4() {
    local ip=$1
    local IFS=.
    read -r -a octets <<<"$ip"
    [[ ${#octets[@]} -eq 4 ]] || return 1
    for o in "${octets[@]}"; do
        if [[ ! "$o" =~ ^[0-9]+$ ]]; then
            return 1
        fi
        if ((o < 0 || o > 255)); then
            return 1
        fi
    done
    return 0
}

##
# validate_telegram_token(token)
# Validates Telegram bot token format and API connectivity.
#
# Token format: {8-10 digit bot ID}:{35-char alphanumeric+underscore string}
# Example: 110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw
#
# Arguments:
#   $1 - Telegram bot token to validate
#
# Returns:
#   0 if valid and API responds successfully, 1 if invalid
#
# Outputs:
#   Status messages to stdout (validation result and API response)
##
validate_telegram_token() {
    local token=$1
    local timeout=5

    # Check token format: {8-10 digits}:{35 alphanumeric+underscore}
    if [[ ! "$token" =~ ^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$ ]]; then
        echo "  [WARN] Token format validation failed. Expected: {8-10 digits}:{35 alphanumeric}"
        return 1
    fi

    # Attempt API validation with Telegram
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" \
        "https://api.telegram.org/bot$token/getMe" 2>/dev/null)

    case "$http_code" in
    200)
        echo "  [OK] Token validated successfully"
        return 0
        ;;
    401)
        echo "  [ERROR] Invalid token (401 Unauthorized)"
        return 1
        ;;
    404)
        echo "  [ERROR] Bot not found (404 Not Found)"
        return 1
        ;;
    *)
        echo "  [WARN] Token format valid but API validation returned HTTP $http_code"
        return 0 # Don't fail; warn only
        ;;
    esac
}

# ==============================================================================
# PROGRESS & OUTPUT FUNCTIONS
# ==============================================================================

##
# progress_bar(total, current)
# Renders a simple ASCII progress bar to stdout.
#
# Arguments:
#   $1 - Total number of steps
#   $2 - Current step (1-based)
#
# Example:
#   progress_bar 10 3  # Shows 30% progress
##
progress_bar() {
    local total=$1
    local current=$2
    local bar_width=40

    if [[ -z "$total" || "$total" -le 0 ]]; then
        return 0
    fi

    local percent=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))
    local filled_str=""
    local empty_str=""
    local i

    for ((i = 0; i < filled; i++)); do filled_str+="#"; done
    for ((i = 0; i < empty; i++)); do empty_str+=" "; done

    printf "\rProgress: [%-${bar_width}s] %d%%" "${filled_str}${empty_str}" "$percent"
}

##
# print_section_summary(title, ...items)
# Prints a formatted summary block for a completed section.
#
# Arguments:
#   $1 - Section title
#   @  - List of status strings to display
#
# Example:
#   print_section_summary "Installation" \
#       "Package A installed" \
#       "Package B installed"
##
print_section_summary() {
    local section_title=$1
    shift
    local items=("$@")
    echo ""
    echo "=== ${section_title^^} Summary ==="
    for item in "${items[@]}"; do
        echo "[OK] $item"
    done
    echo ""
}

##
# print_header(text)
# Prints a formatted section header.
#
# Arguments:
#   $1 - Header text
##
print_header() {
    local text=$1
    echo ""
    echo "=== $text ==="
}

##
# log_timestamp(message)
# Logs a message with the current timestamp.
#
# Arguments:
#   $1 - Message to log
##
log_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ==============================================================================
# ERROR HANDLING FUNCTIONS
# ==============================================================================

##
# handle_error_or_warn(message, exit_code)
# Conditionally treats errors as fatal or warnings based on FAIL_ON_OPENCLAW_ERRORS.
#
# This is useful for optional features that shouldn't block installation.
#
# Arguments:
#   $1 - Error message
#   $2 - Exit code to use if treating as fatal (optional, defaults to 1)
#
# Behavior:
#   - If FAIL_ON_OPENCLAW_ERRORS is "true": exits with provided code
#   - If FAIL_ON_OPENCLAW_ERRORS is "false": prints warning and continues
#
# Example:
#   openclaw config set foo bar || handle_error_or_warn "Failed to set config" $E_CONFIG
##
handle_error_or_warn() {
    local msg=$1
    local code=${2:-1}

    if [[ "${FAIL_ON_OPENCLAW_ERRORS,,}" == "true" ]]; then
        echo "[ERROR] $msg"
        exit "$code"
    else
        echo "[WARN] $msg"
    fi
}

##
# require_tool(tool_name)
# Checks that a required tool is available in PATH.
#
# Arguments:
#   $1 - Tool name to check
#
# Returns:
#   0 if tool is found, 1 if not found
##
require_tool() {
    local tool=$1
    if ! command -v "$tool" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

##
# check_required_tools(tool1 tool2 ...)
# Verifies multiple required tools are available.
#
# Arguments:
#   @  - Tool names to check
#
# Exits:
#   $E_DEPENDENCY if any tool is missing (after installation attempt for curl)
##
check_required_tools() {
    local missing=()
    local tools=("$@")

    for t in "${tools[@]}"; do
        if ! require_tool "$t"; then
            missing+=("$t")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[ERROR] Missing required system tools: ${missing[*]}"
        echo "Please install the above tools and re-run this script."
        exit "${E_DEPENDENCY:-11}"
    fi
}

##
# install_if_missing(package_name)
# Attempts to install a package if it's not available.
#
# Arguments:
#   $1 - Package/tool name to install
#
# Returns:
#   0 if already installed or installation successful, 1 otherwise
##
install_if_missing() {
    local tool=$1

    if require_tool "$tool"; then
        return 0
    fi

    echo "[INFO] '$tool' is missing. Attempting installation..."
    if ! sudo apt-get update && sudo apt-get install -y "$tool"; then
        echo "[ERROR] Failed to install $tool."
        return 1
    fi
    return 0
}

# ==============================================================================
# CONFIGURATION FUNCTIONS
# ==============================================================================

##
# safe_write_secrets_file(filename)
# Writes current credential environment variables to a secrets file.
#
# Uses printf %q for safe shell quoting of all values.
#
# Arguments:
#   $1 - Path to secrets file to create/overwrite
#
# Environment variables used:
#   - LOCAL_INFERENCE, LEMONADE_KEY
#   - EMBEDDING_MODEL, ASSISTANT_MODEL, RESEARCH_MODEL, DEVELOPER_MODEL
#   - ASSISTANT_TOKEN, RESEARCH_TOKEN, DEVELOPER_TOKEN
#   - GITHUB_PAT, GITLAB_PAT, BRAVE_API_KEY, X_API_KEY
#
# Side effects:
#   - Creates file with 0600 permissions (readable only by owner)
#   - Overwrites any existing file
##
safe_write_secrets_file() {
    local filepath=$1

    {
        printf 'LOCAL_INFERENCE=%q\n' "$LOCAL_INFERENCE"
        printf 'LEMONADE_KEY=%q\n' "$LEMONADE_KEY"
        printf 'EMBEDDING_MODEL=%q\n' "$EMBEDDING_MODEL"
        printf 'ASSISTANT_MODEL=%q\n' "$ASSISTANT_MODEL"
        printf 'RESEARCH_MODEL=%q\n' "$RESEARCH_MODEL"
        printf 'DEVELOPER_MODEL=%q\n' "$DEVELOPER_MODEL"
        printf 'ASSISTANT_TOKEN=%q\n' "$ASSISTANT_TOKEN"
        printf 'RESEARCH_TOKEN=%q\n' "$RESEARCH_TOKEN"
        printf 'DEVELOPER_TOKEN=%q\n' "$DEVELOPER_TOKEN"
        printf 'GITHUB_PAT=%q\n' "$GITHUB_PAT"
        printf 'GITLAB_PAT=%q\n' "$GITLAB_PAT"
        printf 'BRAVE_API_KEY=%q\n' "$BRAVE_API_KEY"
        printf 'X_API_KEY=%q\n' "$X_API_KEY"
    } >"$filepath"

    chmod 600 "$filepath" || true
    chown "$(id -un):$(id -gn)" "$filepath" 2>/dev/null || true
}

##
# prompt_for_value(prompt_text, default_value, is_secret)
# Prompts the user for a single value with optional default and masking.
#
# Arguments:
#   $1 - Prompt text to display
#   $2 - Default value (displayed in brackets, optional)
#   $3 - "secret" to mask input, anything else for normal input
#
# Returns:
#   The user's input or default value on stdout
#
# Example:
#   TOKEN=$(prompt_for_value "Enter API token" "" "secret")
##
prompt_for_value() {
    local prompt=$1
    local default=$2
    local is_secret=${3:-}
    local response

    if [[ "$is_secret" == "secret" ]]; then
        read -r -s -p "$prompt: " response </dev/tty
        echo ""
    else
        if [[ -n "$default" ]]; then
            read -r -p "$prompt [Default: $default]: " response </dev/tty
        else
            read -r -p "$prompt: " response </dev/tty
        fi
    fi

    echo "${response:-$default}"
}

# ==============================================================================
# SYSTEM OPERATION FUNCTIONS
# ==============================================================================

##
# run_parallel(command_array)
# Runs multiple commands in parallel using background jobs.
#
# Arguments:
#   @ - Command strings to execute
#
# Behavior:
#   - Starts each command in a background job
#   - Waits for all jobs to complete
#   - Errors in subshells do not propagate to caller
#
# Example:
#   run_parallel "long_task_1" "long_task_2" "long_task_3"
##
run_parallel() {
    local pids=()
    local cmd

    for cmd in "$@"; do
        bash -c -- "$cmd" &
        pids+=($!)
    done

    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

##
# ensure_directory(path)
# Creates a directory if it doesn't already exist.
#
# Arguments:
#   $1 - Directory path to create
#
# Returns:
#   0 if directory exists or was created, 1 otherwise
##
ensure_directory() {
    local path=$1

    if [[ -d "$path" ]]; then
        return 0
    fi

    if mkdir -p "$path"; then
        return 0
    else
        echo "[ERROR] Failed to create directory: $path"
        return 1
    fi
}

##
# init_logging(log_file)
# Initializes logging by redirecting stdout and stderr to a file.
#
# Arguments:
#   $1 - Path to log file (will be created if needed)
#
# Side effects:
#   - Creates log file and parent directory
#   - Redirects all future output to tee (displays and logs)
##
init_logging() {
    local log_file=$1

    ensure_directory "$(dirname "$log_file")" || return 1
    exec > >(tee -a "$log_file") 2>&1

    log_timestamp "Starting OpenClaw Multi-Agent Setup"
}

##
# setup_cleanup_trap(cleanup_function)
# Configures trap to call function on EXIT, INT, TERM signals.
#
# Arguments:
#   $1 - Name of cleanup function to call
#
# Behavior:
#   - Function is called on script exit (any reason)
#   - Receives exit code as parameter
##
setup_cleanup_trap() {
    local cleanup_fn=$1

    trap_handler() {
        local exit_code=$?
        $cleanup_fn "$exit_code"
        exit "$exit_code"
    }

    trap trap_handler EXIT INT TERM
}

##
# check_shellcheck()
# Runs shellcheck on the main script if available.
#
# Behavior:
#   - Silently succeeds if shellcheck not installed
#   - Reports issues but doesn't fail installation
##
check_shellcheck() {
    if ! require_tool "shellcheck"; then
        echo "[INFO] ShellCheck not found. Skipping static analysis."
        echo "      Install with: sudo apt install shellcheck"
        return 0
    fi

    echo "[INFO] Running ShellCheck static analysis..."
    if shellcheck "$0" 2>/dev/null; then
        echo "  [OK] ShellCheck analysis complete: No critical issues found."
    else
        echo "  [WARN] ShellCheck found some issues. Review output above."
        echo "         This is not fatal - installation will continue."
    fi
}

# ==============================================================================
# OPENCLAW-SPECIFIC FUNCTIONS
# ==============================================================================

##
# verify_openclaw_installed()
# Checks that the openclaw binary is available and executable.
#
# Returns:
#   0 if openclaw is found, 1 otherwise
##
verify_openclaw_installed() {
    if require_tool "openclaw"; then
        echo "  [OK] OpenClaw binary found in PATH"
        return 0
    else
        echo "  [ERROR] OpenClaw binary not found in PATH after installation."
        return 1
    fi
}

##
# openclaw_config_safe(key, value)
# Sets an OpenClaw configuration value, handling errors based on FAIL_ON_OPENCLAW_ERRORS.
#
# Arguments:
#   $1 - Configuration key (dot-notation, e.g., "agents.list.assistant.model")
#   $2 - Configuration value
#
# Uses:
#   handle_error_or_warn for error treatment
##
openclaw_config_safe() {
    local key=$1
    local value=$2

    if ! openclaw config set "$key" "$value"; then
        handle_error_or_warn "Failed to set configuration: $key=$value" "${E_CONFIG:-13}"
    fi
}

# ==============================================================================
# EXPORT FUNCTIONS
# ==============================================================================
# Ensure all functions are available to sourcing scripts
export -f valid_ipv4
export -f validate_telegram_token
export -f progress_bar
export -f print_section_summary
export -f print_header
export -f log_timestamp
export -f handle_error_or_warn
export -f require_tool
export -f check_required_tools
export -f install_if_missing
export -f safe_write_secrets_file
export -f prompt_for_value
export -f run_parallel
export -f ensure_directory
export -f init_logging
export -f setup_cleanup_trap
export -f check_shellcheck
export -f verify_openclaw_installed
export -f openclaw_config_safe
