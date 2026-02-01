# Getting Started

This guide will help you get AI Code UI up and running on your local machine.

## Prerequisites

Before you begin, ensure you have:

- **Node.js** 20.x or later ([download](https://nodejs.org/))
- **npm** 10.x or later (comes with Node.js)
- **Git** installed and configured

## Installation Methods

### Method 1: Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/Flopsstuff/ccui.git
cd ccui

# Build and run with Docker Compose
docker-compose up --build

# Or run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down
```

### Method 2: Clone and Run

```bash
# Clone the repository
git clone https://github.com/Flopsstuff/ccui.git
cd ccui

# Install dependencies
npm ci

# Start development server
npm run dev
```

### Method 3: npm Package

For the official npm package, visit the main repository:

**GitHub:** [https://github.com/siteboon/claudecodeui](https://github.com/siteboon/claudecodeui)

```bash
# Install globally
npm install -g @siteboon/claude-code-ui

# Start the application
cloudcli start
# or
claude-code-ui start

# Or run without installing
npx @siteboon/claude-code-ui
```

## Configuration

### 1. Create Environment File

Copy the example environment file:

```bash
cp .env.example .env
```

### 2. Configure Essential Variables

Edit `.env` with your settings:

```bash
# Server ports
PORT=3001              # Backend API server
VITE_PORT=5173         # Frontend dev server (development only)

# Database
DATABASE_PATH=./server/database/auth.db

# AI Provider (choose one or more)
# For Claude via Bedrock:
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Or for direct Anthropic API:
ANTHROPIC_API_KEY=your-api-key
```

### 3. Optional: Enable Platform Mode

For single-user deployments (no login required):

```bash
VITE_IS_PLATFORM=true
```

## First Run

### Development Mode

```bash
npm run dev
```

This starts:
- Backend server on http://localhost:3001
- Vite dev server on http://localhost:5173 (with hot reload)

Open http://localhost:5173 in your browser.

### Production Mode

```bash
# Build frontend
npm run build

# Start server
npm start
```

Open http://localhost:3001 in your browser.

## Initial Setup

### 1. Create Account

On first visit, you'll see the login page. Click "Register" to create an account.

### 2. Complete Onboarding

After registration, the onboarding wizard will guide you through:

- Setting your Git name and email
- Configuring your preferred AI provider
- Optionally adding API keys

### 3. Add Your First Project

Projects are discovered automatically from:
- `~/.claude/projects/` - Claude Code sessions
- `~/.cursor/chats/` - Cursor sessions
- `~/.codex/sessions/` - Codex sessions

Or add projects manually via the sidebar "+" button.

## CLI Commands

If installed globally, you can use these commands:

```bash
# Start the application
cloudcli start

# Check status
cloudcli status

# Update to latest version
cloudcli update

# Show help
cloudcli help

# Show version
cloudcli version
```

## Verifying Installation

### Check Backend Health

```bash
curl http://localhost:3001/api/health
```

Expected response:
```json
{"status": "ok"}
```

### Check WebSocket Connection

Open browser DevTools → Network → WS tab and verify connections to:
- `/ws` - Chat WebSocket
- `/shell` - Terminal WebSocket

## Troubleshooting

### Port Already in Use

```bash
# Find and kill process on port 3001
lsof -i :3001
kill -9 <PID>
```

### Database Errors

```bash
# Remove and recreate database
rm server/database/auth.db
npm start
```

### Node.js Version Issues

```bash
# Check version
node --version

# Use nvm to switch versions
nvm install 20
nvm use 20
```

### Permission Errors (Linux/Mac)

```bash
# Fix npm global permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

## Next Steps

- [Configuration](./configuration.md) - Full configuration reference
- [Architecture](./architecture.md) - Understand the system design
- [AI Providers](./providers.md) - Configure Claude, Cursor, or Codex
