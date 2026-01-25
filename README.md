<div align="center">
  <img src="public/logo.svg" alt="Cloud CLI" width="64" height="64">
  <h1>Cloud CLI (Claude Code UI)</h1>
  <p>Desktop and mobile UI for Claude Code, Cursor CLI, and Codex</p>
  
  <p>
    <strong>Fork of <a href="https://github.com/siteboon/claudecodeui">siteboon/claudecodeui</a> with Docker support</strong>
  </p>
</div>

---

A web interface for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor CLI](https://docs.cursor.com/en/cli/overview), and [Codex](https://developers.openai.com/codex). Access your AI coding assistants from anywhere — desktop or mobile.

**Key difference from original:** This fork adds full Docker and Docker Compose support for easy self-hosted deployment, including Cloudflare Tunnel integration for secure remote access.

## Screenshots

<div align="center">
<table>
<tr>
<td align="center">
<h3>Desktop View</h3>
<img src="public/screenshots/desktop-main.png" alt="Desktop Interface" width="400">
<br>
<em>Main interface with project overview and chat</em>
</td>
<td align="center">
<h3>Mobile Experience</h3>
<img src="public/screenshots/mobile-chat.png" alt="Mobile Interface" width="250">
<br>
<em>Responsive mobile design</em>
</td>
</tr>
<tr>
<td align="center" colspan="2">
<h3>CLI Selection</h3>
<img src="public/screenshots/cli-selection.png" alt="CLI Selection" width="400">
<br>
<em>Choose between Claude Code, Cursor CLI, and Codex</em>
</td>
</tr>
</table>
</div>

## Features

- **Multi-provider support** — Claude Code, Cursor CLI, Codex
- **Responsive design** — Works on desktop, tablet, and mobile
- **Interactive chat** — Real-time streaming with WebSocket
- **File explorer** — Browse and edit files with syntax highlighting
- **Git integration** — View, stage, commit, switch branches
- **Session management** — Resume conversations, track history
- **AWS Bedrock support** — Use Claude without Anthropic API keys

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) v20+
- At least one CLI installed: [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor CLI](https://docs.cursor.com/en/cli/overview), or [Codex](https://developers.openai.com/codex)

### Option 1: Docker (Recommended)

```bash
git clone https://github.com/Flopsstuff/ccui.git
cd ccui
docker-compose up --build
```

### Option 2: Clone and Run

```bash
git clone https://github.com/Flopsstuff/ccui.git
cd ccui
npm ci
npm run dev
```

### Option 3: npm Package

Use the official npm package from the original repository:

```bash
npx @siteboon/claude-code-ui
```

Or install globally:

```bash
npm install -g @siteboon/claude-code-ui
cloudcli start
```

### Configuration

```bash
cp .env.example .env
# Edit .env with your settings
```

Open http://localhost:3001 (production) or http://localhost:5173 (development).

## Documentation

- **[Full Documentation](https://flopsstuff.github.io/ccui/)** — Setup guides, configuration, API reference
- **[Getting Started](docs/getting-started.md)** — Detailed installation instructions
- **[Docker Setup](docs/docker.md)** — Container deployment guide
- **[Configuration](docs/configuration.md)** — Environment variables reference
- **[Architecture](docs/architecture.md)** — System design overview

## Links

| Resource | Link |
|----------|------|
| This repository | [github.com/Flopsstuff/ccui](https://github.com/Flopsstuff/ccui) |
| Original repository | [github.com/siteboon/claudecodeui](https://github.com/siteboon/claudecodeui) |
| npm package | [@siteboon/claude-code-ui](https://www.npmjs.com/package/@siteboon/claude-code-ui) |
| Documentation | [flopsstuff.github.io/ccui](https://flopsstuff.github.io/ccui/) |

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.

---

<div align="center">
  <sub>Based on <a href="https://github.com/siteboon/claudecodeui">siteboon/claudecodeui</a></sub>
</div>
