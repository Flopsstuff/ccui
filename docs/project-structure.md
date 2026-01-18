# Project Structure

Complete file and directory reference for AI Code UI.

## Overview

```
/projects/ccui/
├── server/                 # Backend (Node.js/Express)
├── src/                    # Frontend (React)
├── shared/                 # Shared code (frontend & backend)
├── docs/                   # Documentation
├── public/                 # Static assets
├── dist/                   # Built frontend (generated)
├── cloudflared/            # Cloudflare Tunnel config
└── [config files]          # Root configuration
```

## Root Directory

### Configuration Files

| File | Purpose |
|------|---------|
| `package.json` | NPM dependencies and scripts |
| `vite.config.js` | Vite build configuration |
| `tailwind.config.js` | Tailwind CSS configuration |
| `postcss.config.js` | PostCSS configuration |
| `Dockerfile` | Docker image definition |
| `docker-compose.yml` | Docker orchestration |
| `.env.example` | Environment variable template |
| `mkdocs.yml` | MkDocs documentation config |
| `.release-it.json` | Release automation config |

### Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview and quick start |
| `CLAUDE.md` | Guidelines for AI assistants |
| `WARP.md` | Additional documentation |
| `LICENSE` | MIT license |

---

## Backend (`/server`)

### Entry Points

| File | Lines | Purpose |
|------|-------|---------|
| `index.js` | ~1,748 | Main Express server, WebSocket, routes |
| `cli.js` | ~327 | CLI tool (cloudcli command) |

### AI Provider Integrations

| File | Lines | Purpose |
|------|-------|---------|
| `claude-sdk.js` | ~700 | Claude Agent SDK, tool approval system |
| `cursor-cli.js` | ~600 | Cursor CLI wrapper (child process) |
| `openai-codex.js` | ~300 | OpenAI Codex SDK integration |

### Core Services

| File | Lines | Purpose |
|------|-------|---------|
| `projects.js` | ~1,300 | Project discovery, session management |

### Routes (`/server/routes/`)

| File | Purpose |
|------|---------|
| `auth.js` | JWT authentication (login, register) |
| `projects.js` | Project/session CRUD |
| `git.js` | Git operations (status, commit, push, pull) |
| `cursor.js` | Cursor provider endpoints |
| `codex.js` | Codex provider endpoints |
| `agent.js` | Claude Agent API |
| `taskmaster.js` | TaskMaster AI integration |
| `mcp.js` | MCP server management |
| `mcp-utils.js` | MCP utility functions |
| `settings.js` | User settings |
| `user.js` | User profile |
| `commands.js` | Command execution |
| `cli-auth.js` | CLI authentication flow |

### Database (`/server/database/`)

| File | Purpose |
|------|---------|
| `db.js` | SQLite schema, operations, migrations |
| `auth.db` | SQLite database file (generated) |

### Middleware (`/server/middleware/`)

| File | Purpose |
|------|---------|
| `auth.js` | JWT authentication middleware |

### Utilities (`/server/utils/`)

| File | Purpose |
|------|---------|
| `commandParser.js` | Command parsing logic |
| `mcp-detector.js` | MCP detection utilities |
| `gitConfig.js` | Git configuration handling |
| `taskmaster-websocket.js` | TaskMaster WebSocket utilities |

---

## Frontend (`/src`)

### Main Application

| File | Lines | Purpose |
|------|-------|---------|
| `main.jsx` | ~20 | React entry point |
| `App.jsx` | ~975 | Root component, routing, providers |
| `index.css` | - | Global styles, CSS variables |

### Components (`/src/components/`)

#### Core Components

| File | Size | Purpose |
|------|------|---------|
| `ChatInterface.jsx` | 254KB | Chat UI, streaming, tool approvals |
| `Sidebar.jsx` | 67KB | Project/session navigation |
| `Settings.jsx` | 78KB | Multi-tab settings panel |
| `MainContent.jsx` | 30KB | Main content area router |
| `GitPanel.jsx` | 58KB | Git operations UI |
| `FileTree.jsx` | ~1,200 lines | File browser |
| `CodeEditor.jsx` | ~600 lines | Code editor (CodeMirror) |
| `Shell.jsx` | ~400 lines | Terminal (xterm.js) |

#### Task Management

| File | Purpose |
|------|---------|
| `TaskList.jsx` | Task list display |
| `TaskCard.jsx` | Individual task card |
| `TaskDetail.jsx` | Task detail view |
| `TaskIndicator.jsx` | Task status indicator |
| `CreateTaskModal.jsx` | Task creation dialog |
| `PRDEditor.jsx` | PRD document editor |
| `TodoList.jsx` | Todo management |

#### Settings Components

| File | Purpose |
|------|---------|
| `ApiKeysSettings.jsx` | API key management |
| `CredentialsSettings.jsx` | Credential storage |
| `GitSettings.jsx` | Git configuration |
| `TasksSettings.jsx` | TaskMaster settings |
| `QuickSettingsPanel.jsx` | Quick settings access |

#### Authentication

| File | Purpose |
|------|---------|
| `LoginForm.jsx` | Login form |
| `LoginModal.jsx` | Login modal |
| `SetupForm.jsx` | Initial setup form |
| `Onboarding.jsx` | Onboarding wizard |
| `ProtectedRoute.jsx` | Route protection |

#### Setup & Wizards

| File | Purpose |
|------|---------|
| `ProjectCreationWizard.jsx` | Project setup wizard |
| `TaskMasterSetupWizard.jsx` | TaskMaster onboarding |

