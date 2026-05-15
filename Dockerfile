FROM node:22-bookworm-slim

# Install common dependencies that might be needed for pi or development (git, curl, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gosu \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    apt-transport-https \
    lsb-release \
    ca-certificates \
    wget \
    gnupg2 \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    php8.4-cli \
    php8.4-curl \
    php8.4-mbstring \
    php8.4-xml \
    php8.4-zip \
    php8.4-sqlite3 \
    php8.4-mysql \
    php8.4-pgsql \
    php8.4-redis \
    php8.4-bcmath \
    php8.4-intl \
    php8.4-gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pip install --no-cache-dir --break-system-packages uv pytest

# Invalidate the cache by adding a parameter that always changes on build (passed with --build-arg CACHEBUST=$(date +%s))
ARG CACHEBUST=1

# Install Cursor CLI and copy binaries to a path usable by the unprivileged user
RUN curl https://cursor.com/install -fsS | bash \
    && install -d /usr/local/bin \
    && if [ -d /root/.local/bin ]; then cp -a /root/.local/bin/. /usr/local/bin/; fi
ENV PATH="/usr/local/bin:${PATH}"

# Install pi globally
RUN npm install -g @earendil-works/pi-coding-agent \
    && npm cache clean --force

# API keys: mount a host secret file to /run/secrets/cursor_api_key (see README).

RUN groupadd --gid 1000 sandbox \
    && useradd --uid 1000 --gid sandbox --home-dir /home/sandbox --shell /usr/sbin/nologin sandbox \
    && install -d -o sandbox -g sandbox /home/sandbox

COPY --chmod=755 entrypoint.sh /usr/local/bin/pi-entrypoint.sh

# Set the working directory
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/pi-entrypoint.sh"]
