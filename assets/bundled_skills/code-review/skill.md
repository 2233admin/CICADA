---
name: code-review
description: Comprehensive code review focusing on quality, security, and best practices
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
origin: bundled
version: 1.0.0
---

# Code Review

Systematic code review that identifies issues in quality, security, performance, and maintainability.

## When to Activate

### Explicit Triggers
- User says "review this code"
- User says "帮我审查代码"
- User says "code review"
- User says "check my code"

### Implicit Triggers
- User asks "is this code good?"
- User completes a feature and asks for feedback
- User mentions concerns about code quality

### NOT Activated For
- Simple syntax questions
- Documentation-only changes
- Configuration file edits (unless security-sensitive)

## Review Checklist

### 1. Code Quality
- **Readability**: Clear variable/function names, appropriate comments
- **Complexity**: Functions < 50 lines, files < 800 lines, nesting < 4 levels
- **DRY Principle**: No duplicated logic
- **Single Responsibility**: Each function/class does one thing

### 2. Security
- **Input Validation**: All user inputs validated
- **SQL Injection**: Parameterized queries used
- **XSS Prevention**: HTML sanitized
- **Secrets**: No hardcoded API keys, passwords, tokens
- **Authentication**: Proper auth/authz checks

### 3. Error Handling
- **Comprehensive**: All errors caught and handled
- **User-Friendly**: Clear error messages for users
- **Logging**: Detailed error context logged
- **No Silent Failures**: Never swallow errors

### 4. Testing
- **Coverage**: 80%+ test coverage
- **Test Quality**: Tests are clear, isolated, and meaningful
- **Edge Cases**: Boundary conditions tested

### 5. Performance
- **Algorithms**: Efficient algorithms used (avoid O(n²) when O(n) possible)
- **Database**: Proper indexes, avoid N+1 queries
- **Caching**: Appropriate caching for expensive operations
- **Resource Cleanup**: Connections/files properly closed

## Review Process

1. **Read the code** - Understand what it does
2. **Check against checklist** - Systematically review each category
3. **Prioritize issues** - CRITICAL > HIGH > MEDIUM > LOW
4. **Provide examples** - Show how to fix issues
5. **Suggest improvements** - Offer better alternatives

## Issue Severity Levels

- **CRITICAL**: Security vulnerabilities, data loss risks
- **HIGH**: Bugs, major performance issues, broken functionality
- **MEDIUM**: Code quality issues, minor performance problems
- **LOW**: Style inconsistencies, minor improvements

## Example Review Output

```markdown
## Code Review Results

### CRITICAL Issues (0)
None found.

### HIGH Issues (1)
1. **SQL Injection Risk** (line 45)
   - Current: `query = "SELECT * FROM users WHERE id = " + userId`
   - Fix: Use parameterized query: `query("SELECT * FROM users WHERE id = ?", [userId])`

### MEDIUM Issues (2)
1. **Function Too Long** (line 100-180)
   - `processUserData()` is 80 lines, should be < 50
   - Suggest: Extract validation, transformation, and saving into separate functions

2. **Missing Error Handling** (line 200)
   - `await fetchData()` not wrapped in try-catch
   - Add error handling to prevent unhandled promise rejection

### LOW Issues (1)
1. **Variable Naming** (line 30)
   - `d` is unclear, rename to `userData` or `userDetails`
```

## Best Practices

- **Be Constructive**: Focus on improvement, not criticism
- **Explain Why**: Don't just point out issues, explain the reasoning
- **Provide Examples**: Show concrete fixes, not just descriptions
- **Prioritize**: Focus on critical/high issues first
- **Be Specific**: Reference exact line numbers and code snippets

## Related Resources

- Security guidelines: Check for OWASP Top 10 vulnerabilities
- Testing standards: Ensure 80%+ coverage
- Code style: Follow language-specific conventions
