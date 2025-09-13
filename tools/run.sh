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
echo -e "${INFO}🌌 Atlas Launcher${RESET}"
echo

# --- Menu loop ---
while true; do
  echo -e "${PROMPT}${HIGHLIGHT}What would you like to do?${RESET}"
  echo "  1) Install Atlas (setup configs, secrets, services)"
  echo "  2) Network configuration"
  echo "  3) Prepare runtime (keeps only files needed to run the server)"
  echo "  4) Run sanity check"
  echo "  5) Start services (make up-all)"
  echo "  6) Stop services (make down-all)"
  echo "  7) Troubleshoot Atlas"
  echo "  8) Documentation"
  echo "  9) Exit"
  echo
  read -rp "👉 Choose an option [1-9]: " choice
  echo

  case "$choice" in
    1) bash "$TOOLS_DIR/install.sh" ;;
    2) bash "$TOOLS_DIR/network.sh" ;;
    3) bash "$TOOLS_DIR/prepare-runtime.sh" ;;
    4) bash "$TOOLS_DIR/sanity-check.sh" ;;
    5) make -f "$TOOLS_DIR/Makefile" up-all ;;
    6) make -f "$TOOLS_DIR/Makefile" down-all ;;
    7) bash "$TOOLS_DIR/troubleshoot.sh" ;;
    8) show_docs_menu ;;
    9)
      echo -e "${SUCCESS}👋 Goodbye!${RESET}"
      exit 0
      ;;
    *) echo -e "${ERROR}❌ Invalid option. Try again.${RESET}" ;;
  esac

  echo
done


