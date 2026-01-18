# Docker Setup

Complete Docker configuration for Cloud CLI with multi-provider support (Claude Code, Cursor CLI, Codex) and AWS Bedrock integration.

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    Docker Container (Isolated)                     │
│                                                                    │
│  ┌─────────────────┐                                               │
│  │  Cloud CLI      │                                               │
│  │  (port 3001)    │                                               │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ├──► /root/.claude/  (Claude sessions)  ◄── volume      │
│           ├──► /root/.cursor/  (Cursor sessions)  ◄── volume      │
│           ├──► /root/.codex/   (Codex sessions)   ◄── volume      │
│           │                                                        │
│           └──► /projects/      (all projects)     ◄── volume      │
│                   ├── my-app/                                      │
│                   ├── backend/                                     │
│                   └── frontend/                                    │
│                                                                    │
│  Pre-installed CLI tools:                                          │
│  - Claude CLI (@anthropic-ai/claude-code)                         │
│  - Cursor CLI (cursor.com)                                        │
│  - Codex CLI (@openai/codex)                                      │
│  - TaskMaster AI (task-master-ai)                                 │
│  - AWS CLI v2                                                     │
│  - Git                                                            │
│                                                                    │
│  AWS Credentials ◄── env vars                                      │
└────────────────────────────────────────────────────────────────────┘
```

## Features

- **Maximum isolation** — All providers only see `/projects`
- **Multi-provider support** — Claude, Cursor, and Codex sessions persist in separate volumes
- **AWS Bedrock** — No Anthropic API keys needed
- **Multiple projects** — Create and manage via UI
- **Git clone built-in** — Clone repositories directly from UI
- **Cloudflare Tunnel** — Secure remote access included
- **TaskMaster AI** — Pre-installed for task management

## Quick Start

### 1. Configure Environment

```bash
# Copy example configuration
cp .env.example .env

# Edit .env with your settings
nano .env
```

Required settings in `.env`:

```bash
# AWS Bedrock Configuration
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=eu-central-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key

# Project workspace (required for Docker)
WORKSPACES_ROOT=/projects
```

### 2. Build and Launch

```bash
# Build image
docker-compose build

# Start container
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 3. Open UI

```
http://localhost:3007
```

