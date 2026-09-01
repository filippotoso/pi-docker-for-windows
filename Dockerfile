FROM node:22-bookworm-slim

# Install common dependencies for pi / AI coding agent workflows
RUN apt-get update && apt-get install -y --no-install-recommends \
    # VCS / transfer
    git \
    openssh-client \
    curl \
    wget \
    rsync \
    # Archive / compression
    zip \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    # Search / filesystem
    ripgrep \
    fd-find \
    tree \
    file \
    findutils \
    # Text / data
    jq \
    gawk \
    sed \
    grep \
    patch \
    diffutils \
    less \
    gettext-base \
    # Process / system
    procps \
    psmisc \
    lsof \
    time \
    # Network diagnostics
    iproute2 \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    openssl \
    # Editors / DB
    nano \
    vim-tiny \
    sqlite3 \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Apt / PHP / MS SQL repo setup
    apt-transport-https \
    lsb-release \
    ca-certificates \
    gnupg2 \
    bubblewrap \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
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
    php8.4-soap \
    php8.4-dev \
    php-pear \
    unixodbc-dev \
    build-essential \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && pecl install -o -f sqlsrv-5.13.1 pdo_sqlsrv-5.13.1 \
    && echo "extension=sqlsrv.so" > /etc/php/8.4/mods-available/sqlsrv.ini \
    && echo "extension=pdo_sqlsrv.so" > /etc/php/8.4/mods-available/pdo_sqlsrv.ini \
    && phpenmod -v 8.4 sqlsrv pdo_sqlsrv \
    && apt-get purge -y --auto-remove php8.4-dev php-pear unixodbc-dev build-essential \
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pip install --no-cache-dir --break-system-packages uv pytest graphifyy \
    && graphify install --platform pi

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

# Normalize --model args before invoking pi
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Pass model via env var (no default):
#   docker run --rm -it -e MODEL=cursor/claude-4.6-sonnet-medium pi-agent
ENTRYPOINT ["docker-entrypoint.sh"]
