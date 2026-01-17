# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common development commands

All commands are run from the repo root.

- Install dependencies (from README):
  - `npm install`
- Run full dev stack (backend + frontend with hot reload):
  - `npm run dev`
  - Starts the Express API/WebSocket server using `npm run server` and the Vite dev server using `npm run client`.
  - In development, the Express server listens on `PORT` (see `.env`, default `3001`) and will redirect HTML requests to the Vite dev server on `VITE_PORT` (default `5173`) when `dist/` is missing.
- Run only the backend API/WebSocket server (serves built frontend from `dist/` in production mode):
  - `npm run server`
- Run only the frontend dev server (Vite, proxies `/api`, `/ws`, `/shell` to the backend at `PORT`):
  - `npm run client`
- Build the frontend (Vite build into `dist/`):
  - `npm run build`
- Preview the built frontend with Vite's static server (useful to verify the production bundle only):
  - `npm run preview`
- Production-like start from the repo (build + start server):
  - `npm run start`

Other relevant commands and tools from the README / package metadata:

- Published CLI entrypoints (when installed globally via npm):
  - `npx @siteboon/claude-code-ui` — one-off run.
  - `claude-code-ui` / `cloudcli` — start server after `npm install -g @siteboon/claude-code-ui`.
  - `cloudcli status` — shows configuration and data locations for the installed CLI.
- There are currently **no test or lint/format scripts defined in `package.json`**. The README mentions `npm run lint && npm run format`; if/when those scripts are added, this file should be updated with the actual commands (including how to run a single test, if relevant).

## Environment & configuration

Key requirements and configuration, distilled from `.env.example`, `vite.config.js`, `server/index.js`, and `README.md`:

- Runtime:
  - Node.js v20 or higher (per README).
  - External CLIs expected (for full functionality): Claude Code CLI, Cursor CLI, and OpenAI Codex CLI.
- Environment file:
  - Copy `.env.example` to `.env` in the repo root for OSS/local dev.
  - `server/index.js` manually loads `../.env`, so running `npm run server` / `npm run dev` will pick up values from that file.
- Important environment variables (from `.env.example` and usage in code):
  - `PORT` — backend HTTP/WebSocket server port (Express + `ws`), default `3001`.
  - `VITE_PORT` — Vite dev server port, default `5173`.
  - `VITE_CONTEXT_WINDOW` / `CONTEXT_WINDOW` — max token context window used in token usage calculations; defaults `160000`.
  - `CLAUDE_CLI_PATH` — optional override for the Claude CLI executable if it is not available as `claude`.
  - `DATABASE_PATH` — optional custom path for the authentication SQLite DB (commented in `.env.example`).
  - `VITE_IS_PLATFORM` — toggles "platform" mode; when `true`, several places (e.g. `AuthContext`, WebSocket utilities) short-circuit local auth and token handling to assume an upstream platform provides identity.
- Ports and proxies:
  - `vite.config.js` configures the Vite dev server to listen on `VITE_PORT` and proxy `/api`, `/ws`, `/shell` to `http://localhost:${PORT}` (or `ws://` for WebSockets).
  - `server/index.js` serves static files from `dist/` and, when `dist/index.html` is missing, redirects HTML requests to the Vite dev server (`http://localhost:${VITE_PORT}`) so that hitting the backend port still works in dev.

## High-level architecture

### System overview

This repo implements the "Claude Code UI" (also referred to as Cloud CLI / Claude Code UI in the README): a web UI that sits on top of multiple AI coding CLIs (Claude Code, Cursor, Codex) and an optional TaskMaster AI task-management service.

At a high level:

- **Backend (Node.js + Express + `ws` + `node-pty`)** in `server/`
  - Exposes REST APIs under `/api/*` (projects, sessions, auth, git, TaskMaster, MCP, etc.).
  - Hosts a WebSocket server on the same HTTP server with two main paths:
    - `/ws` — chat/agent streaming channel.
    - `/shell` — terminal/PTY streaming channel.
  - Manages project and session discovery across Claude, Cursor, and Codex, and watches the filesystem for changes to push live updates.
- **Frontend (React 18 + Vite)** in `src/`
  - Single-page app with React Router and several global contexts (auth, theme, WebSocket, TaskMaster, task settings).
  - Main UI surface is a multi-tab workspace per project: Chat, Shell, Files, Git, and optional Tasks (TaskMaster).
  - Uses the REST and WebSocket APIs to drive project/session lists, chat, file editing, git operations, and task management.
- **CLI packaging** (for global installation)
  - `package.json` bin entries point to `server/cli.js` (`claude-code-ui` and `cloudcli`) for the published npm package.
  - The same backend/SPA is used both for local dev (`npm run dev`) and global CLI usage; WARP typically interacts via the dev commands.

