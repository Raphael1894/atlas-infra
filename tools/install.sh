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
SERVICES_SCRIPTS="services/scripts"

# --- Prompt for server hostname ---
echo -ne "${PROMPT}👉 Enter the name of your server (default: atlas): ${RESET}"
read -r SERVER_NAME
SERVER_NAME=${SERVER_NAME:-atlas}

# --- Prompt for base domain ---
echo -ne "${PROMPT}👉 Enter your base domain (default: lan): ${RESET}"
read -r BASE_DOMAIN
BASE_DOMAIN=${BASE_DOMAIN:-lan}

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
  echo -e "${WARN}⚠️  No server_config.env found. Creating one from template...${RESET}"
  cp "$TEMPLATES_DIR/server_config.env.template" "$CONFIG_DIR/server_config.env"
fi

# --- Update server_config.env ---
sed -i "s/^ATLAS_HOSTNAME=.*/ATLAS_HOSTNAME=$SERVER_NAME/" "$CONFIG_DIR/server_config.env" || echo "ATLAS_HOSTNAME=$SERVER_NAME" >> "$CONFIG_DIR/server_config.env"
sed -i "s/^BASE_DOMAIN=.*/BASE_DOMAIN=$BASE_DOMAIN/" "$CONFIG_DIR/server_config.env" || echo "BASE_DOMAIN=$BASE_DOMAIN" >> "$CONFIG_DIR/server_config.env"
sed -i "s/^FQDN_BASE=.*/FQDN_BASE=${SERVER_NAME}.${BASE_DOMAIN}/" "$CONFIG_DIR/server_config.env" || echo "FQDN_BASE=${SERVER_NAME}.${BASE_DOMAIN}" >> "$CONFIG_DIR/server_config.env"

echo -e "${SUCCESS}✅ Server identity configured${RESET}"

# --- Run network configuration ---
bash "$TOOLS_DIR/network.sh"

# --- Load defaults from existing .env if available ---
if [ -f "$CONFIG_DIR/.env" ]; then
  set +u
  set -a
  source "$CONFIG_DIR/.env"
  set +a
  set -u
fi

# --- Handle .env secrets ---
ENV_FILE="$CONFIG_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  echo -ne "${WARN}⚠️  A .env file already exists. Do you want to modify it?${RESET} [y/N]: "
  read -r MODIFY_ENV
  MODIFY_ENV=${MODIFY_ENV,,}

  if [[ "$MODIFY_ENV" != "y" && "$MODIFY_ENV" != "yes" ]]; then
    echo -e "${INFO}ℹ️  Keeping existing .env configuration.${RESET}"
  else
    # Prompt new values
    echo -ne "${PROMPT}👉 Gitea admin username (default: ${GITEA_ADMIN_USER:-atlas}): ${RESET}"
    read -r GITEA_USER
    GITEA_USER=${GITEA_USER:-${GITEA_ADMIN_USER:-atlas}}

    echo -ne "${PROMPT}👉 Gitea admin password (default: ${GITEA_ADMIN_PASS:-changeme}): ${RESET}"
    read -r GITEA_PASS
    GITEA_PASS=${GITEA_PASS:-${GITEA_ADMIN_PASS:-changeme}}

    echo -ne "${PROMPT}👉 Gitea admin email (default: ${GITEA_ADMIN_EMAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}): ${RESET}"
    read -r GITEA_MAIL
    GITEA_MAIL=${GITEA_MAIL:-${GITEA_ADMIN_EMAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}}

    # --- Prompt for Vaultwarden ---
    VW_TOKEN_WAS_GENERATED=false
    echo -ne "${PROMPT}👉 Vaultwarden admin token (leave empty to auto-generate): ${RESET}"
    read -r VW_TOKEN
    if [ -z "$VW_TOKEN" ]; then
      VW_TOKEN=$(openssl rand -base64 48 | tr -d '\n')
      VW_TOKEN_WAS_GENERATED=true
      echo -e "${WARN}🔑 Generated Vaultwarden admin token${RESET}"
    fi

    # --- Prompt for Grafana ---
    echo -ne "${PROMPT}👉 Grafana admin username (default: ${GRAFANA_ADMIN_USER:-admin}): ${RESET}"
    read -r GRAFANA_USER
    GRAFANA_USER=${GRAFANA_USER:-${GRAFANA_ADMIN_USER:-admin}}

    echo -ne "${PROMPT}👉 Grafana admin password (default: ${GRAFANA_ADMIN_PASSWORD:-changeme}): ${RESET}"
    read -r GRAFANA_PASS
    GRAFANA_PASS=${GRAFANA_PASS:-${GRAFANA_ADMIN_PASSWORD:-changeme}}

    # --- Prompt for ntfy ---
    echo -ne "${PROMPT}👉 ntfy default access (default: ${NTFY_AUTH_DEFAULT_ACCESS:-read-only}): ${RESET}"
    read -r NTFY_ACCESS
    NTFY_ACCESS=${NTFY_ACCESS:-${NTFY_AUTH_DEFAULT_ACCESS:-read-only}}

    # Confirm overwrite
    echo
    echo -ne "${WARN}⚠️  Overwrite $ENV_FILE with these new values?${RESET} [y/N]: "
    read -r CONFIRM_OVERWRITE
    CONFIRM_OVERWRITE=${CONFIRM_OVERWRITE,,}

    if [[ "$CONFIRM_OVERWRITE" == "y" || "$CONFIRM_OVERWRITE" == "yes" ]]; then
      cat > "$ENV_FILE" <<EOF
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
      echo -e "${SUCCESS}✅ Secrets updated in $ENV_FILE${RESET}"
    else
      echo -e "${INFO}ℹ️  Keeping existing .env (no changes applied).${RESET}"
    fi
  fi
