#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🌌 Atlas Installer starting...${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR/.."   # Go to repo root

CONFIG_DIR="config"
TEMPLATES_DIR="$CONFIG_DIR/config-templates"
TOOLS_DIR="tools"

# --- Prompt for base domain / tailnet domain ---
echo
echo -e "${INFO}🌐 Atlas requires a base domain for service URLs.${RESET}"
echo -e "${INFO}👉 Typically, this will be your ${HIGHLIGHT}Tailscale tailnet domain${RESET},"
echo -e "   which looks like: ${HIGHLIGHT}tailnet-1234.ts.net${RESET}"
echo
echo -e "${PROMPT}Please choose an option:${RESET}"
echo "   1) I already know my tailnet domain (enter it now)"
echo "   2) Show me how to find / set up my tailnet domain"
echo
read -rp "Enter choice [1/2]: " DOMAIN_CHOICE

if [[ "$DOMAIN_CHOICE" == "2" ]]; then
  echo
  echo -e "${INFO}🛠 Tailscale Domain Setup Instructions:${RESET}"
  echo "1. Go to https://login.tailscale.com and sign in (or create an account)."
  echo "2. In the admin console, go to 'DNS' and enable MagicDNS."
  echo "3. You will see your tailnet domain (like tailnet-1234.ts.net)."
  echo "   If you have a custom domain, you can configure it there too."
  echo
  echo -e "${PROMPT}After completing these steps, re-run the installer.${RESET}"
  exit 0
fi

echo
echo -ne "${PROMPT}👉 Enter your tailnet domain (default: tailnet-1234.ts.net): ${RESET}"
read -r BASE_DOMAIN
BASE_DOMAIN=${BASE_DOMAIN:-tailnet-1234.ts.net}

# --- Prompt for server hostname ---
echo -ne "${PROMPT}👉 Enter the name of your server (default: atlas): ${RESET}"
read -r SERVER_NAME
SERVER_NAME=${SERVER_NAME:-atlas}

# --- Confirm ---
echo
echo -e "${INFO}⚙️  Installation configuration:${RESET}"
echo "   Hostname:    $SERVER_NAME"
echo "   Base domain: $BASE_DOMAIN"
echo "   FQDN base:   $SERVER_NAME.$BASE_DOMAIN"
echo
echo -ne "${PROMPT}${HIGHLIGHT}Proceed with these settings?${RESET} [y/N]: "
read -r CONFIRM
CONFIRM=${CONFIRM,,}
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "yes" ]]; then
  echo -e "${ERROR}❌ Installation aborted.${RESET}"
  exit 1
fi

# --- Ensure server_config.env exists ---
if [ ! -f "$CONFIG_DIR/server_config.env" ]; then
  if [ -f "$TEMPLATES_DIR/server_config.env.template" ]; then
    echo -e "${WARN}⚠️  No server_config.env found. Creating one from template...${RESET}"
    cp "$TEMPLATES_DIR/server_config.env.template" "$CONFIG_DIR/server_config.env"
  else
    echo -e "${ERROR}❌ Missing $TEMPLATES_DIR/server_config.env.template. Cannot continue.${RESET}"
    exit 1
  fi
fi

# --- Update server_config.env with chosen values ---
sed -i "s/^ATLAS_HOSTNAME=.*/ATLAS_HOSTNAME=$SERVER_NAME/" "$CONFIG_DIR/server_config.env" || echo "ATLAS_HOSTNAME=$SERVER_NAME" >> "$CONFIG_DIR/server_config.env"
sed -i "s/^BASE_DOMAIN=.*/BASE_DOMAIN=$BASE_DOMAIN/" "$CONFIG_DIR/server_config.env" || echo "BASE_DOMAIN=$BASE_DOMAIN" >> "$CONFIG_DIR/server_config.env"
sed -i "s/^FQDN_BASE=.*/FQDN_BASE=${SERVER_NAME}.${BASE_DOMAIN}/" "$CONFIG_DIR/server_config.env" || echo "FQDN_BASE=${SERVER_NAME}.${BASE_DOMAIN}" >> "$CONFIG_DIR/server_config.env"

echo -e "${SUCCESS}✅ Server identity configured${RESET}"

