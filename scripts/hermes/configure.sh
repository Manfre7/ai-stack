#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

CONFIG="services/hermes/data/config.yaml"

# -----------------------------------------------------------------------------
# Check if config.yaml is missing
# -----------------------------------------------------------------------------

[ -f "$CONFIG" ] || {
    echo "Missing config.yaml"
    exit 1
}

# -----------------------------------------------------------------------------
# Check if yq command is installed
# -----------------------------------------------------------------------------

command -v yq >/dev/null || {
    echo "ERROR: yq not installed."
    exit 1
}

# -----------------------------------------------------------------------------
# Load .env
# -----------------------------------------------------------------------------

set -a
source .env
set +a

echo "==> Configuring Hermes..."

# -----------------------------------------------------------------------------
# Validate required variables
# -----------------------------------------------------------------------------

required=(
    OPENAI_API_BASE
    OPENAI_API_KEY
    LLM_PROVIDER
    LLM_PROVIDER_NAME
    LLM_MODEL
)

for var in "${required[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "ERROR: Missing variable $var in .env"
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# Update model section
# -----------------------------------------------------------------------------

yq -i '
.model.default = env(LLM_MODEL) |
.model.provider = env(LLM_PROVIDER) |
.model.base_url = env(OPENAI_API_BASE) |
.model.api_key = env(OPENAI_API_KEY)
' "$CONFIG"

# -----------------------------------------------------------------------------
# Create custom_providers if missing
# -----------------------------------------------------------------------------

if ! yq '.custom_providers' "$CONFIG" >/dev/null 2>&1; then
    yq -i '.custom_providers = []' "$CONFIG"
fi

# -----------------------------------------------------------------------------
# Add LLM provider if missing
# -----------------------------------------------------------------------------

FOUND=$(yq '
.custom_providers
| map(select(.name == env(LLM_PROVIDER_NAME)))
| length
' "$CONFIG")

if [ "$FOUND" = "0" ]; then

    yq -i '
.custom_providers += [{
    "name": env(LLM_PROVIDER_NAME),
    "base_url": env(OPENAI_API_BASE),
    "api_key": env(OPENAI_API_KEY),
    "model": env(LLM_MODEL)
}]
' "$CONFIG"

else

yq -i '
(.custom_providers[] | select(.name == env(LLM_PROVIDER_NAME))).base_url = env(OPENAI_API_BASE) |
(.custom_providers[] | select(.name == env(LLM_PROVIDER_NAME))).api_key = env(OPENAI_API_KEY) |
(.custom_providers[] | select(.name == env(LLM_PROVIDER_NAME))).model = env(LLM_MODEL)
' "$CONFIG"

fi

echo
echo "Hermes configuration updated:"
echo
echo " Provider : $LLM_PROVIDER"
echo " Name     : $LLM_PROVIDER_NAME"
echo " Model    : $LLM_MODEL"
echo " Endpoint : $OPENAI_API_BASE"
echo
