# Database Reference

AI Code UI uses SQLite for persistent storage. This document describes the database schema and operations.

## Overview

- **Database Engine**: SQLite 3 (via better-sqlite3)
- **Location**: Configured by `DATABASE_PATH` environment variable
- **Default**: `./server/database/auth.db`

## Schema

### users

Stores user accounts and preferences.

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  git_name TEXT,
  git_email TEXT,
  has_completed_onboarding INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  last_login TEXT
);
```

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key |
| `username` | TEXT | Unique username |
| `password_hash` | TEXT | bcrypt hashed password |
| `git_name` | TEXT | Git commit author name |
| `git_email` | TEXT | Git commit author email |
| `has_completed_onboarding` | INTEGER | 0 or 1 |
| `created_at` | TEXT | ISO timestamp |
| `last_login` | TEXT | ISO timestamp |

### api_keys

Stores user-generated API keys for external access.

```sql
CREATE TABLE api_keys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  key_name TEXT NOT NULL,
  api_key TEXT NOT NULL UNIQUE,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  last_used TEXT,
  is_active INTEGER DEFAULT 1,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key |
| `user_id` | INTEGER | Foreign key to users |
| `key_name` | TEXT | User-defined name |
| `api_key` | TEXT | Generated API key |
| `created_at` | TEXT | ISO timestamp |
| `last_used` | TEXT | Last usage timestamp |
| `is_active` | INTEGER | 0 or 1 |

### user_credentials

Stores third-party credentials (tokens, keys).

```sql
CREATE TABLE user_credentials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  credential_name TEXT NOT NULL,
  credential_type TEXT NOT NULL,
  credential_value TEXT NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  is_active INTEGER DEFAULT 1,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key |
| `user_id` | INTEGER | Foreign key to users |
| `credential_name` | TEXT | Display name |
| `credential_type` | TEXT | Type (token, api_key, etc.) |
| `credential_value` | TEXT | The actual credential |
| `description` | TEXT | User description |
| `created_at` | TEXT | ISO timestamp |
| `is_active` | INTEGER | 0 or 1 |

---

## Database Operations

### Location

All database operations are in `server/database/db.js`.

### Initialization

```javascript
import Database from 'better-sqlite3';

const db = new Database(process.env.DATABASE_PATH || './server/database/auth.db');

// Enable WAL mode for better concurrency
db.pragma('journal_mode = WAL');

// Create tables if they don't exist
db.exec(`
  CREATE TABLE IF NOT EXISTS users (...)
  CREATE TABLE IF NOT EXISTS api_keys (...)
  CREATE TABLE IF NOT EXISTS user_credentials (...)
`);
```

### User Operations

```javascript
// Create user
export function createUser(username, passwordHash) {
  const stmt = db.prepare(`
    INSERT INTO users (username, password_hash)
    VALUES (?, ?)
  `);
  return stmt.run(username, passwordHash);
}

// Get user by username
export function getUserByUsername(username) {
  const stmt = db.prepare(`
    SELECT * FROM users WHERE username = ?
  `);
  return stmt.get(username);
}

// Get user by ID
export function getUserById(id) {
  const stmt = db.prepare(`
    SELECT * FROM users WHERE id = ?
  `);
  return stmt.get(id);
}

// Update user
export function updateUser(id, updates) {
  const fields = Object.keys(updates)
    .map(key => `${key} = ?`)
    .join(', ');
  const values = Object.values(updates);

  const stmt = db.prepare(`
    UPDATE users SET ${fields} WHERE id = ?
  `);
  return stmt.run(...values, id);
}

// Update last login
export function updateLastLogin(id) {
  const stmt = db.prepare(`
    UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?
  `);
  return stmt.run(id);
}
```

### API Key Operations

```javascript
// Create API key
export function createApiKey(userId, keyName, apiKey) {
  const stmt = db.prepare(`
    INSERT INTO api_keys (user_id, key_name, api_key)
    VALUES (?, ?, ?)
  `);
  return stmt.run(userId, keyName, apiKey);
}

// Get user's API keys
export function getApiKeys(userId) {
  const stmt = db.prepare(`
    SELECT id, key_name, created_at, last_used, is_active
    FROM api_keys
    WHERE user_id = ? AND is_active = 1
  `);
  return stmt.all(userId);
}

// Validate API key
export function validateApiKey(apiKey) {
  const stmt = db.prepare(`
    SELECT u.* FROM users u
    JOIN api_keys ak ON u.id = ak.user_id
    WHERE ak.api_key = ? AND ak.is_active = 1
  `);
  const user = stmt.get(apiKey);

  if (user) {
    // Update last used
    db.prepare(`
      UPDATE api_keys SET last_used = CURRENT_TIMESTAMP
      WHERE api_key = ?
    `).run(apiKey);
  }

  return user;
}

