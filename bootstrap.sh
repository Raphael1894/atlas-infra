#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

echo -e "${CYAN}⚙️  Running Atlas bootstrap...${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

if [ ! -f server_config.env ]; then
  echo -e "${RED}❌ Missing server_config.env. Copy server_config.env.example first.${RESET}"
  exit 1
fi

# Load configs
set -a
source server_config.env
[ -f .env ] && source .env
set +a

# --- Run setup scripts ---
echo -e "${CYAN}📦 Installing base system packages...${RESET}"
sudo bash scripts/base.sh

echo -e "${CYAN}🐳 Installing Docker...${RESET}"
sudo bash scripts/docker.sh

echo -e "${CYAN}🔒 Setting up Tailscale...${RESET}"
sudo bash scripts/tailscale.sh

echo -e "${CYAN}🛡️  Configuring firewall...${RESET}"
sudo bash scripts/firewall.sh

# --- Ensure project network exists ---
echo -e "${CYAN}🌐 Ensuring Docker network '$ATLAS_DOCKER_NETWORK' exists...${RESET}"
if ! docker network inspect "$ATLAS_DOCKER_NETWORK" >/dev/null 2>&1; then
  docker network create "$ATLAS_DOCKER_NETWORK"
  echo -e "${GREEN}✅ Created network '$ATLAS_DOCKER_NETWORK'${RESET}"
else
  echo -e "${GREEN}✅ Network '$ATLAS_DOCKER_NETWORK' already exists${RESET}"
fi

# --- Run core services ---
echo -e "${CYAN}🚀 Starting core services...${RESET}"
bash scripts/atlas.sh

echo -e "${GREEN}✅ Bootstrap complete!${RESET}"
