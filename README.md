# Pi Docker Environment

This repository contains the scripts and the `Dockerfile` necessary to securely run [pi](https://pi.dev/) inside an isolated Docker container.

The environment is configured to map two key directories from your host system into the container:
1. **The source directory**: The project on which `pi` needs to work.
2. **The `.pi` directory**: The configuration, skills, and extensions for `pi`.

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) installed and running on your system.

## 1. Build the Docker Image

Before starting the environment, you must build the Docker image (only needed the first time or when you want to update the `pi` version).

**On Windows:**
Run the provided batch script:

```cmd
build.bat
```

This process will download a lightweight Node.js image, install essential dependencies (`git`, `curl`, `jq`), and globally install the latest version of `@mariozechner/pi-coding-agent`.

## 2. Run Pi

You can start the environment using the provided run script.

```cmd
run.bat
```

## Technical Details

- **Base Image**: `node:22-bookworm-slim`
- The host sources are mounted to `/workspace` (which is the container's `WORKDIR`).
- The host's `.pi` configuration folder is mounted to `/root/.pi` inside the container, ensuring your preferences, past chats, and extensions are persistent across runs.
- The container is started with the `-it` flags to support the interactive terminal interface (TUI) and `--rm` so it is automatically destroyed on exit, keeping your Docker system clean.
