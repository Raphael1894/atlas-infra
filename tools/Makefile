# Atlas Infra Makefile
# Manages modular Docker Compose stacks

# Makefile directory (absolute)
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Env files for Compose
ENV_FILES = --env-file $(MAKEFILE_DIR)/../config/server_config.env --env-file $(MAKEFILE_DIR)/../config/.env

COMPOSE = sudo docker compose
SERVICES_DIR = $(MAKEFILE_DIR)/../services
NET ?= $(ATLAS_DOCKER_NETWORK)

.PHONY: help up up-core up-all down-all ps logs restart clean nuke

help:
	@echo "Available commands:"
	@echo "  make up-core      → start core services (proxy, dashboard, portainer)"
	@echo "  make up-all       → start all services"
	@echo "  make up           → alias for up-all"
	@echo "  make down-all     → stop all services"
	@echo "  make ps           → show running containers"
	@echo "  make logs         → follow logs from all containers"
	@echo "  make restart NAME=stack  → restart one stack (e.g. NAME=nextcloud)"
	@echo "  make clean        → remove all containers, networks, and volumes"
	@echo "  make nuke         → ⚠️ stop & remove ALL Docker containers, networks, images, and volumes"

# --- Aliases ---
up: up-all

# --- Core layer ---
up-core:
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/proxy/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/dashboard/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/portainer/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/homepage/docker-compose.yml up -d


# --- Full stack ---
up-all: up-core
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/nextcloud/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/knowledge/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/security/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/monitoring/docker-compose.yml up -d
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/notifications/docker-compose.yml up -d

# --- Tear down ---
down-all:
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/notifications/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/monitoring/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/security/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/knowledge/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/nextcloud/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/portainer/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/dashboard/docker-compose.yml down
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/proxy/docker-compose.yml down

# --- Utilities ---
ps:
	docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

logs:
	docker logs -f --tail=200 $$(docker ps --format '{{.Names}}')

restart:
	@[ -n "$(NAME)" ] || (echo "Usage: make restart NAME=stack" && exit 1)
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/$(NAME)/docker-compose.yml down && $(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/$(NAME)/docker-compose.yml up -d

clean:
	docker system prune -af --volumes

restart-proxy:
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/proxy/docker-compose.yml down && \
	$(COMPOSE) $(ENV_FILES) -f $(SERVICES_DIR)/proxy/docker-compose.yml up -d


nuke:
	@echo "☢️  💥  This will stop and remove ALL Docker containers, networks, images, and volumes."
	@read -p "Are you sure? [y/N] " ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		if [ -n "$$(docker ps -aq)" ]; then \
			echo "☢️  Stopping all containers..."; \
			docker stop $$(docker ps -aq); \
			echo "☢️  Removing all containers..."; \
			docker rm -vf $$(docker ps -aq); \
		fi; \
		echo "💥 Cleaning up networks, images, and volumes..."; \
		docker system prune -af --volumes; \
		echo "☢️💥  Docker environment fully reset. Boom!"; \
	else \
		echo "❌ Nuke cancelled."; \
	fi
