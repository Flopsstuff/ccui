# MCP Server Configuration

AI Code UI supports Model Context Protocol (MCP) servers for extended AI assistant capabilities. This guide covers MCP server detection, configuration, and management.

## What are MCP Servers?

MCP (Model Context Protocol) servers extend AI assistants with additional tools and capabilities. They allow AI models to:

- Access external services and APIs
- Execute specialized commands
- Interact with development tools
- Manage tasks and workflows

## Supported MCP Operations

### Claude CLI Integration

AI Code UI can interact with MCP servers through the Claude CLI:

```bash
# List configured MCP servers
GET /api/mcp/cli/list

# Add a new MCP server
POST /api/mcp/cli/add

# Remove an MCP server
DELETE /api/mcp/cli/remove/:serverName
```

### Direct Configuration

MCP servers are configured in Claude's settings files:

- `~/.claude.json` (user-level)
- `~/.claude/settings.json` (alternative location)

## Configuration Format

### Basic Structure

```json
{
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### Example: TaskMaster MCP Server

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"],
      "env": {}
    }
  }
}
```

### Example: Multiple Servers

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "/path/to/allowed/dir"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

## TaskMaster MCP Server

### Installation

The TaskMaster MCP server is typically used via npx (no installation needed):

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"]
    }
  }
}
```

Or with global installation:

```bash
npm install -g task-master-ai
```

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "task-master-ai"
    }
  }
}
```

### Detection

AI Code UI automatically detects TaskMaster MCP server configuration:

```bash
GET /api/taskmaster/installation-status
```

**Response:**

```json
{
  "success": true,
  "installation": {
    "isInstalled": true,
    "installPath": "/usr/local/bin/task-master",
    "version": "1.0.0"
  },
  "mcpServer": {
    "hasMCPServer": true,
    "isConfigured": true,
    "configPath": "~/.claude.json"
  },
  "isReady": true
}
```

### Capabilities

When configured, TaskMaster MCP provides these tools to AI assistants:

- `get_tasks` - List all tasks
- `get_task` - Get task details
- `add_task` - Create new task
- `update_task` - Modify task
- `set_status` - Update task status
- `next_task` - Get recommended next task
- `parse_prd` - Generate tasks from PRD

## API Endpoints

### List MCP Servers (via Claude CLI)

```bash
GET /api/mcp/cli/list
```

**Response:**

```json
{
  "success": true,
  "servers": [
    {
      "name": "task-master-ai",
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"]
    }
  ]
}
```

### Add MCP Server

```bash
POST /api/mcp/cli/add
Content-Type: application/json

{
  "name": "my-server",
  "command": "npx",
  "args": ["-y", "my-mcp-package"]
}
```

### Remove MCP Server

```bash
DELETE /api/mcp/cli/remove/:serverName
```

### Get Server Configuration

```bash
GET /api/mcp/servers
```

Returns raw MCP server configurations from Claude settings.

## Detection Logic

AI Code UI checks for MCP configuration in this order:

1. `~/.claude.json` - Primary configuration file
2. `~/.claude/settings.json` - Alternative location

The detection utility (`server/utils/mcp-detector.js`) checks:

1. Configuration file exists
2. `mcpServers` key is present
3. Target server (e.g., `task-master-ai`) is configured
4. Server configuration is valid

## Common MCP Servers

| Server | Package | Description |
|--------|---------|-------------|
| TaskMaster | `task-master-ai` | AI-powered task management |
| Filesystem | `@anthropic/mcp-server-filesystem` | File system access |
| GitHub | `@anthropic/mcp-server-github` | GitHub API integration |
| Postgres | `@anthropic/mcp-server-postgres` | PostgreSQL database access |

## Security Considerations

### Environment Variables

Sensitive values like API keys should use environment variables:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Path Restrictions

For filesystem servers, always specify allowed directories:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic/mcp-server-filesystem",
        "/home/user/projects",
        "/home/user/documents"
      ]
    }
  }
}
```

### Command Validation

AI Code UI validates MCP server commands before execution to prevent command injection.

## Troubleshooting

### Server Not Detected

1. **Check configuration file location:**
   ```bash
   ls -la ~/.claude.json ~/.claude/settings.json
   ```

2. **Verify JSON syntax:**
   ```bash
   cat ~/.claude.json | jq .
   ```

3. **Check server name matches exactly:**
   - Configuration uses `task-master-ai`
   - Detection looks for `task-master-ai` (exact match)

### Server Fails to Start

1. **Verify command is available:**
   ```bash
   which npx
   npx -y --package=task-master-ai task-master-ai --version
   ```

2. **Check for package issues:**
   ```bash
   npm cache clean --force
   ```

3. **Review Claude CLI logs for detailed errors**

### Permission Errors

1. **Check file permissions:**
   ```bash
   chmod 644 ~/.claude.json
   ```

2. **Verify npm global directory permissions**

### Configuration Not Updating

1. **Restart Claude CLI:**
   ```bash
   claude mcp list  # Force reload
   ```

2. **Check for syntax errors in configuration**

## See Also

- [TaskMaster Integration](./taskmaster.md) - TaskMaster features and usage
- [Configuration](./configuration.md) - Environment configuration
- [API Reference](./api-reference.md) - Full API documentation
