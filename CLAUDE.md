# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker Compose setup for one service, [Hermes Agent](https://github.com/NousResearch/hermes-agent) (`nousresearch/hermes-agent`), running its Telegram gateway against an OpenAI-compatible LLM server (llama.cpp on the Windows host; developed on WSL2 with Docker Desktop). There is no application code, build, linter, test suite or script: the repo is `docker-compose.yaml`, `.env.example` and one Hermes config file. Verify changes against a running container with the commands below.

## Commands

```bash
cp .env.example .env                          # then edit; .env is gitignored
docker compose config -q                      # validate; plain `config` prints the secrets from .env
docker compose up -d                          # start, or apply .env changes (recreates the container)
docker compose restart hermes                 # apply edits to services/hermes/config.yaml
docker compose logs -f hermes                 # gateway logs
docker compose exec hermes hermes config      # effective config, managed keys included
docker compose exec hermes hermes doctor      # diagnostics
docker compose exec hermes hermes backup      # zip in services/hermes/data/; restore with `hermes import <zip>`
```

## Architecture

All configuration comes from `.env`; there is no init or patch step.

- **Telegram is env-only.** `TELEGRAM_BOT_TOKEN` enables the gateway's Telegram adapter and `TELEGRAM_ALLOWED_USERS` is its allowlist. The compose `command: gateway run` is what starts the gateway; without it the image runs the interactive CLI.
- **Model settings cannot come from env**: Hermes reads `model.*` only from `config.yaml`. [services/hermes/config.yaml](services/hermes/config.yaml) is mounted read-only at `/etc/hermes/config.yaml`, Hermes' *managed scope* (`hermes_cli/managed_scope.py` upstream): both the gateway and the CLI deep-merge it per leaf on top of `/opt/data/config.yaml`, and its `${VAR}` refs expand from the process env. `hermes config set` refuses the keys it pins.
- **`/opt/data` belongs to Hermes** (`services/hermes/data`, gitignored). On first start the image seeds `config.yaml` and `.env` there; don't template or patch them, add overrides to the managed file instead.
- [docker-compose.yaml](docker-compose.yaml) passes `.env` through `env_file` and re-declares every variable the managed file references, with `${VAR:?}` (required) or `${VAR:-}` (default). Hermes has no `${VAR:-default}` syntax and leaves an undefined `${VAR}` as literal text, so a new `${VAR}` in the managed file needs a matching entry there.

## Gotchas

- `/opt/data/.env` is loaded with `override=True`, so its keys beat the container env (Hermes' Docker docs say the opposite; the code wins). `hermes setup`, `hermes gateway setup` and the dashboard QR flow write `TELEGRAM_*` there and shadow the repo `.env`.
- Mount single files into `/etc/hermes`, never the whole directory: the image keeps other files there. Don't bind-mount a file over `/opt/data/config.yaml` either, since Hermes saves it via atomic replace.
- `workspace/` must exist and be owned by the host user before the first `up` (hence `workspace/.gitkeep`): the image chowns only `/opt/data`. `terminal.cwd: /workspace` in the managed file makes it the agent's working directory.
- For llama.cpp use `LLM_PROVIDER=custom` with a `LLM_BASE_URL`: the `llamacpp` alias without a base URL means Hermes' own managed local server. With `custom`, an empty `LLM_API_KEY` becomes the placeholder `no-key-required`.
- Telegram uses outbound polling, so no ports are published (the API server on 8642 stays internal).
- WSL2 on this machine runs in mirrored networking mode, so the old NAT host IP (`172.28.160.1`) no longer reaches Windows. From the container, `host.docker.internal` (Docker Desktop) does.
