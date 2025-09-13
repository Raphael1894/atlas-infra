#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}📦 Preparing Atlas runtime folder...${RESET}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

RUNTIME_DIR="runtime"

# Check if runtime already exists
if [ -d "$RUNTIME_DIR" ]; then
  echo -ne "${WARN}⚠️  A runtime folder already exists. Overwrite it?${RESET} [y/N]: "
  read -r OVERWRITE
  OVERWRITE=${OVERWRITE,,}
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
    echo -e "${ERROR}❌ Aborting. Existing runtime preserved.${RESET}"
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

# Copy runtime tools
cp ../tools/sanity-check.sh "$RUNTIME_DIR/" 2>/dev/null || true

# Copy shared colors
cp ../tools/colors.sh "$RUNTIME_DIR/" 2>/dev/null || true

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

Launch the runtime menu:
\`\`\`bash
./run.sh
\`\`\`

From the menu you can:
- Start/stop all services
- Restart one stack
- View running containers
- Follow logs
- Run a sanity check

Alternatively, you can use \`make\` directly:

\`\`\`bash
make up-all        # Start all services
make down-all      # Stop all services
make restart NAME=cloud   # Restart one stack
make ps            # Show running containers
make logs          # View logs
\`\`\`

## 🩺 Sanity Check

Run:
\`\`\`bash
./sanity-check.sh
\`\`\`

This will verify Docker, the network, and container health.
EOF

# Create runtime run.sh
cat > "$RUNTIME_DIR/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Load shared colors
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/colors.sh"

echo -e "${INFO}🌌 Atlas Runtime Launcher${RESET}"
echo

while true; do
  echo "  1) Start all services"
  echo "  2) Stop all services"
  echo "  3) Restart one stack"
  echo "  4) Show running containers"
  echo "  5) View logs"
  echo "  6) Run sanity check"
  echo "  7) Exit"
  echo
  read -rp "👉 Choose an option [1-7]: " choice
  echo

  case "$choice" in
    1)
      make up-all
      ;;
    2)
      make down-all
      ;;
    3)
      read -rp "Enter stack name (proxy, dashboard, portainer, cloud, knowledge, security, monitoring, notifications): " stack
      make restart NAME="$stack"
      ;;
    4)
      make ps
      ;;
    5)
      make logs
      ;;
    6)
      bash ./sanity-check.sh
      ;;
    7)
      echo -e "${SUCCESS}👋 Goodbye!${RESET}"
      exit 0
      ;;
    *)
      echo -e "${ERROR}❌ Invalid option. Try again.${RESET}"
      ;;
  esac

  echo
done
EOF

chmod +x "$RUNTIME_DIR/run.sh"

echo -e "${SUCCESS}✅ Runtime prepared in: $RUNTIME_DIR${RESET}"

# --- Run sanity check before cleanup ---
if [ -f ../tools/sanity-check.sh ]; then
  echo -e "${INFO}🔎 Running sanity check before cleanup...${RESET}"
  if ! ../tools/sanity-check.sh; then
    echo -e "${ERROR}❌ Sanity check failed. Skipping dev cleanup to avoid breaking runtime.${RESET}"
    echo -e "${WARN}ℹ️ You can fix the issues and re-run this script later.${RESET}"
    exit 1
  fi
fi

# --- Ask user about cleaning dev files ---
echo -ne "${WARN}👉 Do you want to clean development files and keep only runtime?${RESET} [y/N]: "
read -r CONFIRM
CONFIRM=${CONFIRM,,}

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "yes" ]]; then
  echo -e "${INFO}🧹 Cleaning development files...${RESET}"
  for item in * ../config ../docs ../services; do
    if [ "$item" != "$RUNTIME_DIR" ]; then
      rm -rf "$item"
    fi
  done
  mv "$RUNTIME_DIR"/* .
  rmdir "$RUNTIME_DIR"
  echo -e "${SUCCESS}✅ Cleanup complete. Only runtime files remain.${RESET}"

  # --- Ask user about removing this script ---
  echo -ne "${WARN}👉 Do you also want to remove this script (prepare-runtime.sh)?${RESET} [y/N]: "
  read -r REMOVE_SELF
  REMOVE_SELF=${REMOVE_SELF,,}
  if [[ "$REMOVE_SELF" == "y" || "$REMOVE_SELF" == "yes" ]]; then
    rm -- "$0"
    echo -e "${SUCCESS}✅ Script removed. Runtime is now fully clean.${RESET}"
  fi
else
  echo -e "${WARN}ℹ️ Skipped cleanup. Runtime is inside: $RUNTIME_DIR${RESET}"
fi
