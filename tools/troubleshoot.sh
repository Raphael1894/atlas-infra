#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🩺 Atlas Troubleshooting Script${RESET}"

cd "$SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/../config/server_config.env" ]; then
  echo -e "${ERROR}❌ Missing config/server_config.env. Cannot troubleshoot.${RESET}"
  exit 1
fi

# Load configs
set -a
source "$SCRIPT_DIR/../config/server_config.env"
[ -f "$SCRIPT_DIR/../config/.env" ] && source "$SCRIPT_DIR/../config/.env"
set +a

failures=0
mkdir -p logs

check_step () {
  local description=$1
  local cmd=$2
  local hint=$3
  local service_name=$4

  echo -ne "${INFO}🔍 Checking ${description}...${RESET} "
  if eval "$cmd" >/dev/null 2>&1; then
    echo -e "${SUCCESS}✅ OK${RESET}"
  else
    echo -e "${ERROR}❌ FAILED${RESET}"
    echo -e "   ${WARN}Hint:${RESET} $hint"

    if sudo docker ps -a --format '{{.Names}}' | grep -qw "$service_name"; then
      sudo docker logs --tail=200 "$service_name" &> "logs/${service_name}.log" || true
      echo -e "   ${INFO}Logs saved to:${RESET} logs/${service_name}.log"
    else
      echo "No container found for $service_name" > "logs/${service_name}.log"
      echo -e "   ${WARN}No container found — created empty log file at logs/${service_name}.log${RESET}"
    fi

    failures=$((failures+1))
  fi
}

# --- System checks ---
echo -e "\n${HIGHLIGHT}🔧 System Checks${RESET}"
check_step "System package 'curl'" "dpkg -l | grep -q curl" "Run: sudo apt install -y curl" "system"
check_step "System package 'git'" "dpkg -l | grep -q git" "Run: sudo apt install -y git" "system"
check_step "Docker installed" "sudo docker --version" "Re-run tools/bootstrap.sh" "docker"
check_step "Docker daemon running" "systemctl is-active --quiet docker" "Run: sudo systemctl restart docker && sudo systemctl enable docker" "docker"
check_step "Docker network '$ATLAS_DOCKER_NETWORK'" "sudo docker network inspect $ATLAS_DOCKER_NETWORK" "Run: sudo docker network create $ATLAS_DOCKER_NETWORK" "docker"
check_step "Tailscale installed" "tailscale --version" "Re-run services/scripts/tailscale.sh" "tailscale"
check_step "Tailscale running" "systemctl is-active --quiet tailscaled" "Run: sudo systemctl restart tailscaled" "tailscale"
check_step "Firewall active" "sudo ufw status | grep -q 'Status: active'" "Run: sudo ufw enable" "ufw"

# --- Core services ---
echo -e "\n${HIGHLIGHT}🖥️  Core Services${RESET}"
check_step "Proxy (Traefik)" "sudo docker ps --format '{{.Names}}' | grep -qw traefik" "Run: make -f tools/Makefile restart NAME=proxy" "traefik"
check_step "Dashboard (Homepage)" "sudo docker ps --format '{{.Names}}' | grep -qw homepage" "Run: make -f tools/Makefile restart NAME=dashboard" "homepage"
check_step "Portainer" "sudo docker ps --format '{{.Names}}' | grep -qw portainer" "Run: make -f tools/Makefile restart NAME=portainer" "portainer"

# --- Storage & Collaboration ---
echo -e "\n${HIGHLIGHT}📦 Storage & Collaboration${RESET}"
check_step "Nextcloud (cloud)" "sudo docker ps --format '{{.Names}}' | grep -qw nextcloud" \
  "Run: make -f tools/Makefile restart NAME=nextcloud" "nextcloud"
check_step "Gitea" "sudo docker ps --format '{{.Names}}' | grep -qw gitea" \
  "Run: make -f tools/Makefile restart NAME=knowledge" "gitea"

# --- Security ---
echo -e "\n${HIGHLIGHT}🔒 Security${RESET}"
check_step "Vaultwarden" "sudo docker ps --format '{{.Names}}' | grep -qw vaultwarden" "Check config/.env for VW_ADMIN_TOKEN and restart" "vaultwarden"

# --- Monitoring ---
echo -e "\n${HIGHLIGHT}📊 Monitoring${RESET}"
for svc in prometheus grafana alertmanager victoriametrics node_exporter cadvisor; do
  check_step "$svc" "sudo docker ps --format '{{.Names}}' | grep -qw $svc" \
    "Run: make -f tools/Makefile restart NAME=monitoring" "$svc"
done

# --- Notifications ---
echo -e "\n${HIGHLIGHT}📣 Notifications${RESET}"
check_step "ntfy" "sudo docker ps --format '{{.Names}}' | grep -qw ntfy" "Run: make -f tools/Makefile restart NAME=notifications" "ntfy"

# --- Final report ---
echo
if [ "$failures" -eq 0 ]; then
  echo -e "${SUCCESS}🎉 All checks passed. Atlas appears healthy.${RESET}"
else
  echo -e "${ERROR}⚠️  $failures issue(s) detected.${RESET}"
  echo
  echo "👉 Next steps:"
  echo "  - Review logs in the 'logs/' folder"
  echo "  - Check container logs manually: sudo docker logs <container_name> --tail=100 -f"
  echo "  - Check system logs: journalctl -xe"
  echo "  - Consult docs/TROUBLESHOOTING.md for detailed fixes"
  echo
fi
