# Frontend Architecture

This document describes the React frontend architecture of AI Code UI.

## Technology Stack

- **React** 18.2 - UI library
- **Vite** 7.0 - Build tool and dev server
- **Tailwind CSS** 3.4 - Utility-first CSS
- **React Router** 6.8 - Client-side routing
- **CodeMirror** 6 - Code editor
- **xterm.js** 5.5 - Terminal emulator

## Directory Structure

```
src/
├── main.jsx              # Application entry point
├── App.jsx               # Root component
├── index.css             # Global styles
│
├── components/           # React components
│   ├── ChatInterface.jsx # Main chat UI
│   ├── Sidebar.jsx       # Navigation sidebar
│   ├── Settings.jsx      # Settings panel
│   ├── FileTree.jsx      # File browser
│   ├── CodeEditor.jsx    # Code editor
│   ├── Shell.jsx         # Terminal
│   ├── GitPanel.jsx      # Git operations
│   ├── MainContent.jsx   # Content router
│   └── ui/               # Reusable UI components
│
├── contexts/             # React contexts
│   ├── AuthContext.jsx
│   ├── WebSocketContext.jsx
│   ├── ThemeContext.jsx
│   └── TaskMasterContext.jsx
│
├── hooks/                # Custom hooks
│   ├── useLocalStorage.jsx
│   ├── useAudioRecorder.js
│   └── useVersionCheck.js
│
└── utils/                # Utility functions
    ├── api.js            # REST API client
    ├── websocket.js      # WebSocket hook
    └── whisper.js        # Audio transcription
```

## Component Hierarchy

```
App.jsx
├── AuthProvider
│   └── ThemeProvider
│       └── WebSocketProvider
│           └── TaskMasterProvider
│               └── TasksSettingsProvider
│                   └── Router
│                       ├── /login → Login
│                       ├── /register → Register
│                       ├── /onboarding → Onboarding
│                       └── / → MainLayout
│                           ├── Sidebar
│                           │   ├── ProjectList
│                           │   ├── SessionList
│                           │   └── QuickSettings
│                           └── MainContent
│                               ├── ChatInterface
│                               ├── FileTree + CodeEditor
│                               ├── Shell
│                               ├── GitPanel
│                               └── TaskList
```

## Core Components

### App.jsx (974 lines)

Root component responsibilities:
- Provider composition
- Routing setup
- Project/session state management
- Session protection system
- Version checking

```jsx
function App() {
  const [selectedProject, setSelectedProject] = useState(null);
  const [selectedSession, setSelectedSession] = useState(null);
  const [isSessionActive, setIsSessionActive] = useState(false);

  return (
    <AuthProvider>
      <ThemeProvider>
        <WebSocketProvider>
          <TaskMasterProvider>
            <Router>
              <Routes>
                <Route path="/login" element={<Login />} />
                <Route path="/" element={
                  <ProtectedRoute>
                    <MainLayout
                      selectedProject={selectedProject}
                      selectedSession={selectedSession}
                      // ...
                    />
                  </ProtectedRoute>
                } />
              </Routes>
            </Router>
          </TaskMasterProvider>
        </WebSocketProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}
```

### ChatInterface.jsx (5,614 lines)

Main chat interface features:
- Message rendering (text, code, tools)
- Streaming response display
- Tool approval UI
- Token usage tracking
- Message input with keyboard shortcuts
- File attachments
- Voice input (Whisper)

Key state:
```jsx
const [messages, setMessages] = useState([]);
const [isStreaming, setIsStreaming] = useState(false);
const [pendingApprovals, setPendingApprovals] = useState([]);
const [tokenUsage, setTokenUsage] = useState(null);
```

### Sidebar.jsx (~1,800 lines)

Navigation sidebar features:
- Project list with provider grouping
- Session list per project
- Search/filter functionality
- Project creation/import
- Session management (create, delete, rename)

### FileTree.jsx (~1,200 lines)

File browser features:
- Recursive directory tree
- File selection and preview
- Context menu (create, rename, delete)
- Drag and drop
- Integration with CodeEditor

### CodeEditor.jsx (~600 lines)

Code editor features:
- Syntax highlighting (multiple languages)
- Line numbers
- Auto-save
- File change detection
- Multiple themes

