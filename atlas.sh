#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/tools/colors.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
LAUNCHER="$SCRIPT_DIR/tools/run.sh"

echo -e "${INFO}🚀 Launching Atlas...${RESET}"

# --- Check existence ---
if [ ! -f "$LAUNCHER" ]; then
  echo -e "${ERROR}❌ Missing launcher: $LAUNCHER${RESET}"
  echo -e "${WARN}ℹ️  Did you move or delete the tools folder?${RESET}"
  echo -e "   Expected structure:"
  echo -e "   ./atlas.sh"
  echo -e "   ./tools/run.sh"
  exit 1
fi

# --- Ensure executability ---
if [ ! -x "$LAUNCHER" ]; then
  echo -e "${WARN}⚠️  $LAUNCHER was not executable. Fixing...${RESET}"
  chmod +x "$LAUNCHER"
  echo -e "${SUCCESS}✅ Fixed permissions on $LAUNCHER${RESET}"
fi

# --- Hand off to launcher ---
exec "$LAUNCHER" "$@"
