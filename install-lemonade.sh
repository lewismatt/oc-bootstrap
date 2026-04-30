#!/bin/bash
set -euo pipefail

# ==============================================================================
# LEMONADE SERVER INSTALLER (LOCAL INFERENCE)
# ==============================================================================
# This script installs Lemonade Server for local LLM inference.
# It is optimized for Ubuntu 24.04 and AMD/NVIDIA GPUs.
# ==============================================================================

echo "=== Lemonade Server Installer ==="

# 1. Check for Python and Virtual Environment
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 is not installed. Please install it with: sudo apt install python3"
    exit 1
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo "[INFO] Installing pip3..."
    sudo apt update && sudo apt install -y python3-pip
fi

# 2. Clone Lemonade Server
LEMONADE_DIR="$HOME/lemonade-server"
if [[ -d "$LEMONADE_DIR" ]]; then
    echo "[INFO] Lemonade Server already exists at $LEMONADE_DIR. Updating..."
    cd "$LEMONADE_DIR" && git pull
else
    echo "[INFO] Cloning Lemonade Server..."
    git clone https://github.com/lemonade-ai/lemonade-server.git "$LEMONADE_DIR"
    cd "$LEMONADE_DIR"
fi

# 3. Detect GPU and Install Dependencies
echo ""
echo "--- GPU Detection & Dependency Installation ---"
if lspci | grep -i "nvidia" >/dev/null; then
    echo "[INFO] NVIDIA GPU detected."
    # Add NVIDIA-specific dependencies if any, otherwise standard pip install
elif lspci | grep -i "amd" >/dev/null; then
    echo "[INFO] AMD GPU detected."
    echo "[INFO] Installing ROCm core and libraries (this may take a while)..."
    sudo apt update && sudo apt install -y rocm-core rocm-libs || echo "[WARN] Failed to install ROCm via apt. Ensure you have the ROCm repositories configured if performance is low."
else
    echo "[WARN] No dedicated GPU detected. Lemonade will run on CPU (slow)."
fi

# 4. Create Virtual Environment and Install Requirements
if [[ ! -d "venv" ]]; then
    echo "[INFO] Creating virtual environment..."
    python3 -m venv venv
fi

echo "[INFO] Installing Python requirements..."
# shellcheck source=/dev/null
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install huggingface_hub # For model downloads

# 5. Download Default Models (Optional)
echo ""
read -r -p "Download recommended models (Qwen2.5-4B & Nomic Embed)? [y/N]: " DOWNLOAD_MODELS
if [[ "${DOWNLOAD_MODELS^^}" == "Y" ]]; then
    echo "[INFO] Downloading Qwen2.5-4B-Instruct-GGUF..."
    mkdir -p models/huggingface.co/user.Qwen3.5-4B-GGUF/
    huggingface-cli download Qwen/Qwen2.5-4B-Instruct-GGUF qwen2.5-4b-instruct-q4_k_m.gguf \
        --local-dir models/huggingface.co/user.Qwen3.5-4B-GGUF/

    echo "[INFO] Downloading Nomic Embed Text v1.5 GGUF..."
    mkdir -p models/huggingface.co/user.nomic-embed-text-v1.5-GGUF/
    huggingface-cli download nomic-ai/nomic-embed-text-v1.5-GGUF nomic-embed-text-v1.5.Q4_K_M.gguf \
        --local-dir models/huggingface.co/user.nomic-embed-text-v1.5-GGUF/
fi

# 6. Create Startup Script
cat <<EOF >start-lemonade.sh
#!/bin/bash
source venv/bin/activate
# Adjust HSA_OVERRIDE_GFX_VERSION if needed for AMD GPUs
# export HSA_OVERRIDE_GFX_VERSION=11.0.0
python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ./models
EOF
chmod +x start-lemonade.sh

echo ""
echo "=== Installation Complete ==="
echo "To start Lemonade Server, run:"
echo "  cd $LEMONADE_DIR && ./start-lemonade.sh"
echo ""
echo "In the OpenClaw installer, use your local IP and these tags:"
echo "  - LLM: lemonade/user.Qwen3.5-4B-GGUF"
echo "  - Embedding: lemonade/user.nomic-embed-text-v1.5-GGUF"
