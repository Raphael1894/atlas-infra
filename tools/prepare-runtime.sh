#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

echo -e "${CYAN}📦 Preparing Atlas runtime folder...${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

RUNTIME_DIR="runtime"

# Check if runtime already exists
if [ -d "$RUNTIME_DIR" ]; then
  echo -ne "${YELLOW}⚠️  A runtime folder already exists. Overwrite it?${RESET} [y/N]: "
  read -r OVERWRITE
  OVERWRITE=${OVERWRITE,,}
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
    echo -e "${RED}❌ Aborting. Existing runtime preserved.${RESET}"
    exit 1
  fi
  rm -rf "$RUNTIME_DIR"
fi

mkdir -p "$RUNTIME_DIR"

# Copy docker-compose stacks
for stack in proxy dashboard portainer cloud knowledge security monitoring notifications; do
  if [ -d "../services/$stack" ]; then
    mkdir -p "$RUNTIME_DIR/$stack"
    cp "../services/$stack/docker-compose.yml" "$RUNTIME_DIR/$stack/"
  fi
done

# Copy configs
cp ../config/server_config.env "$RUNTIME_DIR/"
if [ -f ../config/.env ]; then
  cp ../config/.env "$RUNTIME_DIR/"
fi

# Copy troubleshooting tools
cp ../docs/TROUBLESHOOTING.md "$RUNTIME_DIR/" 2>/dev/null || true
cp ../tools/troubleshoot.sh "$RUNTIME_DIR/" 2>/dev/null || true
cp ../tools/sanity-check.sh "$RUNTIME_DIR/" 2>/dev/null || true

# Create runtime Makefile
cat > "$RUNTIME_DIR/Makefile" <<'EOF'
COMPOSE = docker compose

.PHONY: up-all down-all restart ps logs

up-all:
	$(COMPOSE) -f proxy/docker-compose.yml up -d
	$(COMPOSE) -f dashboard/docker-compose.yml up -d
	$(COMPOSE) -f portainer/docker-compose.yml up -d
	$(COMPOSE) -f cloud/docker-compose.yml up -d
	$(COMPOSE) -f knowledge/docker-compose.yml up -d
	$(COMPOSE) -f security/docker-compose.yml up -d
	$(COMPOSE) -f monitoring/docker-compose.yml up -d
	$(COMPOSE) -f notifications/docker-compose.yml up -d

down-all:
	$(COMPOSE) -f notifications/docker-compose.yml down
	$(COMPOSE) -f monitoring/docker-compose.yml down
	$(COMPOSE) -f security/docker-compose.yml down
	$(COMPOSE) -f knowledge/docker-compose.yml down
	$(COMPOSE) -f cloud/docker-compose.yml down
	$(COMPOSE) -f portainer/docker-compose.yml down
	$(COMPOSE) -f dashboard/docker-compose.yml down
	$(COMPOSE) -f proxy/docker-compose.yml down

restart:
	@[ -n "$(NAME)" ] || (echo "Usage: make restart NAME=stack" && exit 1)
	$(COMPOSE) -f $(NAME)/docker-compose.yml down && $(COMPOSE) -f $(NAME)/docker-compose.yml up -d

ps:
	docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

logs:
	docker logs -f --tail=200 $(docker ps --format '{{.Names}}')
EOF

# Create runtime README
cat > "$RUNTIME_DIR/README.md" <<EOF
# 🌌 Atlas Runtime

This folder contains the minimal files needed to **run Atlas** after installation.

## 🚀 Usage

Start all services:
\`\`\`bash
make up-all
\`\`\`

Stop all services:
\`\`\`bash
make down-all
\`\`\`

Restart one stack:
\`\`\`bash
make restart NAME=cloud
\`\`\`

## 🩺 Troubleshooting

Run:
\`\`\`bash
./troubleshoot.sh
\`\`\`

Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed fixes.
EOF

echo -e "${GREEN}✅ Runtime prepared in: $RUNTIME_DIR${RESET}"

# --- Run sanity check before cleanup ---
if [ -f ../tools/sanity-check.sh ]; then
  echo -e "${CYAN}🔎 Running sanity check before cleanup...${RESET}"
  if ! ../tools/sanity-check.sh; then
    echo -e "${RED}❌ Sanity check failed. Skipping dev cleanup to avoid breaking runtime.${RESET}"
    echo -e "${YELLOW}ℹ️ You can fix the issues and re-run this script later.${RESET}"
    exit 1
  fi
fi

# --- Ask user about cleaning dev files ---
echo -ne "${YELLOW}👉 Do you want to clean development files and keep only runtime?${RESET} [y/N]: "
read -r CONFIRM
CONFIRM=${CONFIRM,,}

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "yes" ]]; then
  echo -e "${CYAN}🧹 Cleaning development files...${RESET}"
  for item in * ../config ../docs ../services; do
    if [ "$item" != "$RUNTIME_DIR" ]; then
      rm -rf "$item"
    fi
  done
  mv "$RUNTIME_DIR"/* .
  rmdir "$RUNTIME_DIR"
  echo -e "${GREEN}✅ Cleanup complete. Only runtime files remain.${RESET}"

  # --- Ask user about removing this script ---
  echo -ne "${YELLOW}👉 Do you also want to remove this script (prepare-runtime.sh)?${RESET} [y/N]: "
  read -r REMOVE_SELF
  REMOVE_SELF=${REMOVE_SELF,,}
  if [[ "$REMOVE_SELF" == "y" || "$REMOVE_SELF" == "yes" ]]; then
    rm -- "$0"
    echo -e "${GREEN}✅ Script removed. Runtime is now fully clean.${RESET}"
  fi
else
  echo -e "${YELLOW}ℹ️ Skipped cleanup. Runtime is inside: $RUNTIME_DIR${RESET}"
fi
