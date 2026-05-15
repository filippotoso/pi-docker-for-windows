# Pi Docker Environment

This repository contains the scripts and the `Dockerfile` necessary to run [pi](https://pi.dev/) inside an isolated Docker container with basic hardening: non-root runtime, file-mounted API key (not in `docker` environment), and conservative Linux capability restrictions.

The environment maps two directories from your host into the container:

1. **Workspace**: your project at `%cd%` → `/workspace`
2. **Pi state**: skills, settings, and `auth.json` under `PI_DOTPI` (or defaults below) → `/home/sandbox/.pi`

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) installed and running
- An API key file on the host (see below)

## API key file

Pi expects credentials in `~/.pi/agent/auth.json`. The container entrypoint seeds that from a **secret file** mounted read-only at `/run/secrets/cursor_api_key`, so the key is not passed via `docker run -e`.

- **Default host path**: `%USERPROFILE%\.cursor-api-key`
- **Override**: set `CURSOR_API_KEY_FILE` to the full path of your key file before running the batch script.

The file must be a non-empty text file containing the key (one line is enough). By default the key is written into `auth.json` for provider **`opencode`** (see [Pi providers](https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/docs/providers.md)). To target another `auth.json` provider id, set **`PI_AUTH_PROVIDER`** in the container (optional `docker run -e PI_AUTH_PROVIDER=...`); most users can rely on the default.

## Build the image

**Windows:** run:

```cmd
build.bat
```

The image is tagged **`pi-agent`**.

## Run

**Project-local pi state** (`%cd%\.pi` on the host unless you set `PI_DOTPI`):

```cmd
run.bat
```

**Shared pi state** (`agent.bat` defaults to `%USERPROFILE%\.pi-global` when `PI_DOTPI` is unset; override anytime):

```cmd
agent.bat
```

### Environment variables (host)

| Variable | Purpose |
|----------|---------|
| `CURSOR_API_KEY_FILE` | Path to the API key file (default: `%USERPROFILE%\.cursor-api-key`) |
| `PI_DOTPI` | Host directory mounted to `/home/sandbox/.pi` (`run.bat`: default `%cd%\.pi`; `agent.bat`: default `%USERPROFILE%\.pi-global`) |

Runtime flags include `--security-opt=no-new-privileges` and `--cap-drop=ALL`. If a future tool breaks, try narrowing `cap-drop` or add a selective `--cap-add` while testing.

### Optional: provider override (inside container)

Set `PI_AUTH_PROVIDER` if your key is for a different built-in provider id than `opencode` (advanced).

## Technical details

- **Base image**: `node:22-bookworm-slim`
- User **`sandbox`** (uid/gid 1000) runs `pi`; the entrypoint starts as root only long enough to validate the secret, merge `auth.json`, fix ownership under `/home/sandbox/.pi`, and drop privileges.
- **Cursor CLI** binaries are installed under `/usr/local/bin` so they are available on `PATH` for the unprivileged user.
- **Global** install: `@earendil-works/pi-coding-agent` (see `Dockerfile`).

### Migrating from older scripts

Older `run.bat` mounted `%cd%\.pi` to `/root/.pi` and passed `-e CURSOR_API_KEY`. The layout under `.pi` is unchanged (host `%cd%\.pi\agent\` still maps to `/home/sandbox/.pi/agent/`). Put your key in a file and drop `-e`; use the new mount target `/home/sandbox/.pi`.
