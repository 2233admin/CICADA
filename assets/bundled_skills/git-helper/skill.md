---
name: git-helper
description: Generate clear, conventional commit messages and manage Git workflows
allowed-tools: ["Bash", "Read", "Grep"]
origin: bundled
version: 1.0.0
---

# Git Helper

Generate clear, conventional commit messages and assist with Git workflows following best practices.

## When to Activate

### Explicit Triggers
- User says "commit this"
- User says "生成提交信息"
- User says "write commit message"
- User says "git commit"

### Implicit Triggers
- User completes changes and mentions committing
- User asks about Git workflow
- User needs help with commit messages

### NOT Activated For
- Git configuration setup
- Merge conflict resolution
- Branch management (unless commit-related)

## Commit Message Format

### Conventional Commits Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code restructuring without behavior change
- **docs**: Documentation changes
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build config)
- **perf**: Performance improvements
- **ci**: CI/CD configuration changes
- **style**: Code formatting (no logic change)

### Examples

**Good Commit Messages:**

```
feat(auth): add JWT token refresh mechanism

Implement automatic token refresh when access token expires.
Tokens are refreshed 5 minutes before expiration to prevent
authentication failures during active sessions.

- Add RefreshTokenService
- Update AuthMiddleware to handle token refresh
- Add unit tests for refresh logic

Closes #123
```

```
fix(api): prevent SQL injection in user search

Replace string concatenation with parameterized queries
in UserRepository.search() method.

BREAKING CHANGE: search() now requires SearchParams object
instead of raw string query.
```

```
refactor(utils): extract retry logic into separate module

Move retry logic from multiple services into shared
RetryHelper utility to reduce code duplication.
```

**Bad Commit Messages:**

```
update stuff
```

```
fix bug
```

```
WIP
```

## Commit Message Guidelines

### Subject Line (First Line)
- **Length**: 50 characters or less
- **Capitalization**: Lowercase type, lowercase subject
- **Tense**: Imperative mood ("add" not "added" or "adds")
- **No period**: Don't end with a period

### Body (Optional)
- **Length**: Wrap at 72 characters
- **Content**: Explain WHAT and WHY, not HOW
- **Bullet points**: Use `-` or `*` for lists

### Footer (Optional)
- **Breaking changes**: `BREAKING CHANGE: description`
- **Issue references**: `Closes #123`, `Fixes #456`
- **Co-authors**: `Co-authored-by: Name <email>`

## Git Workflow Best Practices

### Before Committing

1. **Review changes**
```bash
git status
git diff
```

2. **Stage selectively**
```bash
git add -p  # Interactive staging
git add specific-file.ts
```

3. **Run tests**
```bash
npm test
# or language-specific test command
```

4. **Check linting**
```bash
npm run lint
# or language-specific linter
```

### Commit Checklist

- [ ] Changes are logically grouped
- [ ] Tests pass
- [ ] Linting passes
- [ ] No debug code or console.logs
- [ ] No commented-out code
- [ ] Commit message follows conventions
- [ ] Commit is atomic (one logical change)

### Atomic Commits

**Good: One logical change per commit**
```bash
git commit -m "feat(auth): add login endpoint"
git commit -m "test(auth): add login endpoint tests"
git commit -m "docs(auth): document login API"
```

**Bad: Multiple unrelated changes**
```bash
git commit -m "add login, fix bug in profile, update README"
```

## Common Git Operations

### Amend Last Commit
```bash
# Fix commit message
git commit --amend -m "new message"

# Add forgotten files
git add forgotten-file.ts
git commit --amend --no-edit
```

### Interactive Rebase
```bash
# Clean up last 3 commits
git rebase -i HEAD~3

# Options: pick, reword, squash, fixup, drop
```

### Stash Changes
```bash
# Save work in progress
git stash save "WIP: feature description"

# List stashes
git stash list

# Apply stash
git stash pop
```

### Cherry-pick
```bash
# Apply specific commit to current branch
git cherry-pick <commit-hash>
```

## Branch Naming Conventions

**Format:** `<type>/<short-description>`

**Examples:**
- `feat/user-authentication`
- `fix/login-validation-bug`
- `refactor/database-layer`
- `docs/api-documentation`

## Pull Request Workflow

### Before Creating PR

1. **Update from main**
```bash
git checkout main
git pull
git checkout feature-branch
git rebase main
```

2. **Squash if needed**
```bash
git rebase -i main
```

3. **Push to remote**
```bash
git push origin feature-branch
# or if rebased
git push --force-with-lease origin feature-branch
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Changes
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Related Issues
Closes #123
```

## Commit Message Generation Process

1. **Analyze changes**
   - Read `git diff --staged`
   - Identify modified files and functions
   - Understand the purpose of changes

2. **Determine type**
   - New feature → `feat`
   - Bug fix → `fix`
   - Refactoring → `refactor`
   - etc.

3. **Identify scope**
   - Module/component affected
   - Keep it short and clear

4. **Write subject**
   - Imperative mood
   - Clear and concise
   - Under 50 characters

5. **Add body if needed**
   - Explain complex changes
   - Provide context
   - List major modifications

## Related Resources

- Follow conventional commits specification
- Keep commits atomic and focused
- Write clear, descriptive messages
- Use interactive rebase to clean history before PR
