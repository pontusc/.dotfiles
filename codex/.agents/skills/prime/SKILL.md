---
name: prime
description: Bootstrap session context from local project docs, file listings, config markers, and recent Git history. Use at the start of a session when project context is absent.
---

Delegate context gathering to a `scout` agent and return its summary. For a very small target, gather it directly.

Target = the path given as an argument (e.g. `@some/dir`), else the cwd.

1. List files in the target (non-recursive, then one level deep).
2. Read present docs: `README*`, `CONTRIBUTING*`, `AGENTS.md`, `ARCHITECTURE.md`.
3. Read present markers: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `justfile`, `flake.nix`, `.codex/config.toml`, `AGENTS.md`, `.envrc`, `.tool-versions`, `mise.toml`.
4. If a git repo: `git log --oneline -10`.

Return a dense summary (≤150 words): what the project is, key directories, language/framework/tooling, visible conventions, recent git activity.
