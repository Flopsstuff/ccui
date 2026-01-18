# Architecture Overview

This document describes the system architecture of AI Code UI.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (React)                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │   Chat   │ │   Files  │ │  Shell   │ │   Git    │           │
│  │Interface │ │  Browser │ │ Terminal │ │  Panel   │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                   │
│       └────────────┴─────┬──────┴────────────┘                   │
│                          │                                       │
│              ┌───────────┴───────────┐                          │
│              │  WebSocket / REST API  │                          │
└──────────────┴───────────┬───────────┴──────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────────┐
│                      Backend (Node.js/Express)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ WebSocket   │  │  REST API   │  │  File       │              │
│  │ Server      │  │  Routes     │  │  Watcher    │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                      │
│  ┌──────┴────────────────┴────────────────┴──────┐              │
│  │              Service Layer                     │              │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐         │              │
│  │  │ Claude  │ │ Cursor  │ │ Codex   │         │              │
│  │  │   SDK   │ │   CLI   │ │   SDK   │         │              │
│  │  └────┬────┘ └────┬────┘ └────┬────┘         │              │
│  └───────┼───────────┼───────────┼───────────────┘              │
│          │           │           │                               │
│  ┌───────┴───────────┴───────────┴───────────────┐              │
│  │              Database (SQLite)                 │              │
│  │  users │ api_keys │ user_credentials           │              │
│  └────────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────────┐
│                    External Services                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Anthropic  │  │   Cursor    │  │   OpenAI    │              │
│  │   (Claude)  │  │   Servers   │  │   (Codex)   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
/projects/ccui/
├── server/                 # Backend application
│   ├── index.js           # Main entry point (Express + WebSocket)
│   ├── cli.js             # CLI entry point
│   ├── claude-sdk.js      # Claude SDK integration
│   ├── cursor-cli.js      # Cursor CLI wrapper
│   ├── openai-codex.js    # Codex SDK integration
│   ├── projects.js        # Project discovery
│   ├── database/
│   │   └── db.js          # SQLite operations
│   ├── middleware/
│   │   └── auth.js        # JWT authentication
│   ├── routes/            # API route handlers
│   └── utils/             # Utility functions
│
├── src/                    # Frontend application
│   ├── main.jsx           # React entry point
│   ├── App.jsx            # Root component
│   ├── components/        # React components
│   ├── contexts/          # React contexts
│   ├── hooks/             # Custom hooks
│   └── utils/             # Frontend utilities
│
├── shared/                 # Shared code
│   └── modelConstants.js  # Model definitions
│
├── public/                 # Static assets
├── dist/                   # Built frontend (generated)
└── docs/                   # Documentation
```

## Backend Architecture

### Entry Points

1. **`server/index.js`** - Main server (1,748 lines)
   - Express HTTP server
   - WebSocket server for `/ws` (chat) and `/shell` (terminal)
   - File system watcher (Chokidar)
   - Route mounting

2. **`server/cli.js`** - CLI tool (327 lines)
   - Global npm command handling
   - Subcommands: start, status, update, help, version

### AI Provider Layer

Three provider integrations with unified interfaces:

| Provider | File | Integration Type |
|----------|------|------------------|
| Claude | `claude-sdk.js` | Direct SDK (in-process) |
| Cursor | `cursor-cli.js` | Child process (CLI wrapper) |
| Codex | `openai-codex.js` | Direct SDK (in-process) |

Each provider implements:
- `startSession(options, wsWriter)` - Begin AI conversation
- Session tracking for abort capability
- Event transformation to common format

### Project Discovery

`server/projects.js` aggregates projects from multiple sources:

```javascript
// Discovery sources
~/.claude/projects/{encoded-path}/          // Claude JSONL sessions
~/.cursor/chats/{md5_hash}/sessions/        // Cursor SQLite sessions
~/.codex/sessions/{project-hash}/           // Codex JSONL sessions
project-config.json                         // Manual projects
```

### Database Layer

SQLite with better-sqlite3 for:
- User authentication
- API key management
- Credential storage

See [Database](./database.md) for schema details.

### Route Handlers

Located in `server/routes/`:

| Route | File | Purpose |
|-------|------|---------|
| `/api/auth/*` | `auth.js` | Authentication |
| `/api/projects/*` | `projects.js` | Project/session management |
| `/api/git/*` | `git.js` | Git operations |
| `/api/cursor/*` | `cursor.js` | Cursor provider |
| `/api/codex/*` | `codex.js` | Codex provider |
| `/api/mcp/*` | `mcp.js` | MCP server management |
| `/api/settings/*` | `settings.js` | User settings |
| `/api/taskmaster/*` | `taskmaster.js` | TaskMaster integration |

## Frontend Architecture

### Component Hierarchy

```
App.jsx
├── AuthProvider
├── ThemeProvider
├── WebSocketProvider
├── TaskMasterProvider
└── Router
    ├── Onboarding
    ├── Login/Register
    └── MainLayout
        ├── Sidebar
        │   ├── ProjectList
        │   └── SessionList
        └── MainContent
            ├── ChatInterface
            ├── FileTree + CodeEditor
            ├── Shell
            ├── GitPanel
            └── TaskList
```

### Key Components

| Component | Lines | Responsibility |
|-----------|-------|----------------|
| `ChatInterface.jsx` | 5,614 | Message display, streaming, tool approvals |
| `Sidebar.jsx` | ~1,800 | Project/session navigation |
| `GitPanel.jsx` | ~1,740 | Git UI operations |
| `Settings.jsx` | ~2,370 | Settings management |
| `FileTree.jsx` | ~1,200 | File browser |

### State Management

React Context-based architecture:

1. **AuthContext** - User authentication state
2. **WebSocketContext** - WebSocket connection
3. **ThemeContext** - Dark/light mode
4. **TaskMasterContext** - TaskMaster state
5. **TasksSettingsContext** - Tasks feature settings

### API Communication

- **REST API**: `src/utils/api.js` - Authenticated fetch wrapper
- **WebSocket**: `src/utils/websocket.js` - Real-time communication

## Data Flow

### Chat Message Flow

```
User Input
    │
    ▼
ChatInterface.jsx
    │
    ▼
WebSocket (/ws)
    │
    ▼
server/index.js (message handler)
    │
    ├── Claude: claude-sdk.js
    ├── Cursor: cursor-cli.js
    └── Codex: openai-codex.js
           │
           ▼
    AI Provider (external)
           │
           ▼
    Stream Events
           │
           ▼
    WebSocket (back to client)
           │
           ▼
    ChatInterface.jsx (render)
```

### Tool Approval Flow (Claude)

```
SDK requests tool use
        │
        ▼
canUseTool() check
        │
        ├── Pre-approved → Execute
        │
        └── Needs approval
               │
               ▼
        WebSocket: permission-request
               │
               ▼
        Frontend: Approval UI
               │
               ▼
        User decision
               │
               ▼
        WebSocket: permission-response
               │
               ▼
        SDK continues/aborts
```

## Session Storage

Different providers use different storage formats:

| Provider | Location | Format |
|----------|----------|--------|
| Claude | `~/.claude/projects/{path}/{session}.jsonl` | JSONL |
| Cursor | `~/.cursor/chats/{hash}/sessions/{id}/store.db` | SQLite |
| Codex | `~/.codex/sessions/{hash}/{session}.jsonl` | JSONL |

## Security Architecture

1. **Authentication**: JWT tokens (no expiration currently)
2. **Authorization**: Middleware checks on protected routes
3. **Input Validation**: Path traversal prevention, session ID sanitization
4. **Database**: Prepared statements prevent SQL injection
5. **Passwords**: bcrypt hashing

## Scalability Considerations

### Current Limitations

- Single-process Node.js server
- SQLite database (single-writer)
- File-based session storage
- No horizontal scaling support

### Future Improvements

- PostgreSQL for multi-instance support
- Redis for session/cache sharing
- Message queue for background jobs
- Load balancer support

## Technology Stack

### Backend
- Node.js 20+ (ES modules)
- Express 4.18
- ws 8.14 (WebSocket)
- better-sqlite3 12.2
- node-pty 1.1 (PTY)
- chokidar 4.0 (file watching)

### Frontend
- React 18.2
- Vite 7.0
- Tailwind CSS 3.4
- CodeMirror 6
- xterm.js 5.5
- React Router 6.8

### Shared
- ES modules
- Model constants synchronization
