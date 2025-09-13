#!/usr/bin/env bash
set -euo pipefail


# Create shared docker network and bring up the core stack.


set -a
source .env 2>/dev/null || true
set +a


NET=${ATLAS_DOCKER_NETWORK:-atlas_net}


docker network ls --format '{{.Name}}' | grep -q "^${NET}$" || docker network create "$NET"


make up-core