---
name: explain
description: Explain code, commands, or concepts from the current conversation — break down what it does, why, with manpage references and sources.
user-invocable: true
model-invocable: false
allowed-tools: Read, Bash, WebFetch, WebSearch
agent: expert
model: sonnet
---

# Explain

Break down the most recent solution, code snippet, or command from this conversation so the user fully understands it.

## What to explain

If the user specifies what to explain, use that. Otherwise, explain the most recent code or command output in the conversation.

## Process

### 1. Identify the subject

Extract the specific code, command, flag, pattern, or concept to explain.

### 2. Break it down

- **Line by line or flag by flag** — what each part does, in plain language
- **Why this approach** — what problem it solves and why this way vs alternatives
- **Non-obvious behavior** — gotchas, side effects, edge cases, implicit defaults

### 3. Provide sources

For each non-trivial element, include at least one authoritative reference:

- **Shell commands/flags**: `man <command>` — run `man <command> | col -b` and quote the relevant section
- **Bash syntax**: reference the Bash manual section (e.g., "Parameter Expansion — see `man bash`, section 'Parameter Expansion'")
- **Programming constructs**: link to official language docs or stdlib reference
- **Tools (terraform, docker, etc.)**: link to official docs or run `<tool> --help` and quote relevant output
- **Concepts (networking, crypto, etc.)**: cite the relevant RFC, standard, or authoritative guide

### 4. Format

```
## <subject>

<1-2 sentence summary of what it does>

### Breakdown

<element>  — <what it does>
<element>  — <what it does>
...

### Why this way

<brief rationale, alternatives considered if relevant>

### Sources

- `man <cmd>` — "<quoted excerpt>"
- <url> — <what it covers>
```

## Guidelines

- Match depth to complexity — a simple `grep` flag needs one line, a complex pipeline needs a full breakdown
- Use the user's domain knowledge (DevOps, Linux, IaC) — don't over-explain basics, focus on the non-obvious parts
- If the subject involves multiple tools chained together, explain the data flow between them
- Prefer manpages and `--help` output over web searches when available
- Keep it concise — explain what's needed, not everything possible
