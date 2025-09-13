#!/usr/bin/env bash
set -euo pipefail

# ── Setup ────────────────────────────────────────────────

# Resolve absolute path to this script (tools/) and repo root
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")

# Load shared colors
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}⚙️  Running Atlas bootstrap...${RESET}"
echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
echo "DEBUG: REPO_ROOT=$REPO_ROOT"

cd "$REPO_ROOT"

# ── Configs ──────────────────────────────────────────────

CONFIG_FILE="$REPO_ROOT/config/server_config.env"
SECRETS_FILE="$REPO_ROOT/config/.env"

echo "DEBUG: CONFIG_FILE=$CONFIG_FILE"
echo "DEBUG: SECRETS_FILE=$SECRETS_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${ERROR}❌ Missing $CONFIG_FILE. Copy template first.${RESET}"
  exit 1
fi

# Load configs
set -a
source "$CONFIG_FILE"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"
set +a

# ── Run setup scripts ────────────────────────────────────

echo -e "${INFO}📦 Installing base system packages...${RESET}"
sudo bash "$REPO_ROOT/services/scripts/base.sh"

echo -e "${INFO}🐳 Installing Docker...${RESET}"
sudo bash "$REPO_ROOT/services/scripts/docker.sh"

echo -e "${INFO}🔒 Setting up Tailscale...${RESET}"
sudo bash "$REPO_ROOT/services/scripts/tailscale.sh"

echo -e "${INFO}🛡️  Configuring firewall...${RESET}"
sudo bash "$REPO_ROOT/services/scripts/firewall.sh"

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
sudo bash "$REPO_ROOT/services/scripts/atlas.sh"

# ── Fix permissions for monitoring ───────────────────────

echo -e "${INFO}🔧 Ensuring correct permissions for Grafana & Prometheus...${RESET}"

# Grafana (UID 472 inside container)
sudo mkdir -p "${DATA_ROOT}/grafana"
sudo chown -R 472:472 "${DATA_ROOT}/grafana"
sudo chmod -R 755 "${DATA_ROOT}/grafana"

# Prometheus (UID 65534 inside container: nobody:nogroup)
sudo mkdir -p "${DATA_ROOT}/prometheus"
sudo chown -R 65534:65534 "${DATA_ROOT}/prometheus"
sudo chmod -R 755 "${DATA_ROOT}/prometheus"

echo -e "${SUCCESS}✅ Permissions fixed for Grafana & Prometheus${RESET}"


# ── Done ─────────────────────────────────────────────────

echo -e "${SUCCESS}✅ Bootstrap complete!${RESET}"
