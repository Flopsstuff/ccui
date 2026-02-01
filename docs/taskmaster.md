# TaskMaster Integration

AI Code UI integrates with TaskMaster for AI-powered task management. This guide covers setup, configuration, and usage.

## Overview

TaskMaster provides:

- **PRD Management** - Create and manage Product Requirements Documents
- **Task Generation** - AI-powered task breakdown from PRDs
- **Task Tracking** - Kanban, list, and grid views for task management
- **MCP Integration** - Model Context Protocol server for AI assistant integration

## Prerequisites

### TaskMaster CLI (Optional)

For full functionality, install the TaskMaster CLI:

```bash
npm install -g task-master-ai
```

Verify installation:

```bash
task-master --version
```

### MCP Server Configuration

For AI assistants to interact with TaskMaster, configure the MCP server. See [MCP Servers](./mcp-servers.md) for details.

## Project Setup

### Initializing TaskMaster

Initialize TaskMaster in a project from the UI:

1. Select a project in the sidebar
2. Navigate to the Tasks panel
3. Click "Initialize TaskMaster" if not already configured

Or via the API:

```bash
POST /api/taskmaster/init/:projectName
```

This creates the `.taskmaster` directory structure:

```
.taskmaster/
├── config.json          # TaskMaster configuration
├── docs/                # PRD documents
│   └── prd.txt         # Default PRD file
└── tasks/
    └── tasks.json      # Task definitions
```

### Detection Status

The system can be in one of these states:

| Status | Description |
|--------|-------------|
| `fully-configured` | Both `.taskmaster` folder and MCP server configured |
| `taskmaster-only` | `.taskmaster` folder exists but no MCP server |
| `mcp-only` | MCP server configured but no `.taskmaster` folder |
| `not-configured` | Neither configured |

Check status via API:

```bash
GET /api/taskmaster/detect/:projectName
```

## PRD Management

### Creating PRDs

Create PRDs from the UI's PRD Editor or via API:

```bash
POST /api/taskmaster/prd/:projectName
Content-Type: application/json

{
  "fileName": "my-feature.md",
  "content": "# Feature PRD\n\n## Overview\n..."
}
```

### PRD Templates

AI Code UI provides built-in PRD templates:

| Template | Description |
|----------|-------------|
| `web-app` | Web application with frontend/backend |
| `api` | REST API development |
| `mobile-app` | iOS/Android mobile app |
| `data-analysis` | Data analysis project |

Apply a template:

```bash
POST /api/taskmaster/apply-template/:projectName
Content-Type: application/json

{
  "templateId": "web-app",
  "fileName": "prd.txt",
  "customizations": {
    "Your App Name": "My Project",
    "Your Name": "Developer"
  }
}
```

### Listing PRDs

```bash
GET /api/taskmaster/prd/:projectName
```

### Reading PRD Content

```bash
GET /api/taskmaster/prd/:projectName/:fileName
```

### Deleting PRDs

```bash
DELETE /api/taskmaster/prd/:projectName/:fileName
```

## Task Management

### Generating Tasks from PRD

Parse a PRD to generate tasks:

```bash
POST /api/taskmaster/parse-prd/:projectName
Content-Type: application/json

{
  "fileName": "prd.txt",
  "numTasks": 10,
  "append": false
}
```

**Options:**

- `fileName`: PRD file to parse (default: `prd.txt`)
- `numTasks`: Maximum number of tasks to generate
- `append`: Add to existing tasks instead of replacing

### Listing Tasks

```bash
GET /api/taskmaster/tasks/:projectName
```

**Response:**

```json
{
  "projectName": "my-project",
  "tasks": [...],
  "totalTasks": 15,
  "tasksByStatus": {
    "pending": 8,
    "in-progress": 3,
    "done": 2,
    "review": 1,
    "deferred": 1,
    "cancelled": 0
  }
}
```

### Adding Tasks

```bash
POST /api/taskmaster/add-task/:projectName
Content-Type: application/json

{
  "prompt": "Add user authentication with JWT",
  "priority": "high",
  "dependencies": "1,2"
}
```

Or with explicit title/description:

```json
{
  "title": "Implement JWT Authentication",
  "description": "Add secure token-based authentication",
  "priority": "high"
}
```

### Updating Tasks

Update task details:

```bash
PUT /api/taskmaster/update-task/:projectName/:taskId
Content-Type: application/json

{
  "title": "Updated Title",
  "status": "in-progress",
  "priority": "high"
}
```

Update status only:

```json
{
  "status": "done"
}
```

### Getting Next Task

Get the recommended next task based on dependencies and priority:

```bash
GET /api/taskmaster/next/:projectName
```

## Task Statuses

| Status | Description |
|--------|-------------|
| `pending` | Not started |
| `in-progress` | Currently being worked on |
| `done` | Completed |
| `review` | Awaiting review |
| `deferred` | Postponed |
| `cancelled` | No longer needed |

## UI Features

### Task Views

The Tasks panel supports multiple views:

- **Kanban** - Columns by status with drag-and-drop
- **List** - Sortable table view
- **Grid** - Card-based grid layout

### Filtering and Sorting

- Filter by status, priority
- Search by task title
- Sort by ID, title, status, priority, or update date

### Task Details

Click any task to view:

- Full description
- Dependencies
- Subtasks
- Test strategy
- Creation and update timestamps

## WebSocket Updates

The UI receives real-time updates via WebSocket:

```javascript
// Server → Client
{
  type: 'taskmaster-project-update',
  projectName: 'my-project',
  data: { hasTaskmaster: true, status: 'initialized' }
}

{
  type: 'taskmaster-tasks-update',
  projectName: 'my-project'
}
```

## API Reference

### Installation Status

```bash
GET /api/taskmaster/installation-status
```

Returns CLI installation and MCP server status.

### Detect All Projects

```bash
GET /api/taskmaster/detect-all
```

Returns TaskMaster status for all known projects.

### Project Detection

```bash
GET /api/taskmaster/detect/:projectName
```

Detailed detection result for a specific project.

## Troubleshooting

### Tasks Not Loading

1. Check if `.taskmaster/tasks/tasks.json` exists
2. Verify file permissions
3. Check browser console for API errors

### PRD Parsing Fails

1. Ensure TaskMaster CLI is installed (`task-master --version`)
2. Check PRD file format (must be `.txt` or `.md`)
3. Review server logs for detailed error messages

### MCP Server Not Detected

1. Check Claude configuration at `~/.claude.json` or `~/.claude/settings.json`
2. Verify `task-master-ai` is in the MCP servers list
3. See [MCP Servers](./mcp-servers.md) for configuration help

## See Also

- [MCP Servers](./mcp-servers.md) - MCP server configuration
- [API Reference](./api-reference.md) - Full API documentation
- [WebSocket API](./websocket-api.md) - Real-time communication