# --- Run network configuration ---
bash "$TOOLS_DIR/network.sh"

# --- Handle .env secrets ---
ENV_FILE="$CONFIG_DIR/.env"
TEMPLATE_FILE="$TEMPLATES_DIR/.env.template"

generate_secret() { openssl rand -hex 32; }
generate_pass()   { openssl rand -base64 16 | tr -d '\n'; }
generate_token()  { openssl rand -base64 48 | tr -d '\n'; }

if [ -f "$ENV_FILE" ]; then
  echo -ne "${WARN}⚠️  A .env file already exists. Do you want to modify it?${RESET} [y/n]: "
  read -r MODIFY_ENV
  MODIFY_ENV=${MODIFY_ENV,,}

  if [[ "$MODIFY_ENV" == "y" || "$MODIFY_ENV" == "yes" ]]; then
    ENV_MODE="prompts"
  else
    ENV_MODE="keep"
  fi
else
  echo -e "${WARN}⚠️  No .env found.${RESET}"
  echo -ne "${PROMPT}👉 Do you want to create it using prompts or defaults from template?${RESET} [prompts/default]: "
  read -r ENV_MODE
  ENV_MODE=${ENV_MODE,,}
fi

if [[ "$ENV_MODE" == "prompts" ]]; then
  # --- Prompt new values ---
  echo -ne "${PROMPT}👉 Gitea admin username (default: atlas): ${RESET}"
  read -r GITEA_ADMIN_USER
  GITEA_ADMIN_USER=${GITEA_ADMIN_USER:-atlas}

  echo -ne "${PROMPT}👉 Gitea admin password (default: changeme): ${RESET}"
  read -r GITEA_ADMIN_PASS
  GITEA_ADMIN_PASS=${GITEA_ADMIN_PASS:-changeme}

  echo -ne "${PROMPT}👉 Gitea admin email (default: admin@${SERVER_NAME}.${BASE_DOMAIN}): ${RESET}"
  read -r GITEA_ADMIN_EMAIL
  GITEA_ADMIN_EMAIL=${GITEA_ADMIN_EMAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}

  echo -ne "${PROMPT}👉 Grafana admin username (default: admin): ${RESET}"
  read -r GRAFANA_ADMIN_USER
  GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

  echo -ne "${PROMPT}👉 Grafana admin password (default: changeme): ${RESET}"
  read -r GRAFANA_ADMIN_PASSWORD
  GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-changeme}

  echo -ne "${PROMPT}👉 Nextcloud admin username (default: admin): ${RESET}"
  read -r NEXTCLOUD_ADMIN_USER
  NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER:-admin}

  echo -ne "${PROMPT}👉 Nextcloud admin password (leave empty to auto-generate): ${RESET}"
  read -r NEXTCLOUD_ADMIN_PASS
  NEXTCLOUD_ADMIN_PASS=${NEXTCLOUD_ADMIN_PASS:-$(generate_pass)}

  echo -ne "${PROMPT}👉 Nextcloud database name (default: nextcloud): ${RESET}"
  read -r NEXTCLOUD_DB
  NEXTCLOUD_DB=${NEXTCLOUD_DB:-nextcloud}

  echo -ne "${PROMPT}👉 Nextcloud database user (default: nextcloud): ${RESET}"
  read -r NEXTCLOUD_DB_USER
  NEXTCLOUD_DB_USER=${NEXTCLOUD_DB_USER:-nextcloud}

  echo -ne "${PROMPT}👉 Nextcloud database password (leave empty to auto-generate): ${RESET}"
  read -r NEXTCLOUD_DB_PASS
  NEXTCLOUD_DB_PASS=${NEXTCLOUD_DB_PASS:-$(generate_pass)}

  echo -ne "${PROMPT}👉 ntfy default access (default: read-only): ${RESET}"
  read -r NTFY_AUTH_DEFAULT_ACCESS
  NTFY_AUTH_DEFAULT_ACCESS=${NTFY_AUTH_DEFAULT_ACCESS:-read-only}

  echo -ne "${PROMPT}👉 CouchDB username (default: obsidian): ${RESET}"
  read -r COUCHDB_USER
  COUCHDB_USER=${COUCHDB_USER:-obsidian}

  echo -ne "${PROMPT}👉 CouchDB password (default: changeme): ${RESET}"
  read -r COUCHDB_PASSWORD
  COUCHDB_PASSWORD=${COUCHDB_PASSWORD:-changeme}

  # --- Generate secrets ---
  VW_ADMIN_TOKEN=$(generate_token)

  # --- Write .env ---
  cat > "$ENV_FILE" <<EOF