Languages supported:
- JavaScript/TypeScript
- Python
- HTML/CSS
- JSON
- Markdown
- And more via CodeMirror

### Shell.jsx (~400 lines)

Terminal emulator features:
- Interactive PTY session
- WebSocket communication
- Terminal resizing
- Copy/paste support
- Custom styling

### GitPanel.jsx (~1,740 lines)

Git operations:
- Repository status
- File staging/unstaging
- Commit with message
- Branch management
- Push/pull
- Diff viewing
- Commit history

### Settings.jsx (~2,370 lines)

Multi-tab settings:
- General settings (theme, provider)
- Git configuration
- API keys management
- Credentials storage
- MCP servers
- Account settings

---

## State Management

### Context-Based Architecture

The application uses React Context for global state:

#### AuthContext

```jsx
const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  const login = async (username, password) => {
    const response = await api.login(username, password);
    setUser(response.user);
    localStorage.setItem('token', response.token);
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('token');
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
```

#### WebSocketContext

```jsx
const WebSocketContext = createContext();

export function WebSocketProvider({ children }) {
  const ws = useWebSocket('/ws');

  return (
    <WebSocketContext.Provider value={ws}>
      {children}
    </WebSocketContext.Provider>
  );
}

export const useWS = () => useContext(WebSocketContext);
```

#### ThemeContext

```jsx
const ThemeContext = createContext();

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useLocalStorage('theme', 'system');

  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'dark' ||
        (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}
```

#### TaskMasterContext

```jsx
const TaskMasterContext = createContext();

export function TaskMasterProvider({ children }) {
  const [projects, setProjects] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [mcpStatus, setMcpStatus] = useState('disconnected');

  // Fetch projects and tasks
  // Handle MCP connection
  // ...

  return (
    <TaskMasterContext.Provider value={{ projects, tasks, mcpStatus }}>
      {children}
    </TaskMasterContext.Provider>
  );
}
```

---

## Custom Hooks

### useLocalStorage

```jsx
function useLocalStorage(key, initialValue) {
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      return initialValue;
    }
  });

  const setValue = (value) => {
    setStoredValue(value);
    window.localStorage.setItem(key, JSON.stringify(value));
  };

  return [storedValue, setValue];
}
```

### useWebSocket

```jsx
function useWebSocket(url) {
  const [ws, setWs] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState(null);

  useEffect(() => {
    const socket = new WebSocket(url);

    socket.onopen = () => setIsConnected(true);
    socket.onclose = () => {
      setIsConnected(false);
      // Implement reconnection
    };
    socket.onmessage = (event) => {
      setLastMessage(JSON.parse(event.data));
    };

    setWs(socket);

    return () => socket.close();
  }, [url]);

  const send = useCallback((message) => {
    if (ws && isConnected) {
      ws.send(JSON.stringify(message));
    }
  }, [ws, isConnected]);

  return { isConnected, lastMessage, send };
}
```

### useVersionCheck

```jsx
function useVersionCheck() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [latestVersion, setLatestVersion] = useState(null);

  useEffect(() => {
    const checkVersion = async () => {
      const response = await fetch('/api/version');
      const { current, latest } = await response.json();

      if (semver.gt(latest, current)) {
        setUpdateAvailable(true);
        setLatestVersion(latest);
      }
    };

    checkVersion();
  }, []);

  return { updateAvailable, latestVersion };
}
```

---

## API Communication

### REST API Client

Located in `src/utils/api.js`:

```jsx
const API_BASE = '/api';

async function fetchWithAuth(url, options = {}) {
  const token = localStorage.getItem('token');

  const response = await fetch(`${API_BASE}${url}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw new Error(await response.text());
  }

  return response.json();
}

