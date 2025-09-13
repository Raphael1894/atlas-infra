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

# --- Check if using DHCP (simple netplan check) ---
DHCP_MODE="unknown"
if grep -qi 'dhcp4: true' /etc/netplan/*.yaml 2>/dev/null; then
  DHCP_MODE="dhcp"
elif grep -qi 'dhcp4: no' /etc/netplan/*.yaml 2>/dev/null; then
  DHCP_MODE="static"
fi

# --- Show current status ---
echo "   Interface:  $DEFAULT_IFACE"
echo "   IP Address: $CURRENT_IP"
echo "   Gateway:    $GATEWAY"
echo "   Mode:       $DHCP_MODE"
if [[ "$DHCP_MODE" == "dhcp" ]]; then
  echo -e "${WARN}⚠️  DHCP detected. A static IP is strongly recommended for servers.${RESET}"
fi

# --- Ask user if they want to change ---
echo -ne "${PROMPT}👉 Do you want to change the IP address? [y/N]: ${RESET}"
read -r CHANGE_IP
CHANGE_IP=${CHANGE_IP,,}

if [[ "$CHANGE_IP" != "y" && "$CHANGE_IP" != "yes" ]]; then
  echo -e "${INFO}ℹ️  Keeping current network configuration.${RESET}"
  exit 0
fi

# --- Loop until a free IP is entered ---
while true; do
  echo -ne "${PROMPT}👉 Enter new static IP address (CIDR, e.g. 192.168.1.100/24): ${RESET}"
  read -r NEW_IP_CIDR
  NEW_IP=${NEW_IP_CIDR%/*}

  if ping -c1 -W1 "$NEW_IP" &>/dev/null; then
    echo -e "${ERROR}❌ IP $NEW_IP is already in use.${RESET}"
    echo -ne "${PROMPT}👉 Do you want to try another IP? [y/N]: ${RESET}"
    read -r TRY_AGAIN
    TRY_AGAIN=${TRY_AGAIN,,}
    if [[ "$TRY_AGAIN" != "y" && "$TRY_AGAIN" != "yes" ]]; then
      echo -e "${ERROR}❌ Aborting network reconfiguration.${RESET}"
      sleep 3
      exit 1
    fi
  else
    break
  fi
done

# --- Prompt for DNS ---
echo -ne "${PROMPT}👉 Enter DNS servers (comma separated, default: 1.1.1.1,8.8.8.8): ${RESET}"
read -r DNS_SERVERS
DNS_SERVERS=${DNS_SERVERS:-"1.1.1.1,8.8.8.8"}

# --- Backup netplan config ---
NETPLAN_FILE="/etc/netplan/01-atlas-network.yaml"
BACKUP_FILE="/etc/netplan/01-atlas-network.backup.$(date +%s).yaml"
if [ -f "$NETPLAN_FILE" ]; then
  sudo cp "$NETPLAN_FILE" "$BACKUP_FILE"
fi

# --- Write new netplan config ---
sudo tee "$NETPLAN_FILE" >/dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $DEFAULT_IFACE:
      dhcp4: no
      addresses:
        - $NEW_IP_CIDR
      gateway4: $GATEWAY
      nameservers:
        addresses: [${DNS_SERVERS//,/ }]
EOF

# --- Apply configuration ---
echo -e "${INFO}⚙️  Applying new network configuration...${RESET}"
if ! sudo netplan apply; then
  echo -e "${ERROR}❌ Failed to apply netplan config. Rolling back...${RESET}"
  if [ -f "$BACKUP_FILE" ]; then
    sudo cp "$BACKUP_FILE" "$NETPLAN_FILE"
    sudo netplan apply || true
  fi
  echo -e "${ERROR}⚠️  Please update your network configuration manually.${RESET}"
  sleep 3
  exit 1
fi

# --- Verify IP applied ---
sleep 3
APPLIED_IP=$(ip -4 addr show dev "$DEFAULT_IFACE" | awk '/inet / {print $2}' | cut -d/ -f1)

if [[ "$APPLIED_IP" == "$NEW_IP" ]]; then
  echo -e "${SUCCESS}✅ Network updated. New IP: $NEW_IP${RESET}"
else
  echo -e "${ERROR}❌ IP change failed. Current IP is still $APPLIED_IP.${RESET}"
  echo -e "${WARN}⚠️  Rolling back to previous configuration...${RESET}"
  if [ -f "$BACKUP_FILE" ]; then
    sudo cp "$BACKUP_FILE" "$NETPLAN_FILE"
    sudo netplan apply || true
  fi
  echo -e "${ERROR}⚠️  Please try again or update your IP manually.${RESET}"
  sleep 3
  exit 1
fi
