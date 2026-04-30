#!/bin/bash
# ==============================================================================
# OpenClaw Docker Cleanup Script
# ==============================================================================
# Stops and removes OpenClaw containers, networks, and optionally volumes
#
# Usage:
#   ./docker-cleanup.sh                  # Stop and remove containers (keep volumes)
#   ./docker-cleanup.sh --prune          # Also remove volumes (DESTRUCTIVE!)
#   ./docker-cleanup.sh --all            # Remove everything including images
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

COMPOSE_FILE="$(cd "$(dirname "$0")" && pwd)/docker-compose.yml"
PRUNE_VOLUMES=false
REMOVE_IMAGES=false

# ==============================================================================
# FUNCTIONS
# ==============================================================================

print_usage() {
    echo "OpenClaw Docker Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --prune     Also remove volumes (DESTRUCTIVE - deletes all data!)"
    echo "  -a, --all       Remove everything including Docker images"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Stop containers, keep volumes"
    echo "  $0 --prune          # Stop containers and delete volumes"
    echo "  $0 --all            # Full cleanup (containers, volumes, images)"
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

confirm_action() {
    local message="$1"
    read -r -p "$message (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Operation cancelled."
        exit 0
    fi
}

# ==============================================================================
# PARSE ARGUMENTS
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -p | --prune)
            PRUNE_VOLUMES=true
            shift
            ;;
        -a | --all)
            PRUNE_VOLUMES=true
            REMOVE_IMAGES=true
            shift
            ;;
        -h | --help)
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

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

log "Starting OpenClaw Docker cleanup..."

# Check if docker-compose file exists
if [[ ! -f "$COMPOSE_FILE" ]]; then
    log "ERROR: docker-compose.yml not found at $COMPOSE_FILE"
    exit 1
fi

# Stop and remove containers
log "Stopping and removing containers..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans

# Prune volumes if requested
if [[ "$PRUNE_VOLUMES" == "true" ]]; then
    log "WARNING: This will delete ALL OpenClaw data (config, memory, workspaces)!"
    confirm_action "Are you sure you want to delete all volumes?"

    log "Removing volumes..."
    docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
    log "Volumes removed."
else
    log "Volumes preserved (use --prune to remove them)."
fi

# Remove images if requested
if [[ "$REMOVE_IMAGES" == "true" ]]; then
    log "Removing Docker images..."
    docker compose -f "$COMPOSE_FILE" down --rmi all --volumes --remove-orphans
    log "Images removed."
fi

# Clean up dangling resources
log "Cleaning up dangling Docker resources..."
docker system prune -f --filter "label=com.docker.compose.project=oc-bootstrap" || true

log "Cleanup complete!"

# Show remaining resources
echo ""
log "Remaining OpenClaw-related resources:"
echo "  Containers:"
docker ps -a --filter "name=oc-bootstrap" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2> /dev/null || echo "    (none)"
echo "  Volumes:"
docker volume ls --filter "name=openclaw" --format "{{.Name}}" 2> /dev/null || echo "    (none)"
echo "  Images:"
docker images --filter "reference=oc-bootstrap" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2> /dev/null || echo "    (none)"
