FROM node:20-slim

# Install dependencies for node-pty, Claude CLI and AWS CLI
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (for Bedrock)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Claude CLI globally
RUN npm install -g @anthropic-ai/claude-code

# install cursor cli
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
RUN mkdir -p /root/.claude/projects /projects

# Expose port
EXPOSE 3001

# Start server
CMD ["npm", "start"]
