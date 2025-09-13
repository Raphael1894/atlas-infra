#!/usr/bin/env bash
set -euo pipefail


# Restrictive defaults: deny inbound by default, allow LAN + Tailscale, allow SSH.


ufw --force reset
ufw default deny incoming
ufw default allow outgoing


# Allow SSH from anywhere (or restrict to LAN ranges if you prefer)
ufw allow 22/tcp


# Allow HTTP/S **from LAN and Tailscale only**
for NET in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
ufw allow from $NET to any port 80 proto tcp
ufw allow from $NET to any port 443 proto tcp
done


# Allow from Tailscale interface
ufw allow in on tailscale0


ufw --force enable
ufw status verbose