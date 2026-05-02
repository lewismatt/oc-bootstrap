#!/bin/bash
# =============================================================================
# Docker Cleanup Script for OpenClaw
# =============================================================================

set -o errexit
nset -o nounset

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

info "Starting Docker cleanup..."

# Stop and remove containers
docker-compose down -v 2>/dev/null || true

# Remove unused containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove unused volumes
docker volume prune -f

# Remove unused networks
docker network prune -f

warn "Cleanup complete!"
