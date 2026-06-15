---
name: prime
description: Bootstrap session context from the local project (READMEs, file listings, config markers, git log) via a Haiku agent.
user-invocable: true
model-invocable: true
allowed-tools: Bash, Agent
model: haiku
---

Load context by delegating the reads to a Haiku agent — never read large files in the main thread.

## Local project (no argument, `.`, or `here`)

Spawn one `Agent` (`general-purpose`, `haiku`) to gather and summarize:

1. List files in cwd (non-recursive, then one level deep).
2. Read any README / CONTRIBUTING / similar.
3. Read present markers: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `justfile`, `flake.nix`; `.claude/CLAUDE.md`, `CLAUDE.md`; `.envrc`, `.tool-versions`, `mise.toml`.
4. If a git repo: `git log --oneline -10`.

Return a dense summary: what the project is, key directories, language/framework/tooling, visible conventions, recent git activity.

Relay the result as restored context and continue.
