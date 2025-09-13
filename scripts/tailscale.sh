#!/usr/bin/env bash
set -euo pipefail


# Install Tailscale and bring the daemon up. You will need to authenticate once.


curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled


# Attempt to bring it up non-interactively if TS_AUTHKEY is provided
if [ -n "${TS_AUTHKEY:-}" ]; then
tailscale up --authkey "$TS_AUTHKEY" --ssh --hostname "${ATLAS_HOSTNAME:-atlas}"
else
echo "👉 Run 'sudo tailscale up --ssh --hostname ${ATLAS_HOSTNAME:-atlas}' to authenticate if not already."
fi