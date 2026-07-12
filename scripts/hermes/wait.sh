#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

CONFIG="services/hermes/data/config.yaml"

echo "Waiting for Hermes..."

until [ -f "$CONFIG" ]
do
    sleep 1
done

echo "config.yaml created."
