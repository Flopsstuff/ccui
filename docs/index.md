# AI Code UI Documentation

Welcome to the AI Code UI documentation. This guide covers everything you need to know about installing, configuring, and using the application.

## What is AI Code UI?

AI Code UI (formerly Claude Code UI) is a full-stack web application providing a unified interface for multiple AI coding assistants:

- **Claude Code** - Anthropic's AI coding assistant via SDK
- **Cursor CLI** - Cursor's AI-powered code editor CLI
- **OpenAI Codex** - OpenAI's code generation model

## Quick Links

| Document | Description |
|----------|-------------|
| [Getting Started](./getting-started.md) | Installation and initial setup |
| [Docker Setup](./docker.md) | Docker deployment and configuration |
| [Architecture](./architecture.md) | System architecture overview |
| [Project Structure](./project-structure.md) | File and directory reference |
| [Configuration](./configuration.md) | Environment variables and settings |
| [API Reference](./api-reference.md) | REST API endpoints |
| [WebSocket API](./websocket-api.md) | Real-time communication protocol |
| [AI Providers](./providers.md) | Claude, Cursor, and Codex integration |
| [Database](./database.md) | Database schema and operations |
| [Frontend](./frontend.md) | React frontend architecture |
| [Contributing](./contributing.md) | How to contribute to the project |

## Features

### Multi-Provider Support
- Switch between Claude, Cursor, and Codex seamlessly
- Unified chat interface for all providers
- Provider-specific model selection

### Project Management
- Automatic project discovery from `~/.claude/`, `~/.cursor/`, `~/.codex/`
- Session history and continuation
- Manual project creation and import

### Development Tools
- Integrated file browser with CodeMirror editor
- Interactive terminal (PTY) sessions
- Git panel with staging, commits, and branch management
- Real-time file watching and updates

### TaskMaster Integration
- AI-powered task management
- PRD (Product Requirements Document) support
- Task breakdown and tracking

### Security
- JWT-based authentication
- Optional API key protection
- Path traversal prevention
- SQL injection protection via prepared statements

## System Requirements

- **Node.js** 20.x or later
- **npm** 10.x or later
- **SQLite** 3.x (bundled with better-sqlite3)
- **Git** (for git operations)

### Optional Requirements

- **Docker** and **Docker Compose** for containerized deployment
- **AWS credentials** for Bedrock integration
- **Claude CLI** for Claude Code integration
- **Cursor CLI** for Cursor integration

## Support

- **Issues**: [GitHub Issues](https://github.com/Flopsstuff/ccui/issues)
- **Documentation**: This docs folder
- **CLAUDE.md**: In-repo architecture guide for AI assistants

## License

See [LICENSE](../LICENSE) in the project root.
