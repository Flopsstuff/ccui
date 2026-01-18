FROM node:20-slim

# Prevent apt from asking interactive questions
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for node-pty, Claude CLI and AWS CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    git \
    curl \
    unzip \
    ca-certificates \
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

# Install Cursor CLI and add to PATH
ENV PATH="/root/.local/bin:${PATH}"
RUN curl https://cursor.com/install -fsS | bash

# install codex cli
RUN npm install -g @openai/codex

# install task-master-ai
RUN npm install -g task-master-ai

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build frontend
RUN npm run build

# Create directories for sessions and projects
RUN mkdir -p /root/.claude/projects /root/.cursor /root/.codex /projects

# Expose port
EXPOSE 3001

# Start server
CMD ["npm", "start"]
