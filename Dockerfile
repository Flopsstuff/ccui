FROM node:20-slim

# Prevent apt from asking interactive questions
ENV DEBIAN_FRONTEND=noninteractive

# Install build deps (node-pty, AWS CLI install) plus a small set of
# shell utilities so the terminal plugin gives a usable interactive shell.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    git \
    curl \
    unzip \
    ca-certificates \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    iproute2 \
    procps \
    less \
    vim-tiny \
    jq \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (for Bedrock) - detect architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
        AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    fi && \
    curl -fsSL "$AWS_URL" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Claude CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install Cursor CLI to /usr/local so /root can be mounted as a single named
# volume without hiding the binary. The installer:
#   - extracts the package to /root/.local/share/cursor-agent/versions/<ver>/
#   - creates symlinks /root/.local/bin/{agent,cursor-agent} -> the version dir
# Move the whole share tree to /usr/local/share and recreate the symlinks
# pointing at the new location, otherwise they end up dangling.
RUN curl https://cursor.com/install -fsS | bash \
    && mkdir -p /usr/local/share \
    && mv /root/.local/share/cursor-agent /usr/local/share/cursor-agent \
    && CURSOR_VERSION_DIR=$(find /usr/local/share/cursor-agent/versions -mindepth 1 -maxdepth 1 -type d | head -1) \
    && ln -sf "$CURSOR_VERSION_DIR/cursor-agent" /usr/local/bin/cursor-agent \
    && ln -sf "$CURSOR_VERSION_DIR/cursor-agent" /usr/local/bin/agent \
    && rm -rf /root/.local

# install codex cli
RUN npm install -g @openai/codex

# install gemini cli
RUN npm install -g @google/gemini-cli

# install task-master-ai
RUN npm install -g task-master-ai

# install GitHub CLI (gh) from the official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files and scripts needed for postinstall
COPY package*.json ./
COPY scripts/ scripts/

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build frontend
RUN npm run build

# Create projects mount target. /root/.{claude,codex,cursor,gemini,cloudcli} are
# created on first run by each CLI / the server itself, and persist via the
# home-data volume mounted at /root.
RUN mkdir -p /projects

# Expose port
EXPOSE 3001

# Entrypoint applies env-driven CLI configuration (Gemini API key, etc.) before exec'ing the server
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Start server
CMD ["npm", "start"]
