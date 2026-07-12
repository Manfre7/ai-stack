#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

echo "=== Docker Containers ==="
docker compose ps

echo
echo "=== Disk Usage ==="
du -sh services/* workspace logs backups 2>/dev/null || true

echo
echo "=== Docker Images ==="
docker images | grep -E 'hermes|openclaw|open-webui'
