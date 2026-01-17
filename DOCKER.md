# Docker Setup for Claude Code UI

Fully isolated Docker configuration with AWS Bedrock support.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│              Docker Container (Isolated)              │
│                                                       │
│  ┌────────────────┐                                   │
│  │ Claude Code UI │                                   │
│  │   (port 3001)  │                                   │
│  └────────┬───────┘                                   │
│           │                                           │
│           ├──► /root/.claude/  (sessions) ◄── volume │
│           │                                           │
│           └──► /projects/       (all projects) ◄──vol│
│                   ├── my-app/                         │
│                   ├── backend/                        │
│                   └── frontend/                       │
│                                                       │
│  AWS Credentials ◄── env vars                         │
└───────────────────────────────────────────────────────┘
```

## Features

✅ **Maximum isolation** — Claude only sees `/projects`
✅ **Persistence** — projects and sessions saved in volumes
✅ **AWS Bedrock** — no Anthropic API keys needed
✅ **Multiple projects** — create via UI
✅ **Git clone built-in** — clone repositories from UI

---

## Quick Start

### 1. Configure AWS Credentials

```bash
# Copy .env.example → .env
cp .env.example .env

# Edit .env
nano .env
```

Uncomment and fill in `.env`:

```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
WORKSPACES_ROOT=/projects
```

### 2. Launch

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
http://localhost:3001
```

---

## Working with Projects

### Create new project via UI

1. Open UI → **"Create New Project"**
2. Select **"New Workspace"**
3. Enter path: `/projects/my-app`
4. Optional: add GitHub URL to clone
5. Click **"Create"**

Project will be created inside Docker volume `projects-data`.

### Import existing project

```bash
# Copy code into container
docker cp ./existing-project claude-code-ui:/projects/my-imported-project

# Then in UI: "Create New Project" → "Existing Workspace" → /projects/my-imported-project
```

### Export project from container

```bash
# Copy project to host
docker cp claude-code-ui:/projects/my-app ./my-app
```

---

## Verification

### 1. Check AWS CLI

```bash
docker-compose exec claude-code-ui aws --version
docker-compose exec claude-code-ui aws bedrock list-foundation-models --region us-east-1
```

### 2. Check volumes

```bash
# List volumes
docker volume ls | grep claude

# Inspect volume
docker volume inspect claudecodeui_projects-data
```

### 3. Create test project

- Open http://localhost:3001
- "Create New Project" → "New Workspace"
- Path: `/projects/test-app`
- Verify project appears in list

### 4. Start Claude Code session

- Select project → "New Session"
- Ask Claude to create file: `test.txt`
- Verify file was created:

```bash
docker-compose exec claude-code-ui ls -la /projects/test-app
```

---

## Volume Management

### Backup projects

```bash
# Create backup
docker run --rm \
  -v claudecodeui_projects-data:/projects \
  -v $(pwd):/backup \
  alpine tar czf /backup/projects-backup.tar.gz /projects
```

### Restore from backup

```bash
# Restore backup
docker run --rm \
  -v claudecodeui_projects-data:/projects \
  -v $(pwd):/backup \
  alpine sh -c "cd / && tar xzf /backup/projects-backup.tar.gz"
```

### Clean volumes

```bash
# Stop containers
docker-compose down

# Remove volumes (WARNING: deletes all projects!)
docker volume rm claudecodeui_projects-data claudecodeui_claude-sessions
```

---

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

---

## Troubleshooting

### Issue: Claude not connecting to Bedrock

```bash
# Check environment variables
docker-compose exec claude-code-ui env | grep AWS

# Check Bedrock access
docker-compose exec claude-code-ui aws bedrock list-foundation-models --region us-east-1
```

### Issue: Project not appearing in UI

```bash
# Check project exists
docker-compose exec claude-code-ui ls -la /projects

# Restart container
docker-compose restart
```

### Issue: Permission denied when creating project

Ensure `WORKSPACES_ROOT=/projects` is set in `.env` or `docker-compose.yml`.

---

## Useful Commands

```bash
# Enter container
docker-compose exec claude-code-ui bash

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Full cleanup (including volumes)
docker-compose down -v

# Rebuild without cache
docker-compose build --no-cache
```

---

## Limitations

- Claude works **only** with projects in `/projects`
- No access to host tools
- AWS credentials need manual update when expired

---

## Additional Configuration

### Change port

In `docker-compose.yml`:

```yaml
ports:
  - "8080:3001"  # Change from 3001 to 8080
```

### Add additional tools

In `Dockerfile` before `WORKDIR /app`:

```dockerfile
# Install additional tools
RUN apt-get update && apt-get install -y \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild:

```bash
docker-compose build
```
