---
name: test-helper
description: Generate comprehensive test cases following TDD principles
allowed-tools: ["Read", "Write", "Bash", "Grep"]
origin: bundled
version: 1.0.0
---

# Test Helper

Generate high-quality test cases following Test-Driven Development (TDD) principles and best practices.

## When to Activate

### Explicit Triggers
- User says "write tests"
- User says "生成测试"
- User says "create test cases"
- User says "help me test this"

### Implicit Triggers
- User implements a new feature without tests
- User asks about test coverage
- User mentions TDD or testing

### NOT Activated For
- Running existing tests (use test runner directly)
- Debugging test failures (use debugging tools)
- Test configuration setup

## Testing Principles

### 1. Test-Driven Development (TDD)
**Always write tests BEFORE implementation:**
1. **RED**: Write a failing test
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Clean up while keeping tests green

### 2. Test Coverage Target
- **Minimum**: 80% code coverage
- **Focus**: Critical paths, edge cases, error conditions
- **Exclude**: Generated code, trivial getters/setters

### 3. Test Quality
- **Isolated**: Each test independent
- **Clear**: Descriptive names, obvious intent
- **Fast**: Run quickly, no unnecessary delays
- **Reliable**: No flaky tests, deterministic results

## Test Types

### Unit Tests
Test individual functions/methods in isolation.

```typescript
describe('retryOperation', () => {
  it('should retry failed operations up to 3 times', async () => {
    let attempts = 0;
    const operation = () => {
      attempts++;
      if (attempts < 3) throw new Error('fail');
      return 'success';
    };

    const result = await retryOperation(operation);

    expect(result).toBe('success');
    expect(attempts).toBe(3);
  });

  it('should throw error after max retries exceeded', async () => {
    const operation = () => {
      throw new Error('persistent failure');
    };

    await expect(retryOperation(operation)).rejects.toThrow('persistent failure');
  });

  it('should return immediately on first success', async () => {
    let attempts = 0;
    const operation = () => {
      attempts++;
      return 'success';
    };

    await retryOperation(operation);

    expect(attempts).toBe(1);
  });
});
```

### Integration Tests
Test interactions between components.

```typescript
describe('UserService', () => {
  let db: Database;
  let userService: UserService;

  beforeEach(async () => {
    db = await createTestDatabase();
    userService = new UserService(db);
  });

  afterEach(async () => {
    await db.close();
  });

  it('should create user and store in database', async () => {
    const userData = {
      email: 'test@example.com',
      name: 'Test User'
    };

    const user = await userService.createUser(userData);

    expect(user.id).toBeDefined();
    expect(user.email).toBe(userData.email);

    const stored = await db.users.findById(user.id);
    expect(stored).toEqual(user);
  });
});
```

### End-to-End Tests
Test complete user workflows.

```typescript
describe('User Registration Flow', () => {
  it('should allow new user to register and login', async () => {
    // Register
    const response = await request(app)
      .post('/api/register')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePass123!',
        name: 'New User'
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);

    // Login
    const loginResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePass123!'
      });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.token).toBeDefined();
  });
});
```

## Test Structure (AAA Pattern)

```typescript
it('should do something specific', () => {
  // Arrange - Set up test data and conditions
  const input = 'test data';
  const expected = 'expected result';

  // Act - Execute the code under test
  const result = functionUnderTest(input);

  // Assert - Verify the result
  expect(result).toBe(expected);
});
```

## Edge Cases to Test

### 1. Boundary Conditions
- Empty inputs ([], "", null, undefined)
- Maximum/minimum values
- Off-by-one errors

### 2. Error Conditions
- Invalid inputs
- Network failures
- Database errors
- Timeout scenarios

### 3. Concurrent Operations
- Race conditions
- Deadlocks
- Resource contention

### 4. State Transitions
- Valid state changes
- Invalid state changes
- Idempotency

## Test Naming Conventions

**Good Names:**
- `should return user when valid ID provided`
- `should throw error when email already exists`
- `should retry 3 times before failing`

**Bad Names:**
- `test1`
- `it works`
- `user test`

## Mocking Best Practices

### When to Mock
- External APIs
- Database connections
- File system operations
- Time-dependent code

### When NOT to Mock
- Simple functions
- Internal logic
- Data structures

```typescript
// Good: Mock external API
const mockFetch = jest.fn().mockResolvedValue({
  json: () => Promise.resolve({ data: 'test' })
});

// Bad: Over-mocking internal logic
const mockAdd = jest.fn((a, b) => a + b); // Just test the real function!
```

## Test Coverage Checklist

- [ ] All public functions tested
- [ ] Happy path covered
- [ ] Error conditions tested
- [ ] Edge cases handled
- [ ] Integration points verified
- [ ] 80%+ code coverage achieved
- [ ] All tests passing
- [ ] No flaky tests

## Common Testing Frameworks

### JavaScript/TypeScript
- Jest, Vitest, Mocha + Chai
- Supertest (API testing)
- Playwright (E2E)

### Python
- pytest, unittest
- requests-mock (API mocking)
- Selenium (E2E)

### Go
- testing package
- testify (assertions)
- httptest (HTTP testing)

### Java
- JUnit 5
- Mockito (mocking)
- RestAssured (API testing)

## Related Resources

- Follow TDD workflow: RED → GREEN → REFACTOR
- Aim for 80%+ test coverage
- Keep tests fast and isolated
- Use descriptive test names
