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
# DOCKER COMPOSE COMMANDS (using modern 'docker compose' V2 syntax)
# ==============================================================================

.PHONY: build up down restart logs shell test test-full test-full-real test-quick clean clean-all help

## Build Docker image
build:
	docker compose -f $(COMPOSE_FILE) build

## Start services in background
up:
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "Services started. Use 'make logs' to view logs."

## Stop services
down:
	docker compose -f $(COMPOSE_FILE) down

## Restart services
restart: down up

## View logs (follow mode)
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

## View last N lines of logs
logs-%:
	docker compose -f $(COMPOSE_FILE) logs --tail=$* $(CONTAINER_NAME)

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
		-v openclaw-data:/home/openclaw/.openclaw \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		shell

## Run bootstrap in container
bootstrap:
	docker run -it --rm \
		--env-file docker-config.env \
		-v openclaw-data:/home/openclaw/.openclaw \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		bootstrap

## Start gateway in foreground
gateway:
	docker run -it --rm \
		--env-file docker-config.env \
		-v openclaw-data:/home/openclaw/.openclaw \
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

## Run full integration test (requires Docker)
test-full:
	./tests/full-integration-test.sh --verbose

## Run full integration test with real credentials (set env vars first)
test-full-real:
	./tests/full-integration-test.sh --verbose

# ==============================================================================
# CLEANUP
# ==============================================================================

## Stop and remove containers (keep volumes)
clean:
	docker compose -f $(COMPOSE_FILE) down

## Stop and remove containers AND volumes (DESTRUCTIVE)
clean-all:
	docker compose -f $(COMPOSE_FILE) down -v
	rm -rf scripts/*.bak *.bak

## Remove test images
clean-images:
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true

# ==============================================================================
# HELP
# ==============================================================================

help:
	@echo "OpenClaw Docker Makefile - Available commands:"
	@echo "  make build        - Build Docker image"
	@echo "  make up            - Start services"
	@echo "  make down          - Stop services"
	@echo "  make restart       - Restart services"
	@echo "  make logs          - View logs (follow)"
	@echo "  make shell         - Open shell in container"
	@echo "  make test          - Run Docker tests"
	@echo "  make test-full     - Run full integration test"
	@echo "  make test-full-real - Run full test with real credentials"
	@echo "  make test-quick    - Run quick tests"
	@echo "  make clean         - Stop and remove containers"
	@echo "  make clean-all     - Stop, remove containers AND volumes"
	@echo "  make help          - Show this help message"
