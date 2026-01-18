# REST API Reference

This document describes all REST API endpoints available in AI Code UI.

## Base URL

- **Development**: `http://localhost:3001/api`
- **Production**: `http://your-domain/api`

## Authentication

Most endpoints require JWT authentication.

### Headers

```http
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

### Optional API Key

If `API_KEY` environment variable is set:

```http
X-API-Key: <api-key>
```

---

## Auth Endpoints

### POST /api/auth/register

Create a new user account.

**Request:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": 1,
    "username": "string",
    "hasCompletedOnboarding": false
  }
}
```

### POST /api/auth/login

Authenticate and get JWT token.

**Request:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": 1,
    "username": "string",
    "hasCompletedOnboarding": true,
    "gitName": "string",
    "gitEmail": "string"
  }
}
```

### GET /api/auth/status

Check authentication status.

**Response:**
```json
{
  "authenticated": true,
  "user": {
    "id": 1,
    "username": "string"
  }
}
```

---

## Projects Endpoints

### GET /api/projects

Get all projects with sessions.

**Query Parameters:**
- `includeHidden` (boolean) - Include hidden projects

**Response:**
```json
{
  "projects": [
    {
      "path": "/path/to/project",
      "name": "project-name",
      "sessions": [
        {
          "id": "session-id",
          "provider": "claude|cursor|codex",
          "lastModified": "2024-01-01T00:00:00Z",
          "messageCount": 42
        }
      ]
    }
  ]
}
```

### POST /api/projects

Add a manual project.

**Request:**
```json
{
  "path": "/path/to/project",
  "name": "optional-name"
}
```

### DELETE /api/projects/:encodedPath

Remove a manual project.

### GET /api/projects/:encodedPath/sessions

Get sessions for a specific project.

### GET /api/projects/:encodedPath/sessions/:sessionId

Get session details and messages.

**Response:**
```json
{
  "session": {
    "id": "session-id",
    "provider": "claude",
    "messages": [
      {
        "role": "user|assistant",
        "content": "string",
        "timestamp": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

### POST /api/projects/:encodedPath/sessions

Create a new session.

**Request:**
```json
{
  "provider": "claude|cursor|codex"
}
```

### DELETE /api/projects/:encodedPath/sessions/:sessionId

Delete a session.

---

## Files Endpoints

### GET /api/files

List files in a directory.

**Query Parameters:**
- `path` (string, required) - Directory path

**Response:**
```json
{
  "files": [
    {
      "name": "file.js",
      "path": "/path/to/file.js",
      "type": "file|directory",
      "size": 1234
    }
  ]
}
```

### GET /api/files/content

Get file content.

**Query Parameters:**
- `path` (string, required) - File path

**Response:**
```json
{
  "content": "file contents",
  "encoding": "utf-8"
}
```

### PUT /api/files/content

Update file content.

**Request:**
```json
{
  "path": "/path/to/file.js",
  "content": "new content"
}
```

### POST /api/files/create

Create a new file or directory.

**Request:**
```json
{
  "path": "/path/to/new-file.js",
  "type": "file|directory",
  "content": "optional content"
}
```

### DELETE /api/files

Delete a file or directory.

**Query Parameters:**
- `path` (string, required)

---

## Git Endpoints

### GET /api/git/status

Get git status for a project.

**Query Parameters:**
- `projectPath` (string, required)

**Response:**
```json
{
  "branch": "main",
  "staged": ["file1.js"],
  "modified": ["file2.js"],
  "untracked": ["file3.js"],
  "ahead": 0,
  "behind": 0
}
```

### POST /api/git/stage

Stage files for commit.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "files": ["file1.js", "file2.js"]
}
```

### POST /api/git/unstage

Unstage files.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "files": ["file1.js"]
}
```

### POST /api/git/commit

Create a commit.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "message": "commit message"
}
```

### POST /api/git/push

Push to remote.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "remote": "origin",
  "branch": "main"
}
```

### POST /api/git/pull

Pull from remote.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "remote": "origin",
  "branch": "main"
}
```

### GET /api/git/branches

Get branches.

**Query Parameters:**
- `projectPath` (string, required)

**Response:**
```json
{
  "current": "main",
  "branches": [
    {
      "name": "main",
      "isRemote": false,
      "isCurrent": true
    }
  ]
}
```

### POST /api/git/checkout

Checkout a branch.

**Request:**
```json
{
  "projectPath": "/path/to/project",
  "branch": "feature-branch",
  "create": false
}
```

### GET /api/git/diff

Get diff for a file.

**Query Parameters:**
- `projectPath` (string, required)
- `file` (string, required)
- `staged` (boolean) - Get staged diff

**Response:**
```json
{
  "diff": "diff content"
}
```

### GET /api/git/log

Get commit history.

**Query Parameters:**
- `projectPath` (string, required)
- `limit` (number) - Number of commits

**Response:**
```json
{
  "commits": [
    {
      "hash": "abc123",
      "message": "commit message",
      "author": "name",
      "date": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## Settings Endpoints

### GET /api/settings

Get user settings.

**Response:**
```json
{
  "theme": "dark|light|system",
  "defaultProvider": "claude|cursor|codex",
  "gitName": "string",
  "gitEmail": "string"
}
```

### PUT /api/settings

Update user settings.

**Request:**
```json
{
  "theme": "dark",
  "defaultProvider": "claude"
}
```

### PUT /api/settings/git

Update git configuration.

**Request:**
```json
{
  "gitName": "Your Name",
  "gitEmail": "your@email.com"
}
```

---

## User Endpoints

### GET /api/user/profile

Get current user profile.

**Response:**
```json
{
  "id": 1,
  "username": "string",
  "gitName": "string",
  "gitEmail": "string",
  "hasCompletedOnboarding": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### PUT /api/user/profile

Update user profile.

**Request:**
```json
{
  "gitName": "New Name",
  "gitEmail": "new@email.com"
}
```

### PUT /api/user/onboarding

Complete onboarding.

**Request:**
```json
{
  "gitName": "Your Name",
  "gitEmail": "your@email.com"
}
```

---

## API Keys Endpoints

### GET /api/keys

Get user's API keys.

**Response:**
```json
{
  "keys": [
    {
      "id": 1,
      "keyName": "My API Key",
      "createdAt": "2024-01-01T00:00:00Z",
      "lastUsed": "2024-01-02T00:00:00Z",
      "isActive": true
    }
  ]
}
```

### POST /api/keys

Create a new API key.

**Request:**
```json
{
  "keyName": "My API Key"
}
```

**Response:**
```json
{
  "id": 1,
  "keyName": "My API Key",
  "apiKey": "generated-key"
}
```

### DELETE /api/keys/:id

Delete an API key.

---

## Credentials Endpoints

### GET /api/credentials

Get user's stored credentials.

**Response:**
```json
{
  "credentials": [
    {
      "id": 1,
      "credentialName": "GitHub Token",
      "credentialType": "token",
      "description": "Personal access token",
      "isActive": true
    }
  ]
}
```

### POST /api/credentials

Store a new credential.

**Request:**
```json
{
  "credentialName": "GitHub Token",
  "credentialType": "token",
  "credentialValue": "ghp_xxx",
  "description": "Personal access token"
}
```

### DELETE /api/credentials/:id

Delete a credential.

---

## MCP Endpoints

### GET /api/mcp/servers

Get MCP server configurations.

**Response:**
```json
{
  "servers": [
    {
      "name": "server-name",
      "command": "node",
      "args": ["server.js"],
      "enabled": true
    }
  ]
}
```

### POST /api/mcp/servers

Add MCP server configuration.

**Request:**
```json
{
  "name": "server-name",
  "command": "node",
  "args": ["server.js"]
}
```

### PUT /api/mcp/servers/:name

Update MCP server.

### DELETE /api/mcp/servers/:name

Remove MCP server.

### POST /api/mcp/servers/:name/restart

Restart an MCP server.

---

## TaskMaster Endpoints

### GET /api/taskmaster/projects

Get TaskMaster projects.

### GET /api/taskmaster/projects/:id/tasks

Get tasks for a project.

### POST /api/taskmaster/projects/:id/tasks

Create a new task.

**Request:**
```json
{
  "title": "Task title",
  "description": "Task description",
  "priority": "high|medium|low"
}
```

### PUT /api/taskmaster/projects/:id/tasks/:taskId

Update a task.

### DELETE /api/taskmaster/projects/:id/tasks/:taskId

Delete a task.

---

## Health Check

### GET /api/health

Check server health.

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {}
}
```

### Common Error Codes

| Status | Code | Description |
|--------|------|-------------|
| 400 | BAD_REQUEST | Invalid request parameters |
| 401 | UNAUTHORIZED | Missing or invalid token |
| 403 | FORBIDDEN | Insufficient permissions |
| 404 | NOT_FOUND | Resource not found |
| 500 | INTERNAL_ERROR | Server error |

---

## Rate Limiting

Currently no rate limiting is implemented. Consider adding rate limiting for production deployments.

## Pagination

Endpoints that return lists support pagination:

**Query Parameters:**
- `page` (number) - Page number (1-indexed)
- `limit` (number) - Items per page

**Response includes:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```
