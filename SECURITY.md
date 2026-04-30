# Security Policy

## Reporting a Vulnerability

We take the security of OpenClaw Bootstrap seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to:
- **Security Contact**: [openclaw-security@github.com](mailto:openclaw-security@github.com)

### What to Include

When reporting a vulnerability, please include:

- **Description** of the vulnerability
- **Steps to reproduce** (if reproducible)
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your contact information** for follow-up questions

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Status updates**: Every 7 days until resolution

### Disclosure Policy

- Security vulnerabilities will be disclosed responsibly
- We will coordinate with you on the disclosure timeline
- Credit will be given in security advisories (unless you prefer to remain anonymous)

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < 1.0   | :x:                |

## Security Best Practices

When using OpenClaw Bootstrap:

1. **Protect your tokens**: Never commit Telegram bot tokens or API keys to version control
2. **Use secrets management**: Consider using Docker secrets or environment variable files that are gitignored
3. **Regular updates**: Keep your OpenClaw installation and dependencies up to date
4. **Least privilege**: Run containers with minimal required permissions (this project uses non-root user by default)
5. **Network security**: When using local inference, ensure Lemonade Server is properly firewalled

## Third-Party Dependencies

This project relies on:
- **OpenClaw** - Review their security advisories at [github.com/openclaw/openclaw/security](https://github.com/openclaw/openclaw/security)
- **Node.js** - See [nodejs.org/security](https://nodejs.org/en/security)
- **Docker** - See [docker.com/security](https://www.docker.com/security)

## Known Security Considerations

### Telegram Bot Tokens
Bot tokens are sensitive credentials. If a token is compromised:
1. Contact @BotFather on Telegram
2. Use the `/mybots` command
3. Select your bot → API Token → Regenerate token

### Local Inference (Lemonade Server)
When running Lemonade Server locally:
- The server runs with default authentication (`local-dummy-key`)
- Ensure the server is not exposed to the public internet
- Consider adding proper authentication if deployed on a network

### Docker Containers
- Containers run as non-root user (`openclaw`, UID 1000)
- Volume mounts should be properly permissioned
- Keep Docker and Docker Compose up to date

## Contact

For security-related questions or concerns:
- Email: [openclaw-security@github.com](mailto:openclaw-security@github.com)
- Open an issue for non-sensitive security discussions