else
  echo -e "${INFO}ℹ️  No .env found. Creating a new one...${RESET}"

  # Prompt new values
  echo -ne "${PROMPT}👉 Gitea admin username (default: atlas): ${RESET}"
  read -r GITEA_USER
  GITEA_USER=${GITEA_USER:-atlas}

  echo -ne "${PROMPT}👉 Gitea admin password (default: changeme): ${RESET}"
  read -r GITEA_PASS
  GITEA_PASS=${GITEA_PASS:-changeme}

  echo -ne "${PROMPT}👉 Gitea admin email (default: admin@${SERVER_NAME}.${BASE_DOMAIN}): ${RESET}"
  read -r GITEA_MAIL
  GITEA_MAIL=${GITEA_MAIL:-admin@${SERVER_NAME}.${BASE_DOMAIN}}

  VW_TOKEN_WAS_GENERATED=false
  echo -ne "${PROMPT}👉 Vaultwarden admin token (leave empty to auto-generate): ${RESET}"
  read -r VW_TOKEN
  if [ -z "$VW_TOKEN" ]; then
    VW_TOKEN=$(openssl rand -base64 48 | tr -d '\n')
    VW_TOKEN_WAS_GENERATED=true
    echo -e "${WARN}🔑 Generated Vaultwarden admin token${RESET}"
  fi

  echo -ne "${PROMPT}👉 Grafana admin username (default: admin): ${RESET}"
  read -r GRAFANA_USER
  GRAFANA_USER=${GRAFANA_USER:-admin}

  echo -ne "${PROMPT}👉 Grafana admin password (default: changeme): ${RESET}"
  read -r GRAFANA_PASS
  GRAFANA_PASS=${GRAFANA_PASS:-changeme}

  echo -ne "${PROMPT}👉 ntfy default access (default: read-only): ${RESET}"
  read -r NTFY_ACCESS
  NTFY_ACCESS=${NTFY_ACCESS:-read-only}

  # Write new .env
  cat > "$ENV_FILE" <<EOF
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
  echo -e "${SUCCESS}✅ Secrets written to $ENV_FILE${RESET}"
fi

# --- Run bootstrap ---
echo -e "${INFO}⚙️  Running bootstrap...${RESET}"
bash "$TOOLS_DIR/bootstrap.sh"

# --- Bring everything up ---
echo -e "${INFO}🚀 Starting all services...${RESET}"
make -f "$TOOLS_DIR/Makefile" up-all

# --- Final summary ---
echo
echo -e "${SUCCESS}🎉 Installation complete!${RESET}"
echo
echo -e "${INFO}You can now access your server '$SERVER_NAME' services via:${RESET}"
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

# --- Credentials Summary ---
echo -e "${WARN}⚠️  IMPORTANT:${RESET} Save the following credentials securely."
echo -e "   You may use a password manager, write them down, or store them however you prefer."
echo -e "   ${HIGHLIGHT}Tip:${RESET} Since Vaultwarden is installed with Atlas, you can also add them there for convenience:"
echo -e "   → Vaultwarden URL: http://vault.$SERVER_NAME.$BASE_DOMAIN"
echo
echo -e "   Credentials are also stored in ${HIGHLIGHT}config/.env${RESET} (do not commit this file)."
echo

# Vaultwarden admin token
if [ "${VW_TOKEN_WAS_GENERATED:-false}" = true ]; then
  echo -e "${ERROR}${HIGHLIGHT}Vaultwarden Admin Token:${RESET} $VW_TOKEN"
  echo "   → Required to access the Vaultwarden admin panel."
  echo
fi

# Gitea
echo -e "${HIGHLIGHT}Gitea Admin:${RESET}"
echo "   User: $GITEA_USER"
echo "   Pass: $GITEA_PASS"
echo "   URL:  http://git.$SERVER_NAME.$BASE_DOMAIN"
echo

# Grafana
echo -e "${HIGHLIGHT}Grafana Admin:${RESET}"
echo "   User: $GRAFANA_USER"
echo "   Pass: $GRAFANA_PASS"
echo "   URL:  http://grafana.$SERVER_NAME.$BASE_DOMAIN"
echo

# ntfy
echo -e "${HIGHLIGHT}ntfy Default Access:${RESET} $NTFY_ACCESS"
echo "   URL:  http://ntfy.$SERVER_NAME.$BASE_DOMAIN"
echo

echo -e "${SUCCESS}✅ Setup finished. Your homelab is ready!${RESET}"
echo
