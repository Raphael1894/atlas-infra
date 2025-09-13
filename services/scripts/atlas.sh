#!/usr/bin/env bash
set -euo pipefail

# Load env if present
set -a
source .env 2>/dev/null || true
set +a

NET=${ATLAS_DOCKER_NETWORK:-atlas_net}

# Ensure docker network exists
if ! sudo docker network ls --format '{{.Name}}' | grep -q "^${NET}$"; then
  sudo docker network create "$NET"
fi

# Always call the correct Makefile
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)
make -f "$REPO_ROOT/tools/Makefile" up-core
