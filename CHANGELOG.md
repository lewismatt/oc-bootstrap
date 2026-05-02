# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Documentation Specialist Agent**: Created `.github/agents/documentation-specialist.agent.md` for improving repository documentation
- **CONTRIBUTING.md**: Comprehensive contributing guidelines with coding standards and testing instructions
- **CODE_OF_CONDUCT.md**: Contributor Covenant Code of Conduct for community standards
- **Dependencies & Attributions Section**: Added to README.md with proper citation of open source projects
- **README Badges**: Added license, platform, Node.js, Docker, and Telegram badges
- **Quick Start Section**: Added concise 5-minute setup guide at the top of README

### Changed

- **README.md**: Improved structure with better section organization and visual enhancements
- **Documentation**: Enhanced formatting and clarity across all documentation files

### Improved

- **Repository Organization**: Better structure for both seasoned developers and new users
- **Dependency Citations**: Clear attribution of open source projects with license information

---

## [Previous]

### Added

- **Uninstall Script**: Created `uninstall-oc-bootstrap.sh` for safe removal of OpenClaw installations
  - Interactive confirmation for each major deletion (workspaces, secrets, memory, config)
  - Supports `--yes` flag for automated uninstalls (use with caution)
  - Supports `--preserve-workspaces` flag to keep agent prompt files
  - Stops gateway if running before removal
  - Optionally removes OpenClaw binary (asks user)
  - Does NOT remove system packages (curl, git, nodejs) - prints manual removal instructions
- **Progress Indicators**: Implemented progress bars for long-running operations
  - System Preparation: 5-step progress tracking (sudo, PPA, apt, install, health check)
  - Agent Provisioning: 3-agent progress tracking
  - Memory Configuration: 5-task progress tracking
- **Section Summaries**: Added comprehensive summaries at the end of each installation stage
  - System Preparation
  - Agent Workspace Provisioning
  - Agent Secrets & MCP Configuration
  - Skills & Hooks Configuration
  - Telegram Channel Binding
  - Memory & Vector Search
  - Prompt File Seeding
  - Gateway Startup
  - Final Verification
- **Enhanced Final Report**: Detailed setup summary displaying paths, configurations, and deployed models

### Changed

- **Documentation**: Updated `LLM.md` to reflect that the dreaming process uses the generative Assistant Model
  rather than the embedding model.
- **Gitignore**: Replaced hardcoded `.qwen-recommends.md` with agnostic `*.recommends.md` rule to support any
  chosen model.

### Fixed

- **Dreaming Model Assignment**: Assigned generative assistant model instead of embedding model to
  `memory.dreaming.model` to prevent crashes during the dreaming phase.
- **Vector Search Model Prefix**: Stripped provider prefixes (e.g., `lemonade/`) from the embedding model tag
  before passing it to the OpenClaw `openai` provider block.
- **Critical Bug**: Fixed undefined variable reference in sudo check that occurred before exit codes were
  defined
  - Moved exit code definitions before the sudo trap guardrail (Section 0)
- **Exit Code Consistency**: Replaced 15+ generic `exit 1` statements with semantic exit codes
  - `E_SUDO=10` for sudo access failures
  - `E_DEPENDENCY=11` for missing dependencies
  - `E_OPENCLAW=12` for OpenClaw installation issues
  - `E_CONFIG=13` for configuration failures
  - `E_GATEWAY=14` for gateway startup issues

### Improved

- **User Feedback**: Enhanced script visibility with progress tracking and structured section reporting
- **Error Handling**: Semantic exit codes now enable better error diagnosis and scripting integration
- **Code Organization**: Consistent formatting and summary patterns throughout all installation stages
