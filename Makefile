# ==============================================================================
# OpenClaw Docker Makefile
# ==============================================================================
# Convenience commands for Docker operations
#
# Usage:
#   make build          # Build Docker image
#   make up             # Start services
#   make down           # Stop services
#   make logs           # View logs
#   make shell          # Open shell in container
#   make test           # Run tests
#   make clean          # Clean up everything
# ==============================================================================

# Variables
COMPOSE_FILE := docker-compose.yml
IMAGE_NAME := oc-bootstrap
IMAGE_TAG := latest
CONTAINER_NAME := oc-bootstrap

# ==============================================================================
# DOCKER COMPOSE COMMANDS
# ==============================================================================

.PHONY: build up down restart logs shell test clean help

## Build Docker image
build:
	docker-compose -f $(COMPOSE_FILE) build

## Start services in background
up:
	docker-compose -f $(COMPOSE_FILE) up -d
	@echo "Services started. Use 'make logs' to view logs."

## Stop services
down:
	docker-compose -f $(COMPOSE_FILE) down

## Restart services
restart: down up

## View logs (follow mode)
logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

## View last N lines of logs
logs-%:
	docker-compose -f $(COMPOSE_FILE) logs --tail=$* $(CONTAINER_NAME)

# ==============================================================================
# DOCKER CLI COMMANDS
# ==============================================================================

## Open interactive shell in running container
shell:
	docker exec -it $(CONTAINER_NAME) bash

## Open interactive shell (new container)
shell-new:
	docker run -it --rm \
		--env-file docker-config.env \
		-v oc-bootstrap_openclaw-data:/home/openclaw/.openclaw \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		shell

## Run bootstrap in container
bootstrap:
	docker run -it --rm \
		--env-file docker-config.env \
		-v oc-bootstrap_openclaw-data:/home/openclaw/.openclaw \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		bootstrap

## Start gateway in foreground
gateway:
	docker run -it --rm \
		--env-file docker-config.env \
		-v oc-bootstrap_openclaw-data:/home/openclaw/.openclaw \
		$(IMAGE_NAME):$(IMAGE_TAG)

# ==============================================================================
# TESTING
# ==============================================================================

## Run all Docker tests
test:
	./tests/docker-test.sh --verbose

## Run quick tests (skip build)
test-quick:
	./tests/docker-test.sh --quick --verbose

# ==============================================================================
# CLEANUP
# ==============================================================================

## Stop and remove containers (keep volumes)
clean:
	./docker-cleanup.sh

## Stop and remove containers + volumes (DESTRUCTIVE)
clean-all:
	./docker-cleanup.sh --prune

## Full cleanup (containers, volumes, images)
clean-images:
	./docker-cleanup.sh --all

# ==============================================================================
# HELP
# ==============================================================================

## Show this help message
help:
	@echo "OpenClaw Docker Makefile"
	@echo ""
	@echo "Commands:"
	@echo "  build        - Build Docker image"
	@echo "  up           - Start services in background"
	@echo "  down         - Stop services"
	@echo "  restart      - Restart services"
	@echo "  logs         - View logs (follow mode)"
	@echo "  shell        - Open shell in running container"
	@echo "  shell-new    - Open shell (new container)"
	@echo "  bootstrap    - Run bootstrap in container"
	@echo "  gateway      - Start gateway in foreground"
	@echo "  test         - Run all Docker tests"
	@echo "  test-quick   - Run quick tests (skip build)"
	@echo "  clean        - Stop and remove containers (keep volumes)"
	@echo "  clean-all    - Stop and remove containers + volumes"
	@echo "  clean-images - Full cleanup (containers, volumes, images)"
	@echo "  help         - Show this help message"
