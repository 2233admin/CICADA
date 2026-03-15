---
name: i18n
description: Internationalization and localization assistance for multi-language applications
allowed-tools: ["Read", "Write", "Grep", "Glob"]
origin: bundled
version: 1.0.0
---

# Internationalization (i18n) Helper

Assist with internationalization and localization of applications, including translation management, locale handling, and i18n best practices.

## When to Activate

### Explicit Triggers
- User says "translate this"
- User says "国际化"
- User says "add i18n support"
- User says "localization"

### Implicit Triggers
- User mentions multi-language support
- User asks about translation files
- User needs to support multiple locales

### NOT Activated For
- Simple text changes
- Code comments translation
- Documentation translation (unless i18n-related)

## i18n Fundamentals

### Key Concepts

- **i18n**: Internationalization (18 letters between 'i' and 'n')
- **l10n**: Localization (10 letters between 'l' and 'n')
- **Locale**: Language + region code (e.g., en-US, zh-CN, fr-FR)
- **Translation Key**: Unique identifier for translatable text
- **Fallback Language**: Default language when translation missing

## Translation File Structure

### JSON Format (Common)

```json
// en.json
{
  "common": {
    "welcome": "Welcome",
    "save": "Save",
    "cancel": "Cancel",
    "error": "An error occurred"
  },
  "auth": {
    "login": "Log In",
    "logout": "Log Out",
    "email": "Email Address",
    "password": "Password"
  }
}
```

```json
// zh-CN.json
{
  "common": {
    "welcome": "欢迎",
    "save": "保存",
    "cancel": "取消",
    "error": "发生错误"
  },
  "auth": {
    "login": "登录",
    "logout": "退出登录",
    "email": "电子邮箱",
    "password": "密码"
  }
}
```

## i18n Best Practices

### 1. Use Translation Keys, Not Raw Text

**Bad:**
```typescript
<button>Save</button>
```

**Good:**
```typescript
<button>{t('common.save')}</button>
```

### 2. Organize by Feature/Module

```
locales/
├── en/
│   ├── common.json
│   ├── auth.json
│   └── settings.json
└── zh-CN/
    ├── common.json
    ├── auth.json
    └── settings.json
```

### 3. Handle Pluralization

```json
{
  "items": {
    "zero": "No items",
    "one": "{{count}} item",
    "other": "{{count}} items"
  }
}
```

### 4. Support Variable Interpolation

```json
{
  "greeting": "Hello, {{name}}!",
  "itemsInCart": "You have {{count}} items"
}
```

### 5. Handle Date/Time Formatting

```typescript
const date = new Date();
date.toLocaleDateString('en-US'); // "3/15/2026"
date.toLocaleDateString('zh-CN'); // "2026/3/15"
```

### 6. Handle Currency Formatting

```typescript
const amount = 1234.56;
amount.toLocaleString('en-US', { style: 'currency', currency: 'USD' }); // "$1,234.56"
amount.toLocaleString('zh-CN', { style: 'currency', currency: 'CNY' }); // "¥1,234.56"
```

## Common i18n Libraries

### JavaScript/TypeScript
- **react-i18next**: React integration
- **i18next**: Framework-agnostic
- **vue-i18n**: Vue.js integration

### Python
- **gettext**: Standard library
- **Babel**: Comprehensive toolkit

### Go
- **go-i18n**: Popular library

## Translation Workflow

1. **Extract Strings**: Identify all user-facing text
2. **Create Keys**: Replace with translation keys
3. **Translate**: Get professional translations
4. **Test**: Verify all locales work correctly

## Common Pitfalls

### 1. String Concatenation
**Bad:**
```typescript
const msg = t('hello') + ' ' + userName;
```

**Good:**
```typescript
const msg = t('greeting', { name: userName });
```

### 2. Hardcoded Text
**Bad:**
```typescript
<p>Welcome to our app</p>
```

**Good:**
```typescript
<p>{t('common.welcome')}</p>
```

### 3. Missing Fallbacks
Always provide fallback language for missing translations.

## Related Resources

- Use professional translators for production
- Test all supported locales
- Consider RTL languages (Arabic, Hebrew)
- Handle date/time/currency formatting properly