# ── Gitea ────────────────────────────────────────────────
GITEA_ADMIN_USER=$GITEA_ADMIN_USER
GITEA_ADMIN_PASS=$GITEA_ADMIN_PASS
GITEA_ADMIN_EMAIL=$GITEA_ADMIN_EMAIL

# ── Vaultwarden ──────────────────────────────────────────
VW_SIGNUPS_ALLOWED=false
VW_ADMIN_TOKEN=$VW_ADMIN_TOKEN

# ── Grafana ──────────────────────────────────────────────
GRAFANA_ADMIN_USER=$GRAFANA_ADMIN_USER
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD

# ── ntfy ─────────────────────────────────────────────────
NTFY_AUTH_DEFAULT_ACCESS=$NTFY_AUTH_DEFAULT_ACCESS

# ── Nextcloud ───────────────────────────────────────────
NEXTCLOUD_ADMIN_USER=$NEXTCLOUD_ADMIN_USER
NEXTCLOUD_ADMIN_PASS=$NEXTCLOUD_ADMIN_PASS
NEXTCLOUD_DB=$NEXTCLOUD_DB
NEXTCLOUD_DB_USER=$NEXTCLOUD_DB_USER
NEXTCLOUD_DB_PASS=$NEXTCLOUD_DB_PASS
OVERWRITEWEBROOT=/nextcloud
OVERWRITECLIURL=http://$SERVER_NAME.$BASE_DOMAIN/nextcloud

# ── CouchDB ─────────────────────────────────────────────
COUCHDB_USER=$COUCHDB_USER
COUCHDB_PASSWORD=$COUCHDB_PASSWORD
EOF

  echo -e "${SUCCESS}✅ Secrets written to $ENV_FILE${RESET}"

elif [[ "$ENV_MODE" == "default" ]]; then
  echo -e "${INFO}📋 Using template defaults${RESET}"
  cp "$TEMPLATE_FILE" "$ENV_FILE"
else
  echo -e "${INFO}ℹ️  Keeping existing .env configuration.${RESET}"
fi

# --- Always source .env so variables are available ---
set +u
set -a
source "$ENV_FILE"
set +a
set -u

# --- Run bootstrap ---
echo -e "${INFO}⚙️  Running bootstrap...${RESET}"
bash "$TOOLS_DIR/bootstrap.sh"

# --- Ensure Nextcloud data permissions ---
NEXTCLOUD_DIR="${DATA_ROOT:-/srv/atlas}/nextcloud"
echo -e "${INFO}🛠 Fixing Nextcloud permissions in $NEXTCLOUD_DIR...${RESET}"
sudo mkdir -p "$NEXTCLOUD_DIR/html" "$NEXTCLOUD_DIR/data"
sudo chown -R 33:33 "$NEXTCLOUD_DIR/html" "$NEXTCLOUD_DIR/data"
echo -e "${SUCCESS}✅ Nextcloud volumes prepared with www-data ownership${RESET}"

# --- Bring everything up ---
echo -e "${INFO}🚀 Starting all services...${RESET}"
make -f "$TOOLS_DIR/Makefile" up-all

# --- Final summary ---
echo
echo -e "${SUCCESS}🎉 Installation complete!${RESET}"
echo
echo -e "${INFO}ℹ️ Nextcloud cron container is running to handle background jobs every 5 minutes${RESET}"
echo
echo -e "${INFO}You can now access your server '$SERVER_NAME' services via:${RESET}"
echo "  Homepage:     http://$SERVER_NAME.$BASE_DOMAIN/"
echo "  Portainer:    http://$SERVER_NAME.$BASE_DOMAIN/portainer"
echo "  Gitea:        http://$SERVER_NAME.$BASE_DOMAIN/gitea"
echo "  Nextcloud:    http://$SERVER_NAME.$BASE_DOMAIN/nextcloud"
echo "  Vaultwarden:  http://$SERVER_NAME.$BASE_DOMAIN/vault"
echo "  Grafana:      http://$SERVER_NAME.$BASE_DOMAIN/grafana"
echo "  Prometheus:   http://$SERVER_NAME.$BASE_DOMAIN/prometheus"
echo "  Alertmanager: http://$SERVER_NAME.$BASE_DOMAIN/alerts"
echo "  ntfy:         http://$SERVER_NAME.$BASE_DOMAIN/ntfy"
echo

