#!/usr/bin/env bash
set -euo pipefail

# ── Setup ────────────────────────────────────────────────

# Resolve absolute path to this script (tools/)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Load shared colors (tools/colors.sh)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}⚙️  Running Atlas bootstrap...${RESET}"

# Always operate from repo root
cd "$SCRIPT_DIR/.."


# ── Configs ──────────────────────────────────────────────

if [ ! -f config/server_config.env ]; then
  echo -e "${ERROR}❌ Missing config/server_config.env. Copy template first.${RESET}"
  exit 1
fi

# Load configs
set -a
source config/server_config.env
[ -f config/.env ] && source config/.env
set +a


# ── Run setup scripts ────────────────────────────────────

echo -e "${INFO}📦 Installing base system packages...${RESET}"
sudo bash services/scripts/base.sh

echo -e "${INFO}🐳 Installing Docker...${RESET}"
sudo bash services/scripts/docker.sh

echo -e "${INFO}🔒 Setting up Tailscale...${RESET}"
sudo bash services/scripts/tailscale.sh

echo -e "${INFO}🛡️  Configuring firewall...${RESET}"
sudo bash services/scripts/firewall.sh


# ── Docker network ───────────────────────────────────────

echo -e "${INFO}🌐 Ensuring Docker network '$ATLAS_DOCKER_NETWORK' exists...${RESET}"
if ! sudo docker network inspect "$ATLAS_DOCKER_NETWORK" >/dev/null 2>&1; then
  sudo docker network create "$ATLAS_DOCKER_NETWORK"
  echo -e "${SUCCESS}✅ Created network '$ATLAS_DOCKER_NETWORK'${RESET}"
else
  echo -e "${SUCCESS}✅ Network '$ATLAS_DOCKER_NETWORK' already exists${RESET}"
fi


# ── Core services ────────────────────────────────────────

echo -e "${INFO}🚀 Starting core services...${RESET}"
sudo bash services/scripts/atlas.sh


# ── Done ─────────────────────────────────────────────────

echo -e "${SUCCESS}✅ Bootstrap complete!${RESET}"
