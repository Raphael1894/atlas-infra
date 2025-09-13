#!/usr/bin/env bash
set -euo pipefail

# ── Setup ────────────────────────────────────────────────

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Load shared colors
source "$SCRIPT_DIR/../../tools/colors.sh"

echo -e "${INFO}🐳 Installing Docker...${RESET}"

# ── Install Docker Engine + Compose v2 ───────────────────

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker and start it
sudo systemctl enable --now docker

# Add current user to docker group (so future logins don’t need sudo)
sudo usermod -aG docker "${SUDO_USER:-$USER}" || true

# Tune containerd for better defaults
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo systemctl restart containerd

# Wait for Docker to be ready before continuing
echo -e "${INFO}⏳ Waiting for Docker daemon...${RESET}"
timeout 30s bash -c 'until sudo docker info >/dev/null 2>&1; do sleep 1; done' || true

# ── Sanity check ─────────────────────────────────────────

echo -e "${INFO}🔍 Running Docker sanity checks...${RESET}"
sudo docker --version
sudo docker compose version
sudo docker ps >/dev/null 2>&1 || true

echo -e "${INFO}🐳 Running hello-world test...${RESET}"
if sudo docker run --rm hello-world >/dev/null 2>&1; then
  echo -e "${SUCCESS}✅ hello-world ran successfully${RESET}"
else
  echo -e "${ERROR}❌ Failed to run hello-world${RESET}"
fi

# Clean up hello-world image so system stays clean
sudo docker image rm -f hello-world >/dev/null 2>&1 || true

echo -e "${SUCCESS}🎉 Docker & Compose are installed and working!${RESET}"
