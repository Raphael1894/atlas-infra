#!/usr/bin/env bash
set -euo pipefail


export DEBIAN_FRONTEND=noninteractive


apt-get update
apt-get upgrade -y
apt-get install -y \
ca-certificates curl gnupg lsb-release \
ufw jq vim htop git wget unzip apt-transport-https \
avahi-daemon # mDNS for *.local if you use it


# Timezone
if [ -n "${TZ:-}" ]; then
timedatectl set-timezone "$TZ" || true
fi


# Create data roots
DATA_ROOT=${DATA_ROOT:-/srv/atlas}
BACKUPS_ROOT=${BACKUPS_ROOT:-/srv/atlas-backups}
mkdir -p "$DATA_ROOT" "$BACKUPS_ROOT"
chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} "$DATA_ROOT" "$BACKUPS_ROOT"