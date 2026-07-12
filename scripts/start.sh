#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Starting AI Stack..."

./scripts/hermes/init.sh

docker compose up -d

echo "Done."
