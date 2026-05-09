---
name: doc-gen
description: Generate comprehensive documentation for code, APIs, and projects
allowed-tools: ["Read", "Write", "Grep", "Glob"]
origin: bundled
version: 1.0.0
---

# Documentation Generator

Automatically generate clear, comprehensive documentation for code, APIs, and projects.

## When to Activate

### Explicit Triggers
- User says "generate documentation"
- User says "生成文档"
- User says "document this code"
- User says "write docs for this"

### Implicit Triggers
- User completes a feature and mentions documentation
- User asks "how do I document this?"
- User needs API documentation

### NOT Activated For
- Simple code comments (use inline comments instead)
- README updates (unless comprehensive rewrite needed)
- Changelog generation

## Documentation Types

### 1. Code Documentation
- **Function/Method Docs**: Parameters, return values, exceptions
- **Class Docs**: Purpose, usage examples, properties
- **Module Docs**: Overview, exports, dependencies

### 2. API Documentation
- **Endpoints**: Method, path, parameters, responses
- **Authentication**: Auth methods, token formats
- **Examples**: Request/response samples
- **Error Codes**: All possible errors with descriptions

### 3. Project Documentation
- **README**: Overview, installation, quick start
- **Architecture**: System design, components, data flow
- **Contributing**: Development setup, guidelines
- **Deployment**: Build, test, deploy instructions

## Documentation Standards

### Function Documentation Template

```typescript
/**
 * Retries a failed operation up to 3 times with exponential backoff.
 *
 * @param operation - The async function to retry
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @param baseDelay - Initial delay in ms (default: 1000)
 * @returns The result of the successful operation
 * @throws {Error} If all retry attempts fail
 *
 * @example
 * ```typescript
 * const data = await retryOperation(
 *   () => fetchUserData(userId),
 *   3,
 *   1000
 * );
 * ```
 */
async function retryOperation<T>(
  operation: () => Promise<T>,
  maxRetries = 3,
  baseDelay = 1000
): Promise<T>
```

### API Documentation Template

```markdown
## POST /api/users

Create a new user account.

### Request

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <token>` (optional)

**Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user"
}
```

### Response

**Success (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "usr_123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "createdAt": "2026-03-15T10:30:00Z"
  }
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Invalid email format"
}
```

### Error Codes
- `400` - Invalid input data
- `401` - Unauthorized (missing/invalid token)
- `409` - Email already exists
- `500` - Internal server error
```

## Best Practices

### 1. Clarity
- Use simple, clear language
- Avoid jargon unless necessary
- Define technical terms

### 2. Completeness
- Document all parameters and return values
- Include error conditions
- Provide usage examples

### 3. Accuracy
- Keep docs in sync with code
- Update docs when code changes
- Test all examples

### 4. Structure
- Use consistent formatting
- Organize logically (overview → details → examples)
- Include table of contents for long docs

### 5. Examples
- Provide realistic examples
- Show common use cases
- Include error handling examples

## Documentation Checklist

Before marking documentation complete:
- [ ] All public functions/classes documented
- [ ] Parameters and return values described
- [ ] Usage examples provided
- [ ] Error conditions documented
- [ ] Code examples tested and working
- [ ] Links to related documentation included
- [ ] Formatting consistent throughout

## Language-Specific Formats

### TypeScript/JavaScript
Use JSDoc format with TypeScript types

### Python
Use docstrings (Google or NumPy style)

### Go
Use godoc format with examples

### Java
Use Javadoc format

## Related Resources

- Keep documentation close to code
- Use automated doc generators (JSDoc, Sphinx, godoc)
- Version documentation with code
