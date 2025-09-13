#!/usr/bin/env bash
set -euo pipefail


# Runs the full host preparation and brings up the core layer.


SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"


source .env 2>/dev/null || true


sudo bash scripts/base.sh
sudo bash scripts/docker.sh
sudo bash scripts/tailscale.sh
sudo bash scripts/firewall.sh


# Create project network and run core services
bash scripts/atlas.sh


echo "✅ Bootstrap complete. Try: http://$ATLAS_HOSTNAME.$BASE_DOMAIN"