#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Stopping AI Stack..."

docker compose down

echo "Done."
