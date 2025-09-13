#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
LAUNCHER="$SCRIPT_DIR/tools/run.sh"

echo -e "${CYAN}🚀 Launching Atlas...${RESET}"

# --- Check existence ---
if [ ! -f "$LAUNCHER" ]; then
  echo -e "${RED}❌ Missing launcher: $LAUNCHER${RESET}"
  echo -e "${YELLOW}ℹ️  Did you move or delete the tools folder?${RESET}"
  echo -e "   Expected structure:"
  echo -e "   ./run.sh"
  echo -e "   ./tools/run.sh"
  exit 1
fi

# --- Check executability ---
if [ ! -x "$LAUNCHER" ]; then
  echo -e "${YELLOW}⚠️  $LAUNCHER is not executable.${RESET}"
  echo -e "   Fix with:"
  echo -e "   chmod +x tools/run.sh"
  echo
  exit 1
fi

# --- Hand off to launcher ---
exec "$LAUNCHER" "$@"
