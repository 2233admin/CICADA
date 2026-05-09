---
name: refactor
description: Identify code smells and suggest refactoring improvements
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
origin: bundled
version: 1.0.0
---

# Refactoring Assistant

Identify code smells, suggest improvements, and guide safe refactoring following best practices.

## When to Activate

### Explicit Triggers
- User says "refactor this"
- User says "重构代码"
- User says "improve this code"
- User says "clean up this code"

### Implicit Triggers
- User mentions code is hard to understand
- User asks about code quality
- User mentions technical debt

### NOT Activated For
- New feature implementation
- Bug fixes (unless refactoring is needed)
- Simple formatting changes

## Code Smells to Detect

### 1. Long Functions/Methods
**Smell:** Function > 50 lines
**Fix:** Extract smaller functions

```typescript
// Before: 80-line function
function processOrder(order) {
  // validation (20 lines)
  // calculation (30 lines)
  // database save (20 lines)
  // notification (10 lines)
}

// After: Extracted functions
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  saveOrder(order, total);
  notifyCustomer(order);
}
```

### 2. Large Files
**Smell:** File > 800 lines
**Fix:** Split by responsibility

```
// Before: user-service.ts (1200 lines)
UserService
  - authentication
  - profile management
  - permissions
  - notifications

// After: Split into focused files
auth-service.ts (300 lines)
profile-service.ts (250 lines)
permission-service.ts (200 lines)
notification-service.ts (150 lines)
```

### 3. Duplicated Code
**Smell:** Same logic in multiple places
**Fix:** Extract to shared function

```typescript
// Before: Duplicated validation
function createUser(data) {
  if (!data.email || !data.email.includes('@')) {
    throw new Error('Invalid email');
  }
  // ...
}

function updateUser(id, data) {
  if (!data.email || !data.email.includes('@')) {
    throw new Error('Invalid email');
  }
  // ...
}

// After: Extracted validation
function validateEmail(email) {
  if (!email || !email.includes('@')) {
    throw new Error('Invalid email');
  }
}

function createUser(data) {
  validateEmail(data.email);
  // ...
}

function updateUser(id, data) {
  validateEmail(data.email);
  // ...
}
```

### 4. Deep Nesting
**Smell:** Nesting > 4 levels
**Fix:** Early returns, extract functions

```typescript
// Before: Deep nesting
function processData(data) {
  if (data) {
    if (data.isValid) {
      if (data.user) {
        if (data.user.isActive) {
          // actual logic here
        }
      }
    }
  }
}

// After: Early returns
function processData(data) {
  if (!data) return;
  if (!data.isValid) return;
  if (!data.user) return;
  if (!data.user.isActive) return;

  // actual logic here
}
```

### 5. Magic Numbers/Strings
**Smell:** Hardcoded values without explanation
**Fix:** Named constants

```typescript
// Before: Magic numbers
function calculateDiscount(price) {
  if (price > 100) {
    return price * 0.1;
  }
  return 0;
}

// After: Named constants
const DISCOUNT_THRESHOLD = 100;
const DISCOUNT_RATE = 0.1;

function calculateDiscount(price) {
  if (price > DISCOUNT_THRESHOLD) {
    return price * DISCOUNT_RATE;
  }
  return 0;
}
```

### 6. God Objects/Classes
**Smell:** Class with too many responsibilities
**Fix:** Split by Single Responsibility Principle

```typescript
// Before: God class
class UserManager {
  authenticate() { }
  validateEmail() { }
  sendNotification() { }
  generateReport() { }
  processPayment() { }
}

// After: Focused classes
class AuthService {
  authenticate() { }
}

class EmailValidator {
  validate() { }
}

class NotificationService {
  send() { }
}

class ReportGenerator {
  generate() { }
}

class PaymentProcessor {
  process() { }
}
```

### 7. Long Parameter Lists
**Smell:** Function with > 4 parameters
**Fix:** Parameter object

```typescript
// Before: Too many parameters
function createUser(
  email: string,
  name: string,
  age: number,
  address: string,
  phone: string,
  role: string
) { }

// After: Parameter object
interface UserData {
  email: string;
  name: string;
  age: number;
  address: string;
  phone: string;
  role: string;
}

function createUser(userData: UserData) { }
```

### 8. Mutable State
**Smell:** Direct mutation of objects
**Fix:** Immutable updates

```typescript
// Before: Mutation
function updateUser(user, newEmail) {
  user.email = newEmail;
  return user;
}

// After: Immutable
function updateUser(user, newEmail) {
  return {
    ...user,
    email: newEmail
  };
}
```

## Refactoring Techniques

### 1. Extract Function
Move code block into a named function

### 2. Extract Variable
Replace complex expression with named variable

### 3. Inline Function
Replace function call with function body (if trivial)

### 4. Rename
Give better names to variables, functions, classes

### 5. Move Function
Move function to more appropriate class/module

### 6. Replace Conditional with Polymorphism
Use inheritance/interfaces instead of if/switch

### 7. Introduce Parameter Object
Group related parameters into object

### 8. Replace Magic Number with Constant
Name hardcoded values

## Safe Refactoring Process

### 1. Ensure Tests Exist
```bash
# Run tests before refactoring
npm test

# Check coverage
npm run coverage
```

### 2. Make Small Changes
- One refactoring at a time
- Commit after each successful change
- Keep tests green

### 3. Run Tests After Each Change
```bash
# After each refactoring step
npm test
```

### 4. Use Automated Tools
- IDE refactoring features (rename, extract, move)
- Linters (ESLint, Pylint, golangci-lint)
- Code formatters (Prettier, Black, gofmt)

## Refactoring Checklist

Before refactoring:
- [ ] Tests exist and pass
- [ ] Understand the code's purpose
- [ ] Identify specific code smell
- [ ] Plan refactoring approach

During refactoring:
- [ ] Make one change at a time
- [ ] Run tests after each change
- [ ] Keep commits small and focused
- [ ] Preserve existing behavior

After refactoring:
- [ ] All tests still pass
- [ ] Code is more readable
- [ ] Complexity reduced
- [ ] No new bugs introduced

## When NOT to Refactor

- **Deadline pressure**: Refactor after delivery
- **Unclear requirements**: Understand first, refactor later
- **No tests**: Write tests first
- **Working code in production**: If it works and isn't causing issues, leave it

## Refactoring Priorities

**High Priority:**
- Security vulnerabilities
- Performance bottlenecks
- Code causing frequent bugs
- Code blocking new features

**Medium Priority:**
- Hard-to-understand code
- Duplicated logic
- Large files/functions

**Low Priority:**
- Minor style inconsistencies
- Slightly verbose code
- Personal preferences

## Related Resources

- Always have tests before refactoring
- Make small, incremental changes
- Keep tests green throughout
- Use IDE refactoring tools when available
- Commit frequently during refactoring
