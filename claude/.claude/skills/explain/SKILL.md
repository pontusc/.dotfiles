---
name: explain
description: Provide detailed explanation of code, architecture, or patterns
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash
argument-hint: [file-path or pattern]
context: fork
agent: Explore
model: haiku
---

Explain how the specified code works. Arguments: $ARGUMENTS

## Workflow

1. **Read target file(s)**
   - Use Read for specific files
   - Use Glob to find related files by pattern
   - Use Grep to search for keywords

2. **Find dependencies**
   - Look for import/include statements
   - Find files that import this code
   - Trace function calls and data flow

3. **Check git history** (read-only)
   - `git log --follow -- <file>` - See file evolution
   - `git blame <file>` - Track line origins
   - `git show <commit>` - See specific changes
   - Understanding why code was written this way

4. **Provide comprehensive explanation**
   - **What**: What the code does functionally
   - **How**: How it's structured and implemented
   - **Why**: Why it's designed this way (from git history, comments, patterns)
   - **Dependencies**: Key imports and interactions
   - **Recent changes**: What changed recently and why

## Example Invocations

```bash
/explain src/auth/login.py
/explain "authentication flow"
/explain src/api/
/explain "how websockets work in this codebase"
```

## Output Format

```
## Overview
[High-level summary of what this code does]

## Key Components
- **Component 1** (file:line): Description
- **Component 2** (file:line): Description

## How It Works
[Step-by-step explanation of the flow]

## Dependencies
- Import X from Y: Used for Z
- Depends on A: Reason

## Design Rationale
[Why it's structured this way, based on patterns and history]

## Recent Changes
[Summary from git log, if relevant]
```

This skill delegates to the **Explore agent** for efficient codebase navigation.
