#!/bin/bash
# ==============================================================================
# LEMONADE SERVER INSTALLER (LOCAL INFERENCE)
# ==============================================================================
# This script installs Lemonade Server for local LLM inference.
# It is optimized for Ubuntu 24.04 and AMD/NVIDIA GPUs.
#
# Exit on errors, undefined variables, and pipe failures to ensure robustness
# ==============================================================================
set -euo pipefail

echo "=== Lemonade Server Installer ==="

# SECTION 1: Verify Python3 is installed and accessible
# Requirements: Python 3.8+ for lemonade-server compatibility
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 is not installed. Please install it with: sudo apt install python3"
    exit 1
fi

# Verify pip3 is installed, which is required for dependency management
if ! command -v pip3 >/dev/null 2>&1; then
    echo "[INFO] Installing pip3..."
    sudo apt update && sudo apt install -y python3-pip
fi

# Verify git is installed (required for cloning/updating the Lemonade Server repository)
if ! command -v git >/dev/null 2>&1; then
    echo "[ERROR] Git is not installed. Please install it with: sudo apt install git"
    exit 1
fi

# SECTION 2: Clone or update Lemonade Server repository
# This repository contains the server code and requirements.txt
LEMONADE_DIR="$HOME/lemonade-server"
if [[ -d "$LEMONADE_DIR" ]]; then
    echo "[INFO] Lemonade Server already exists at $LEMONADE_DIR. Updating..."
    cd "$LEMONADE_DIR" && git pull || { echo "[ERROR] Failed to update repository"; exit 1; }
else
    echo "[INFO] Cloning Lemonade Server..."
    git clone https://github.com/lemonade-ai/lemonade-server.git "$LEMONADE_DIR" || \
        { echo "[ERROR] Failed to clone repository"; exit 1; }
    cd "$LEMONADE_DIR"
fi

# Verify lspci is available for GPU detection (provided by pciutils package)
if ! command -v lspci >/dev/null 2>&1; then
    echo "[WARN] lspci not found. Installing pciutils to enable GPU detection..."
    sudo apt update && sudo apt install -y pciutils || \
        echo "[WARN] Failed to install pciutils. GPU detection will be skipped, defaulting to CPU mode."
fi

# SECTION 3: Detect GPU hardware and install appropriate drivers/libraries
# GPU acceleration dramatically improves inference speed. CPU-only mode is significantly slower.
echo ""
echo "--- GPU Detection & Dependency Installation ---"
if lspci | grep -i "nvidia" >/dev/null; then
    echo "[INFO] NVIDIA GPU detected. CUDA support will be used automatically."
    # NVIDIA container toolkit and CUDA are typically handled by torch installation
elif lspci | grep -i "amd" >/dev/null; then
    echo "[INFO] AMD GPU detected. Installing ROCm support..."
    echo "[INFO] Installing ROCm core and libraries (this may take a while)..."
    sudo apt update && sudo apt install -y rocm-core rocm-libs || \
        echo "[WARN] Failed to install ROCm via apt. Ensure you have the ROCm repositories configured if performance is low."
else
    echo "[WARN] No dedicated GPU detected. Lemonade will run on CPU (significantly slower)."
fi

# SECTION 4: Create and activate Python virtual environment
# Isolates dependencies from system packages to prevent conflicts
# The --system-site-packages flag is intentionally omitted for cleaner isolation
if [[ ! -d "venv" ]]; then
    echo "[INFO] Creating Python virtual environment..."
    python3 -m venv venv
fi

# SECTION 5: Install Python dependencies in the virtual environment
echo "[INFO] Installing Python requirements..."
# shellcheck source=/dev/null (suppresses shellcheck warnings for dynamic sourcing)
source venv/bin/activate

# Upgrade pip first to avoid compatibility issues with newer packages
pip install --upgrade pip || { echo "[ERROR] Failed to upgrade pip"; exit 1; }
# Install project requirements from the cloned repository
pip install -r requirements.txt || { echo "[ERROR] Failed to install requirements.txt"; exit 1; }
# Install huggingface_hub for model downloads via huggingface-cli
pip install huggingface_hub || { echo "[ERROR] Failed to install huggingface_hub"; exit 1; }

# Verify huggingface-cli is available after installation
if ! command -v huggingface-cli >/dev/null 2>&1; then
    echo "[ERROR] huggingface-cli not found after installing huggingface_hub. Please check installation."
    exit 1
fi

# SECTION 6: Download Default Models (Optional)
# These models are recommended for basic local inference use cases
# Note: Some models may require HuggingFace authentication (huggingface-cli login)
echo ""
read -r -p "Download recommended models (Qwen2.5-4B & Nomic Embed)? [y/N]: " DOWNLOAD_MODELS
if [[ "${DOWNLOAD_MODELS^^}" == "Y" ]]; then
    echo "[INFO] Downloading Qwen2.5-4B-Instruct-GGUF..."
    # Create local directory for Qwen2.5-4B model (consistent naming with model version)
    mkdir -p models/huggingface.co/user.Qwen2.5-4B-GGUF/
    huggingface-cli download Qwen/Qwen2.5-4B-Instruct-GGUF qwen2.5-4b-instruct-q4_k_m.gguf \
        --local-dir models/huggingface.co/user.Qwen2.5-4B-GGUF/ || \
        { echo "[ERROR] Failed to download Qwen2.5-4B model"; exit 1; }

    echo "[INFO] Downloading Nomic Embed Text v1.5 GGUF..."
    # Create local directory for Nomic Embed model
    mkdir -p models/huggingface.co/user.nomic-embed-text-v1.5-GGUF/
    huggingface-cli download nomic-ai/nomic-embed-text-v1.5-GGUF nomic-embed-text-v1.5.Q4_K_M.gguf \
        --local-dir models/huggingface.co/user.nomic-embed-text-v1.5-GGUF/ || \
        { echo "[ERROR] Failed to download Nomic Embed model"; exit 1; }
fi

# SECTION 7: Create Startup Script
# This script activates the venv and starts the Lemonade server with sensible defaults
cat <<EOF >start-lemonade.sh
#!/bin/bash
# Activate the Python virtual environment created during installation
source venv/bin/activate

# Optional: Override AMD GPU version if your GPU is not officially supported by ROCm
# Uncomment and adjust the version below to match your AMD GPU's GFX version
# export HSA_OVERRIDE_GFX_VERSION=11.0.0

# Start Lemonade Server
# --host 0.0.0.0: Listen on all network interfaces (accessible from other devices)
# --port 8000: Default port for Lemonade Server
# --models-path ./models: Directory where downloaded models are stored
python -m lemonade.server --host 0.0.0.0 --port 8000 --models-path ./models
EOF
chmod +x start-lemonade.sh

echo ""
echo "=== Installation Complete ==="
echo "To start Lemonade Server, run:"
echo "  cd $LEMONADE_DIR && ./start-lemonade.sh"
echo ""
echo "In the OpenClaw installer, use your local IP and these tags:"
echo "  - LLM: lemonade/user.Qwen2.5-4B-GGUF"
echo "  - Embedding: lemonade/user.nomic-embed-text-v1.5-GGUF"
