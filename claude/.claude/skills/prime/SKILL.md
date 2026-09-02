---
name: prime
description: Bootstrap session context from the local project (READMEs, file listings, config markers, git log) via a Haiku agent. Use at the start of a new session or after /clear when project context is absent.
user-invocable: true
allowed-tools: Bash, Agent
model: haiku
---

Load context by delegating the reads to a Haiku agent: never read large files in the main thread.

## Procedure

Target = the path given as an argument (e.g. `@some/dir`), else the cwd.

Spawn one `Agent` (`general-purpose`, `haiku`) to gather and summarize:

1. List files in the target (non-recursive, then one level deep).
2. Read present docs: `README*`, `CONTRIBUTING*`, `AGENTS.md`, `ARCHITECTURE.md`.
3. Read present markers: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `justfile`, `flake.nix`, `.claude/CLAUDE.md`, `CLAUDE.md`, `.envrc`, `.tool-versions`, `mise.toml`.
4. If a git repo: `git log --oneline -10`.

Return a dense summary (≤150 words): what the project is, key directories, language/framework/tooling, visible conventions, recent git activity.

Present the summary as restored context, then stop.