// Delete API key
export function deleteApiKey(id, userId) {
  const stmt = db.prepare(`
    DELETE FROM api_keys WHERE id = ? AND user_id = ?
  `);
  return stmt.run(id, userId);
}
```

### Credential Operations

```javascript
// Create credential
export function createCredential(userId, name, type, value, description) {
  const stmt = db.prepare(`
    INSERT INTO user_credentials
    (user_id, credential_name, credential_type, credential_value, description)
    VALUES (?, ?, ?, ?, ?)
  `);
  return stmt.run(userId, name, type, value, description);
}

// Get user's credentials
export function getCredentials(userId) {
  const stmt = db.prepare(`
    SELECT id, credential_name, credential_type, description, created_at, is_active
    FROM user_credentials
    WHERE user_id = ? AND is_active = 1
  `);
  return stmt.all(userId);
}

// Get credential value
export function getCredentialValue(id, userId) {
  const stmt = db.prepare(`
    SELECT credential_value
    FROM user_credentials
    WHERE id = ? AND user_id = ? AND is_active = 1
  `);
  return stmt.get(id, userId)?.credential_value;
}

// Delete credential
export function deleteCredential(id, userId) {
  const stmt = db.prepare(`
    DELETE FROM user_credentials WHERE id = ? AND user_id = ?
  `);
  return stmt.run(id, userId);
}
```

---

## Migrations

Migrations are handled in the `runMigrations()` function in `db.js`.

### Adding a Migration

```javascript
function runMigrations() {
  // Check if column exists
  const columns = db.pragma('table_info(users)');
  const hasNewColumn = columns.some(c => c.name === 'new_column');

  if (!hasNewColumn) {
    db.exec(`ALTER TABLE users ADD COLUMN new_column TEXT`);
    console.log('Migration: Added new_column to users');
  }
}
```

### Migration Best Practices

1. Check if migration is needed before running
2. Use transactions for multi-statement migrations
3. Log migration completion
4. Handle errors gracefully

```javascript
function runMigrations() {
  const migrations = [
    {
      name: 'add_theme_preference',
      check: () => {
        const cols = db.pragma('table_info(users)');
        return cols.some(c => c.name === 'theme');
      },
      run: () => {
        db.exec(`ALTER TABLE users ADD COLUMN theme TEXT DEFAULT 'system'`);
      }
    },
    // Add more migrations here
  ];

  for (const migration of migrations) {
    if (!migration.check()) {
      try {
        migration.run();
        console.log(`Migration completed: ${migration.name}`);
      } catch (error) {
        console.error(`Migration failed: ${migration.name}`, error);
      }
    }
  }
}
```

---

## Direct Database Access

### CLI Access

```bash
# Open database
sqlite3 server/database/auth.db

# List tables
.tables

# Show schema
.schema users

# Query users
SELECT id, username, git_name, created_at FROM users;

# Exit
.quit
```

### Useful Queries

```sql
-- List all users
SELECT id, username, git_name, git_email, has_completed_onboarding, created_at
FROM users;

-- List API keys with user info
SELECT u.username, ak.key_name, ak.created_at, ak.last_used
FROM api_keys ak
JOIN users u ON ak.user_id = u.id
WHERE ak.is_active = 1;

-- Count credentials by type
SELECT credential_type, COUNT(*) as count
FROM user_credentials
WHERE is_active = 1
GROUP BY credential_type;

-- Find users who haven't completed onboarding
SELECT username, created_at
FROM users
WHERE has_completed_onboarding = 0;
```

---

## Backup and Restore

### Backup

```bash
# Copy database file
cp server/database/auth.db server/database/auth.db.backup

# Or use SQLite backup command
sqlite3 server/database/auth.db ".backup server/database/auth.db.backup"

# Export to SQL
sqlite3 server/database/auth.db .dump > backup.sql
```

### Restore

```bash
# From file copy
cp server/database/auth.db.backup server/database/auth.db

# From SQL dump
sqlite3 server/database/auth.db < backup.sql
```

---

## Security Considerations

### Current State

- Passwords are bcrypt hashed
- API keys are stored in plaintext
- Credentials are stored in plaintext

### Recommended Improvements

1. **Encrypt credentials at rest**
```javascript
import crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

function decrypt(text) {
  const [ivHex, encrypted] = text.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}
```

2. **Add JWT expiration**
```javascript
// In auth.js
const token = jwt.sign(
  { id: user.id, username: user.username },
  JWT_SECRET,
  { expiresIn: '7d' }
);
```

3. **Add audit logging**
```sql
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  action TEXT NOT NULL,
  details TEXT,
  ip_address TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## Performance

### WAL Mode

The database uses WAL (Write-Ahead Logging) for better concurrent access:

```javascript
db.pragma('journal_mode = WAL');
```

### Indexes

Consider adding indexes for frequently queried columns:

```sql
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_api_key ON api_keys(api_key);
CREATE INDEX idx_credentials_user_id ON user_credentials(user_id);
```

### Connection Pooling

better-sqlite3 uses synchronous operations, so connection pooling isn't needed. For high-concurrency scenarios, consider:

1. Using a different database (PostgreSQL)
2. Implementing request queuing
3. Using read replicas
