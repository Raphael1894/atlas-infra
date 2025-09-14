#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

TOOLS_DIR="$SCRIPT_DIR"

# --- Clear terminal ---
clear || tput clear || true

# --- Check required scripts ---
REQUIRED_FILES=(
  "install.sh"
  "prepare-runtime.sh"
  "sanity-check.sh"
  "troubleshoot.sh"
  "Makefile"
)

CONFIG_DIR="$SCRIPT_DIR/../config"
INSTALLED_FLAG="$CONFIG_DIR/installed.flag"
ATLAS_INSTALLED=false
declare -A INSTALL_META

if [ -f "$INSTALLED_FLAG" ]; then
  ATLAS_INSTALLED=true
  while IFS='=' read -r key value; do
    case "$key" in
      installed_at) INSTALL_META["installed_at"]=$value ;;
      atlas_version) INSTALL_META["atlas_version"]=$value ;;
      hostname) INSTALL_META["hostname"]=$value ;;
      base_domain) INSTALL_META["base_domain"]=$value ;;
      *_url) INSTALL_META["$key"]=$value ;;
    esac
  done < "$INSTALLED_FLAG"
else
  # No flag yet → fallback to Git version
  GIT_VERSION=$(git -C "$SCRIPT_DIR/.." describe --tags --abbrev=0 2>/dev/null || echo "dev")
  INSTALL_META["atlas_version"]=$GIT_VERSION
fi

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
  TARGET="$TOOLS_DIR/$file"
  if [ ! -f "$TARGET" ]; then
    echo -e "${ERROR}❌ Missing required file: $TARGET${RESET}"
    MISSING=1
  else
    # If it's a shell script, ensure executable
    if [[ "$file" == *.sh ]]; then
      if [ ! -x "$TARGET" ]; then
        echo -e "${WARN}⚠️  $file is not executable. Fixing...${RESET}"
        chmod +x "$TARGET"
        echo -e "${SUCCESS}✅ Fixed: $file is now executable${RESET}"
      fi
    fi
  fi
done

if [ "$MISSING" -ne 0 ]; then
  echo
  echo -e "${ERROR}❌ Some required files are missing. Cannot continue.${RESET}"
  exit 1
fi

# --- Documentation submenu ---
show_docs_menu() {
  while true; do
    clear || tput clear || true
    echo -e "${PROMPT}${HIGHLIGHT}📖 Documentation Menu${RESET}"
    echo "  1) View README ('q' to exit)"
    echo "  2) View TROUBLESHOOTING ('q' to exit)"
    echo "  3) View CONTRIBUTING ('q' to exit)"
    echo "  4) Export documentation"
    echo "  5) Back"
    echo
    read -rp "👉 Choose an option [1-5]: " doc_choice
    echo

    case "$doc_choice" in
      1) show_doc "README.md" ;;
      2) show_doc "docs/TROUBLESHOOTING.md" ;;
      3) show_doc "docs/CONTRIBUTING.md" ;;
      4) export_docs_menu ;;
      5) clear || tput clear || true; return ;;
      *) echo -e "${ERROR}❌ Invalid option. Try again.${RESET}" ;;
    esac
    echo
    read -rp "👉 Press Enter to return to docs menu..." _
  done
}

show_doc() {
  local doc_file=$1
  if [ ! -f "$doc_file" ]; then
    echo -e "${ERROR}❌ File not found: $doc_file${RESET}"
    return
  fi
  echo -e "${INFO}📖 Showing $(basename "$doc_file") in terminal:${RESET}"
  echo
  less "$doc_file"
}

export_docs_menu() {
  while true; do
    clear || tput clear || true
    echo -e "${PROMPT}${HIGHLIGHT}📤 Export Documentation${RESET}"
    echo "  1) Export README"
    echo "  2) Export TROUBLESHOOTING"
    echo "  3) Export CONTRIBUTING"
    echo "  4) Export ALL"
    echo "  5) Back"
    echo
    read -rp "👉 Choose an option [1-5]: " export_choice
    echo

    case "$export_choice" in
      1) export_doc "README.md" ;;
      2) export_doc "docs/TROUBLESHOOTING.md" ;;
      3) export_doc "docs/CONTRIBUTING.md" ;;
      4) export_doc "README.md" && export_doc "docs/TROUBLESHOOTING.md" && export_doc "docs/CONTRIBUTING.md" ;;
      5) return ;;
      *) echo -e "${ERROR}❌ Invalid option.${RESET}" ;;
    esac
    echo
    read -rp "👉 Press Enter to return to export menu..." _
  done
}

