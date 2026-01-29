---
name: prime
description: Bootstrap session context by reading READMEs, listing files, and building a mental model of the current project.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash
---

Prime your context for this session. Do the following in parallel where possible:

1. List all files in the current working directory (non-recursively first, then one level deep).
2. Find and read any README, README.md, CONTRIBUTING.md, or similar documentation files in the current directory.
3. Check for common project markers and read them if present:
   - package.json, Cargo.toml, pyproject.toml, go.mod, Makefile, justfile, flake.nix, shell.nix
   - .claude/settings.json, .claude/CLAUDE.md, CLAUDE.md
   - .envrc, .tool-versions, mise.toml
4. If this is a git repo, run `git log --oneline -10` to see recent activity.

After gathering context, provide a concise summary:
- What this project is and what it does
- Key directories and their purpose
- Language/framework/tooling in use
- Any conventions or patterns visible from the config files
- Recent git activity

Keep the summary dense and useful. Skip anything that adds no value.
