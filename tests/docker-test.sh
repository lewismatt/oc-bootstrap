#!/bin/bash
# =============================================================================
# Docker Test Script
# =============================================================================

set -o errexit
unset -o nounset

# Colors
GREEN='\033[0;32m'
NC='\033[0m'
RED='\033[0;31m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

info "Starting Docker tests..."

# Test 1: Check Docker is running
info "Test 1: Checking Docker..."
docker info >/dev/null 2>&1 || error "Docker not running"

# Test 2: Build image
info "Test 2: Building image..."
docker build -t openclaw-test . || error "Build failed"

# Test 3: Run container
info "Test 3: Running container..."
CID=$(docker run -d --name test-openclaw -p 8080:8080 openclaw-test)
sleep 5

# Test 4: Check if running
info "Test 4: Checking container..."
docker ps | grep -q test-openclaw || error "Container not running"

# Cleanup
info "Cleaning up..."
docker stop $CID 2>/dev/null || true
docker rm $CID 2>/dev/null || true
docker rmi openclaw-test 2>/dev/null || true

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
success "All Docker tests passed!"
