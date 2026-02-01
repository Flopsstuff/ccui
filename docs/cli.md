# CLI Reference

AI Code UI provides a command-line interface for managing and running the application.

## Installation

### Global Installation

```bash
npm install -g @siteboon/claude-code-ui
```

After global installation, the `cloudcli` and `claude-code-ui` commands become available.

### Run Without Installing

```bash
npx @siteboon/claude-code-ui
```

## Commands

### start (default)

Start the AI Code UI server. This is the default command when no arguments are provided.

```bash
cloudcli start
cloudcli              # Same as 'start'
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--port <port>` | `-p` | Server port (default: 3001) |
| `--database-path <path>` | | Custom database location |

**Examples:**

```bash
cloudcli                          # Start with defaults on port 3001
cloudcli --port 8080              # Start on port 8080
cloudcli -p 3000                  # Short form for port
cloudcli start --port 4000        # Explicit start command
```

### status

Display configuration and data locations. Useful for debugging and understanding the current setup.

```bash
cloudcli status
```

**Output includes:**

- Current version
- Installation directory
- Database location and status
- Current configuration values
- Claude projects folder location
- Configuration file status

**Example output:**

```
Claude Code UI - Status
════════════════════════════════════════════════════════════════

[INFO] Version: 1.2.0

[INFO] Installation Directory:
       /usr/local/lib/node_modules/@siteboon/claude-code-ui

[INFO] Database Location:
       /home/user/.config/claude-code-ui/auth.db
       Status: [OK] Exists
       Size: 24.50 KB
       Modified: 1/25/2026, 10:30:00 AM

[INFO] Configuration:
       PORT: 3001 (default)
       DATABASE_PATH: (using default location)
       CLAUDE_CLI_PATH: claude (default)
       CONTEXT_WINDOW: 160000 (default)

[INFO] Claude Projects Folder:
       /home/user/.claude/projects
       Status: [OK] Exists

[INFO] Configuration File:
       /usr/local/lib/node_modules/@siteboon/claude-code-ui/.env
       Status: [WARN] Not found (using defaults)
```

### update

Check for and install updates to the latest version.

```bash
cloudcli update
```

**Behavior:**

1. Checks npm registry for latest version
2. Compares with currently installed version
3. If newer version available, runs `npm update -g @siteboon/claude-code-ui`
4. Reports success or provides manual update instructions on failure

### help

Display help information with all available commands and options.

```bash
cloudcli help
cloudcli --help
cloudcli -h
```

### version

Display the current version number.

```bash
cloudcli version
cloudcli --version
cloudcli -v
```

## Environment Variables

The CLI respects environment variables that can be set in a `.env` file or the shell environment:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3001` | Server port |
| `DATABASE_PATH` | `./server/database/auth.db` | Custom database location |
| `CLAUDE_CLI_PATH` | `claude` | Path to Claude CLI |
| `CONTEXT_WINDOW` | `160000` | Context window size |

**Priority:** CLI arguments > Environment variables > Default values

## Configuration File

The CLI looks for a `.env` file in the installation directory. You can copy `.env.example` to `.env` and customize:

```bash
# Navigate to installation directory
cd $(npm root -g)/@siteboon/claude-code-ui

# Copy example configuration
cp .env.example .env

# Edit configuration
nano .env
```

## Accessing the UI

After starting the server, access the web interface at:

- **Default:** `http://localhost:3001`
- **Custom port:** `http://localhost:<port>`

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 3001
lsof -i :3001

# Use a different port
cloudcli --port 8080
```

### Database Issues

```bash
# Check database status
cloudcli status

# Use custom database path
cloudcli --database-path /path/to/custom/auth.db
```

### Permission Errors

If you encounter permission errors during global installation:

```bash
# Option 1: Use npm prefix
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH

# Option 2: Use npx instead
npx @siteboon/claude-code-ui
```

## See Also

- [Getting Started](./getting-started.md) - Initial setup guide
- [Configuration](./configuration.md) - Full configuration reference
- [Docker](./docker.md) - Docker deployment alternative
