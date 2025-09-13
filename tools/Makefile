# Atlas Infra Makefile
# Manages modular Docker Compose stacks

# Load configs
include ../config/server_config.env
-include ../config/.env
export

COMPOSE = sudo docker compose
SERVICES_DIR = ../services
NET ?= $(ATLAS_DOCKER_NETWORK)

.PHONY: help up up-core up-all down-all ps logs restart clean

help:
	@echo "Available commands:"
	@echo "  make up-core      → start core services (proxy, dashboard, portainer)"
	@echo "  make up-all       → start all services"
	@echo "  make up           → alias for up-all"
	@echo "  make down-all     → stop all services"
	@echo "  make ps           → show running containers"
	@echo "  make logs         → follow logs from all containers"
	@echo "  make restart NAME=stack  → restart one stack (e.g. NAME=cloud)"
	@echo "  make clean        → remove all containers, networks, and volumes"

# --- Aliases ---
up: up-all

# --- Core layer ---
up-core:
	$(COMPOSE) -f $(SERVICES_DIR)/proxy/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/dashboard/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/portainer/docker-compose.yml up -d

# --- Full stack ---
up-all: up-core
	$(COMPOSE) -f $(SERVICES_DIR)/cloud/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/knowledge/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/security/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/monitoring/docker-compose.yml up -d
	$(COMPOSE) -f $(SERVICES_DIR)/notifications/docker-compose.yml up -d

# --- Tear down ---
down-all:
	$(COMPOSE) -f $(SERVICES_DIR)/notifications/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/monitoring/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/security/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/knowledge/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/cloud/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/portainer/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/dashboard/docker-compose.yml down
	$(COMPOSE) -f $(SERVICES_DIR)/proxy/docker-compose.yml down

# --- Utilities ---
ps:
	docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

logs:
	docker logs -f --tail=200 $$(docker ps --format '{{.Names}}')

restart:
	@[ -n "$(NAME)" ] || (echo "Usage: make restart NAME=stack" && exit 1)
	$(COMPOSE) -f $(SERVICES_DIR)/$(NAME)/docker-compose.yml down && $(COMPOSE) -f $(SERVICES_DIR)/$(NAME)/docker-compose.yml up -d

clean:
	docker system prune -af --volumes
