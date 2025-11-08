# Contributing to SFOps

Thank you for your interest in contributing to SFOps! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/sfops.git`
3. Add upstream remote: `git remote add upstream https://github.com/original-owner/sfops.git`
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Node.js 18+ and npm 9+
- Docker and Docker Compose
- PostgreSQL 15+
- Redis 7+
- Salesforce CLI (`sf` or `sfdx`)
- Git

### Initial Setup

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# Edit .env with your configuration

# Start infrastructure services
npm run infra:up

# Run database migrations
npm run db:migrate

# Seed database (optional)
npm run db:seed

# Start development servers
npm run dev
```

### Running Individual Services

```bash
# Backend API only
npm run dev:backend

# Frontend UI only
npm run dev:frontend

# Worker processes only
npm run dev:workers
```

## Project Structure

```
sfops/
├── backend/              # Backend API service
│   ├── src/
│   │   ├── api/         # REST API routes
│   │   ├── services/    # Business logic
│   │   ├── workers/     # Background jobs
│   │   ├── middleware/  # Express middleware
│   │   ├── models/      # Database models
│   │   └── utils/       # Utilities
│   └── tests/           # Backend tests
├── frontend/            # React UI application
│   └── src/
│       ├── components/  # React components
│       ├── pages/       # Page components
│       ├── hooks/       # Custom hooks
│       └── services/    # API clients
├── cli/                 # CLI tool
├── packages/            # Shared packages
│   ├── shared/         # Common types/utils
│   ├── salesforce-client/
│   └── vault-client/
├── database/            # Database scripts
│   ├── migrations/     # SQL migrations
│   └── seeds/          # Seed data
└── infrastructure/      # IaC and configs
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/my-new-feature
# or
git checkout -b fix/bug-description
```

### 2. Make Your Changes

- Write clean, maintainable code
- Follow the coding standards
- Add tests for new functionality
- Update documentation as needed

### 3. Run Tests

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit
npm run test:integration
npm run test:e2e

# Check code coverage
npm run test:coverage
```

### 4. Lint and Format

```bash
# Check linting
npm run lint

# Auto-fix linting issues
npm run lint:fix

# Format code
npm run format

# Type check
npm run typecheck
```

### 5. Commit Your Changes

Follow the commit message guidelines below.

### 6. Push and Create PR

```bash
git push origin feature/my-new-feature
```

Then create a Pull Request on GitHub.

## Coding Standards

### TypeScript

- Use TypeScript for all new code
- Prefer interfaces over types for object shapes
- Use explicit return types for functions
- Avoid `any` type; use `unknown` if necessary

```typescript
// Good
interface User {
  id: string;
  email: string;
}

function getUser(id: string): Promise<User> {
  // implementation
}

// Avoid
function getUser(id: any): any {
  // implementation
}
```

### Naming Conventions

- **Files**: kebab-case (`user-service.ts`)
- **Classes**: PascalCase (`UserService`)
- **Functions**: camelCase (`getUserById`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)
- **Interfaces**: PascalCase (`UserInterface` or `User`)

### Code Style

- Use 2 spaces for indentation
- Use single quotes for strings
- Add trailing commas in multi-line objects/arrays
- Maximum line length: 100 characters
- Use arrow functions for callbacks

```typescript
// Good
const users = [
  { id: '1', name: 'John' },
  { id: '2', name: 'Jane' },
];

// Good
const processUser = async (user: User): Promise<void> => {
  // implementation
};
```

### Error Handling

- Always handle errors explicitly
- Use custom error classes for domain errors
- Include context in error messages

```typescript
class ValidationError extends Error {
  constructor(message: string, public field: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

try {
  await deployToOrg(deployment);
} catch (error) {
  logger.error('Deployment failed', { deploymentId, error });
  throw new DeploymentError('Failed to deploy', error);
}
```

## Testing Guidelines

### Unit Tests

- Test individual functions and classes in isolation
- Mock external dependencies
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

```typescript
describe('DeploymentService', () => {
  describe('createDeployment', () => {
    it('should create deployment with valid parameters', async () => {
      // Arrange
      const params = { orgId: '123', branch: 'main' };

      // Act
      const result = await service.createDeployment(params);

      // Assert
      expect(result).toBeDefined();
      expect(result.orgId).toBe('123');
    });
  });
});
```

### Integration Tests

- Test interactions between components
- Use test database
- Clean up after tests

### E2E Tests

- Test complete user workflows
- Use realistic test data
- Run against staging environment

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```bash
feat(deployment): add parallel validation support

Implemented concurrent validation across multiple orgs
to reduce validation time for large deployments.

Closes #123
```

```bash
fix(auth): resolve JWT token expiration issue

Fixed issue where tokens were expiring prematurely
due to incorrect timezone handling.

Fixes #456
```

## Pull Request Process

### Before Submitting

1. ✅ All tests pass
2. ✅ Code is linted and formatted
3. ✅ Documentation is updated
4. ✅ Commit messages follow conventions
5. ✅ Branch is up to date with main

### PR Template

Use this template for your PR description:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Changelog updated
```

### Review Process

1. At least one approval required
2. All CI checks must pass
3. No merge conflicts
4. Branch up to date with main

### After Merge

1. Delete your feature branch
2. Pull latest main: `git pull upstream main`
3. Update your fork: `git push origin main`

## Reporting Bugs

### Before Reporting

1. Check existing issues
2. Verify you're using the latest version
3. Collect relevant information

### Bug Report Template

```markdown
**Describe the bug**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
Add screenshots if applicable

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Node.js version: [e.g., 18.17.0]
- SFOps version: [e.g., 1.0.0]

**Additional context**
Any other relevant information
```

## Suggesting Features

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
Clear description of the problem

**Describe the solution you'd like**
Description of your proposed solution

**Describe alternatives you've considered**
Alternative solutions you've thought about

**Additional context**
Any other relevant information
```

## Questions?

- **Documentation**: Check the [docs](./docs/) folder
- **Issues**: Create an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact maintainers at support@sfops.io

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to SFOps! 🎉
