#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}🌌 Atlas Installer starting...${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

# --- Prompt for server hostname ---
echo -ne "${WHITE}👉 Enter the name of your server (default: atlas): ${RESET}"
read -r SERVER_NAME
SERVER_NAME=${SERVER_NAME:-atlas}

# --- Prompt for base domain ---
echo -ne "${WHITE}👉 Enter your base domain (default: lan): ${RESET}"
read -r BASE_DOMAIN
BASE_DOMAIN=${BASE_DOMAIN:-lan}

# --- Confirm ---
echo
echo -e "${BLUE}⚙️  Installation configuration:${RESET}"
echo "   Hostname:    $SERVER_NAME"
echo "   Base domain: $BASE_DOMAIN"
echo "   FQDN base:   $SERVER_NAME.$BASE_DOMAIN"
echo
echo -ne "${WHITE}${BOLD}Proceed with these settings?${RESET} [y/N]: "
read -r CONFIRM
CONFIRM=${CONFIRM,,} # lowercase
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "yes" ]]; then
  echo -e "${RED}❌ Installation aborted.${RESET}"
  exit 1
fi

# --- Update server_config.env ---
if [ -f server_config.env ]; then
  sed -i "s/^ATLAS_HOSTNAME=.*/ATLAS_HOSTNAME=$SERVER_NAME/" server_config.env
  sed -i "s/^BASE_DOMAIN=.*/BASE_DOMAIN=$BASE_DOMAIN/" server_config.env
  sed -i "s/^FQDN_BASE=.*/FQDN_BASE=${SERVER_NAME}.${BASE_DOMAIN}/" server_config.env
else
  echo -e "${RED}❌ Missing server_config.env. Copy server_config.env.example first.${RESET}"
  exit 1
fi

echo -e "${GREEN}✅ Server identity configured${RESET}"

# --- Load defaults from existing .env if available ---
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# --- Prompt for Gitea ---
echo -ne "${WHITE}👉 Gitea admin username (default: ${GITEA_ADMIN_USER:-atlas}): ${RESET}"
read -r GITEA_USER
GITEA_USER=${GITEA_USER:-${GITEA_ADMIN_USER:-atlas}}

echo -ne "${WHITE}👉 Gitea admin password (default: ${GITEA_ADMIN_PASS:-changeme}): ${RESET}"
read -r GITEA_PASS
GITEA_PASS=${GITEA_PASS:-${GITEA_ADMIN_PASS:-changeme}}

echo -ne "${WHITE}👉 Gitea admin email (default: ${GITEA_ADMIN_EMAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}): ${RESET}"
read -r GITEA_MAIL
GITEA_MAIL=${GITEA_MAIL:-${GITEA_ADMIN_EMAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}}

# --- Prompt for Vaultwarden ---
VW_TOKEN_WAS_GENERATED=false
echo -ne "${WHITE}👉 Vaultwarden admin token (leave empty to auto-generate): ${RESET}"
read -r VW_TOKEN
if [ -z "$VW_TOKEN" ]; then
  VW_TOKEN=$(openssl rand -base64 48 | tr -d '\n')
  VW_TOKEN_WAS_GENERATED=true
  echo -e "${YELLOW}🔑 Generated Vaultwarden admin token${RESET}"
fi

# --- Prompt for Grafana ---
echo -ne "${WHITE}👉 Grafana admin username (default: ${GRAFANA_ADMIN_USER:-admin}): ${RESET}"
read -r GRAFANA_USER
GRAFANA_USER=${GRAFANA_USER:-${GRAFANA_ADMIN_USER:-admin}}

echo -ne "${WHITE}👉 Grafana admin password (default: ${GRAFANA_ADMIN_PASSWORD:-changeme}): ${RESET}"
read -r GRAFANA_PASS
GRAFANA_PASS=${GRAFANA_PASS:-${GRAFANA_ADMIN_PASSWORD:-changeme}}

# --- Prompt for ntfy ---
echo -ne "${WHITE}👉 ntfy default access (default: ${NTFY_AUTH_DEFAULT_ACCESS:-read-only}): ${RESET}"
read -r NTFY_ACCESS
NTFY_ACCESS=${NTFY_ACCESS:-${NTFY_AUTH_DEFAULT_ACCESS:-read-only}}

# --- Write .env (with safety check) ---
if [ -f .env ]; then
  echo -ne "${YELLOW}⚠️  Detected existing .env. Overwrite it?${RESET} [y/N]: "
  read -r OVERWRITE
  OVERWRITE=${OVERWRITE,,} # lowercase
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
    echo -e "${RED}❌ Keeping existing .env. Installation aborted to avoid overwriting secrets.${RESET}"
    exit 1
  fi
fi

cat > .env <<EOF
# ── Gitea ────────────────────────────────────────────────
GITEA_ADMIN_USER=$GITEA_USER
GITEA_ADMIN_PASS=$GITEA_PASS
GITEA_ADMIN_EMAIL=$GITEA_MAIL

# ── Vaultwarden ──────────────────────────────────────────
VW_SIGNUPS_ALLOWED=false
VW_ADMIN_TOKEN=$VW_TOKEN

# ── Grafana ──────────────────────────────────────────────
GRAFANA_ADMIN_USER=$GRAFANA_USER
GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASS

# ── ntfy ─────────────────────────────────────────────────
NTFY_AUTH_DEFAULT_ACCESS=$NTFY_ACCESS
EOF

echo -e "${GREEN}✅ Secrets written to .env${RESET}"

# --- Ensure scripts are executable ---
chmod +x bootstrap.sh
chmod +x scripts/*.sh

# --- Run bootstrap ---
echo -e "${CYAN}⚙️  Running bootstrap...${RESET}"
./bootstrap.sh

# --- Bring everything up ---
echo -e "${CYAN}🚀 Starting all services...${RESET}"
make up-all

# --- Final summary ---
echo
echo -e "${GREEN}🎉 Installation complete!${RESET}"
echo
echo -e "${BLUE}You can now access your server '$SERVER_NAME' services via:${RESET}"
echo "  Homepage:     http://$SERVER_NAME.$BASE_DOMAIN"
echo "  Portainer:    http://portainer.$SERVER_NAME.$BASE_DOMAIN"
echo "  Gitea:        http://git.$SERVER_NAME.$BASE_DOMAIN"
echo "  OCIS:         http://cloud.$SERVER_NAME.$BASE_DOMAIN"
echo "  Vaultwarden:  http://vault.$SERVER_NAME.$BASE_DOMAIN"
echo "  Grafana:      http://grafana.$SERVER_NAME.$BASE_DOMAIN"
echo "  Prometheus:   http://prometheus.$SERVER_NAME.$BASE_DOMAIN"
echo "  Alertmanager: http://alerts.$SERVER_NAME.$BASE_DOMAIN"
echo "  ntfy:         http://ntfy.$SERVER_NAME.$BASE_DOMAIN"
echo

if [ "$VW_TOKEN_WAS_GENERATED" = true ]; then
  echo -e "${YELLOW}⚠️  IMPORTANT:${RESET} A new Vaultwarden admin token was generated."
  echo "   Save this token securely — you will need it to access the Vaultwarden admin panel."
  echo
  echo -e "${BOLD}${RED}   Vaultwarden Admin Token:${RESET} ${BOLD}$VW_TOKEN${RESET}"
  echo
fi
