#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Pull latest images..."
docker compose pull

# init script
./scripts/hermes/init.sh

echo "Recreating containers..."
docker compose up -d

echo "Removing old images..."
docker image prune -f

docker compose ps
