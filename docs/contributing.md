# Contributing Guide

Thank you for your interest in contributing to AI Code UI! This guide will help you get started.

## Getting Started

### Prerequisites

- Node.js 20.x or later
- npm 10.x or later
- Git

### Setup

1. **Fork and clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/claude-code-ui.git
   cd claude-code-ui
   ```

2. **Install dependencies**
   ```bash
   npm ci
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

5. **Verify setup**
   - Backend: http://localhost:3001
   - Frontend: http://localhost:5173

## Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/add-new-provider` - New features
- `fix/websocket-reconnection` - Bug fixes
- `docs/update-api-reference` - Documentation
- `refactor/simplify-auth` - Refactoring

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting (no code change)
- `refactor` - Code restructuring
- `test` - Adding tests
- `chore` - Maintenance

Examples:
```
feat(providers): add support for GPT-5

fix(websocket): handle reconnection on network change

docs(api): add authentication section to API reference
```

### Code Style

Follow existing patterns in the codebase:

**JavaScript/JSX:**
- 2-space indentation
- Single quotes for strings
- No semicolons (consistent with codebase)
- Arrow functions for components

**Example component:**
```jsx
import { useState, useEffect } from 'react'

export function MyComponent({ prop1, prop2 }) {
  const [state, setState] = useState(null)

  useEffect(() => {
    // Effect logic
  }, [prop1])

  return (
    <div className="my-component">
      {/* Component JSX */}
    </div>
  )
}
```

**Backend:**
```javascript
// ES modules
import express from 'express'
import { someFunction } from './utils.js'

export async function handler(req, res) {
  try {
    const result = await someFunction(req.body)
    res.json(result)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
}
```

## Making Changes

### Adding a New Feature

1. **Plan the feature**
   - Discuss in an issue first for large features
   - Consider backward compatibility
   - Think about testing strategy

2. **Implement**
   - Follow existing patterns
   - Update related documentation
   - Add comments for complex logic

3. **Test locally**
   ```bash
   npm run dev
   npm run build
   ```

4. **Submit PR**
   - Write clear description
   - Reference related issues
   - Include screenshots for UI changes

### Fixing a Bug

1. **Reproduce the bug**
   - Document steps to reproduce
   - Identify root cause

2. **Write fix**
   - Keep changes minimal
   - Don't fix unrelated issues in same PR

3. **Verify fix**
   - Test the specific scenario
   - Check for regressions

### Adding a New AI Provider

See [Providers Guide](./providers.md#adding-a-new-provider) for detailed steps.

Quick checklist:
- [ ] Create `server/your-provider.js`
- [ ] Add WebSocket handler in `server/index.js`
- [ ] Add models to `shared/modelConstants.js`
- [ ] Add discovery in `server/projects.js`
- [ ] Update frontend components
- [ ] Add documentation

## Code Organization

### Backend Structure

```
server/
├── index.js          # Entry point - routes, WebSocket, middleware
├── your-feature.js   # Feature modules
├── routes/           # API route handlers
│   └── your-route.js
├── database/
│   └── db.js         # Database operations
├── middleware/
│   └── auth.js       # Authentication
└── utils/
    └── helper.js     # Utility functions
```

### Frontend Structure

```
src/
├── components/       # React components
│   ├── Feature.jsx   # Feature component
│   └── ui/           # Reusable UI components
├── contexts/         # React contexts
├── hooks/            # Custom hooks
└── utils/            # Utility functions
```

### Shared Code

```
shared/
└── modelConstants.js # Shared between frontend and backend
```

Keep this file synchronized when adding models.

## Testing

### Manual Testing

Before submitting:

1. **Test affected features**
   - New functionality works
   - Existing features aren't broken

2. **Test in different scenarios**
   - Different browsers (Chrome, Firefox, Safari)
   - Different screen sizes
   - With/without authentication

3. **Build verification**
   ```bash
   npm run build
   npm start
   ```

### Future: Automated Testing

When tests are added:

```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.js

# Run with coverage
npm test -- --coverage
```

## Pull Request Process

### Before Submitting

- [ ] Code follows project style
- [ ] Local build succeeds (`npm run build`)
- [ ] Changes are tested manually
- [ ] Documentation is updated if needed
- [ ] Commit messages follow convention

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring

## Related Issues
Fixes #123

## Testing Done
- Tested X scenario
- Verified Y works

## Screenshots (if UI changes)
[Add screenshots]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Updated documentation
- [ ] No new warnings
```

### Review Process

1. Submit PR
2. Automated checks run
3. Maintainer reviews code
4. Address feedback
5. Merge when approved

## Documentation

### When to Update Docs

- Adding new features
- Changing API endpoints
- Modifying configuration
- Updating dependencies

### Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `CLAUDE.md` | AI assistant guide |
| `docs/` | Detailed documentation |

### Documentation Style

- Use clear, concise language
- Include code examples
- Add tables for structured data
- Use proper markdown formatting

## Common Tasks

### Adding an API Endpoint

1. Create route handler in `server/routes/`
2. Add route in `server/index.js`
3. Add client method in `src/utils/api.js`
4. Update `docs/api-reference.md`

### Adding a Component

1. Create component in `src/components/`
2. Use existing patterns for styling
3. Add to parent component
4. Document props if complex

### Updating Database Schema

1. Add migration in `server/database/db.js`
2. Update schema documentation
3. Test migration on fresh and existing databases

### Adding Environment Variable

1. Add to `.env.example` with description
2. Document in `docs/configuration.md`
3. Add default value handling in code

## Getting Help

- **Questions**: Open a discussion or issue
- **Bugs**: Open an issue with reproduction steps
- **Features**: Open an issue to discuss first

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! Your help makes this project better for everyone.
