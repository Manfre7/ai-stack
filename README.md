# AI Stack

> A reproducible, local-first AI development environment powered by Docker, Hermes Agent and local LLMs.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)]()
[![Linux](https://img.shields.io/badge/Linux-WSL2-green?logo=linux)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)]()

AI Stack is an opinionated Docker environment that provides everything needed to run a complete local AI ecosystem.

It combines:

- 🤖 Hermes Agent
- 🧠 Local LLMs through llama.cpp
- 💬 Telegram bot
- 📁 Shared development workspace
- 🧠 Persistent AI memory
- ⚙️ Configuration from a single `.env` file

The entire environment is reproducible from Git with a single `docker compose up -d`.

---

# Features

- Local-first architecture
- Docker-based deployment
- LLM provider, model and Telegram bot configured in `.env`
- No setup scripts: Hermes reads the configuration at startup
- OpenAI-compatible local endpoint (llama.cpp)
- Persistent memories and sessions
- Shared workspace for AI agents
- Native Backup & Restore
- Health diagnostics
- One-command updates
- UID/GID synchronization
- Ready for OpenWebUI and OpenClaw

---

# Architecture

```
                 +-----------------------+
                 |       llama.cpp       |
                 | OpenAI-compatible API |
                 +-----------+-----------+
                             |
                        LLM_BASE_URL
                             |
 +----------+    +-----------v-----------+
 | Telegram |<-->|     Hermes Agent      |
 +----------+    |   (gateway process)   |
                 +-----------+-----------+
                             |
            +----------------+----------------+
            |                                 |
        /opt/data                        /workspace
      Hermes state                    Shared projects
```

Hermes stores its own data separately from the development workspace.

This allows multiple AI tools to share the same project directory without interfering with Hermes internal state.

---

# Project Structure

```
ai-stack/
│
├── services/
│   └── hermes/
│       ├── config.yaml      # managed Hermes config, values taken from .env
│       └── data/            # Hermes state, mounted at /opt/data (gitignored)
│
├── workspace/               # shared workspace, mounted at /workspace
│
├── docker-compose.yaml
├── .env.example
└── README.md
```

---

# Requirements

- Docker with Docker Compose v2
- WSL2 (recommended on Windows)
- An OpenAI-compatible LLM server, e.g. llama.cpp
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

---

# Quick Start

Clone the repository

```bash
git clone https://github.com/Manfre7/ai-stack.git
cd ai-stack
```

Create your environment

```bash
cp .env.example .env
```

Edit the configuration: LLM endpoint and model, Telegram bot token and allowed users

```bash
nano .env
```

Start the stack

```bash
docker compose up -d
```

Check the logs, then send a message to your bot

```bash
docker compose logs -f hermes
```

---

# Configuration

All configuration lives inside `.env`.

| Variable | Description |
|----------|-------------|
| `LLM_PROVIDER` | Hermes provider id. `custom` (default) = any OpenAI-compatible endpoint |
| `LLM_BASE_URL` | Endpoint URL as seen from the container, e.g. `http://host.docker.internal:8080/v1` |
| `LLM_MODEL` | Model id exposed by the endpoint **(required)** |
| `LLM_API_KEY` | Endpoint key; leave empty if llama.cpp runs without `--api-key` |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather **(required)** |
| `TELEGRAM_ALLOWED_USERS` | Comma-separated numeric Telegram user IDs allowed to use the bot **(required)** |
| `TZ` | Container timezone |
| `HERMES_UID` / `HERMES_GID` | Host user that owns `services/hermes/data` |
| `HERMES_VERSION` | Image tag, `latest` when unset |

If a required variable is missing, `docker compose up` stops with an explicit error.

To change the configuration, edit `.env` and run `docker compose up -d` again: Compose recreates the container with the new values.

Any other variable supported by Hermes (e.g. `TELEGRAM_HOME_CHANNEL`) can be added to `.env` too: the whole file is passed to the container.

---

# How Configuration Works

Hermes reads two kinds of settings, and the stack feeds both from `.env`:

- **Telegram** is configured by environment variables only. `TELEGRAM_BOT_TOKEN` enables the Telegram adapter of the Hermes gateway and `TELEGRAM_ALLOWED_USERS` is its allowlist.
- **The model** is read only from `config.yaml`. The repo mounts [services/hermes/config.yaml](services/hermes/config.yaml) at `/etc/hermes/config.yaml`, the *managed* configuration layer of Hermes: its keys are applied on top of the `config.yaml` that Hermes generates in `/opt/data`, and its `${VAR}` references are resolved from the container environment, that is from `.env`.

```
.env ──► container environment ──┬──► TELEGRAM_*  ──► Telegram gateway
                                 │
                                 └──► ${LLM_*} in /etc/hermes/config.yaml
                                                  │
                                                  ▼
                                      overrides /opt/data/config.yaml
```

Everything else in `/opt/data/config.yaml` stays under Hermes' control, so options added by new Hermes releases keep working.

Things to know:

- `.env` is the single source of truth for the model: the keys set by the managed layer cannot be changed with `hermes config set` or from chat.
- Configure Telegram only through `.env`. `hermes setup`, `hermes gateway setup` and the dashboard QR flow write `TELEGRAM_*` into `services/hermes/data/.env`, which Hermes loads with priority over the container environment. If that happens, delete those lines from `services/hermes/data/.env`.
- `host.docker.internal` points to the Docker host (with Docker Desktop, the Windows host running llama.cpp), so `LLM_BASE_URL` does not depend on WSL2 IP addresses, which change with reboots and networking mode. If the container cannot connect, start llama.cpp with `--host 0.0.0.0`.

---

# Workspace

The project intentionally separates two different directories.

## Hermes data

```
/opt/data
```

Contains:

- memories
- sessions
- skills
- cache
- configuration
- authentication
- SQLite databases
- plugins

Mounted from

```
services/hermes/data
```

---

## Development workspace

```
/workspace
```

Contains:

- projects
- playground
- documentation
- prompts
- experiments
- temporary files

Mounted from

```
workspace/
```

This directory is intentionally kept separate so multiple AI tools can safely share it. Commands run by the Hermes agent start here.

---

# Operations

| Task | Command |
|------|---------|
| Start, or apply `.env` changes | `docker compose up -d` |
| Stop | `docker compose down` |
| Apply changes to `services/hermes/config.yaml` | `docker compose restart hermes` |
| Status | `docker compose ps` |
| Logs | `docker compose logs -f hermes` |
| Diagnostics | `docker compose exec hermes hermes doctor` |
| Effective Hermes configuration | `docker compose exec hermes hermes config` |
| Chat from the terminal | `docker compose exec hermes hermes` |

---

# Updating

```bash
docker compose pull
docker compose up -d
```

Persistent data in `services/hermes/data` is preserved. Set `HERMES_VERSION` in `.env` to pin a release and update only when you choose.

---

# Backup & Restore

Create a backup (a zip of `/opt/data`, with a consistent copy of the SQLite databases)

```bash
docker compose exec hermes hermes backup
```

The zip is written to `services/hermes/data/hermes-backup-<timestamp>.zip`: move it somewhere safe. It does not include the repository `.env`, so keep a copy of that too.

Restore: copy the zip back into `services/hermes/data/`, then

```bash
docker compose exec hermes hermes import /opt/data/hermes-backup-<timestamp>.zip
docker compose restart hermes
```

---

# Persistent Data

Hermes stores all persistent data inside

```
services/hermes/data/
```

including

- memories
- sessions
- authentication
- SQLite databases
- configuration
- cache
- skills

Removing this directory completely resets Hermes.

---

# Roadmap

- ✅ Docker deployment
- ✅ Configuration from `.env`
- ✅ Local llama.cpp integration
- ✅ UID/GID synchronization
- ✅ Backup & Restore
- ✅ Health diagnostics
- ✅ Telegram integration
- ⏳ OpenWebUI
- ⏳ OpenClaw
- ⏳ Benchmark suite
- ⏳ CI/CD
- ⏳ Multi-model profiles

---

# Contributing

Contributions, issues and feature requests are welcome.

Feel free to open an Issue or submit a Pull Request.

---

# License

MIT License

---

Made with ❤️ for local AI development.
