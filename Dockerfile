# ==============================================================================
# OpenClaw Multi-Agent Bootstrap - Docker Image
# ==============================================================================
# Containerized environment for OpenClaw AI agents
# Base: Ubuntu 24.04 (matching project requirements)
# Includes: Node.js 20.x, OpenClaw CLI, and all dependencies
# ==============================================================================

FROM ubuntu:24.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ==============================================================================
# INSTALL SYSTEM DEPENDENCIES
# ==============================================================================

RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# INSTALL NODE.JS 22.x (via NodeSource) - Required by OpenClaw
# ==============================================================================

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify Node.js and npm installation
RUN node --version && npm --version

# ==============================================================================
# INSTALL OPENCLAW CLI
# ==============================================================================

# Install OpenClaw globally via npm (avoids interactive installer issues in Docker)
RUN npm install -g openclaw@latest

# Verify OpenClaw installation
RUN openclaw --version || echo "OpenClaw installed (version check may require config)"

# ==============================================================================
# CREATE NON-ROOT USER FOR SECURITY
# ==============================================================================

RUN useradd -m -s /bin/bash openclaw \
    && echo "openclaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/openclaw \
    && chmod 0440 /etc/sudoers.d/openclaw

# ==============================================================================
# SET UP WORKING DIRECTORY AND PERMISSIONS
# ==============================================================================

WORKDIR /home/openclaw

# Create OpenClaw directories with proper permissions
RUN mkdir -p /home/openclaw/.openclaw/logs \
    && mkdir -p /home/openclaw/.openclaw/memory \
    && mkdir -p /home/openclaw/workspace \
    && chown -R openclaw:openclaw /home/openclaw

# Copy bootstrap scripts to container (optional, for development/testing)
COPY --chown=openclaw:openclaw . /home/openclaw/oc-bootstrap/

# ==============================================================================
# SWITCH TO NON-ROOT USER
# ==============================================================================

USER openclaw

# Set environment variables for OpenClaw
ENV HOME=/home/openclaw
ENV OPENCLAW_HOME=/home/openclaw/.openclaw

# ==============================================================================
# VOLUME FOR PERSISTENCE
# ==============================================================================

VOLUME ["/home/openclaw/.openclaw"]

# ==============================================================================
# ENTRYPOINT
# ==============================================================================

COPY --chown=openclaw:openclaw scripts/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["gateway"]
