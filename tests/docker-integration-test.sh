#!/bin/bash
# =============================================================================
# Docker Integration Test Script
# =============================================================================

set -o errexit
unset -o nounset

# Colors
GREEN='\033[0;32m'
NC='\033[0m'
RED='\033[0;31m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

info "Starting Docker integration tests..."

# Test 1: Build Docker image
info "Test 1: Building Docker image..."
docker build -t openclaw-test . || error "Docker build failed"

# Test 2: Run container
info "Test 2: Running container..."
docker run -d --name openclaw-test -p 8080:8080 openclaw-test || error "Container start failed"

# Test 3: Wait for Ollama
sleep 10

# Test 4: Check if Ollama is running
info "Test 3: Checking Ollama..."
curl -s http://localhost:8080/api/tags || error "Ollama not responding"

# Cleanup
info "Cleaning up..."
docker stop openclaw-test 2>/dev/null || true
docker rm openclaw-test 2>/dev/null || true
docker rmi openclaw-test 2>/dev/null || true

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
success "All Docker integration tests passed!"
