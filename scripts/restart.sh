#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

docker compose down
./scripts/init.sh
docker compose up -d

docker compose ps
