# Lemonade Configuration

Lemonade Server provides local LLM (Large Language Model) inference, allowing you to run AI models entirely on
your own hardware. This guide covers the complete setup and configuration of Lemonade Server for use with
OpenClaw.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Model Selection](#model-selection)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Lemonade Server is an open-source inference server that supports various LLM models, optimized for both AMD and NVIDIA GPUs. When configured with OpenClaw, it enables:

- **Privacy**: All inference happens locally on your server
- **Cost Savings**: No API usage fees
- **Low Latency**: Direct hardware access
- **Offline Capability**: Works without internet (after model download)

---

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GPU | 8GB VRAM | 12GB+ VRAM |
| RAM | 16GB | 32GB |
| Storage | 10GB free | 20GB+ free |
| CPU | 4 cores | 8+ cores |

### Software Requirements

- Ubuntu 24.04 LTS
- Python 3.8+
- pip3
- Git
- CUDA (for NVIDIA) or ROCm (for AMD)

---

## Installation

### Automated Installation (Recommended)

Use the included installation script:

```bash
cd /path/to/oc-bootstrap
./scripts/install-lemonade.sh
```

The script will:
1. Verify Python3 and pip3 are installed
2. Clone or update the Lemonade Server repository
3. Install Python dependencies
4. Configure the server for your hardware

### Manual Installation

If you prefer manual setup:

```bash
# 1. Clone the repository
git clone https://github.com/lemonade-ai/lemonade-server.git ~/lemonade-server
cd ~/lemonade-server

# 2. Install dependencies
pip3 install -r requirements.txt

# 3. Verify installation
python3 -m lemonade --version
```

---

## Configuration

### Basic Configuration

Edit your OpenClaw configuration to use Lemonade Server:

**For Docker Deployment** (`docker-config.env`):

```bash
# Enable local inference
LOCAL_INFERENCE=true

# Lemonade API Key (use 'local-dummy-key' if not needed)
LEMONADE_KEY=local-dummy-key

# Lemonade Server IP (if running separately)
# LEMONADE_IP=192.168.12.50

# Model selection
ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF
RESEARCH_MODEL=lemonade/user.Qwen3.5-4B-GGUF
DEVELOPER_MODEL=lemonade/user.Qwen3.5-4B-GGUF
EMBEDDING_MODEL=lemonade/user.Qwen3.5-4B-GGUF
```

**For Bare Metal Installation** (`.env` or config file):

```bash
export LOCAL_INFERENCE=true
export LEMONADE_KEY=local-dummy-key
export ASSISTANT_MODEL=lemonade/user.Qwen3.5-4B-GGUF
```

### Advanced Configuration

Create a Lemonade configuration file at `~/lemonade-server/config.yaml`:

```yaml
server:
  host: 0.0.0.0
  port: 8000
  api_key: local-dummy-key

models:
  - name: user.Qwen3.5-4B-GGUF
    path: /path/to/models/qwen3.5-4b.gguf
    context_length: 4096
    gpu_layers: 32  # Adjust based on VRAM

  - name: user.Qwen2.5-7B-GGUF
    path: /path/to/models/qwen2.5-7b.gguf
    context_length: 8192
    gpu_layers: 28

inference:
  threads: 8
  batch_size: 512
  temperature: 0.7
```

---

## Model Selection

### Recommended Models

| Model | Size | VRAM Required | Use Case |
|-------|------|---------------|----------|
| Qwen3.5-4B | 2.5GB | 6GB | Lightweight, fast responses |
| Qwen2.5-7B | 4.2GB | 8GB | Balanced performance |
| Llama3.1-8B | 4.9GB | 10GB | High quality responses |
| Mistral-7B | 4.1GB | 8GB | Good general purpose |

### Downloading Models

```bash
cd ~/lemonade-server

# Download a model (example using huggingface-cli)
huggingface-cli download Qwen/Qwen3.5-4B-GGUF \
  --local-dir models/ \
  --local-dir-use-symlinks False

# Or manually place .gguf files in the models/ directory
```

### Verifying Model Availability

```bash
# List available models
python3 -m lemonade list-models

# Test a specific model
python3 -m lemonade run --model user.Qwen3.5-4B-GGUF --prompt "Hello, world!"
```

---

## Testing

### Test Lemonade Server

```bash
# Start the server
cd ~/lemonade-server
python3 -m lemonade serve --host 0.0.0.0 --port 8000

# In another terminal, test the API
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer local-dummy-key" \
  -d '{
    "model": "user.Qwen3.5-4B-GGUF",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Test OpenClaw Integration

```bash
# For Docker
docker compose restart openclaw
docker compose logs -f openclaw

# For Bare Metal
openclaw --test-connection
```

---

## Troubleshooting

### Common Issues

#### 1. "CUDA out of memory" Error

**Solution**: Use a smaller model or reduce GPU layers:

```yaml
# In config.yaml
models:
  - name: user.Qwen3.5-4B-GGUF
    gpu_layers: 20  # Reduce from 32 to 20
```

#### 2. "Model not found" Error

**Solution**: Verify model path and filename:

```bash
ls -la ~/lemonade-server/models/
# Ensure .gguf file exists and path is correct in config.yaml
```

#### 3. Slow Inference Speed

**Solutions**:
- Ensure GPU is being used (check `nvidia-smi` or `rocm-smi`)
- Increase GPU layers in configuration
- Use a smaller, more efficient model
- Check CPU threads setting (increase if using CPU inference)

#### 4. Connection Refused

**Solution**: Verify Lemonade Server is running and accessible:

```bash
# Check if server is listening
ss -tlnp | grep 8000

# Check firewall
sudo ufw status
sudo ufw allow 8000/tcp  # If needed
```

#### 5. AMD GPU Not Detected

**Solution**: Install ROCm drivers:

```bash
# For Ubuntu 24.04
sudo apt update
sudo apt install rocm-hip-runtime rocm-opencl-runtime
sudo reboot

# Verify
rocm-smi
```

---

## Docker Integration

To run Lemonade Server as a Docker container:

```yaml
# Add to docker-compose.yml
services:
  lemonade:
    image: python:3.11-slim
    container_name: lemonade-server
    restart: unless-stopped
    environment:
      - MODEL_PATH=/models
    volumes:
      - ./models:/models:ro
      - lemonade-data:/data
    ports:
      - "8000:8000"
    command: >
      bash -c "pip install lemonade-server && 
               python -m lemonade serve --host 0.0.0.0"
    networks:
      - openclaw-network

volumes:
  lemonade-data:
```

---

## Performance Optimization

### GPU Optimization

```bash
# For NVIDIA - monitor GPU usage
watch -n 1 nvidia-smi

# For AMD - monitor GPU usage
watch -n 1 rocm-smi

# Adjust batch size and threads based on hardware
```

### Model Quantization

Use quantized models (Q4_K_M, Q5_K_S) for better performance:

| Quantization | Size Reduction | Quality Loss |
|--------------|----------------|--------------|
| Q4_K_M | ~60% | Minimal |
| Q5_K_S | ~50% | Very minimal |
| Q8_0 | ~30% | Nearly none |

---

## Security Considerations

1. **API Key**: Even for local use, set a strong API key
2. **Network Binding**: Bind to `127.0.0.1` if not accessing remotely
3. **Firewall**: Only open port 8000 if needed externally
4. **Model Storage**: Secure the models directory with proper permissions

```bash
# Restrict access to models
chmod 700 ~/lemonade-server/models
chown -R $USER:$USER ~/lemonade-server/models
```

---

## Additional Resources

- [Lemonade Server GitHub](https://github.com/lemonade-ai/lemonade-server)
- [GGUF Model Repository](https://huggingface.co/models?search=gguf)
- [OpenClaw Documentation](../README.md)
- [Docker Setup](Docker-Deployment)

---

*Last updated: April 2026*
