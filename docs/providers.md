# AI Providers Guide

AI Code UI supports multiple AI coding assistants. This guide covers configuration and usage for each provider.

## Supported Providers

| Provider | Integration Type | Session Format |
|----------|------------------|----------------|
| Claude Code | Direct SDK | JSONL |
| Cursor | CLI wrapper | SQLite |
| OpenAI Codex | Direct SDK | JSONL |

---

## Claude Code

Claude Code is Anthropic's AI coding assistant, integrated via the official SDK.

### Configuration

#### AWS Bedrock (Recommended)

```bash
# .env
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Model selection (EU inference profiles)
ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
ANTHROPIC_SMALL_FAST_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0'
```

#### Direct API

```bash
# .env
ANTHROPIC_API_KEY=sk-ant-xxx
```

### Available Models

| Model | ID | Context |
|-------|-----|---------|
| Claude Sonnet 4.5 | `claude-sonnet-4-5-20250929` | 160K |
| Claude Opus 4 | `claude-opus-4-20250514` | 160K |
| Claude Haiku 3.5 | `claude-3-5-haiku-20241022` | 160K |
| Claude Opus 4 Plan | `claude-opus-4-20250514-plan` | 160K |
| Claude Sonnet [1M] | `claude-sonnet-4-5-20250929-1m` | 1M |

### Session Storage

Sessions are stored as JSONL files:

```
~/.claude/projects/{encoded-path}/{session-id}.jsonl
```

Each line contains a JSON object representing a conversation turn.

### Tool Approval System

Claude uses a tool approval system for potentially dangerous operations:

1. **Auto-approved tools**: Read-only operations (file reading, listing)
2. **Requires approval**: Write operations, command execution, network requests

#### Approval Flow

```
Claude SDK → canUseTool() → Backend check → WebSocket request → User UI → Response
```

#### Approval Timeout

55 seconds (under SDK's 60-second limit)

### Implementation Details

Location: `server/claude-sdk.js`

Key functions:
- `startClaudeSession()` - Initialize conversation
- `canUseTool()` - Permission check callback
- `handleToolApproval()` - WebSocket permission flow

---

## Cursor

Cursor is integrated via its CLI tool (`cursor-agent`).

### Prerequisites

1. Install Cursor IDE
2. Enable CLI in Cursor settings
3. Ensure `cursor-agent` is in PATH

### Configuration

```bash
# .env
CURSOR_CLI_PATH=cursor-agent  # Default, usually works
```

### Available Models

| Model | ID |
|-------|-----|
| GPT-5.2 | `gpt-5.2` |
| Gemini 3 | `gemini-3` |
| Claude Opus | `claude-opus` |
| Cursor Composer | `cursor-composer` |
| O3 | `o3` |
| O4-mini | `o4-mini` |

### Session Storage

Cursor uses SQLite databases:

```
~/.cursor/chats/{md5_of_project_path}/sessions/{session-id}/store.db
```

### Discovery Limitation

Cursor projects are discovered using MD5 hashes of project paths. This means:
- Projects must be known to be discovered
- Cannot reverse-lookup from hash
- Manual project addition may be required

### Implementation Details

Location: `server/cursor-cli.js`

The integration spawns a child process and transforms output to Claude-compatible format.

---

## OpenAI Codex

Codex is OpenAI's code generation model, integrated via the official SDK.

### Configuration

```bash
# .env
OPENAI_API_KEY=sk-xxx
```

### Available Models

| Model | ID |
|-------|-----|
| GPT-5.2 | `gpt-5.2` |
| O3 | `o3` |
| O4-mini | `o4-mini` |
| Codex | `codex` |

### Session Storage

Sessions are stored as JSONL files:

```
~/.codex/sessions/{project-hash}/{session-id}.jsonl
```

### Implementation Details

Location: `server/openai-codex.js`

---

## Adding a New Provider

To add support for a new AI provider:

### 1. Create Provider Module

Create `server/your-provider.js`:

```javascript
// server/your-provider.js
import { EventEmitter } from 'events';

const activeSessions = new Map();

export async function startYourProviderSession(options, wsWriter) {
  const { projectPath, sessionId, prompt, model } = options;

  // Initialize your SDK/CLI
  const session = initializeProvider(options);

  // Track for abort capability
  activeSessions.set(sessionId, session);

  // Transform events to common format
  session.on('text', (content) => {
    wsWriter({
      type: 'your-provider-response',
      data: { type: 'text', content }
    });
  });

  session.on('tool', (tool, input) => {
    wsWriter({
      type: 'your-provider-response',
      data: { type: 'tool_use', tool, input }
    });
  });

  session.on('end', () => {
    activeSessions.delete(sessionId);
    wsWriter({
      type: 'session-ended',
      sessionId,
      provider: 'your-provider'
    });
  });

  // Start conversation
  await session.send(prompt);
}

export function abortSession(sessionId) {
  const session = activeSessions.get(sessionId);
  if (session) {
    session.abort();
    activeSessions.delete(sessionId);
    return true;
  }
  return false;
}
```

### 2. Add WebSocket Handler

In `server/index.js`:

```javascript
import { startYourProviderSession, abortSession } from './your-provider.js';

// In WebSocket message handler
case 'your-provider-command':
  await startYourProviderSession(message.options, wsWriter);
  break;

case 'abort-session':
  if (message.provider === 'your-provider') {
    abortSession(message.sessionId);
  }
  break;
```

### 3. Add Model Constants

In `shared/modelConstants.js`:

```javascript
export const YOUR_PROVIDER_MODELS = [
  { id: 'model-1', name: 'Model 1', contextWindow: 100000 },
  { id: 'model-2', name: 'Model 2', contextWindow: 200000 },
];
```

### 4. Add Session Discovery

In `server/projects.js`:

```javascript
async function discoverYourProviderSessions(projectPath) {
  // Implement session discovery logic
  const sessionPath = path.join(
    os.homedir(),
    '.your-provider/sessions',
    hashProjectPath(projectPath)
  );

  // Read and parse sessions
  return sessions;
}

// Add to fetchProjectsWithSessions()
const yourProviderSessions = await discoverYourProviderSessions(projectPath);
```

### 5. Update Frontend

In `src/components/ChatInterface.jsx`:

```javascript
// Add case for new provider messages
case 'your-provider-response':
  handleProviderResponse(message.data);
  break;
```

In `src/components/Settings.jsx`:

```javascript
// Add provider option
<option value="your-provider">Your Provider</option>
```

---

## Provider Comparison

| Feature | Claude | Cursor | Codex |
|---------|--------|--------|-------|
| Tool approval UI | Yes | No | No |
| Session continuation | Yes | Yes | Yes |
| Streaming responses | Yes | Yes | Yes |
| Context window | 160K-1M | Varies | Varies |
| Local session storage | JSONL | SQLite | JSONL |
| Auto-discovery | Yes | Partial | Yes |

---

## Troubleshooting

### Claude Issues

**"SDK initialization failed"**
- Check AWS credentials or API key
- Verify Bedrock access is enabled
- Check model availability in your region

**"Tool approval timeout"**
- Increase `TOOL_APPROVAL_TIMEOUT` in config
- Check WebSocket connection stability

### Cursor Issues

**"cursor-agent not found"**
- Install Cursor IDE
- Add Cursor CLI to PATH
- Set `CURSOR_CLI_PATH` explicitly

**"Sessions not discovered"**
- Add project manually via UI
- Check `~/.cursor/chats/` directory exists

### Codex Issues

**"OpenAI API error"**
- Verify API key is valid
- Check API quota/billing
- Ensure model access is enabled
