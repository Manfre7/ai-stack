#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

STAMP=$(date +"%Y-%m-%d_%H-%M")

DEST="backups/$STAMP"

mkdir -p "$DEST"

cp docker-compose.yaml "$DEST"
cp .env "$DEST"

cp -a services/hermes/data "$DEST/hermes-data"

echo "Backup completed:"
echo "$DEST"
