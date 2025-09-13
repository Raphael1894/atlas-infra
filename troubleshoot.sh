#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}🩺 Atlas Troubleshooting Script${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

if [ ! -f server_config.env ]; then
  echo -e "${RED}❌ Missing server_config.env. Cannot troubleshoot.${RESET}"
  exit 1
fi

# Load configs
set -a
source server_config.env
[ -f .env ] && source .env
set +a

failures=0
mkdir -p logs

check_step () {
  local description=$1
  local cmd=$2
  local hint=$3
  local service_name=$4

  echo -ne "${CYAN}🔍 Checking ${description}...${RESET} "
  if eval "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${RESET}"
  else
    echo -e "${RED}❌ FAILED${RESET}"
    echo -e "   ${YELLOW}Hint:${RESET} $hint"
    # Save logs if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "$service_name"; then
      docker logs --tail=200 "$service_name" &> "logs/${service_name}.log" || true
      echo -e "   ${CYAN}Logs saved to:${RESET} logs/${service_name}.log"
    fi
    failures=$((failures+1))
  fi
}

# --- System checks ---
echo -e "\n${BOLD}🔧 System Checks${RESET}"
check_step "System package 'curl'" "dpkg -l | grep -q curl" "Run: sudo apt install -y curl" "system"
check_step "System package 'git'" "dpkg -l | grep -q git" "Run: sudo apt install -y git" "system"
check_step "Docker installed" "docker --version" "Re-run scripts/docker.sh" "docker"
check_step "Docker daemon running" "systemctl is-active --quiet docker" "Run: sudo systemctl restart docker && sudo systemctl enable docker" "docker"
check_step "Docker network '$ATLAS_DOCKER_NETWORK'" "docker network inspect $ATLAS_DOCKER_NETWORK" "Run: docker network create $ATLAS_DOCKER_NETWORK" "docker"
check_step "Tailscale installed" "tailscale --version" "Re-run scripts/tailscale.sh" "tailscale"
check_step "Tailscale running" "systemctl is-active --quiet tailscaled" "Run: sudo systemctl restart tailscaled" "tailscale"
check_step "Firewall active" "sudo ufw status | grep -q 'Status: active'" "Run: sudo ufw enable" "ufw"

# --- Core services ---
echo -e "\n${BOLD}🖥️  Core Services${RESET}"
check_step "Proxy (Traefik)" "docker ps --format '{{.Names}}' | grep -q proxy" "Run: make restart NAME=proxy && check logs" "proxy"
check_step "Dashboard (Homepage)" "docker ps --format '{{.Names}}' | grep -q dashboard" "Run: make restart NAME=dashboard" "dashboard"
check_step "Portainer" "docker ps --format '{{.Names}}' | grep -q portainer" "Run: make restart NAME=portainer" "portainer"

# --- Data & collaboration ---
echo -e "\n${BOLD}📦 Storage & Collaboration${RESET}"
check_step "OCIS (cloud)" "docker ps --format '{{.Names}}' | grep -q cloud" "Run: make restart NAME=cloud" "cloud"
check_step "Gitea" "docker ps --format '{{.Names}}' | grep -q knowledge" "Run: make restart NAME=knowledge" "knowledge"

# --- Security ---
echo -e "\n${BOLD}🔒 Security${RESET}"
check_step "Vaultwarden" "docker ps --format '{{.Names}}' | grep -q security" "Check .env for VW_ADMIN_TOKEN and restart" "security"

# --- Monitoring ---
echo -e "\n${BOLD}📊 Monitoring${RESET}"
check_step "Prometheus" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"
check_step "Grafana" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"
check_step "Alertmanager" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"
check_step "VictoriaMetrics" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"
check_step "node_exporter" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"
check_step "cAdvisor" "docker ps --format '{{.Names}}' | grep -q monitoring" "Run: make restart NAME=monitoring" "monitoring"

# --- Notifications ---
echo -e "\n${BOLD}📣 Notifications${RESET}"
check_step "ntfy" "docker ps --format '{{.Names}}' | grep -q notifications" "Run: make restart NAME=notifications" "notifications"

# --- Final report ---
echo
if [ "$failures" -eq 0 ]; then
  echo -e "${GREEN}🎉 All checks passed. Atlas appears healthy.${RESET}"
else
  echo -e "${RED}⚠️  $failures issue(s) detected.${RESET}"
  echo
  echo "👉 Next steps:"
  echo "  - Review logs in the 'logs/' folder (one file per failing service)"
  echo "  - Check container logs manually: docker logs <container_name> --tail=100 -f"
  echo "  - Check system logs: journalctl -xe"
  echo "  - Consult TROUBLESHOOTING.md for detailed fixes"
  echo
fi
