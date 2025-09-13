#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🔍 Running Atlas sanity check...${RESET}"
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
  echo -e "${SUCCESS}✅ Docker is installed${RESET}"
else
  echo -e "${ERROR}❌ Docker is not installed${RESET}"
  FAIL=1
fi

# 2. Docker daemon running
if docker info >/dev/null 2>&1; then
  echo -e "${SUCCESS}✅ Docker daemon is running${RESET}"
else
  echo -e "${ERROR}❌ Docker daemon is not running${RESET}"
  FAIL=1
fi

# 3. Network exists
if docker network inspect "$ATLAS_DOCKER_NETWORK" >/dev/null 2>&1; then
  echo -e "${SUCCESS}✅ Docker network '$ATLAS_DOCKER_NETWORK' exists${RESET}"
else
  echo -e "${ERROR}❌ Docker network '$ATLAS_DOCKER_NETWORK' missing${RESET}"
  FAIL=1
fi

# 4. Containers running
echo
echo -e "${INFO}🔎 Checking containers...${RESET}"
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
  echo -e "${ERROR}❌ No running containers found${RESET}"
  FAIL=1
else
  docker ps --format '   {{.Names}} → {{.Status}}' | while read -r line; do
    if [[ "$line" == *"Up"* ]]; then
      echo -e "${SUCCESS}✅ $line${RESET}"
    else
      echo -e "${ERROR}❌ $line${RESET}"
      FAIL=1
    fi
  done
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo -e "${SUCCESS}🎉 Sanity check passed. Atlas looks healthy!${RESET}"
  exit 0
else
  echo -e "${ERROR}⚠️  Sanity check failed. ${RESET}"
  exit 1
fi
