# Contributing to SFOps

Thank you for your interest in contributing to SFOps! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your feature or bugfix
4. **Make your changes** and commit them
5. **Push to your fork** and submit a pull request

## Development Setup

See the [README.md](./README.md#local-development-setup) for detailed setup instructions.

Quick start:
```bash
git clone https://github.com/yourusername/sfops.git
cd sfops
npm install
docker-compose up -d
npm run dev
```

## Coding Standards

### TypeScript

- Use TypeScript strict mode
- Provide type annotations for function parameters and return types
- Avoid `any` types - use `unknown` if type is truly unknown
- Use interfaces for object shapes, types for unions

### Code Style

- Run ESLint and Prettier before committing
- Maximum line length: 100 characters
- Use 2 spaces for indentation
- Use single quotes for strings

```bash
npm run lint
npm run format
```

### Naming Conventions

- **Files**: kebab-case (`user-service.ts`)
- **Classes**: PascalCase (`UserService`)
- **Functions**: camelCase (`getUserById`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`)
- **Interfaces**: PascalCase with 'I' prefix optional (`User` or `IUser`)

## Testing

### Unit Tests

- Write unit tests for all new code
- Aim for 80%+ code coverage
- Use descriptive test names

```typescript
describe('UserService', () => {
  describe('getUserById', () => {
    it('should return user when user exists', async () => {
      // Arrange
      const userId = '123';
      // Act
      const user = await userService.getUserById(userId);
      // Assert
      expect(user).toBeDefined();
      expect(user.id).toBe(userId);
    });

    it('should return null when user does not exist', async () => {
      const user = await userService.getUserById('nonexistent');
      expect(user).toBeNull();
    });
  });
});
```

### Integration Tests

- Test interactions between components
- Use test database (not production!)
- Clean up test data after each test

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- user-service.test.ts

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

## Pull Request Process

### Before Submitting

- [ ] Tests pass (`npm test`)
- [ ] Linting passes (`npm run lint`)
- [ ] Code is formatted (`npm run format`)
- [ ] Documentation updated if needed
- [ ] Commit messages follow convention (see below)

### PR Description

Include:
1. **What**: Summary of changes
2. **Why**: Motivation and context
3. **How**: Brief description of implementation
4. **Testing**: How you tested the changes
5. **Screenshots**: If UI changes

Example:
```markdown
## What
Add snapshot comparison feature

## Why
Users need to compare snapshots to understand what changed between deployments

## How
- Added new API endpoint `/api/v1/tenants/:id/snapshots/compare`
- Implemented diff algorithm using levenshtein distance
- Added React component for displaying diffs

## Testing
- Unit tests for diff algorithm
- Integration test for API endpoint
- Manual testing with sample orgs

## Screenshots
[Screenshot of diff view]
```

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semicolons, etc)
- `refactor`: Code refactor
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(api): add snapshot comparison endpoint

Add POST /api/v1/tenants/:id/snapshots/compare to compare two snapshots.
Returns a detailed diff showing added, modified, and deleted components.

Closes #123
```

```
fix(workers): resolve deployment timeout issue

Increase Temporal workflow timeout from 30m to 60m to handle large deployments.
Add progress logging every 5 minutes to track deployment status.

Fixes #456
```

## Review Process

1. **Automated checks** must pass (CI/CD pipeline)
2. **Code review** by at least one maintainer
3. **Manual testing** if UI changes
4. **Approval** required before merge

## Types of Contributions

### Bug Reports

- Use GitHub Issues
- Provide clear title and description
- Include steps to reproduce
- Add logs, screenshots if applicable
- Specify environment (OS, Node version, etc)

### Feature Requests

- Use GitHub Issues
- Describe the problem you're trying to solve
- Provide use cases
- Suggest possible solutions

### Documentation

- Fix typos
- Improve clarity
- Add examples
- Update outdated information

### Code Contributions

- Bug fixes
- New features
- Performance improvements
- Refactoring

## Questions?

- **Documentation**: Check [README.md](./README.md) and [docs/](./docs/)
- **Slack**: Join our community at sfops-community.slack.com
- **GitHub Discussions**: For general questions
- **Email**: dev@sfops.io

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