### Backend: Express API + WebSocket server

The main server entrypoint is `server/index.js`:

- **Express setup**
  - Loads `.env` manually before importing other modules so `process.env` is populated early.
  - Attaches middleware:
    - `cors()`.
    - JSON body parser with special handling to skip `multipart/form-data` (used by image and audio uploads).
    - `validateApiKey` on `/api/*` (optional API-key-based gate if configured).
  - Exposes a public health check at `GET /health`.
  - Mounts route modules, mostly behind `authenticateToken`:
    - `/api/auth` — login/register/status/user endpoints.
    - `/api/projects` — project/session listing and metadata (also wrapped by a dedicated `server/routes/projects.js`).
    - `/api/git` — git operations for the Git panel.
    - `/api/mcp` and `/api/mcp-utils` — MCP server management and status helpers.
    - `/api/cursor` and `/api/codex` — provider-specific endpoints for Cursor and Codex sessions.
    - `/api/taskmaster` — TaskMaster-related operations.
    - `/api/commands`, `/api/settings`, `/api/cli`, `/api/user`, `/api/agent` — various supporting APIs.
  - Serves static assets from `public/` and `dist/` with cache-control tuned so that HTML is not cached but hashed assets are.
  - Any other non-asset route falls back to `dist/index.html` if it exists, or redirects to the Vite dev server when running in dev.

- **WebSocket server (`ws`)**
  - A single `WebSocketServer` is attached to the HTTP server.
  - `verifyClient` authenticates incoming sockets:
    - In platform mode (`VITE_IS_PLATFORM === 'true'`), it uses `authenticateWebSocket(null)` and allows the first user from the DB.
    - In OSS mode, it expects a token in the query string or Authorization header and uses `authenticateWebSocket(token)`.
  - Connection handler (`wss.on('connection')`) routes by path:
    - `/ws` → `handleChatConnection(ws)`
      - Wraps the raw socket in a `WebSocketWriter` abstraction that matches the streaming interface used by the Claude Agents SDK and other providers.
      - Receives typed messages (e.g. `claude-command`, `cursor-command`, `codex-command`, `abort-session`, `check-session-status`, `get-active-sessions`, `claude-permission-response`).
      - Dispatches to provider-specific helpers:
        - Claude Code via `queryClaudeSDK`/`abortClaudeSDKSession`/`isClaudeSDKSessionActive`.
        - Cursor via `spawnCursor`/`abortCursorSession`.
        - Codex via `queryCodex`/`abortCodexSession`.
      - Sends back structured JSON events that the frontend consumes as streaming chat updates and status changes.
      - Also sends `projects_updated` messages when the project list changes (see watcher below).
    - `/shell` → `handleShellConnection(ws)`
      - Creates or reuses a `node-pty` session per `(projectPath, sessionId, initialCommand)` key.
      - Supports two main modes:
        - **Plain shell mode**: run an arbitrary `initialCommand` inside the project directory.
        - **Provider-attached mode**: launch `claude` or `cursor-agent`, optionally resuming an existing session.
      - Sends `output` events (terminal data) and `url_open` events when it detects URLs in the PTY output (by pattern matching on known shell/browser invocation strings), letting the frontend open links in a browser.
      - Keeps PTY sessions alive for 30 minutes after the socket closes, so reconnections can attach to the same terminal.

- **Project and session discovery (`server/projects.js`)**
  - Centralizes logic for discovering and enriching project metadata across providers.
  - Claude projects:
    - Lives in `~/.claude/projects/<encodedProjectName>/`.
    - `extractProjectDirectory(projectName)` scans all `.jsonl` session files to infer the real `cwd` and caches the mapping in `projectDirectoryCache`.
    - `generateDisplayName` uses `package.json` (if present in the project path) or falls back to the last path segment.
  - Cursor projects:
    - Lives in `~/.cursor/chats/<md5(absoluteProjectPath)>/`.
    - For each known project (from Claude projects or manually added), the backend computes the MD5 of the project path and gathers Cursor sessions from per-project SQLite DBs.
  - Codex projects:
    - Similar pattern using Codex's JSONL session files in its own directory hierarchy.
  - Manual projects:
    - Additional projects can be manually added from the UI and are stored in `~/.claude/project-config.json` with metadata such as `originalPath` and `displayName`.
  - TaskMaster detection:
    - `detectTaskMasterFolder(projectPath)` inspects `.taskmaster/` in each project for key files (`tasks/tasks.json`, `config.json`) and derives task statistics (counts by status, completion %). These are attached to the project object so the frontend can surface TaskMaster status.

