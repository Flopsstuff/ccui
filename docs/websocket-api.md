# WebSocket API Reference

AI Code UI uses WebSocket connections for real-time communication. This document describes the WebSocket protocol and message formats.

## WebSocket Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/ws` | Chat messages and AI interactions |
| `/shell` | Interactive terminal (PTY) sessions |

## Connection

### Chat WebSocket (`/ws`)

```javascript
const ws = new WebSocket('ws://localhost:3001/ws');

ws.onopen = () => {
  console.log('Connected to chat WebSocket');
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  // Handle message
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('WebSocket closed');
};
```

### Shell WebSocket (`/shell`)

```javascript
const shell = new WebSocket('ws://localhost:3001/shell');

shell.onopen = () => {
  // Initialize terminal session
  shell.send(JSON.stringify({
    type: 'init',
    projectPath: '/path/to/project',
    sessionId: 'session-id',
    provider: 'claude'
  }));
};
```

---

## Chat WebSocket Messages

### Client → Server

#### Start Claude Session

```json
{
  "type": "claude-command",
  "command": "start",
  "options": {
    "projectPath": "/path/to/project",
    "sessionId": "session-id",
    "prompt": "User message",
    "model": "claude-sonnet-4-5-20250929",
    "contextWindow": 160000
  }
}
```

#### Start Cursor Session

```json
{
  "type": "cursor-command",
  "command": "start",
  "options": {
    "projectPath": "/path/to/project",
    "sessionId": "session-id",
    "prompt": "User message",
    "model": "gpt-5.2"
  }
}
```

#### Start Codex Session

```json
{
  "type": "codex-command",
  "command": "start",
  "options": {
    "projectPath": "/path/to/project",
    "sessionId": "session-id",
    "prompt": "User message",
    "model": "gpt-5.2"
  }
}
```

#### Abort Session

```json
{
  "type": "abort-session",
  "sessionId": "session-id",
  "provider": "claude|cursor|codex"
}
```

#### Permission Response (Claude)

```json
{
  "type": "claude-permission-response",
  "requestId": "request-id",
  "allow": true,
  "remember": false
}
```

#### Continue Conversation

```json
{
  "type": "continue",
  "sessionId": "session-id",
  "provider": "claude"
}
```

### Server → Client

#### Claude Response Events

```json
{
  "type": "claude-response",
  "data": {
    "type": "text",
    "content": "AI response text"
  }
}
```

```json
{
  "type": "claude-response",
  "data": {
    "type": "tool_use",
    "tool": "bash",
    "input": {
      "command": "ls -la"
    }
  }
}
```

```json
{
  "type": "claude-response",
  "data": {
    "type": "tool_result",
    "tool": "bash",
    "output": "file1.js\nfile2.js"
  }
}
```

#### Permission Request (Claude)

```json
{
  "type": "claude-permission-request",
  "requestId": "request-id",
  "tool": "bash",
  "input": {
    "command": "rm -rf node_modules"
  },
  "description": "Execute bash command"
}
```

#### Cursor Response Events

```json
{
  "type": "cursor-response",
  "data": {
    "type": "text",
    "content": "AI response text"
  }
}
```

#### Codex Response Events

```json
{
  "type": "codex-response",
  "data": {
    "type": "text",
    "content": "AI response text"
  }
}
```

#### Session Events

```json
{
  "type": "session-started",
  "sessionId": "session-id",
  "provider": "claude"
}
```

```json
{
  "type": "session-ended",
  "sessionId": "session-id",
  "provider": "claude",
  "reason": "completed|aborted|error"
}
```

#### Error Events

