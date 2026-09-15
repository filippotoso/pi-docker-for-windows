FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies for pi / AI coding agent workflows
RUN apt-get update && apt-get install -y --no-install-recommends \
    # VCS / transfer
    git \
    openssh-client \
    curl \
    wget \
    rsync \
    # Archive / compression (tar/gzip already in slim; keep extras agents use)
    zip \
    unzip \
    bzip2 \
    xz-utils \
    zstd \
    # Search / filesystem
    ripgrep \
    fd-find \
    tree \
    file \
    # Text / data
    jq \
    gawk \
    patch \
    less \
    gettext-base \
    # Process / system
    psmisc \
    lsof \
    time \
    # Network diagnostics
    iproute2 \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    # Editors / DB
    nano \
    vim-tiny \
    sqlite3 \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Apt / PHP / MS SQL repo setup
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
    && rm -rf \
        /var/lib/apt/lists/* \
        /var/cache/apt/archives/* \
        /tmp/pear \
        /tmp/pear-* \
        /usr/share/doc/* \
        /usr/share/man/* \
        /usr/share/info/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /tmp/*

# Install llama.cpp server (CPU prebuilt) for pi /llama router support.
# Pin with --build-arg LLAMA_CPP_VERSION=bXXXX (see ggml-org/llama.cpp releases).
ARG LLAMA_CPP_VERSION=b10809
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) LLAMA_ARCH=x64 ;; \
      arm64) LLAMA_ARCH=arm64 ;; \
      *) echo "Unsupported architecture for llama.cpp: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    apt-get update && apt-get install -y --no-install-recommends libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && curl -fsSL "https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_CPP_VERSION}/llama-${LLAMA_CPP_VERSION}-bin-ubuntu-${LLAMA_ARCH}.tar.gz" \
        -o /tmp/llama.cpp.tar.gz \
    && mkdir -p /opt/llama.cpp \
    && tar -xzf /tmp/llama.cpp.tar.gz -C /opt/llama.cpp --strip-components=1 \
    && rm -f /tmp/llama.cpp.tar.gz \
    # Keep runtime binaries + shared libs; drop extra CLI tools / examples.
    && find /opt/llama.cpp -mindepth 1 -maxdepth 1 \
         ! -name 'llama-server' \
         ! -name 'llama-cli' \
         ! -name 'lib*.so*' \
         -exec rm -rf {} + \
    && ln -sf /opt/llama.cpp/llama-server /usr/local/bin/llama-server \
    && ln -sf /opt/llama.cpp/llama-cli /usr/local/bin/llama-cli \
    && mkdir -p /root/models \
    && LD_LIBRARY_PATH=/opt/llama.cpp llama-server --version
ENV LLAMA_CPP_HOME=/opt/llama.cpp
ENV LD_LIBRARY_PATH=/opt/llama.cpp
ENV LLAMA_BASE_URL=http://127.0.0.1:8080

RUN pip install --no-cache-dir --break-system-packages uv pytest graphifyy \
    && graphify install --platform pi \
    && rm -rf /root/.cache/pip /tmp/*

# Invalidate the cache by adding a parameter that always changes on build (passed with --build-arg CACHEBUST=$(date +%s))
ARG CACHEBUST=1

# Install Cursor CLI and make it reachable system-wide
RUN curl https://cursor.com/install -fsS | bash \
    && rm -rf /tmp/* /root/.cache/cursor-compile-cache

# Install Bun (required by upstream gstack builds / browser helpers)
RUN curl -fsSL https://bun.sh/install | bash \
    && rm -rf /tmp/* /root/.bun/install/cache
ENV BUN_INSTALL="/root/.bun"
ENV PATH="/root/.bun/bin:/root/.local/bin:${PATH}"

# Git HTTPS to github.com over HTTP/2 can 401 on some networks; force HTTP/1.1
# so pi-gstack clone/sync and Docker builds stay reliable.
RUN git config --system http.version HTTP/1.1 \
    && git config --system --add safe.directory '*'

# Install pi globally
RUN npm install -g @earendil-works/pi-coding-agent \
    && npm cache clean --force \
    && rm -rf /tmp/* /root/.npm/_cacache

# Install pi packages outside the host bind of /root/.pi and /opt/packages
# (agent.bat mounts //d/projects/.pi/.pi and .../.pi/packages). Point
# settings.json packages at these paths. `pi install npm:...` would land under
# ~/.pi and be masked at runtime.
# pi-gstack adapts https://github.com/garrytan/gstack skills for pi.dev.
RUN mkdir -p /opt/pi-packages/pi-gstack /opt/pi-packages/pi-subagents \
    && npm pack pi-gstack --pack-destination /tmp \
    && tar -xzf /tmp/pi-gstack-*.tgz -C /opt/pi-packages/pi-gstack --strip-components=1 \
    && rm -f /tmp/pi-gstack-*.tgz \
    && npm pack pi-subagents --pack-destination /tmp \
    && tar -xzf /tmp/pi-subagents-*.tgz -C /opt/pi-packages/pi-subagents --strip-components=1 \
    && rm -f /tmp/pi-subagents-*.tgz \
    && npm install --omit=dev --prefix /opt/pi-packages/pi-subagents \
    && npm cache clean --force \
    && rm -rf /tmp/* /root/.npm/_cacache

# Pre-clone + compile gstack under /opt/gstack-pi (Linux FS; Bun cannot write
# ELF binaries on the Windows-mounted ~/.pi). settings.json cannot set this —
# only GSTACK_PI_HOME / default ~/.pi/agent/gstack-pi.
ENV GSTACK_PI_HOME=/opt/gstack-pi
RUN mkdir -p /opt/gstack-pi \
    && git -c http.version=HTTP/1.1 clone --depth 1 https://github.com/garrytan/gstack.git /opt/gstack-pi/repo \
    && cd /opt/gstack-pi/repo \
    && bun install --frozen-lockfile \
    && bun run build \
    && bun x playwright install --with-deps chromium \
    && COMMIT="$(git rev-parse HEAD)" \
    && printf '%s\n' \
        '{' \
        "  \"adapterVersion\": \"0.2.0\"," \
        "  \"gstackCommit\": \"${COMMIT}\"," \
        "  \"bunPath\": \"/root/.bun/bin/bun\"," \
        "  \"builtAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," \
        '  "ok": true' \
        '}' > /opt/gstack-pi/.build.json \
    && mkdir -p /root/.pi/agent/bin \
    && ln -sfn /root/.bun/bin/bun /root/.pi/agent/bin/bun \
    && node --input-type=module -e "\
import { generatePiSkills, getPaths } from '/opt/pi-packages/pi-gstack/extensions/gstack.js';\
const paths = getPaths();\
const result = await generatePiSkills(paths, { prefix: true });\
console.log('Generated', result.count, 'gstack skills into', paths.skillsDir);\
" \
    # Keep only Laravel/Vue web skills; drop iOS, OpenClaw, fixtures, gbrain, etc.
    && cd /opt/gstack-pi/skills \
    && KEEP='gstack gstack-autoplan gstack-browse gstack-careful gstack-design-consultation gstack-design-html gstack-design-review gstack-design-shotgun gstack-investigate gstack-office-hours gstack-plan-ceo-review gstack-plan-design-review gstack-plan-eng-review gstack-plan-tune gstack-qa gstack-qa-only gstack-review' \
    && for skill in *; do \
         case " ${KEEP} " in \
           *" ${skill} "*) ;; \
           *) rm -rf "${skill}" ;; \
         esac; \
       done \
    && echo "Kept $(ls -1 | wc -l) gstack skills:" \
    && ls -1 \
    # Shrink image: drop build-only deps/caches and unused gstack sources.
    # Playwright headless uses chromium_headless_shell; full chromium is for headed/UI.
    && cd /opt/gstack-pi/repo \
    && rm -rf node_modules \
    && bun install --frozen-lockfile --production \
    && rm -rf \
        /root/.bun/install/cache \
        /root/.cache/ms-playwright/chromium-* \
        test \
        ios-qa \
        canary \
        benchmark \
        contrib \
        .agents \
        .cursor \
        .opencode \
        .kiro \
        .slate \
        .factory \
        .openclaw \
        .hermes \
        .gbrain \
        browse/test \
        design/test \
        make-pdf/test \
    && find /opt/gstack-pi/repo -depth -type d -name '__tests__' -exec rm -rf {} + \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/*

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