- **Filesystem watcher and live project updates**
  - `setupProjectsWatcher()` (in `server/index.js`) uses `chokidar` to watch `~/.claude/projects`:
    - Ignores heavy and irrelevant directories (`node_modules`, `dist`, `.git`, etc.).
    - Debounces events and, on changes, clears `projectDirectoryCache`, recomputes `getProjects()`, and broadcasts a `projects_updated` message via WebSocket to all connected `/ws` clients.
    - Includes `changeType` and `changedFile` in the payload so the frontend can decide how to react (e.g. lightweight message reload vs. full sidebar refresh).

- **File API**
  - Several endpoints are dedicated to interacting with project files, always constrained to the resolved project root:
    - `GET /api/projects/:projectName/files` — returns a directory tree (via `getFileTree`) with metadata.
    - `GET /api/projects/:projectName/file?filePath=...` — reads a text file; enforces that the resolved path stays under the project root.
    - `PUT /api/projects/:projectName/file` — saves file content with the same path-safety checks.
    - `GET /api/projects/:projectName/files/content?path=...` — streams binary file content (images, etc.) with appropriate MIME type.

- **TaskMaster and MCP integration**
  - `server/routes/taskmaster.js` and `server/routes/mcp-utils.js` (and their helpers) implement the HTTP surface for TaskMaster AI and MCP servers.
  - `server/utils/taskmaster-websocket.js` integrates TaskMaster status with the main WebSocket server, emitting messages like `taskmaster-project-updated`, `taskmaster-tasks-updated`, and `taskmaster-mcp-status-changed` that the frontend listens for.

- **Other notable endpoints**
  - `/api/system/update` — runs `git checkout main && git pull && npm install` in the project root (used by the in-app "Update available" modal in `App.jsx`).
  - `/api/transcribe` — multipart audio upload endpoint that proxies to OpenAI Whisper (`whisper-1`) and, depending on `mode`, can optionally post-process transcriptions with GPT (`gpt-4o-mini`) into structured prompts or instructions.
  - `/api/projects/:projectName/upload-images` — image upload endpoint used by the chat UI; stores images temporarily, returns base64-encoded data URLs.
  - `/api/projects/:projectName/sessions/:sessionId/token-usage` — parses Claude/Codex session artifacts (JSONL files, SQLite) to compute token usage and context-window utilization for visualization in the UI.

### Frontend: React application structure

- **Entry and routing**
  - `src/main.jsx` bootstraps the React app, imports global styles (`index.css`, `katex`), and explicitly unregisters any stale service workers to avoid caching issues in production builds.
  - `src/App.jsx`:
    - Wraps the app with providers: `ThemeProvider`, `AuthProvider`, `WebSocketProvider`, `TasksSettingsProvider`, `TaskMasterProvider`, then `ProtectedRoute` and React Router.
    - Defines `AppContent`, which owns most of the top-level client-side state:
      - Project and session selection (`projects`, `selectedProject`, `selectedSession`).
      - View-selection state (`activeTab` for Chat/Files/Shell/Git/Tasks, mobile sidebar visibility, etc.).
      - User preference flags persisted via `useLocalStorage` (e.g. `autoExpandTools`, `showRawParameters`, `showThinking`, `autoScrollToBottom`, `sendByCtrlEnter`, `sidebarVisible`).
      - Session protection and processing state (`activeSessions`, `processingSessions`, `externalMessageUpdate`).
      - Version-check and update modal state (`useVersionCheck`, `VersionUpgradeModal`, which calls `/api/system/update`).
    - Uses `useWebSocketContext` to get the shared `/ws` connection (`ws`, `sendMessage`, `messages`).
    - Handles URL-based deep linking to sessions via `sessionId` route param.

- **Global contexts**
  - `src/contexts/AuthContext.jsx`:
    - Handles auth bootstrap by calling `/api/auth/status` and `/api/auth/user`.
    - Stores `auth-token` in `localStorage` and exposes `login`, `register`, `logout` methods.
    - Supports a special `VITE_IS_PLATFORM` mode where it trusts an upstream platform and skips local login.
  - `src/utils/api.js` and `src/contexts/WebSocketContext.jsx` + `src/utils/websocket.js`:
    - `authenticatedFetch` automatically adds `Authorization: Bearer <token>` for OSS mode and manages headers.
    - `api` object wraps all major backend routes (projects, sessions, TaskMaster, user, generic `get()`), keeping API URLs centralized.
    - `useWebSocket` constructs the `/ws` URL based on platform vs OSS mode, auto-reconnects on close, and exposes `sendMessage` and `messages`.
    - `WebSocketProvider` simply provides that hook's return value to the rest of the tree.
  - `src/contexts/TaskMasterContext.jsx` and `src/contexts/TasksSettingsContext.jsx`:
    - `TaskMasterContext` loads TaskMaster-enhanced project metadata, current project tasks, and MCP server status using the `api.taskmaster` endpoints and generic `api.get`.
    - Listens for TaskMaster-related WebSocket events and refreshes projects/tasks/MCP status accordingly.
    - `TasksSettingsContext` stores user preference for enabling/disabling tasks and probes `/api/taskmaster/installation-status` on mount.

