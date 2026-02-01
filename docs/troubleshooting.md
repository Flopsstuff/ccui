# Troubleshooting Guide

This guide covers common issues and solutions for AI Code UI.

## Quick Diagnostics

### Check System Status

```bash
cloudcli status
```

This displays:
- Current version
- Database location and status
- Configuration values
- Claude projects folder status

### Check Server Logs

Backend logs appear in the terminal running `npm run dev` or `npm run server`.

### Check Browser Console

Open browser DevTools (F12) → Console tab for frontend errors.

### Check WebSocket Traffic

Browser DevTools → Network tab → WS filter

---

## Connection Issues

### Server Won't Start

**Symptom:** Server fails to start or immediately exits.

**Solutions:**

1. **Check port availability:**
   ```bash
   lsof -i :3001
   # If occupied, use different port:
   cloudcli --port 8080
   ```

2. **Check Node.js version:**
   ```bash
   node --version  # Must be 20.x or later
   ```

3. **Reinstall dependencies:**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

4. **Check for syntax errors:**
   ```bash
   npm run build  # Will show compilation errors
   ```

### WebSocket Connection Failed

**Symptom:** Chat doesn't work, "Connecting..." status persists.

**Solutions:**

1. **Verify server is running:**
   ```bash
   curl http://localhost:3001/api/health
   ```

2. **Check WebSocket endpoint:**
   - Development: `ws://localhost:3001/ws`
   - Behind proxy: Ensure WebSocket upgrade is configured

3. **Check browser extensions:**
   - Disable ad blockers temporarily
   - VPN/proxy extensions may block WebSocket

4. **Check CORS settings:**
   - Server allows all origins by default
   - Custom deployments may need CORS configuration

### Cannot Connect to AI Provider

**Symptom:** Messages send but no response from AI.

**Solutions:**

1. **Check API credentials:**
   - Claude: Verify AWS Bedrock credentials or API key
   - Cursor: Ensure Cursor CLI is authenticated
   - Codex: Check OpenAI API key configuration

2. **Check environment variables:**
   ```bash
   # For AWS Bedrock
   echo $AWS_ACCESS_KEY_ID
   echo $AWS_SECRET_ACCESS_KEY
   echo $AWS_REGION
   ```

3. **Test Claude CLI directly:**
   ```bash
   claude --version
   echo "test" | claude
   ```

---

## Authentication Issues

### Login Fails

**Symptom:** Cannot log in with correct credentials.

**Solutions:**

1. **Check database exists:**
   ```bash
   cloudcli status  # Shows database location and status
   ```

2. **Reset password (if needed):**
   ```bash
   sqlite3 server/database/auth.db
   > DELETE FROM users WHERE username = 'your_username';
   > .exit
   ```
   Then re-register through the UI.

3. **Check for platform mode:**
   - If `VITE_IS_PLATFORM=true`, authentication is bypassed
   - First user in database is used automatically

### JWT Token Expired

**Symptom:** Logged in but API calls fail with 401.

**Solutions:**

1. **Clear localStorage:**
   ```javascript
   // In browser console
   localStorage.clear();
   ```

2. **Log out and log in again**

3. **Note:** Current implementation has no token expiration. This issue typically indicates token corruption.

### Session Not Persisting

**Symptom:** Must log in again after page refresh.

**Solutions:**

1. **Check localStorage is enabled:**
   - Private/incognito mode may block localStorage
   - Some browsers block third-party storage

2. **Check for browser storage quota:**
   ```javascript
   // In browser console
   navigator.storage.estimate().then(console.log)
   ```

---

## Project Discovery Issues

### Projects Not Appearing

**Symptom:** Sidebar shows no projects or missing projects.

**Solutions:**

1. **Check Claude projects folder:**
   ```bash
   ls -la ~/.claude/projects/
   ```

2. **Verify JSONL files exist:**
   ```bash
   find ~/.claude/projects -name "*.jsonl"
   ```

3. **Check file permissions:**
   ```bash
   chmod -R 755 ~/.claude/projects/
   ```

4. **Manually add project:**
   - Click "+" in sidebar
   - Enter project path
   - Project is added to `~/.claude/projects/project-config.json`

### Cursor Projects Missing

**Symptom:** Only Claude projects appear, not Cursor.

**Explanation:** Cursor uses MD5 hashes of project paths for storage. Discovery requires knowing the path first (cannot reverse-lookup).

**Solutions:**

1. **Manually add the project path**
2. **Open project in Cursor first, then it may be discovered**

### Sessions Not Loading

**Symptom:** Project shows but no chat history.

**Solutions:**

1. **Check session files:**
   ```bash
   # Claude sessions
   ls ~/.claude/projects/*/session-*.jsonl

   # Cursor sessions
   ls ~/.cursor/chats/*/sessions/*/store.db
   ```

2. **Verify file is valid JSONL:**
   ```bash
   head -1 ~/.claude/projects/project-name/session-id.jsonl | jq .
   ```