```json
{
  "type": "error",
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

#### Projects Updated

```json
{
  "type": "projects-updated",
  "projects": [
    {
      "path": "/path/to/project",
      "name": "project-name",
      "sessions": []
    }
  ]
}
```

#### Token Usage

```json
{
  "type": "token-usage",
  "usage": {
    "inputTokens": 1000,
    "outputTokens": 500,
    "totalTokens": 1500,
    "contextWindow": 160000
  }
}
```

---

## Shell WebSocket Messages

### Client → Server

#### Initialize Terminal

```json
{
  "type": "init",
  "projectPath": "/path/to/project",
  "sessionId": "session-id",
  "provider": "claude"
}
```

#### Send Input

```json
{
  "type": "input",
  "data": "ls -la\n"
}
```

#### Resize Terminal

```json
{
  "type": "resize",
  "cols": 120,
  "rows": 30
}
```

### Server → Client

#### Terminal Output

```json
{
  "type": "output",
  "data": "terminal output data"
}
```

#### Terminal Ready

```json
{
  "type": "ready"
}
```

#### Terminal Error

```json
{
  "type": "error",
  "error": "Error message"
}
```

#### Terminal Exit

```json
{
  "type": "exit",
  "code": 0
}
```

---

## Event Flow Examples

### Complete Chat Flow

```
Client                          Server                          AI Provider
   │                               │                                  │
   │ claude-command (start)        │                                  │
   ├──────────────────────────────►│                                  │
   │                               │ Start session                    │
   │                               ├─────────────────────────────────►│
   │                               │                                  │
   │                               │ Stream: text                     │
   │                               │◄─────────────────────────────────┤
   │ claude-response (text)        │                                  │
   │◄──────────────────────────────┤                                  │
   │                               │                                  │
   │                               │ Stream: tool_use                 │
   │                               │◄─────────────────────────────────┤
   │ claude-permission-request     │                                  │
   │◄──────────────────────────────┤                                  │
   │                               │                                  │
   │ claude-permission-response    │                                  │
   ├──────────────────────────────►│                                  │
   │                               │ Execute tool                     │
   │                               ├─────────────────────────────────►│
   │                               │                                  │
   │                               │ Stream: tool_result              │
   │                               │◄─────────────────────────────────┤
   │ claude-response (tool_result) │                                  │
   │◄──────────────────────────────┤                                  │
   │                               │                                  │
   │                               │ Stream: end                      │
   │                               │◄─────────────────────────────────┤
   │ session-ended                 │                                  │
   │◄──────────────────────────────┤                                  │
```

### Tool Approval Flow

```
Client                          Server
   │                               │
   │                               │ Tool requires approval
   │                               │
   │ claude-permission-request     │
   │◄──────────────────────────────┤
   │                               │
   │ [User reviews in UI]          │
   │                               │
   │ claude-permission-response    │
   │ {allow: true, remember: true} │
   ├──────────────────────────────►│
   │                               │
   │                               │ Execute tool
   │                               │ (future uses auto-approved)
```

---

## Connection Management

### Reconnection Strategy

The frontend implements automatic reconnection:

```javascript
// From src/utils/websocket.js
const RECONNECT_DELAY = 1000;
const MAX_RECONNECT_DELAY = 30000;

function reconnect() {
  const delay = Math.min(
    RECONNECT_DELAY * Math.pow(2, reconnectAttempts),
    MAX_RECONNECT_DELAY
  );

  setTimeout(() => {
    connect();
    reconnectAttempts++;
  }, delay);
}
```

### Heartbeat

The server sends periodic heartbeat messages:

```json
{
  "type": "heartbeat",
  "timestamp": 1704067200000
}
```

Clients should respond within 30 seconds or the connection may be terminated.

---

## Error Handling

### Error Message Format

```json
{
  "type": "error",
  "error": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": {
    "field": "additional context"
  }
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `INVALID_MESSAGE` | Malformed message format |
| `UNKNOWN_COMMAND` | Unrecognized message type |
| `SESSION_NOT_FOUND` | Session doesn't exist |
| `PROVIDER_ERROR` | AI provider returned error |
| `PERMISSION_DENIED` | Tool execution denied |
| `TIMEOUT` | Operation timed out |
| `CONNECTION_ERROR` | Connection-related error |

---

## Best Practices

### Message Handling

1. Always validate message types before processing
2. Handle unknown message types gracefully
3. Implement timeout handling for requests
4. Buffer messages during reconnection

### Performance

1. Avoid sending large payloads (>1MB)
2. Implement client-side rate limiting
3. Use message batching when appropriate
4. Clean up listeners on disconnect

### Security

1. Validate all incoming messages
2. Sanitize user input before sending
3. Don't trust client-provided session IDs
4. Implement proper authentication
