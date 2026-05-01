# Docker Deployment

Deploy OpenClaw using Docker containers.

## Quick Start

```bash
# Clone repository
git clone https://github.com/lewismatt/oc-bootstrap.git
cd oc-bootstrap

# Configure
cp docker-config.env.template docker-config.env
nano docker-config.env

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

## Architecture

```
┌─────────────────────────────────────┐
│         Docker Network              │
│  ┌──────────┐  ┌──────────┐  │
│  │OpenClaw│  │Lemonade │  │
│  │Container│  │Server   │  │
│  └──────────┘  └──────────┘  │
└─────────────────────────────────────┘
```

## Configuration

Edit `docker-config.env`:
- `OPENCLAW_HOME`: Container path (default: /opt/openclaw)
- `OPENCLAW_USER`: User to run services
- `OPENCLAW_DEFAULT_MODEL`: Model to use
- `LEMONADE_URL`: Lemonade server URL

## Volumes

- `openclaw-data`: Persistent OpenClaw data
- `openclaw-logs`: Container logs
- `lemonade-data`: Model cache

## Commands

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop and cleanup
docker-compose down -v

# Rebuild after changes
docker-compose up -d --build
```

## Troubleshooting

See [Troubleshooting](Troubleshooting.md) for common issues.
