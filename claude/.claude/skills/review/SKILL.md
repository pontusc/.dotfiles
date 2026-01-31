---
name: review
description: Review code for bugs, security issues, and best practices
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash
argument-hint: [file-path or commit-range]
context: fork
agent: code-reviewer
model: opus
---

Review the specified code for:
- Security vulnerabilities (OWASP top 10)
- Logic errors and edge cases
- Performance issues
- Code style and best practices
- Maintainability concerns

## Arguments

**File/Directory path:**
```
/review src/auth/
/review src/main.rs
/review .
```

**Git commit range:**
```
/review HEAD~3..HEAD
/review main..feature-branch
/review abc123f
```

## Scope

Arguments: $ARGUMENTS

If no arguments provided, review unstaged/uncommitted changes (`git diff`).

## Git Operations (READ-ONLY)

Allowed:
- `git log` - View commit history
- `git diff` - View changes
- `git show` - View specific commits
- `git blame` - Track code origins

**NOT allowed:** commit, push, rebase, reset, or any state changes.

## Output Format

Provide actionable feedback with file:line references:

```
## Critical Issues
[Security and correctness problems requiring immediate attention]

## Performance Concerns
[Optimization opportunities with measurable impact]

## Best Practices
[Code style, maintainability, and convention improvements]

## Test Coverage
[Missing test cases or weak assertions]
```

This skill delegates to the **code-reviewer agent** for deep analysis.
