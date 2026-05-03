# Contributing to OpenClaw Bootstrap

Thank you for your interest in contributing to OpenClaw Bootstrap! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Development Setup](#development-setup)
4. [Pull Request Process](#pull-request-process)
5. [Coding Standards](#coding-standards)
6. [Testing](#testing)
7. [Documentation](#documentation)

---

## 📜 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](https://github.com/lewismatt/oc-bootstrap/blob/main/CODE_OF_CONDUCT.md). Please read it to understand what behavior is expected.

---

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/lewismatt/oc-bootstrap/issues) to avoid duplicates.

**When creating a bug report, include:**

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Include relevant system information** (OS, Node.js version, etc.)
- **Include error messages and logs**

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Use a clear and descriptive title**
- **Provide a detailed description of the proposed enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make test` or `./tests/docker-test.sh`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## 🛠️ Development Setup

### Prerequisites

- Ubuntu 24.04 (or compatible Linux distribution)
- Node.js 22.x
- Docker (for testing Docker-related changes)
- Git

### Local Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/oc-bootstrap.git
cd oc-bootstrap/

# Add upstream remote
git remote add upstream https://github.com/lewismatt/oc-bootstrap.git

# Make scripts executable
chmod +x *.sh
chmod +x lib/*.sh
```

### Testing Your Changes

```bash
# Run the test suite
./tests/docker-test.sh --verbose/

# Or use make
make test

# Test interactive installation (in a VM or test environment)
./oc-bootstrap.sh
```

---

## 📏 Coding Standards

### Bash Script Standards

- **Use `set -euo pipefail`** at the top of scripts for safety
- **Quote all variable expansions** (`"$variable"` not `$variable`)
- **Use meaningful variable names** (avoid single letters except in loops)
- **Add comments for complex logic**
- **Use the helper functions** from `lib/helpers.sh` when possible
- **Follow the existing code style** (indentation, spacing)

### Example

```bash
#!/bin/bash
set -euo pipefail

# Good: descriptive variable names, quoted, commented
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Configuration file not found: $CONFIG_FILE"
    exit 1
fi
```

### Documentation Standards

- **Use Markdown** for all documentation files
- **Include code examples** with proper syntax highlighting
- **Keep README.md updated** with new features
- **Document all new environment variables**
- **Add entries to CHANGELOG.md** for user-facing changes

---

## 🧪 Testing

### Test Types

1. **Unit Tests** - Test individual functions in `lib/helpers.sh`
2. **Integration Tests** - Test the full installation process
3. **Docker Tests** - Test Docker build and functionality

### Running Tests

```bash
# Run all tests
./tests/docker-test.sh --verbose/

# Run quick tests (skip Docker build)
./tests/docker-test.sh --quick --verbose/

# Test specific functionality
bash -x oc-bootstrap.sh --help
```

### Writing Tests

When adding new features, please add corresponding tests:

```bash
# Example test structure
test_new_feature() {
    echo "Testing new feature..."
    
    # Setup
    local test_dir="/tmp/oc-test-$$"
    mkdir -p "$test_dir"
    
    # Test logic
    # ... your test here ...
    
    # Cleanup
    rm -rf "$test_dir"
    
    echo "✓ New feature test passed"
}
```

---

## 📝 Documentation

### README Updates

When making changes that affect users, update `README.md`:

- **New features** → Add to "Advanced Topics" or appropriate section
- **Configuration changes** → Update "Configuration" section
- **New dependencies** → Update "Dependencies & Attributions" section

### Inline Documentation

- **Comment complex bash logic**
- **Use function headers** to describe purpose and parameters
- **Keep comments up-to-date** with code changes

Example function documentation:

```bash
# ==============================================================================
# Install system dependencies
# ==============================================================================
# Arguments:
#   $1 - Package name or space-separated list of packages
# Returns:
#   0 on success, E_DEPENDENCY on failure
# ==============================================================================
install_packages() {
    local packages="$1"
    echo "[INFO] Installing packages: $packages"
    # ... implementation ...
}
```

---

## 🏷️ Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible changes
- **MINOR** version for new functionality (backwards-compatible)
- **PATCH** version for bug fixes (backwards-compatible)

### Changelog

Update `CHANGELOG.md` with your changes:

```text
## [Unreleased]
### Added
- New feature description

### Changed
- Change description

### Fixed
- Bug fix description
```

---

## ❓ Questions?

Feel free to:

- **Open an issue** for questions about contributing
- **Join our Discord** at [discord.gg/openclaw](https://discord.gg/openclaw)
- **Check the docs** at [docs.openclaw.ai](https://docs.openclaw.ai)

---

## 🙏 Thank You

Your contributions help make OpenClaw Bootstrap better for everyone. We appreciate your time and effort!
