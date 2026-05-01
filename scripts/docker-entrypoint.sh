#!/bin/bash
# =============================================================================
# Docker Entrypoint Script for OpenClaw
# =============================================================================

set -o errexit

# Default values
OPENCLAW_HOME="${OPENCLAW_HOME:-/opt/openclaw}"
OPENCLAW_ENV="${OPENCLAW_ENV:-development}"

# Ensure directories exist
mkdir -p "$OPENCLAW_HOME/logs"
mkdir -p "$OPENCLAW_HOME/workspace"

# Start Ollama in background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "[INFO] Ollama is ready!"
        break
    fi
    echo "[INFO] Waiting for Ollama... ($i/30)"
    sleep 1
done

# Pull default model if not present
if ! ollama list | grep -q "$OPENCLAW_DEFAULT_MODEL"; then
    echo "[INFO] Pulling default model: $OPENCLAW_DEFAULT_MODEL"
    ollama pull "$OPENCLAW_DEFAULT_MODEL"
fi

# Start OpenClaw
cd "$OPENCLAW_HOME"
echo "[INFO] Starting OpenClaw in $OPENCLAW_ENV mode..."

# Run OpenClaw (adjust based on actual command)
if [[ -x ./oc-bootstrap.sh ]]; then
    ./oc-bootstrap.sh --start
else
    echo "[ERROR] oc-bootstrap.sh not found or not executable"
    exit 1
fi

# Cleanup on exit
trap 'kill $OLLAMA_PID 2>/dev/null; exit' TERM INT
wait $OLLAMA_PID
