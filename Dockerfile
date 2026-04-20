FROM node:22-bookworm-slim

# Installiamo dipendenze comuni che potrebbero servire a pi o allo sviluppo (git, curl, ecc.)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages uv

# Installiamo pi globalmente
RUN npm install -g @mariozechner/pi-coding-agent

# Impostiamo la directory di lavoro
WORKDIR /workspace

# Il comando di default all'avvio del container
ENTRYPOINT ["pi"]