export const api = {
  // Auth
  login: (username, password) =>
    fetchWithAuth('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),

  // Projects
  getProjects: () => fetchWithAuth('/projects'),
  createProject: (path) =>
    fetchWithAuth('/projects', {
      method: 'POST',
      body: JSON.stringify({ path }),
    }),

  // Sessions
  getSessions: (projectPath) =>
    fetchWithAuth(`/projects/${encodeURIComponent(projectPath)}/sessions`),

  // Files
  getFiles: (path) => fetchWithAuth(`/files?path=${encodeURIComponent(path)}`),
  getFileContent: (path) =>
    fetchWithAuth(`/files/content?path=${encodeURIComponent(path)}`),

  // Git
  getGitStatus: (projectPath) =>
    fetchWithAuth(`/git/status?projectPath=${encodeURIComponent(projectPath)}`),

  // Settings
  getSettings: () => fetchWithAuth('/settings'),
  updateSettings: (settings) =>
    fetchWithAuth('/settings', {
      method: 'PUT',
      body: JSON.stringify(settings),
    }),
};
```

---

## Styling

### Tailwind CSS

Configuration in `tailwind.config.js`:

```javascript
module.exports = {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        // ...
      },
    },
  },
};
```

### CSS Variables

Defined in `src/index.css`:

```css
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 222.2 47.4% 11.2%;
  --primary-foreground: 210 40% 98%;
  /* ... */
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --primary: 210 40% 98%;
  --primary-foreground: 222.2 47.4% 11.2%;
  /* ... */
}
```

### Component Styling Pattern

```jsx
function Button({ variant = 'primary', size = 'md', children, ...props }) {
  const baseClasses = 'inline-flex items-center justify-center rounded-md font-medium';

  const variantClasses = {
    primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
    secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
    outline: 'border border-input bg-background hover:bg-accent',
  };

  const sizeClasses = {
    sm: 'h-8 px-3 text-sm',
    md: 'h-10 px-4',
    lg: 'h-12 px-6 text-lg',
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`}
      {...props}
    >
      {children}
    </button>
  );
}
```

---

## Build Configuration

### Vite Config

```javascript
// vite.config.js
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:3001',
      '/ws': {
        target: 'ws://localhost:3001',
        ws: true,
      },
      '/shell': {
        target: 'ws://localhost:3001',
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-codemirror': [
            '@codemirror/view',
            '@codemirror/state',
            '@codemirror/commands',
          ],
          'vendor-xterm': ['xterm', 'xterm-addon-fit'],
        },
      },
    },
  },
});
```

### Code Splitting

The build produces these chunks:
- `vendor-react.js` - React ecosystem
- `vendor-codemirror.js` - Code editor
- `vendor-xterm.js` - Terminal
- `index.js` - Application code

---

## Performance Optimization

### React.memo

```jsx
const MessageItem = React.memo(function MessageItem({ message, onAction }) {
  return (
    <div className="message">
      {/* ... */}
    </div>
  );
}, (prevProps, nextProps) => {
  return prevProps.message.id === nextProps.message.id;
});
```

### useMemo and useCallback

```jsx
function ChatInterface({ messages, onSend }) {
  const sortedMessages = useMemo(
    () => messages.sort((a, b) => a.timestamp - b.timestamp),
    [messages]
  );

  const handleSend = useCallback((text) => {
    onSend({ text, timestamp: Date.now() });
  }, [onSend]);

  return (/* ... */);
}
```

### Virtualization

For long lists (messages, files), consider virtualization:

```jsx
import { useVirtualizer } from '@tanstack/react-virtual';

function MessageList({ messages }) {
  const parentRef = useRef();

  const virtualizer = useVirtualizer({
    count: messages.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
  });

  return (
    <div ref={parentRef} className="h-full overflow-auto">
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <MessageItem
            key={virtualItem.key}
            message={messages[virtualItem.index]}
            style={{
              position: 'absolute',
              top: virtualItem.start,
              height: virtualItem.size,
            }}
          />
        ))}
      </div>
    </div>
  );
}
```

---

## Testing (Future)

Recommended testing setup:

### Unit Tests (Vitest)

```javascript
// src/utils/api.test.js
import { describe, it, expect, vi } from 'vitest';
import { api } from './api';

describe('api', () => {
  it('should fetch projects', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ projects: [] }),
    });

    const result = await api.getProjects();
    expect(result.projects).toEqual([]);
  });
});
```

### Component Tests (React Testing Library)

```javascript
// src/components/Button.test.jsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('should render children', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('should call onClick', () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click</Button>);
    fireEvent.click(screen.getByText('Click'));
    expect(onClick).toHaveBeenCalled();
  });
});
```
