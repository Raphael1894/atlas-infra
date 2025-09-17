#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🔍 Running Atlas sanity check...${RESET}"
echo

FAIL=0

# --- Config resolution ---
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/server_config.env"

if [ -f "$CONFIG_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  set +a
else
  echo -e "${WARN}⚠️  No server_config.env found at: $CONFIG_FILE. Using defaults.${RESET}"
fi

# Defaults
: "${ATLAS_DOCKER_NETWORK:=atlas_net}"

# Resolve hostname/domain → prefer FQDN_BASE, then fallbacks
SERVER_NAME_FALLBACK="${SERVER_NAME:-}"
ATLAS_HOSTNAME_FALLBACK="${ATLAS_HOSTNAME:-}"
BASE_DOMAIN_FALLBACK="${BASE_DOMAIN:-}"
FQDN_BASE_FALLBACK="${FQDN_BASE:-}"

if [ -n "$FQDN_BASE_FALLBACK" ]; then
  FQDN="$FQDN_BASE_FALLBACK"
elif [ -n "$ATLAS_HOSTNAME_FALLBACK" ] && [ -n "$BASE_DOMAIN_FALLBACK" ]; then
  FQDN="${ATLAS_HOSTNAME_FALLBACK}.${BASE_DOMAIN_FALLBACK}"
elif [ -n "$SERVER_NAME_FALLBACK" ] && [ -n "$BASE_DOMAIN_FALLBACK" ]; then
  FQDN="${SERVER_NAME_FALLBACK}.${BASE_DOMAIN_FALLBACK}"
else
  FQDN="atlas.tailnet-1234.ts.net"
fi

BASE_URL="http://$FQDN"

echo -e "${INFO}Using config file: ${HIGHLIGHT}${CONFIG_FILE}${RESET}"
echo -e "${INFO}Resolved base URL: ${HIGHLIGHT}${BASE_URL}${RESET}"
echo

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

# --- Nextcloud-specific checks ---
echo
echo -e "${HIGHLIGHT}📦 Nextcloud Stack Checks${RESET}"

for cname in nextcloud nextcloud-db nextcloud-redis nextcloud-cron; do
  if sudo docker ps --format '{{.Names}}' | grep -qw "$cname"; then
    STATUS=$(sudo docker inspect --format '{{.State.Status}}' "$cname")
    HEALTH=$(sudo docker inspect --format '{{.State.Health.Status}}' "$cname" 2>/dev/null || true)

    if [[ "$STATUS" == "running" && ( -z "$HEALTH" || "$HEALTH" == "healthy" ) ]]; then
      echo -e "${SUCCESS}✅ $cname → $STATUS ${HEALTH:+($HEALTH)}${RESET}"
    else
      echo -e "${ERROR}❌ $cname → $STATUS ${HEALTH:+($HEALTH)}${RESET}"
      FAIL=1
    fi
  else
    echo -e "${ERROR}❌ Container missing: $cname${RESET}"
    FAIL=1
  fi
done

echo
echo -e "${INFO}ℹ️ Reminder: 'nextcloud-cron' runs background jobs every 5 minutes (cleanup, previews, notifications).${RESET}"
echo

# --- URL reachability checks ---
echo -e "${HIGHLIGHT}🌐 Service URL Checks${RESET}"

check_url() {
  local url=$1
  local keyword=$2
  local name=$3

  if curl -fsSL "$url" | grep -qi "$keyword"; then
    echo -e "${SUCCESS}✅ $name reachable at $url${RESET}"
  else
    echo -e "${ERROR}❌ $name not reachable at $url${RESET}"
    FAIL=1
  fi
}

check_url "$BASE_URL/" "Homepage" "Homepage"
check_url "$BASE_URL/nextcloud/status.php" "installed" "Nextcloud"
check_url "$BASE_URL/portainer" "Portainer" "Portainer"
check_url "$BASE_URL/grafana/login" "Grafana" "Grafana"
check_url "$BASE_URL/vault" "Vaultwarden" "Vaultwarden"
check_url "$BASE_URL/couchdb/" "couchdb" "CouchDB"

echo
if [ "$FAIL" -eq 0 ]; then
  echo -e "${SUCCESS}🎉 Sanity check passed. Atlas looks healthy!${RESET}"
  exit 0
else
  echo -e "${ERROR}⚠️  Sanity check failed.${RESET}"
  exit 1
fi