# --- Credentials Summary ---
echo -e "${WARN}⚠️  IMPORTANT:${RESET} Save the following credentials securely."
echo -e "   They are also stored in ${HIGHLIGHT}config/.env${RESET} (do not commit this file)."
echo

echo -e "${HIGHLIGHT}Gitea Admin:${RESET}"
echo "   User: ${GITEA_ADMIN_USER:-unknown}"
echo "   Pass: ${GITEA_ADMIN_PASS:-unknown}"
echo "   URL:  http://$SERVER_NAME.$BASE_DOMAIN/gitea"
echo

echo -e "${HIGHLIGHT}Grafana Admin:${RESET}"
echo "   User: ${GRAFANA_ADMIN_USER:-unknown}"
echo "   Pass: ${GRAFANA_ADMIN_PASSWORD:-unknown}"
echo "   URL:  http://$SERVER_NAME.$BASE_DOMAIN/grafana"
echo

echo -e "${HIGHLIGHT}Nextcloud Admin:${RESET}"
echo "   User: ${NEXTCLOUD_ADMIN_USER:-unknown}"
echo "   Pass: ${NEXTCLOUD_ADMIN_PASS:-unknown}"
echo "   URL:  http://$SERVER_NAME.$BASE_DOMAIN/nextcloud"
echo "   (overwrite config applied: OVERWRITEWEBROOT=/nextcloud, OVERWRITECLIURL set dynamically)"
echo

echo -e "${HIGHLIGHT}ntfy Default Access:${RESET} ${NTFY_AUTH_DEFAULT_ACCESS:-unknown}"
echo "   URL:  http://$SERVER_NAME.$BASE_DOMAIN/ntfy"
echo

echo -e "${HIGHLIGHT}CouchDB:${RESET}"
echo "   User: ${COUCHDB_USER:-unknown}"
echo "   Pass: ${COUCHDB_PASSWORD:-unknown}"
echo "   URL:  http://$SERVER_NAME.$BASE_DOMAIN/couchdb"
echo

# --- Post-install reminder ---
echo -e "${INFO}👉 Reminder:${RESET}"
echo -e "   If you haven’t authenticated Tailscale yet, run:"
echo -e "   ${HIGHLIGHT}sudo tailscale up --ssh --hostname ${SERVER_NAME}${RESET}"
echo

# --- Detect current version from git tag ---
ATLAS_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")

# --- Mark installation complete (with metadata) ---
{
  echo "true"
  echo "installed_at=$(date '+%d-%m-%Y %H:%M:%S')"
  echo "atlas_version=$ATLAS_VERSION"
  echo "hostname=$SERVER_NAME"
  echo "base_domain=$BASE_DOMAIN"

  echo "homepage_url=http://$SERVER_NAME.$BASE_DOMAIN/"
  echo "portainer_url=http://$SERVER_NAME.$BASE_DOMAIN/portainer"
  echo "gitea_url=http://$SERVER_NAME.$BASE_DOMAIN/gitea"
  echo "nextcloud_url=http://$SERVER_NAME.$BASE_DOMAIN/nextcloud"
  echo "vaultwarden_url=http://$SERVER_NAME.$BASE_DOMAIN/vault"
  echo "grafana_url=http://$SERVER_NAME.$BASE_DOMAIN/grafana"
  echo "prometheus_url=http://$SERVER_NAME.$BASE_DOMAIN/prometheus"
  echo "alertmanager_url=http://$SERVER_NAME.$BASE_DOMAIN/alerts"
  echo "ntfy_url=http://$SERVER_NAME.$BASE_DOMAIN/ntfy"
} > "$CONFIG_DIR/installed.flag"
