#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
TOOLS_DIR="$SCRIPT_DIR"

# --- Clear terminal ---
clear || tput clear || true

# --- Check required scripts ---
REQUIRED_FILES=(
  "install.sh"
  "bootstrap.sh"
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

# --- Banner ---
echo -e "${INFO}🌌 Atlas Launcher${RESET}"
echo

# --- Menu loop ---
while true; do
  echo -e "${PROMPT}${HIGHLIGHT}What would you like to do?${RESET}"
  echo "  1) Install Atlas (setup configs, secrets, services)"
  echo "  2) Bootstrap (install system deps, Docker, firewall, tailscale)"
  echo "  3) Prepare runtime (keeps only files needed to run the server)"
  echo "  4) Run sanity check"
  echo "  5) Troubleshoot Atlas"
  echo "  6) Start services (make up-all)"
  echo "  7) Stop services (make down-all)"
  echo "  8) Exit"
  echo
  read -rp "👉 Choose an option [1-8]: " choice
  echo

  case "$choice" in
    1) bash "$TOOLS_DIR/install.sh" ;;
    2) bash "$TOOLS_DIR/bootstrap.sh" ;;
    3) bash "$TOOLS_DIR/prepare-runtime.sh" ;;
    4) bash "$TOOLS_DIR/sanity-check.sh" ;;
    5) bash "$TOOLS_DIR/troubleshoot.sh" ;;
    6) make -f "$TOOLS_DIR/Makefile" up-all ;;
    7) make -f "$TOOLS_DIR/Makefile" down-all ;;
    8)
      echo -e "${SUCCESS}👋 Goodbye!${RESET}"
      exit 0
      ;;
    *) echo -e "${ERROR}❌ Invalid option. Try again.${RESET}" ;;
  esac

  echo
done