#### Utility Components

| File | Purpose |
|------|---------|
| `DiffViewer.jsx` | Git diff visualization |
| `ImageViewer.jsx` | Image display |
| `TokenUsagePie.jsx` | Token usage chart |
| `CommandMenu.jsx` | Command palette |
| `MobileNav.jsx` | Mobile navigation |
| `StandaloneShell.jsx` | Standalone terminal |
| `DarkModeToggle.jsx` | Theme toggle |
| `MicButton.jsx` | Audio input |
| `Tooltip.jsx` | Tooltip component |
| `ErrorBoundary.jsx` | Error boundary |

#### Branding

| File | Purpose |
|------|---------|
| `ClaudeLogo.jsx` | Claude logo |
| `CursorLogo.jsx` | Cursor logo |
| `CodexLogo.jsx` | Codex logo |
| `ClaudeStatus.jsx` | Claude status indicator |
| `TaskMasterStatus.jsx` | TaskMaster status |

#### UI Library (`/src/components/ui/`)

| File | Purpose |
|------|---------|
| `button.jsx` | Button component |
| `input.jsx` | Input field |
| `badge.jsx` | Badge component |
| `scroll-area.jsx` | Scrollable area |

### Contexts (`/src/contexts/`)

| File | Purpose |
|------|---------|
| `AuthContext.jsx` | User authentication state |
| `WebSocketContext.jsx` | WebSocket connection |
| `ThemeContext.jsx` | Dark/light theme |
| `TaskMasterContext.jsx` | TaskMaster state |
| `TasksSettingsContext.jsx` | Tasks feature settings |

### Hooks (`/src/hooks/`)

| File | Purpose |
|------|---------|
| `useLocalStorage.jsx` | Local storage persistence |
| `useAudioRecorder.js` | Audio recording |
| `useVersionCheck.js` | Version update check |

### Utilities (`/src/utils/`)

| File | Purpose |
|------|---------|
| `api.js` | REST API client (30+ endpoints) |
| `websocket.js` | WebSocket hook with reconnect |
| `whisper.js` | Whisper API integration |

### Library (`/src/lib/`)

| File | Purpose |
|------|---------|
| `utils.js` | General utility functions |

---

## Shared Code (`/shared`)

| File | Purpose |
|------|---------|
| `modelConstants.js` | Model definitions (Claude, Cursor, Codex) |

**Important:** This file is used by both frontend and backend. Keep in sync when adding models.

---

## Documentation (`/docs`)

| File | Purpose |
|------|---------|
| `index.md` | Documentation home |
| `getting-started.md` | Installation guide |
| `architecture.md` | System architecture |
| `configuration.md` | Environment variables |
| `api-reference.md` | REST API reference |
| `websocket-api.md` | WebSocket protocol |
| `providers.md` | AI provider integration |
| `database.md` | Database schema |
| `frontend.md` | Frontend architecture |
| `docker.md` | Docker deployment |
| `contributing.md` | Contribution guidelines |
| `project-structure.md` | This file |
| `.pages` | MkDocs page ordering |

---

## Public Assets (`/public`)

Static files served directly:

| Path | Purpose |
|------|---------|
| `favicon.ico` | Browser favicon |
| `logo.png` | Application logo |
| `screenshots/` | Documentation screenshots |

---

## Build Output (`/dist`)

Generated by `npm run build`:

```
dist/
├── index.html
├── assets/
│   ├── index-[hash].js
│   ├── index-[hash].css
│   ├── vendor-react-[hash].js
│   ├── vendor-codemirror-[hash].js
│   └── vendor-xterm-[hash].js
└── [static assets]
```

---

## Cloudflare Tunnel (`/cloudflared`)

| File | Purpose |
|------|---------|
| `config.yml` | Tunnel configuration |
| `credentials.json` | Tunnel credentials (not in repo) |
| `credentials.json.example` | Credentials template |

---

## Code Statistics

| Layer | Files | Approx. Lines |
|-------|-------|---------------|
| Backend | 25 | ~13,800 |
| Frontend | 51 | ~24,800 |
| Shared | 1 | ~100 |
| **Total** | 77 | **~38,700** |

---

## Key File Relationships

### WebSocket Communication

```
Frontend                          Backend
────────                          ───────
src/utils/websocket.js  ────────► server/index.js (/ws, /shell)
         │                               │
         ▼                               ▼
src/components/           server/claude-sdk.js
ChatInterface.jsx         server/cursor-cli.js
Shell.jsx                 server/openai-codex.js
```

### API Communication

```
Frontend                          Backend
────────                          ───────
src/utils/api.js  ──────────────► server/routes/*.js
                                         │
                                         ▼
                                  server/database/db.js
                                  server/projects.js
```

### Shared Models

```
shared/modelConstants.js
         │
         ├────► src/components/Settings.jsx
         │      src/components/ChatInterface.jsx
         │
         └────► server/claude-sdk.js
                server/cursor-cli.js
                server/openai-codex.js
```

---

## Navigation Quick Reference

| Task | Location |
|------|----------|
| Add API endpoint | `server/routes/` + `src/utils/api.js` |
| Add React component | `src/components/` |
| Add AI provider | `server/` + `shared/modelConstants.js` |
| Modify database | `server/database/db.js` |
| Update authentication | `server/middleware/auth.js` |
| Configure build | `vite.config.js` |
| Style components | `tailwind.config.js` + `src/index.css` |
| Add environment var | `.env.example` + `docs/configuration.md` |
