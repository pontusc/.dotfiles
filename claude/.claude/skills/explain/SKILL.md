---
name: explain
description: Provide detailed explanation of code, architecture, or patterns including official documentation
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
argument-hint: [file-path or pattern]
context: fork
agent: explainer
model: sonnet
---

Explain how the specified code works. Arguments: $ARGUMENTS

## WORKFLOW

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

4. **Provide comprehensive explanation**
   - **What**: What the code does functionally
   - **How**: How it's structured and implemented
   - **Why**: Why it's designed this way (from git history, comments, patterns)
   - **Dependencies**: Key imports and interactions
   - **Recent changes**: What changed recently and why

5. **Fetch relevant documentation** (when applicable)
   - Identify frameworks/libraries from code
   - Search for official documentation
   - Include docs summary and links

## EXAMPLE INVOCATIONS

```bash
/explain src/auth/login.py
/explain "authentication flow"
/explain src/api/
/explain "how websockets work in this codebase"
/explain "Next.js app router"
/explain src/api/auth.ts  # includes relevant auth library docs
```

## OUTPUT FORMAT

```
═══════════════════════════════════════
  [COMPONENT NAME]
═══════════════════════════════════════

OVERVIEW
────────
[High-level summary]

KEY COMPONENTS
──────────────
- **Component 1** (file:line): Description
- **Component 2** (file:line): Description

HOW IT WORKS
────────────
[Step-by-step explanation with diagrams]

DEPENDENCIES
────────────
- Import X from Y: Used for Z
- Depends on A: Reason

OFFICIAL DOCUMENTATION
──────────────────────
[Summary + links to official docs]

DESIGN RATIONALE
────────────────
[Why it's structured this way]

RECENT CHANGES
──────────────
[Summary from git log, if relevant]
```

This skill delegates to the **explainer agent** for comprehensive code analysis with visual diagrams.
