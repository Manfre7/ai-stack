#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

set -a
source .env
set +a

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

ok()   { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✖${NC} $1"; }

echo
echo "=========================================="
echo " AI Stack Health Check"
echo "=========================================="
echo

####################################################
# Docker
####################################################

echo -e "${BLUE}Docker${NC}"

if docker info >/dev/null 2>&1; then
    ok "Docker daemon running"
else
    err "Docker daemon not running"
    exit 1
fi

echo

####################################################
# Containers
####################################################

echo -e "${BLUE}Containers${NC}"

for c in hermes open-webui openclaw
do
    if docker ps --format "{{.Names}}" | grep -qx "$c"; then
        ok "$c running"
    else
        warn "$c not running"
    fi
done

echo

####################################################
# LLM provider
####################################################

echo -e "${BLUE}${LLM_PROVIDER_NAME}${NC}"

MODEL=$(curl -s $OPENAI_API_BASE/models \
| jq -r '.data[0].id' 2>/dev/null)

if [ -z "$MODEL" ] || [ "$MODEL" = "null" ]; then
    err "${LLM_PROVIDER_NAME} not reachable"
else
    ok "Endpoint reachable"
    ok "Model: $MODEL"
fi

echo

####################################################
# Hermes
####################################################

echo -e "${BLUE}Hermes${NC}"

if docker exec hermes hermes --version >/dev/null 2>&1
then
    ok "Hermes responding"
else
    err "Hermes not responding"
fi

echo

####################################################
# Workspace
####################################################

echo -e "${BLUE}Workspace${NC}"

if docker exec hermes test -d /workspace
then
    ok "/workspace mounted"
else
    err "/workspace missing"
fi

echo

####################################################
# Telegram Bot
####################################################

echo -e "${BLUE}Telegram${NC}"

IS_TG_BOT_OK=$(curl -s https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getWebhookInfo \
| jq -r '.ok' 2>/dev/null)

if [ -z "$IS_TG_BOT_OK" ] || [ "$IS_TG_BOT_OK" = "null" ] || [ "$IS_TG_BOT_OK" = "false" ]; then
    err "Telegram bot not reachable"
else
    ok "Telegram bot reachable"
fi

echo

####################################################
# Healthcheck
####################################################

echo -e "${BLUE}Docker health${NC}"

STATUS=$(docker inspect \
--format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
hermes)

case "$STATUS" in

healthy)
    ok "Hermes healthy"
;;

starting)
    warn "Hermes starting"
;;

none)
    warn "No docker healthcheck"
;;

*)
    err "Hermes unhealthy"
;;

esac

echo
echo "Done."
