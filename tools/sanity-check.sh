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
if sudo docker info >/dev/null 2>&1; then
  echo -e "${SUCCESS}✅ Docker daemon is running${RESET}"
else
  echo -e "${ERROR}❌ Docker daemon is not running${RESET}"
  FAIL=1
fi

# 3. Network exists
if sudo docker network inspect "$ATLAS_DOCKER_NETWORK" >/dev/null 2>&1; then
  echo -e "${SUCCESS}✅ Docker network '$ATLAS_DOCKER_NETWORK' exists${RESET}"
else
  echo -e "${ERROR}❌ Docker network '$ATLAS_DOCKER_NETWORK' missing${RESET}"
  FAIL=1
fi

# 4. Containers running
echo
echo -e "${INFO}🔎 Checking Atlas containers (network: $ATLAS_DOCKER_NETWORK)...${RESET}"
ATLAS_CONTAINERS=$(sudo docker ps --filter "network=$ATLAS_DOCKER_NETWORK" --format '{{.Names}}')

if [ -z "$ATLAS_CONTAINERS" ]; then
  echo -e "${ERROR}❌ No Atlas containers found on network '$ATLAS_DOCKER_NETWORK'${RESET}"
  FAIL=1
else
  for cname in $ATLAS_CONTAINERS; do
    STATUS=$(sudo docker inspect --format '{{.State.Status}}' "$cname" 2>/dev/null || echo "unknown")
    HEALTH=$(sudo docker inspect --format '{{.State.Health.Status}}' "$cname" 2>/dev/null || true)

    if [[ "$STATUS" == "running" && ( -z "$HEALTH" || "$HEALTH" == "healthy" ) ]]; then
      echo -e "${SUCCESS}✅ $cname → $STATUS ${HEALTH:+($HEALTH)}${RESET}"
    else
      echo -e "${ERROR}❌ $cname → $STATUS ${HEALTH:+($HEALTH)}${RESET}"
      FAIL=1
    fi
  done
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo -e "${SUCCESS}🎉 Sanity check passed. Atlas looks healthy!${RESET}"
  exit 0
else
  echo -e "${ERROR}⚠️  Sanity check failed.${RESET}"
  exit 1
fi