> **Note**: Default port is 3007 (mapped to internal 3001). See [Changing Port](#change-port) to customize.

## Working with Projects

### Create New Project via UI

1. Open UI → **"Create New Project"**
2. Select **"New Workspace"**
3. Enter path: `/projects/my-app`
4. Optional: add GitHub URL to clone
5. Click **"Create"**

Project will be created inside Docker volume `projects-data`.

### Import Existing Project

```bash
# Copy code into container
docker cp ./existing-project claude-code-ui:/projects/my-imported-project

# Then in UI: "Create New Project" → "Existing Workspace" → /projects/my-imported-project
```

### Export Project from Container

```bash
# Copy project to host
docker cp claude-code-ui:/projects/my-app ./my-app
```

## Volume Configuration

The docker-compose.yml defines four persistent volumes:

| Volume | Container Path | Purpose |
|--------|----------------|---------|
| `claude-sessions` | `/root/.claude` | Claude Code session history |
| `cursor-sessions` | `/root/.cursor` | Cursor CLI session history |
| `codex-sessions` | `/root/.codex` | Codex session history |
| `projects-data` | `/projects` | All project files |

## Model Configuration

Default models (EU Bedrock inference profiles):

```bash
# In .env or docker-compose.yml environment section
ANTHROPIC_DEFAULT_SONNET_MODEL=eu.anthropic.claude-sonnet-4-5-20250929-v1:0
ANTHROPIC_DEFAULT_OPUS_MODEL=eu.anthropic.claude-opus-4-5-20251101-v1:0
ANTHROPIC_DEFAULT_HAIKU_MODEL=eu.anthropic.claude-haiku-4-5-20251001-v1:0
```

## Cloudflare Tunnel Setup

The docker-compose.yml includes a Cloudflare Tunnel service for secure remote access.

### Configure Tunnel

1. **Create tunnel at Cloudflare:**
   - Visit [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
   - Create a new tunnel and get credentials

2. **Configure credentials:**
   ```bash
   # Copy example file
   cp cloudflared/credentials.json.example cloudflared/credentials.json

   # Edit with your tunnel credentials
   nano cloudflared/credentials.json
   ```

3. **Update config:**
   ```yaml
   # cloudflared/config.yml
   tunnel: your-tunnel-id
   credentials-file: /etc/cloudflared/credentials.json

   ingress:
     - hostname: your-domain.com
       service: http://claude-code-ui:3001
     - service: http_status:404
   ```

4. **Restart containers:**
   ```bash
   docker-compose up -d
   ```

## Verification

### Check AWS CLI

```bash
docker-compose exec claude-code-ui aws --version
docker-compose exec claude-code-ui aws bedrock list-foundation-models --region eu-central-1
```

### Check Installed CLIs

```bash
# Claude CLI
docker-compose exec claude-code-ui claude --version

# Cursor CLI
docker-compose exec claude-code-ui cursor --version

# Codex CLI
docker-compose exec claude-code-ui codex --version
```

### Check Volumes

```bash
# List volumes
docker volume ls | grep ccui

# Inspect volume
docker volume inspect ccui_projects-data
```

### Test Project Creation

1. Open http://localhost:3007
2. "Create New Project" → "New Workspace"
3. Path: `/projects/test-app`
4. Verify project appears in list
5. Start a session and ask AI to create a file
6. Verify file was created:

```bash
docker-compose exec claude-code-ui ls -la /projects/test-app
```

## Volume Management

### Backup Projects

```bash
# Create backup
docker run --rm \
  -v ccui_projects-data:/projects \
  -v $(pwd):/backup \
  alpine tar czf /backup/projects-backup.tar.gz /projects
```

### Backup All Sessions

```bash
# Backup all session data
docker run --rm \
  -v ccui_claude-sessions:/claude \
  -v ccui_cursor-sessions:/cursor \
  -v ccui_codex-sessions:/codex \
  -v $(pwd):/backup \
  alpine sh -c "tar czf /backup/sessions-backup.tar.gz /claude /cursor /codex"
```

### Restore from Backup

```bash
# Restore projects
docker run --rm \
  -v ccui_projects-data:/projects \
  -v $(pwd):/backup \
  alpine sh -c "cd / && tar xzf /backup/projects-backup.tar.gz"
```

### Clean Volumes

```bash
# Stop containers
docker-compose down

# Remove volumes (WARNING: deletes all projects and sessions!)
docker volume rm ccui_projects-data ccui_claude-sessions ccui_cursor-sessions ccui_codex-sessions
```

## Alternative: AWS Profile

If you prefer using AWS Profile instead of credentials in `.env`:

### 1. Uncomment in `docker-compose.yml`:

```yaml
volumes:
  - ~/.aws:/root/.aws:ro
```

### 2. Set in `.env`:

```bash
AWS_PROFILE=default
```

## Additional Configuration

### Change Port

In `docker-compose.yml`:

```yaml
ports:
  - "8080:3001"  # Change from 3007 to 8080
```

### Add Additional Tools

In `Dockerfile` before `WORKDIR /app`:

```dockerfile
# Install additional tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild:

```bash
docker-compose build --no-cache
```

## Useful Commands

```bash
# Enter container shell
docker-compose exec claude-code-ui bash

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f claude-code-ui

# Stop all services
docker-compose down

# Full cleanup (including volumes)
docker-compose down -v

# Rebuild without cache
docker-compose build --no-cache

# Restart specific service
docker-compose restart claude-code-ui
```

## Troubleshooting

### Claude not connecting to Bedrock

```bash
# Check environment variables
docker-compose exec claude-code-ui env | grep AWS

# Check Bedrock access
docker-compose exec claude-code-ui aws bedrock list-foundation-models --region eu-central-1
```

### Project not appearing in UI

```bash
# Check project exists
docker-compose exec claude-code-ui ls -la /projects

# Restart container
docker-compose restart claude-code-ui
```

### Permission denied when creating project

Ensure `WORKSPACES_ROOT=/projects` is set in `.env` or `docker-compose.yml` environment section.

### Container fails to start

```bash
# Check for build errors
docker-compose build

# Check container logs
docker-compose logs claude-code-ui

# Check if port is already in use
lsof -i :3007
```

### Cloudflare Tunnel not working

```bash
# Check tunnel logs
docker-compose logs cloudflared

# Verify credentials file exists
ls -la cloudflared/credentials.json

# Verify config file
cat cloudflared/config.yml
```

## Limitations

- All providers work **only** with projects in `/projects`
- No access to host filesystem (by design for security)
- AWS credentials need manual update when expired
- Cursor CLI requires projects to be initialized in the container
