#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo
echo "=========================================="
echo " AI Stack Doctor"
echo "=========================================="
echo

echo "System"

uname -a

echo
echo "Disk"

df -h

echo
echo "Docker"

docker version

echo
docker compose ps

echo
echo "Volumes"

docker exec hermes ls -lah /opt/data

echo
echo "UID/GID"

docker exec hermes id hermes

echo
echo "Environment"

docker exec hermes env | grep HERMES || true

echo
echo "Workspace"

docker exec hermes pwd
docker exec hermes ls /workspace

echo
echo "Config"

docker exec hermes grep "default:" /opt/data/config.yaml

docker exec hermes grep "provider:" /opt/data/config.yaml

docker exec hermes grep "base_url:" /opt/data/config.yaml

echo
echo "Model"

LLM_HOST=$(ip route | awk '/default/ {print $3}')

curl -s http://$LLM_HOST:8080/v1/models | jq

echo
echo "Inference test"

curl -s http://$LLM_HOST:8080/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
"model":"Qwen3.6-27B-Q3_K_M.gguf",
"messages":[
{
"role":"user",
"content":"Rispondi esclusivamente OK"
}
],
"max_tokens":4
}' | jq '.choices[0].message.content'

echo
echo "Docker logs"

docker logs hermes --tail 30

echo
echo "Health"

docker inspect hermes \
--format='{{json .State.Health}}' \
| jq

echo
echo "Container usage"

docker stats --no-stream

echo
echo "Directory sizes"

du -sh services/hermes/data
du -sh workspace

echo
echo "Recent files"

find services/hermes/data -type f | tail

echo
echo "Done."
