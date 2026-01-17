# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cloud CLI (Claude Code UI)** is a full-stack web application providing a unified interface for AI coding assistants: Claude Code, Cursor CLI, and OpenAI Codex. It features a React frontend, Node.js/Express backend with WebSocket communication, and direct SDK integrations with AI providers.

**Tech Stack:**
- Backend: Node.js (ES modules), Express.js, WebSocket (ws)
- Frontend: React 18, Vite 7, Tailwind CSS
- Database: SQLite (better-sqlite3)
- AI SDKs: Claude Agent SDK (v0.2.11), Codex SDK (v0.75.0)
- Terminal: node-pty, xterm.js
- Code Editor: CodeMirror 6

## Common Commands

### Development

```bash
# Start development (runs server + frontend with hot reload)
npm run dev

# Server runs on http://localhost:3001
# Vite dev server runs on http://localhost:5173 (proxies API to :3001)
```

### Production

```bash
# Build and start production server
npm start

# Or separately:
npm run build   # Builds frontend to dist/
npm run server  # Starts Express server serving dist/
```

### Package Management

```bash
# Install dependencies (use ci for clean install)
npm ci

# Run as CLI without installing
npx @siteboon/claude-code-ui

# Global installation
npm install -g @siteboon/claude-code-ui
cloudcli  # or claude-code-ui
```

### Docker

```bash
# Build and run with docker-compose
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f
```

## Architecture

### Backend Structure (`/server`)

**Main Entry Point:** `server/index.js` (1748 lines)
- Express server with integrated WebSocket server
- File system watcher (Chokidar) monitoring `~/.claude/projects/`
- Routes: auth, projects, git, mcp, cursor, codex, taskmaster, settings

**AI Provider Integrations:**
- `claude-sdk.js` - Direct SDK integration (in-process), tool approval system
- `cursor-cli.js` - Child process wrapper for cursor-agent CLI
- `openai-codex.js` - Direct Codex SDK integration

**Key Services:**
- `projects.js` (1300+ lines) - Multi-source project discovery (Claude/Cursor/Codex)
- `database/db.js` - SQLite schema and operations (users, api_keys, credentials)
- `middleware/auth.js` - JWT authentication with platform mode support

**WebSocket Endpoints:**
- `/ws` - Chat messages and AI interactions
- `/shell` - Interactive terminal (PTY sessions)

### Frontend Structure (`/src`)

**Main App:** `src/App.jsx` (975 lines)
- Context-based state management (Auth, WebSocket, Theme, TaskMaster)
- Session protection system to prevent data loss during active conversations
- Router with `/` home and `/session/:sessionId` routes

**Key Components:**
- `ChatInterface.jsx` (254KB) - Message display, streaming, tool approvals, token tracking
- `Sidebar.jsx` (67KB) - Project/session navigation with multi-provider grouping
- `FileTree.jsx` - Recursive directory tree with CodeMirror editor
- `GitPanel.jsx` (58KB) - Git operations (status, staging, commits, branches)
- `Shell.jsx` - xterm.js terminal with WebSocket PTY communication
- `Settings.jsx` (79KB) - Multi-tab settings panel

**Utilities:**
- `src/utils/api.js` - Authenticated fetch wrapper with 30+ endpoint methods
- `src/utils/websocket.js` - WebSocket hook with auto-reconnect

### Shared Code (`/shared`)

**Important:** `shared/modelConstants.js` is used by both frontend and backend. Keep in sync when adding new models.

## Project Discovery System

The backend aggregates projects from multiple sources:

1. **Claude Projects:** Scans `~/.claude/projects/` for JSONL files
2. **Cursor Projects:** Hash-based discovery (MD5 of project path → `~/.cursor/chats/{hash}/`)
3. **Codex Projects:** Scans `~/.codex/sessions/` for session metadata
4. **Manual Projects:** User-added projects stored in project-config.json

**Critical Limitation:** Cursor discovery requires knowing the project path first (cannot reverse-lookup from MD5 hash). This means Cursor-only projects won't appear unless manually added.

## WebSocket Communication

### Message Flow

```
Frontend → WebSocket → Backend → AI Provider → Stream Events → Frontend
```

### Key Message Types

**Chat WebSocket (`/ws`):**
```javascript
// Client → Server
{type: 'claude-command', command: 'start', options: {...}}
{type: 'cursor-command', command: 'start', options: {...}}
{type: 'codex-command', command: 'start', options: {...}}
{type: 'abort-session', sessionId, provider}
{type: 'claude-permission-response', requestId, allow}

// Server → Client
{type: 'claude-response', data: {...}}
{type: 'cursor-response', data: {...}}
{type: 'codex-response', data: {...}}
{type: 'projects-updated', projects: [...]}
```

**Shell WebSocket (`/shell`):**
```javascript
{type: 'init', projectPath, sessionId, provider}
{type: 'input', data}
{type: 'resize', cols, rows}
{type: 'output', data}  // Server → Client
```

## Tool Approval System (Claude)

