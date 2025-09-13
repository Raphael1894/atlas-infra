#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

echo -e "${CYAN}🔍 Running Atlas sanity check...${RESET}"
echo

FAIL=0

# Load config for network
if [ -f ../config/server_config.env ]; then
  set -a
  source ../config/server_config.env
  set +a
else
  ATLAS_DOCKER_NETWORK="atlas_net"
fi

# 1. Docker installed
if command -v docker >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Docker is installed${RESET}"
else
  echo -e "${RED}❌ Docker is not installed${RESET}"
  FAIL=1
fi

# 2. Docker daemon running
if docker info >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Docker daemon is running${RESET}"
else
  echo -e "${RED}❌ Docker daemon is not running${RESET}"
  FAIL=1
fi

# 3. Network exists
if docker network inspect "$ATLAS_DOCKER_NETWORK" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Docker network '$ATLAS_DOCKER_NETWORK' exists${RESET}"
else
  echo -e "${RED}❌ Docker network '$ATLAS_DOCKER_NETWORK' missing${RESET}"
  FAIL=1
fi

# 4. Containers running
echo
echo -e "${CYAN}🔎 Checking containers...${RESET}"
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
  echo -e "${RED}❌ No running containers found${RESET}"
  FAIL=1
else
  docker ps --format '   {{.Names}} → {{.Status}}' | while read -r line; do
    if [[ "$line" == *"Up"* ]]; then
      echo -e "${GREEN}✅ $line${RESET}"
    else
      echo -e "${RED}❌ $line${RESET}"
      FAIL=1
    fi
  done
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}🎉 Sanity check passed. Atlas looks healthy!${RESET}"
  exit 0
else
  echo -e "${RED}⚠️  Sanity check failed. Please fix issues before cleaning.${RESET}"
  exit 1
fi
