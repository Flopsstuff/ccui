# Security Guide

This document describes the security architecture and best practices for AI Code UI.

## Authentication

### JWT Token Authentication

AI Code UI uses JSON Web Tokens (JWT) for authentication.

**Flow:**

1. User submits credentials to `/api/auth/login`
2. Server validates against bcrypt-hashed password
3. Server issues JWT token
4. Client stores token in localStorage
5. Client includes token in `Authorization: Bearer <token>` header
6. Server validates token on each request

**Configuration:**

```bash
# .env
JWT_SECRET=your-secret-key-here  # Auto-generated if not set
```

**Current Limitations:**

- Tokens do not expire (consider implementing expiration)
- Single secret key for all tokens
- No refresh token mechanism

**Recommendations:**

- Set a strong `JWT_SECRET` in production
- Consider implementing token expiration
- Use HTTPS in production

### Platform Mode

For single-user deployments, platform mode bypasses JWT authentication:

```bash
# .env
VITE_IS_PLATFORM=true
```

**Behavior:**

- No login required
- First user in database used for all requests
- Suitable for local development or trusted environments

### API Key Authentication

Optional API key for external access:

```bash
# .env
API_KEY=your-api-key-here
```

When set, requests must include:

```
X-API-Key: your-api-key-here
```

## Password Security

### Storage

Passwords are hashed using bcrypt before storage:

```javascript
// server/database/db.js
bcrypt.hashSync(password, 10)
```

**Parameters:**

- Salt rounds: 10 (industry standard)
- Algorithm: bcrypt (resistant to rainbow tables)

### Requirements

Current implementation has no password requirements. Consider enforcing:

- Minimum length (8+ characters)
- Complexity requirements
- Password history

## Tool Approval System

AI Code UI implements a tool approval system for Claude SDK integration.

### How It Works

1. Claude SDK requests tool execution
2. Backend intercepts via `canUseTool` callback
3. Backend sends approval request to frontend via WebSocket
4. User sees approval dialog with tool name and arguments
5. User approves or denies
6. Backend returns decision to SDK
7. SDK proceeds or cancels

**Timeout:**

- 55 seconds (under SDK's 60-second limit)
- Configurable via `CLAUDE_TOOL_APPROVAL_TIMEOUT_MS`

### Security Benefits

- Users control what tools execute
- Visibility into AI actions
- Audit trail of approved operations

### Message Types

```javascript
// Server → Client: Request approval
{
  type: 'claude-permission-request',
  requestId: 'uuid',
  toolName: 'bash',
  toolInput: { command: '...' }
}

// Client → Server: User decision
{
  type: 'claude-permission-response',
  requestId: 'uuid',
  allow: true
}
```

## Input Validation

### Path Traversal Prevention

File operations validate paths to prevent directory traversal:

```javascript
// Paths must be within project root
const safePath = path.resolve(projectRoot, userPath);
if (!safePath.startsWith(projectRoot)) {
  throw new Error('Path traversal detected');
}
```

**Protected Operations:**

- File reading/writing
- Directory listing
- Terminal session working directory

### SQL Injection Prevention

All database queries use prepared statements:

```javascript
// Safe - uses parameterized query
db.prepare('SELECT * FROM users WHERE id = ?').get(userId)

// Unsafe - never do this
db.exec(`SELECT * FROM users WHERE id = ${userId}`)
```

### Session ID Sanitization

Session IDs are restricted to alphanumeric characters:

```javascript
const sanitizedId = sessionId.replace(/[^a-zA-Z0-9-]/g, '');
```

## WebSocket Security

### Connection Handling

- WebSocket connections authenticated via token query parameter
- Connections closed on authentication failure
- Rate limiting on message processing

### Message Validation

- Message types validated against whitelist
- Payload structure validated
- Large payloads rejected

## CORS Configuration

Default configuration allows all origins:

```javascript
app.use(cors());
```

**Production Recommendations:**

```javascript
app.use(cors({
  origin: ['https://your-domain.com'],
  credentials: true
}));
```

## Credential Storage

### Current State

User credentials (API keys, etc.) are stored in the database with basic encryption:

```sql
CREATE TABLE user_credentials (
  credential_value TEXT NOT NULL,
  ...
);
```

**Limitations:**

- Not encrypted at rest
- Accessible to database readers

### Recommendations

1. **Database Encryption:**
   - Use SQLCipher for encrypted SQLite
   - Encrypt sensitive columns

2. **Key Management:**
   - Store encryption keys outside database
   - Use environment variables or key vault

3. **Access Control:**
   - Restrict database file permissions
   - Use separate credentials per service

## Network Security

### HTTPS

AI Code UI does not enforce HTTPS internally. For production:

1. **Use a reverse proxy:**
   ```nginx
   server {
       listen 443 ssl;
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;

       location / {
           proxy_pass http://localhost:3001;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
       }
   }
   ```

2. **Or use Cloudflare Tunnel:**
   - See `cloudflared/` directory for configuration

### Firewall

Restrict access to necessary ports:

```bash
# Allow only local access
iptables -A INPUT -p tcp --dport 3001 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 3001 -j DROP
```

## Docker Security

When running in Docker:

1. **Use non-root user:**
   ```dockerfile
   USER node
   ```

2. **Read-only filesystem:**
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
   ```

3. **Resource limits:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 1G
         cpus: '1.0'
   ```

## Security Headers

Consider adding security headers via middleware:

```javascript
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000');
  next();
});
```

## Audit Logging

Current implementation has basic console logging. For production:

1. **Log authentication events**
2. **Log tool approvals/denials**
3. **Log file access**
4. **Store logs securely**

## Security Checklist

### Before Deployment

- [ ] Set strong `JWT_SECRET`
- [ ] Configure HTTPS (reverse proxy or Cloudflare)
- [ ] Review CORS settings
- [ ] Set appropriate file permissions
- [ ] Configure firewall rules
- [ ] Disable platform mode unless needed

### Ongoing

- [ ] Monitor logs for suspicious activity
- [ ] Keep dependencies updated
- [ ] Review access periodically
- [ ] Test authentication flows
- [ ] Backup database securely

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do not** open a public issue
2. Email security concerns privately
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## See Also

- [Configuration](./configuration.md) - Environment variables
- [Docker](./docker.md) - Container deployment
- [API Reference](./api-reference.md) - Authentication endpoints
