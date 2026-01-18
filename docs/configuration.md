# Configuration Reference

Complete reference for all configuration options in AI Code UI.

## Environment Variables

Copy `.env.example` to `.env` and configure as needed.

### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3001` | Backend server port |
| `VITE_PORT` | `5173` | Frontend dev server port |
| `NODE_ENV` | `development` | Environment mode |

### Database

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_PATH` | `./server/database/auth.db` | SQLite database path |

### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | (generated) | JWT signing secret |
| `API_KEY` | (none) | Optional API key for external access |
| `VITE_IS_PLATFORM` | `false` | Enable single-user mode (bypasses auth) |

### Claude Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CLI_PATH` | `claude` | Path to Claude CLI |
| `CONTEXT_WINDOW` | `160000` | Default context window size |
| `TOOL_APPROVAL_TIMEOUT` | `55000` | Tool approval timeout (ms) |

### AWS Bedrock

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CODE_USE_BEDROCK` | `0` | Enable Bedrock (`1` = enabled) |
| `AWS_REGION` | `us-east-1` | AWS region |
| `AWS_ACCESS_KEY_ID` | (none) | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | (none) | AWS secret key |
| `AWS_SESSION_TOKEN` | (none) | Optional session token |
| `AWS_PROFILE` | (none) | AWS profile name |

### Anthropic API

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | (none) | Anthropic API key |

### Model Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_MODEL` | `claude-sonnet-4-5-20250929` | Default Claude model |
| `ANTHROPIC_SMALL_FAST_MODEL` | `claude-3-5-haiku-20241022` | Fast/cheap model |

For Bedrock, use inference profile IDs:
```bash
ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
ANTHROPIC_SMALL_FAST_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0'
```

### OpenAI/Codex

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | (none) | OpenAI API key |

### Cursor

| Variable | Default | Description |
|----------|---------|-------------|
| `CURSOR_CLI_PATH` | `cursor-agent` | Path to Cursor CLI |

### TaskMaster

| Variable | Default | Description |
|----------|---------|-------------|
| `TASKMASTER_ENABLED` | `true` | Enable TaskMaster features |
| `TASKMASTER_MCP_SERVER` | (none) | MCP server for TaskMaster |

### File System

| Variable | Default | Description |
|----------|---------|-------------|
| `WATCH_DEBOUNCE` | `1000` | File watcher debounce (ms) |
| `MAX_FILE_SIZE` | `10485760` | Max file size to read (10MB) |

### Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `LOG_FORMAT` | `json` | Log format (json, pretty) |

---

## Configuration Files

### project-config.json

Stores manually added projects:

```json
{
  "projects": [
    {
      "path": "/path/to/project",
      "name": "My Project",
      "addedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "hiddenProjects": [
    "/path/to/hidden/project"
  ]
}
```

Location: `~/.claude-code-ui/project-config.json`

### MCP Configuration

MCP servers are configured in Claude's config:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["path/to/server.js"],
      "env": {
        "API_KEY": "xxx"
      }
    }
  }
}
```

Location: `~/.claude/config.json`

---

## Vite Configuration

Frontend build configuration in `vite.config.js`:

```javascript
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:3001',
      '/ws': {
        target: 'ws://localhost:3001',
        ws: true
      },
      '/shell': {
        target: 'ws://localhost:3001',
        ws: true
      }
    }
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-codemirror': ['@codemirror/view', '@codemirror/state'],
          'vendor-xterm': ['xterm', 'xterm-addon-fit']
        }
      }
    }
  }
});
```

---

## Tailwind Configuration

Theme customization in `tailwind.config.js`:

```javascript
module.exports = {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // Custom colors using CSS variables
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: 'hsl(var(--primary))',
        // ...
      }
    }
  }
};
```

---

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'
services:
  claude-code-ui:
    build: .
    ports:
      - "3001:3001"
    volumes:
      - ~/.claude:/root/.claude
      - ~/.cursor:/root/.cursor
      - ~/.codex:/root/.codex
      - ./data:/app/data
    environment:
      - NODE_ENV=production
      - CLAUDE_CODE_USE_BEDROCK=1
      - AWS_REGION=us-east-1
    env_file:
      - .env
```

### Dockerfile

Key stages:
1. Base Node.js 20 image
2. Install system dependencies (git, python, build tools)
3. Install CLI tools (Claude, Cursor, Codex, AWS CLI)
4. Install npm dependencies
5. Build frontend
6. Set entrypoint

---

## Runtime Configuration

### Settings (UI)

User-configurable settings stored in database:

| Setting | Options | Description |
|---------|---------|-------------|
| Theme | dark, light, system | UI theme |
| Default Provider | claude, cursor, codex | Default AI provider |
| Git Name | (text) | Git commit author name |
| Git Email | (text) | Git commit author email |

### Per-Project Settings

Projects can have individual settings:

```json
{
  "defaultProvider": "claude",
  "defaultModel": "claude-sonnet-4-5-20250929",
  "contextWindow": 160000
}
```

---

## Security Configuration

### CORS

Currently allows all origins. For production:

```javascript
// server/index.js
app.use(cors({
  origin: ['https://your-domain.com'],
  credentials: true
}));
```

### Rate Limiting

Not implemented by default. Add with:

```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### Helmet Security Headers

```javascript
import helmet from 'helmet';

app.use(helmet());
```

---

## Example Configurations

### Development

```bash
# .env
NODE_ENV=development
PORT=3001
VITE_PORT=5173
DATABASE_PATH=./server/database/auth.db
ANTHROPIC_API_KEY=sk-ant-dev-xxx
LOG_LEVEL=debug
```

### Production (Bedrock)

```bash
# .env
NODE_ENV=production
PORT=3001
VITE_IS_PLATFORM=true
DATABASE_PATH=/data/auth.db
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=xxx
ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
LOG_LEVEL=info
```

### Docker (Full Stack)

```bash
# .env
NODE_ENV=production
PORT=3001
VITE_IS_PLATFORM=true
DATABASE_PATH=/app/data/auth.db
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
```

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "3001:3001"
    volumes:
      - ./data:/app/data
      - ~/.aws:/root/.aws:ro
    env_file:
      - .env
```
