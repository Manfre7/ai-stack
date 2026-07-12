#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "./restore.sh backups/<directory>"
    exit 1
fi

docker compose down

rm -rf services/hermes/data

cp -a "$1/hermes-data" services/hermes/data

cp "$1/docker-compose.yaml" .

cp "$1/.env" .

./scripts/start.sh
