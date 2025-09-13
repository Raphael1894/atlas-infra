#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🌐 Network configuration tool starting...${RESET}"

# --- Detect default interface ---
DEFAULT_IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -z "$DEFAULT_IFACE" ]; then
  echo -e "${ERROR}❌ Could not detect default network interface.${RESET}"
  exit 1
fi

CURRENT_IP=$(ip -4 addr show dev "$DEFAULT_IFACE" | awk '/inet / {print $2}' | cut -d/ -f1)
GATEWAY=$(ip route | awk '/default/ {print $3; exit}')

# --- Show current status ---
echo "   Interface:  $DEFAULT_IFACE"
echo "   Current IP: $CURRENT_IP"
echo "   Gateway:    ${GATEWAY:-not set}"
echo
echo -e "${WARN}⚠️  If your system is using DHCP, we strongly recommend switching to a static IP.${RESET}"
echo

# --- Ask user if they want to prepare static config ---
echo -ne "${PROMPT}👉 Do you want to prepare a static IP configuration? [y/N]: ${RESET}"
read -r CHANGE_IP
CHANGE_IP=${CHANGE_IP,,}

if [[ "$CHANGE_IP" != "y" && "$CHANGE_IP" != "yes" ]]; then
  echo -e "${INFO}ℹ️  Keeping current network configuration.${RESET}"
  exit 0
fi

# --- Ask for static IP ---
while true; do
  echo -ne "${PROMPT}👉 Enter new static IP address (e.g. 192.168.1.59): ${RESET}"
  unset IFS
  read -r NEW_IP || true

  # Validate IP format
  if [[ ! "$NEW_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e "${ERROR}❌ Invalid IP format. Use something like 192.168.1.59${RESET}"
    continue
  fi

  NEW_IP_CIDR="${NEW_IP}/24"
  break
done

# --- Ask for route (gateway) ---
echo -ne "${PROMPT}👉 Enter gateway IP (default: 192.168.1.254): ${RESET}"
read -r NEW_GATEWAY
NEW_GATEWAY=${NEW_GATEWAY:-192.168.1.254}

# --- Show the config to user ---
echo
echo -e "${INFO}📄 Here is the static network configuration we recommend:${RESET}"
echo "------------------------------------------------------------"
cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $DEFAULT_IFACE:
      dhcp4: no
      addresses:
        - $NEW_IP_CIDR
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: $NEW_GATEWAY
EOF
echo "------------------------------------------------------------"
echo

# --- Instructions ---
echo -e "${INFO}👉 To apply this manually:${RESET}"
echo "   1. Save the above config into: /etc/netplan/01-atlas-network.yaml"
echo "   2. Run: sudo chmod 600 /etc/netplan/01-atlas-network.yaml"
echo "   3. Apply with: sudo netplan apply"
echo
echo -e "${WARN}⚠️ Make sure you are on console/SSH with fallback access before applying.${RESET}"
echo
echo -e "${SUCCESS}✅ Configuration snippet generated. Manual action required.${RESET}"
