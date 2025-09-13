include .env


COMPOSE=docker compose
NET?=$(ATLAS_DOCKER_NETWORK)


.PHONY: help up-core up-all down-all logs ps restart %


help:
@echo "Targets:"
@echo " up-core → proxy + dashboard + portainer"
@echo " up-all → everything"
@echo " down-all → stop all stacks"
@echo " logs → tail all"
@echo " ps → list services"
@echo " restart NAME=stack → restart a stack (folder name)"


up-core:
$(COMPOSE) -f proxy/docker-compose.yml up -d
$(COMPOSE) -f dashboard/docker-compose.yml up -d
$(COMPOSE) -f portainer/docker-compose.yml up -d


up-all: up-core
$(COMPOSE) -f cloud/docker-compose.yml up -d
$(COMPOSE) -f knowledge/docker-compose.yml up -d
$(COMPOSE) -f security/docker-compose.yml up -d
$(COMPOSE) -f monitoring/docker-compose.yml up -d
$(COMPOSE) -f notifications/docker-compose.yml up -d


down-all:
$(COMPOSE) -f notifications/docker-compose.yml down
$(COMPOSE) -f monitoring/docker-compose.yml down
$(COMPOSE) -f security/docker-compose.yml down
$(COMPOSE) -f knowledge/docker-compose.yml down
$(COMPOSE) -f cloud/docker-compose.yml down
$(COMPOSE) -f portainer/docker-compose.yml down
$(COMPOSE) -f dashboard/docker-compose.yml down
$(COMPOSE) -f proxy/docker-compose.yml down


logs:
docker logs -f --tail=200 $$(docker ps --format '{{.Names}}')


ps:
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'


restart:
@[ -n "$(NAME)" ] || (echo "Usage: make restart NAME=stack" && exit 1)
$(COMPOSE) -f $(NAME)/docker-compose.yml down && $(COMPOSE) -f $(NAME)/docker-compose.yml up -d