3. **Check for file corruption:**
   - Large files may have truncation issues
   - Invalid JSON lines cause parsing failures

---

## Chat Issues

### Messages Not Sending

**Symptom:** Send button doesn't work or message disappears.

**Solutions:**

1. **Check WebSocket status:** Look for green connection indicator
2. **Check browser console for errors**
3. **Verify provider is selected in settings**

### Tool Approval Stuck

**Symptom:** Tool approval dialog appears but doesn't respond.

**Solutions:**

1. **Check for timeout:**
   - Approvals timeout after 55 seconds
   - SDK cancellation clears pending approvals

2. **Refresh the page:**
   - Pending approvals are cleared on reconnect
   - May need to resend the message

3. **Check server logs for approval flow errors**

### Responses Cut Off

**Symptom:** AI response stops mid-sentence.

**Solutions:**

1. **Check context window:**
   - Default: 160,000 tokens
   - Set `CONTEXT_WINDOW` in `.env` if needed

2. **Check for abort signals:**
   - User may have accidentally aborted
   - Network interruption causes abort

3. **Check token limits in response**

---

## File Browser Issues

### Files Not Loading

**Symptom:** File tree empty or files won't open.

**Solutions:**

1. **Check project path exists:**
   ```bash
   ls -la /path/to/project
   ```

2. **Check file permissions:**
   - Server runs as current user
   - Files must be readable

3. **Check for symlinks:**
   - Symlinks outside project root are blocked
   - Security measure prevents path traversal

### Editor Won't Save

**Symptom:** Save button fails or content lost.

**Solutions:**

1. **Check write permissions:**
   ```bash
   touch /path/to/project/test-file
   ```

2. **Check for file locks:**
   - Other editors may have file open
   - Git operations may lock files

3. **Check disk space**

---

## Terminal Issues

### Terminal Not Connecting

**Symptom:** Shell shows "Connecting..." or blank.

**Solutions:**

1. **Check PTY support:**
   - `node-pty` requires native compilation
   - May need to rebuild: `npm rebuild`

2. **Check shell availability:**
   ```bash
   echo $SHELL
   which bash
   ```

3. **Check WebSocket endpoint `/shell`**

### Terminal Output Garbled

**Symptom:** Colors or formatting broken.

**Solutions:**

1. **Check terminal type:**
   - xterm.js expects xterm-256color
   - Some shells need TERM configured

2. **Resize terminal:**
   - Drag terminal divider
   - Triggers resize event

---

## Git Panel Issues

### Git Operations Failing

**Symptom:** Stage, commit, or other git commands fail.

**Solutions:**

1. **Check git is initialized:**
   ```bash
   git status  # In project directory
   ```

2. **Check git configuration:**
   ```bash
   git config user.name
   git config user.email
   ```

3. **Configure in Settings:**
   - Go to Settings → Git
   - Set name and email

### Branch Operations Fail

**Symptom:** Cannot switch branches or create new ones.

**Solutions:**

1. **Check for uncommitted changes**
2. **Check for merge conflicts**
3. **Verify branch name is valid**

---

## Database Issues

### Database Locked

**Symptom:** "Database is locked" errors.

**Solutions:**

1. **Stop other processes:**
   ```bash
   fuser server/database/auth.db
   ```

2. **Check for zombie processes:**
   ```bash
   ps aux | grep node
   ```

3. **Delete lock file if exists:**
   ```bash
   rm server/database/auth.db-journal
   ```

### Database Corruption

**Symptom:** Queries fail or return unexpected results.

**Solutions:**

1. **Check database integrity:**
   ```bash
   sqlite3 server/database/auth.db "PRAGMA integrity_check;"
   ```

2. **Export and reimport:**
   ```bash
   sqlite3 server/database/auth.db ".dump" > backup.sql
   sqlite3 new-auth.db < backup.sql
   mv new-auth.db server/database/auth.db
   ```

3. **Start fresh:**
   ```bash
   rm server/database/auth.db
   # Database recreated on next start
   ```

---

## Performance Issues

### Slow Page Load

**Solutions:**

1. **Check build is production:**
   ```bash
   npm run build
   npm run server  # Serves optimized build
   ```

2. **Check for large session files**
3. **Clear browser cache**

### High Memory Usage

**Solutions:**

1. **Check for memory leaks in DevTools**
2. **Limit chat history display**
3. **Close unused terminal sessions**

### Slow File Tree

**Solutions:**

1. **Large directories take time to load**
2. **Add paths to `.gitignore` style exclusions**
3. **Check for node_modules in project**

---

## Getting Help

If issues persist:

1. **Check server logs** for detailed error messages
2. **Check browser console** for frontend errors
3. **Report issues** at [GitHub Issues](https://github.com/Flopsstuff/ccui/issues)

Include:
- Node.js version
- Operating system
- Error messages
- Steps to reproduce

## See Also

- [Getting Started](./getting-started.md) - Initial setup
- [Configuration](./configuration.md) - Environment variables
- [CLI Reference](./cli.md) - Command-line options