Located in `server/claude-sdk.js`:

1. SDK calls `canUseTool(toolName)` before executing
2. Backend checks pending approvals registry
3. If not pre-approved, sends permission request via WebSocket
4. Frontend displays approval UI in ChatInterface
5. User decision sent back via `claude-permission-response`
6. Backend resolves promise and SDK continues
7. Timeout: 55 seconds (under SDK's 60s limit)

## Session Storage Formats

**Claude Sessions:**
- Location: `~/.claude/projects/{encoded-path}/{session-id}.jsonl`
- Format: JSONL (one JSON per line)

**Cursor Sessions:**
- Location: `~/.cursor/chats/{md5_of_path}/sessions/{session-id}/store.db`
- Format: SQLite database

**Codex Sessions:**
- Location: `~/.codex/sessions/{project-hash}/{session-id}.jsonl`
- Format: JSONL

## Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Server
PORT=3001              # Backend port
VITE_PORT=5173         # Frontend dev server port

# Claude CLI
CLAUDE_CLI_PATH=claude # Path to claude command
CONTEXT_WINDOW=160000  # Token limit

# Database
DATABASE_PATH=/path/to/auth.db

# Models (EU Bedrock inference profiles)
ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
ANTHROPIC_SMALL_FAST_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0'

# Platform Mode (single-user, bypasses JWT auth)
VITE_IS_PLATFORM=false

# AWS Bedrock (optional)
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

## Authentication

**JWT-based:**
- Tokens generated on login, stored in localStorage
- Never expire (consider adding expiration in auth.js)
- Attached as `Authorization: Bearer <token>` header

**Platform Mode:**
- Set `VITE_IS_PLATFORM=true` for single-user deployments
- Bypasses JWT, uses first database user for all requests

**API Key (optional):**
- Set `API_KEY` env variable to require `X-API-Key` header
- Used for external API access

## Database Schema

Located in `server/database/db.js`:

```sql
users (id, username, password_hash, git_name, git_email,
       has_completed_onboarding, created_at, last_login)

api_keys (id, user_id, key_name, api_key, created_at,
          last_used, is_active)

user_credentials (id, user_id, credential_name, credential_type,
                  credential_value, description, created_at, is_active)
```

**Migrations:** Add to `runMigrations()` function in db.js for schema changes.

## Adding a New AI Provider

Follow the pattern in `cursor-cli.js` or `openai-codex.js`:

1. Create `server/your-provider.js` with:
   - `startSession(options, wsWriter)` function
   - Event transformation to Claude-compatible format
   - Session tracking for abort capability

2. Add WebSocket message handler in `server/index.js`:
   ```javascript
   case 'your-provider-command':
     await startYourProviderSession(message.options, wsWriter);
     break;
   ```

3. Add frontend support:
   - Update `shared/modelConstants.js` with provider models
   - Add provider option in Settings.jsx
   - Update ChatInterface.jsx to handle provider-specific events

4. Add session discovery in `server/projects.js`:
   - Implement discovery logic (scan session storage)
   - Add to `fetchProjectsWithSessions()` aggregation

## Build Configuration

**Vite (`vite.config.js`):**
- Dev server proxies `/api`, `/ws`, `/shell` to backend
- Code splitting: vendor-react, vendor-codemirror, vendor-xterm
- Build output: `dist/` directory

**Tailwind (`tailwind.config.js`):**
- Dark mode: class-based strategy
- Custom design tokens using HSL CSS variables

## Known Issues & Technical Debt

1. **No automated tests** - Consider adding Jest for utilities, Supertest for API
2. **No TypeScript** - Plain JavaScript throughout
3. **JWT never expires** - Security concern, should add expiration
4. **Cursor project discovery limitation** - Cannot reverse-lookup from MD5 hash
5. **Credentials stored in plaintext** - Database encryption needed
6. **Session JSONL parsing** - Full file read on every request (no incremental parsing)
7. **LocalStorage limits** - Chat history may be truncated and lose data
8. **WebSocket reconnection** - Messages may be lost during reconnection

## Security Considerations

- File access restricted to project roots (path traversal prevention)
- SQL injection prevented via prepared statements
- bcrypt password hashing
- Session IDs sanitized (alphanumeric only)
- CORS enabled for all origins (consider restricting in production)

## Debugging

**Backend logs:** Check console output from `npm run server`

**Frontend logs:** Browser DevTools console

**WebSocket traffic:** Browser DevTools → Network → WS tab

**Database inspection:**
```bash
sqlite3 server/database/auth.db
.tables
.schema users
SELECT * FROM users;
```

**Session files:**
```bash
# Claude sessions
cat ~/.claude/projects/*/session-*.jsonl

# Cursor sessions
sqlite3 ~/.cursor/chats/{md5}/sessions/{id}/store.db
```

## Contributing

- Follow existing patterns (especially for provider integrations)
- Test locally with `npm run dev` before committing
- Run `npm run build` to verify production build
- Update this file if architecture changes significantly
