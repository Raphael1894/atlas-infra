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
echo "   IP Address: $CURRENT_IP"
echo "   Gateway:    $GATEWAY"

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
  echo -ne "${PROMPT}👉 Enter new static IP address (e.g. 192.168.1.59): ${RESET}"
  unset IFS
  read -r NEW_IP || true

  # Validate IP format
  if [[ ! "$NEW_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e "${ERROR}❌ Invalid IP address format. Please enter like 192.168.1.59${RESET}"
    continue
  fi

  NEW_IP_CIDR="${NEW_IP}/24"

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

# --- Ask for route (gateway) ---
echo -ne "${PROMPT}👉 Enter gateway IP (default: 192.168.1.254): ${RESET}"
read -r NEW_GATEWAY
NEW_GATEWAY=${NEW_GATEWAY:-192.168.1.254}

# --- File paths ---
NETPLAN_FILE="/etc/netplan/01-atlas-network.yaml"
BACKUP_FILE="/etc/netplan/01-atlas-network.backup.yaml"
ORIGINAL_FILE="/etc/netplan/01-atlas-network.original.yaml"

# --- Save original config once (from cloud-init) ---
if [ ! -f "$ORIGINAL_FILE" ] && [ -f "/etc/netplan/50-cloud-init.yaml" ]; then
  echo -e "${INFO}📦 Saving original distro config as $ORIGINAL_FILE${RESET}"
  sudo cp /etc/netplan/50-cloud-init.yaml "$ORIGINAL_FILE"
  sudo chmod 600 "$ORIGINAL_FILE"
fi

# --- Validate current config before backing up ---
if sudo netplan generate 2>/dev/null; then
  if [ -f "$NETPLAN_FILE" ]; then
    echo -e "${INFO}📦 Backing up last known good config to $BACKUP_FILE${RESET}"
    sudo cp "$NETPLAN_FILE" "$BACKUP_FILE"
    sudo chmod 600 "$BACKUP_FILE"
  fi
else
  echo -e "${WARN}⚠️  Current netplan config is invalid, skipping backup.${RESET}"
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
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: $NEW_GATEWAY
EOF

# --- Secure permissions ---
sudo chmod 600 "$NETPLAN_FILE"

# --- Apply configuration ---
echo -e "${INFO}⚙️  Applying new network configuration...${RESET}"
if ! sudo netplan apply; then
  echo -e "${ERROR}❌ Failed to apply netplan config. Rolling back...${RESET}"
  if [ -f "$BACKUP_FILE" ]; then
    echo -e "${WARN}⚠️  Restoring last known good config...${RESET}"
    sudo cp "$BACKUP_FILE" "$NETPLAN_FILE"
    sudo chmod 600 "$NETPLAN_FILE"
    sudo netplan apply || true
  elif [ -f "$ORIGINAL_FILE" ]; then
    echo -e "${WARN}⚠️  Restoring original distro config...${RESET}"
    sudo cp "$ORIGINAL_FILE" "$NETPLAN_FILE"
    sudo chmod 600 "$NETPLAN_FILE"
    sudo netplan apply || true
  else
    echo -e "${ERROR}❌ No valid backup available. Please fix manually.${RESET}"
  fi
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
    sudo chmod 600 "$NETPLAN_FILE"
    sudo netplan apply || true
  elif [ -f "$ORIGINAL_FILE" ]; then
    sudo cp "$ORIGINAL_FILE" "$NETPLAN_FILE"
    sudo chmod 600 "$NETPLAN_FILE"
    sudo netplan apply || true
  fi
  echo -e "${ERROR}⚠️  Please try again or update your IP manually.${RESET}"
  sleep 3
  exit 1
fi