export_doc() {
  local doc_file=$1
  if [ ! -f "$doc_file" ]; then
    echo -e "${ERROR}❌ File not found: $doc_file${RESET}"
    return 1
  fi

  CLIENT_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
  LOCAL_USER=${USER}

  # Clean screen before asking
  clear || tput clear || true
  echo -e "${PROMPT}👉 What OS is your local machine running?${RESET}"
  echo "   1) Linux / macOS (scp)"
  echo "   2) Windows (manual copy with WinSCP)"
  echo "   3) Cancel"
  read -rp "Choose [1-3]: " os_choice

  case "$os_choice" in
    1)
      read -rp "👉 Local username [${LOCAL_USER}]: " USERNAME
      USERNAME=${USERNAME:-$LOCAL_USER}
      read -rp "👉 Destination folder [~/AtlasDocs]: " FOLDER
      FOLDER=${FOLDER:-~/AtlasDocs}
      echo -e "${INFO}📤 Exporting $(basename "$doc_file") to $USERNAME@$CLIENT_IP:$FOLDER/${RESET}"
            if scp -o ConnectTimeout=5 "$doc_file" "$USERNAME@$CLIENT_IP:$FOLDER/"; then
        echo -e "${SUCCESS}✅ Exported successfully!${RESET}"
      else
        echo -e "${ERROR}❌ Export failed. It looks like your client may not support SCP.${RESET}"
        echo -e "${WARN}💡 If you are on Windows, please choose option 2 (manual export).${RESET}"
        sleep 3
      fi
      ;;
    2)
      echo -e "${INFO}💡 On your Windows computer, use WinSCP or PuTTY to connect to:${RESET}"
      echo "   Host: $CLIENT_IP"
      echo "   User: $USER"
      echo "   Copy file: $(realpath "$doc_file")"
      echo
      echo -e "${WARN}⚠️ Windows export must be done manually.${RESET}"
      ;;
    3)
      echo -e "${WARN}⚠️ Export cancelled.${RESET}"
      ;;
    *)
      echo -e "${ERROR}❌ Invalid option.${RESET}"
      ;;
  esac
}

# --- Banner ---
clear || tput clear || true
echo -e "${HIGHLIGHT}${INFO}=========================================${RESET}"
echo -e "${HIGHLIGHT}${INFO}🌌           Atlas Launcher              ${RESET}"
echo -e "${HIGHLIGHT}${INFO}=========================================${RESET}"

if [ "$ATLAS_INSTALLED" = true ]; then
  echo -e "${SUCCESS}✅ Installed on:${RESET} ${INSTALL_META[installed_at]:-unknown}"
  echo -e "${PROMPT}💻 Host:${RESET} ${INSTALL_META[hostname]:-unknown}.${INSTALL_META[base_domain]:-unknown}"
fi

echo -e "${WARN}📦 Version:${RESET} ${INSTALL_META[atlas_version]:-dev}"
echo

# --- Show services function and URL ---
show_services() {
  echo -e "${INFO}You can now access your server '${INSTALL_META[hostname]}' services via:${RESET}"
  echo "  Homepage:     http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/"
  echo "  Portainer:    http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/portainer"
  echo "  Gitea:        http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/gitea"
  echo "  OCIS:         http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/ocis"
  echo "  Vaultwarden:  http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/vault"
  echo "  Grafana:      http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/grafana"
  echo "  Prometheus:   http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/prometheus"
  echo "  Alertmanager: http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/alerts"
  echo "  ntfy:         http://${INSTALL_META[hostname]}.${INSTALL_META[base_domain]}/ntfy"
}

# --- Menu loop ---
while true; do
  echo -e "${PROMPT}${HIGHLIGHT}What would you like to do?${RESET}"

  MENU_ITEMS=(
    "Install Atlas (setup configs, secrets, services)|bash \"$TOOLS_DIR/install.sh\"; exit 0"
    "Network configuration|bash \"$TOOLS_DIR/network.sh\""
    "Run sanity check|bash \"$TOOLS_DIR/sanity-check.sh\""
    "Troubleshoot Atlas|bash \"$TOOLS_DIR/troubleshoot.sh\""
    "Documentation|show_docs_menu"
  )

  if [ "$ATLAS_INSTALLED" = true ]; then
    MENU_ITEMS+=(
      "Prepare runtime (keeps only files needed to run the server)|bash \"$TOOLS_DIR/prepare-runtime.sh\""
      "Start services (make up-all)|make -f \"$TOOLS_DIR/Makefile\" up-all"
      "Stop services (make down-all)|make -f \"$TOOLS_DIR/Makefile\" down-all"
      "Show service URLs|show_services"
    )
  fi

  # Show numbered menu
  for i in "${!MENU_ITEMS[@]}"; do
    label="${MENU_ITEMS[$i]%%|*}"
    echo "  $((i+1))) $label"
  done
  echo "  0) Exit"

  echo
  read -rp "👉 Choose an option [0-${#MENU_ITEMS[@]}]: " choice
  echo

  if [[ "$choice" == "0" ]]; then
    echo -e "${SUCCESS}👋 Goodbye!${RESET}"
    exit 0
  elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#MENU_ITEMS[@]}" ]; then
    cmd="${MENU_ITEMS[$((choice-1))]#*|}"
    eval "$cmd"
  else
    echo -e "${ERROR}❌ Invalid option. Try again.${RESET}"
  fi

  echo
done


