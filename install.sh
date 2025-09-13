#!/usr/bin/env bash
# install.sh - One-shot installer for Atlas
# Usage: chmod +x install.sh && ./install.sh

set -euo pipefail

echo "🌌 Atlas Installer starting..."

# Ensure we're in the repo root
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

# 1. Make bootstrap executable
chmod +x bootstrap.sh
chmod +x scripts/*.sh

# 2. Run bootstrap (base setup + Docker + Tailscale + firewall + atlas.sh)
echo "⚙️  Running bootstrap..."
./bootstrap.sh

# 3. Bring everything up
echo "🚀 Starting all services..."
make up-all

echo "✅ Atlas installation complete!"
echo
echo "You can now access Atlas services via:"
echo "  Homepage:     http://atlas.local"
echo "  Portainer:    http://portainer.atlas.local"
echo "  Gitea:        http://git.atlas.local"
echo "  OCIS:         http://cloud.atlas.local"
echo "  Vaultwarden:  http://vault.atlas.local"
echo "  Grafana:      http://grafana.atlas.local"
echo "  Prometheus:   http://prometheus.atlas.local"
echo "  Alertmanager: http://alerts.atlas.local"
echo "  ntfy:         http://ntfy.atlas.local"
echo
echo "🎉 All done. Happy homelabbing!"