- **Main workspace layout (`src/components/MainContent.jsx`)**
  - Renders the upper tab bar and routes the main content area between:
    - **Chat** — `ChatInterface` (not shown here) handles conversation with the selected provider, drives calls over the `/ws` socket, and uses the "session protection" callbacks.
    - **Shell** — `StandaloneShell` (uses `Shell.jsx` internally) attaches to the `/shell` WebSocket, either running a plain shell command or starting/resuming Claude/Cursor sessions.
    - **Files** — `FileTree` and `CodeEditor` integrate with the file APIs; a resizable right-side editor panel can be toggled and resized.
    - **Git** — `GitPanel` wraps git operations via `/api/git` and allows opening changed files in the editor.
    - **Tasks** — `TaskList`, `TaskDetail`, and `PRDEditor` provide TaskMaster UI when TaskMaster is installed and enabled.
  - Manages the interactive layout for desktop vs mobile (sidebar overlay, bottom nav, editor sidebar vs modal editor).

### WebSocket-driven project updates and session protection

One of the more complex, cross-cutting pieces of architecture is how live project updates are delivered and applied without disrupting active conversations.

- Backend side:
  - `server/index.js` sends `projects_updated` events from the filesystem watcher and from various project-modifying endpoints.
- Frontend side (`App.jsx` + `MainContent.jsx` + `ChatInterface`):
  - `useWebSocketContext` feeds all `/ws` messages into `AppContent`.
  - When a `projects_updated` message arrives, `AppContent`:
    - Optionally triggers a lightweight message reload for the current session if `latestMessage.changedFile` points at the current session's JSONL file and the session is **not** marked active.
    - Uses `activeSessions` and `isUpdateAdditive` to decide whether the incoming project list is a purely additive change (new sessions/projects elsewhere) or would modify/delete the currently selected session or project.
      - If a session is active (user is mid-conversation), it skips non-additive updates to avoid sidebar flicker and chat resets.
      - Otherwise, it merges the updated projects and tries to preserve object identity where possible to minimize re-renders.
  - `MainContent` receives callbacks like `onSessionActive`, `onSessionInactive`, `onSessionProcessing`, `onSessionNotProcessing`, and `onReplaceTemporarySession` from `AppContent` and simply passes them through to `ChatInterface`.
  - `ChatInterface` (not shown here) calls these hooks when:
    - A message is sent (session becomes active).
    - A response finishes or is aborted (session becomes inactive).
    - The provider starts or finishes "thinking" (processing state).
    - A temporary session ID (e.g. `new-session-*`) is replaced with a real ID from backend events.

This design means that when modifying WebSocket message formats or the project update flow, agents must keep the `projects_updated` contract and session-protection logic aligned between backend and frontend.

### Shell and CLI integration

- `src/components/Shell.jsx` encapsulates the xterm.js terminal and `/shell` WebSocket protocol:
  - Handles initialization, reconnection, resize events, and environment detection (`VITE_IS_PLATFORM`).
  - On connect, sends an `init` message with:
    - `projectPath` — derived from the selected project's `fullPath`/`path`.
    - `sessionId` / `hasSession` — used to decide whether to resume a Claude/Cursor session.
    - `provider` — `'claude'`, `'cursor'`, or `'plain-shell'`.
    - `initialCommand` — for plain-shell invocations.
    - `cols` / `rows` — terminal geometry.
  - Receives `output` and `url_open` messages.
- Backend `handleShellConnection` uses those fields to build the right shell command and spawn a PTY session, with special-casing for login commands so they do not reuse PTY sessions.

When changing shell behavior, keep both the frontend `Shell` component and backend `handleShellConnection` in sync with respect to message types and payload shapes.

### TaskMaster and MCP integration

TaskMaster integration is optional but wired through several layers:

- Backend detects `.taskmaster` folders in projects and augments project metadata with TaskMaster status and task counts.
- `/api/taskmaster/*` routes and `/api/mcp-utils/*` expose operations to initialize TaskMaster in a project, manage tasks, parse PRDs, and inspect MCP server status.
- `TaskMasterContext` listens for TaskMaster-related WebSocket messages and refreshes projects/tasks accordingly.
- `TasksSettingsContext` controls whether the "Tasks" tab is enabled, based on installation checks and user preference.
- `MainContent` conditionally includes the Tasks tab and wires `TaskList`, `TaskDetail`, and `PRDEditor` using the TaskMaster contexts.

If you change TaskMaster-related APIs or WebSocket message types, update all three pieces: backend routes, `TaskMasterContext`, and the components in `MainContent` that depend on them.
