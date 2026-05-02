# Troubleshooting

Common issues and solutions for OpenClaw.

## Installation Issues

### Ollama Won't Install
- **Cause**: Network issue or unsupported OS
- **Solution**: Check internet, verify OS compatibility
- **Command**: `curl -fsSL https://ollama.com/install.sh | sh`

### Permission Denied
- **Cause**: Insufficient privileges
- **Solution**: Use sudo or check file permissions
- **Command**: `chmod +x oc-bootstrap.sh`

## Runtime Issues

### Container Won't Start
- **Cause**: Port conflict or config error
- **Solution**: Check logs, verify config
- **Command**: `docker-compose logs -f`

### Ollama Not Responding
- **Cause**: Model not pulled or service down
- **Solution**: Pull model, restart service
- **Command**: `ollama pull llama3.2`

### Out of Memory
- **Cause**: Model too large for system
- **Solution**: Use smaller model or add swap
- **Command**: `ollama pull llama3.2:1b`

## Network Issues

### Connection Refused
- **Cause**: Service not running or firewall
- **Solution**: Check service status, verify firewall
- **Command**: `curl http://localhost:11434/api/tags`

### API Errors
- **Cause**: Invalid request or model
- **Solution**: Check API format, verify model name
- **Command**: `curl http://localhost:11434/api/tags`

## Getting Help

- Check [Installation](Installation.md) guide
- Review [Docker Deployment](Docker-Deployment.md)
- Open issue on [GitHub](https://github.com/lewismatt/oc-bootstrap/issues)
