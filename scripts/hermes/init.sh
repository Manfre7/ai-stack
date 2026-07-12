#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

CONFIG="services/hermes/data/config.yaml"

# config già presente?
if [ -f "$CONFIG" ]; then
    echo "Hermes already initialized."

    ./scripts/hermes/configure.sh

    exit 0
fi

echo "First Hermes initialization..."

docker compose up -d hermes

./scripts/hermes/wait.sh

docker compose stop hermes

./scripts/hermes/configure.sh

echo "Hermes initialized."
