FROM node:22-bookworm-slim

# Install common dependencies that might be needed for pi or development (git, curl, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Install Cursor CLI and make it reachable system-wide
RUN curl https://cursor.com/install -fsS | bash
ENV PATH="/root/.local/bin:${PATH}"

# Install pi globally
RUN npm install -g @earendil-works/pi-coding-agent \
    && npm cache clean --force

# Cursor API Key (passed at runtime: docker run -e CURSOR_API_KEY=your_key)
# ENV CURSOR_API_KEY=""

# Set the working directory
WORKDIR /workspace

# The default command when starting the container
ENTRYPOINT ["pi"]
