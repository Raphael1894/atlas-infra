#!/usr/bin/env bash
set -euo pipefail

# Install Docker Engine + Compose v2
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker and start it
systemctl enable --now docker

# Add user to docker group (so you can run docker without sudo after re-login)
usermod -aG docker ${SUDO_USER:-$USER} || true

# Tune containerd for better defaults
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
systemctl restart containerd

# Wait for Docker to be ready before continuing
echo "⏳ Waiting for Docker daemon..."
timeout 30s bash -c 'until docker info >/dev/null 2>&1; do sleep 1; done' || true

# --- Sanity check function ---
check_docker() {
  echo "🔍 Running Docker sanity checks..."
  docker --version || return 1
  docker compose version || return 1
  docker ps >/dev/null 2>&1 || return 1

  echo "🐳 Running hello-world container test..."
  if docker run --rm hello-world >/dev/null 2>&1; then
    echo "✅ hello-world ran successfully"
  else
    echo "❌ Failed to run hello-world"
    return 1
  fi

  # Remove hello-world image so system stays clean
  docker image rm -f hello-world >/dev/null 2>&1 || true
  echo "🧹 hello-world image removed"

  return 0
}

# First attempt
if check_docker; then
  echo "🎉 Docker & Compose are installed and working!"
else
  echo "⚠️  Docker not ready yet. Waiting 60s and retrying..."
  sleep 60
  if check_docker; then
    echo "🎉 Docker & Compose are installed and working (after retry)!"
  else
    echo "❌ Docker failed to start after retry. Exiting."
    exit 1
  fi
fi
