---
name: prime
description: Bootstrap session context by reading READMEs, listing files, and building a mental model of the current project.
user-invocable: true
model-invocable: true
allowed-tools: Agent
model: haiku
---

Delegate the priming work to a Haiku agent. Do not run the reads/listings in the main thread.

Spawn one `Agent` with:

- `subagent_type: "general-purpose"`
- `model: "haiku"`
- A self-contained prompt instructing the agent to gather the context below and return a concise summary.

The agent's prompt should cover:

1. List files in the current working directory (non-recursively first, then one level deep).
2. Find and read any README, README.md, CONTRIBUTING.md, or similar documentation files in the current directory.
3. Check for and read common project markers if present:
   - package.json, Cargo.toml, pyproject.toml, go.mod, Makefile, justfile, flake.nix, shell.nix
   - .claude/settings.json, .claude/CLAUDE.md, CLAUDE.md
   - .envrc, .tool-versions, mise.toml
4. If this is a git repo, run `git log --oneline -10` to see recent activity.

Ask the agent to return a concise summary covering:

- What this project is and what it does
- Key directories and their purpose
- Language/framework/tooling in use
- Any conventions or patterns visible from the config files
- Recent git activity

Relay the agent's summary to the user. Keep it dense and useful. Skip anything that adds no value.
