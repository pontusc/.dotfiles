---
name: lsp-setup
description: Scaffold or extend a project's OMP language-server configuration, one correctly-rooted server per language. Use when wiring code intelligence into a project or adding a service or language to an existing setup.
---

# Per-Project LSP Setup

Wires the OMP `lsp` tool into the current project. Language servers are **always defined per
project, never globally**.

## Why per-project (don't relitigate)

- A globally installed language-server setup roots its server at the launch directory and cannot
  re-root to subfolders, broken in multi-service monorepos.
- Keep one server configuration per language and scope its workspace root explicitly.
- OMP auto-detects common project roots. Add an override only when the built-in definition needs
  a different command, file type, root marker, or initialization option.

## Loading conditions

- OMP discovers this skill from the launch directory's `.omp/agent/skills/` and
  `~/.omp/agent/skills/`, with no walking up or recursing down.
- OMP discovers user LSP overrides from `~/.omp/agent/lsp.json` and project overrides from
  `<cwd>/.omp/lsp.json`.
- The workspace must be trusted. Restart OMP after changing its LSP configuration.

## Scaffold

1. Detect languages: Glob for `Cargo.toml`, `go.mod`, `pyproject.toml`,
   `tsconfig.json`/`package.json`, and where each lives (one service or several per language).
2. Verify each needed server binary exists (`command -v rust-analyzer ty
   typescript-language-server gopls`). Report missing ones. Don't install anything.
3. Create or update `<cwd>/.omp/lsp.json` with only the project-specific overrides.
4. Restart OMP from the repo root so it loads the project-local configuration.

## lsp.json rules

- Routing is `file extension → ONE server`. A second server for an already-mapped extension
  collides, never register two.
- **One service owns the language** → pin the server with a specific `rootMarkers` set and a
  workspace-specific configuration.
- **Several services share a language** → root at the repo root and use the server's own
  multi-project support:
  - Rust: `initOptions.linkedProjects` listing every `Cargo.toml`, plus
    `settings.cargo.targetDir` so each crate keeps its own `target/`.
  - TS/JS: `typescript-language-server` discovers each `tsconfig.json`/`package.json` natively.
  - Python: `ty` handles multiple `pyproject.toml` as a workspace.

## Server catalog

```json
{
  "servers": {
    "rust-analyzer": {
      "command": "rust-analyzer",
      "fileTypes": [".rs"],
      "languageId": "rust",
      "rootMarkers": ["Cargo.toml"]
    },
    "ty": {
      "command": "ty",
      "args": ["server"],
      "fileTypes": [".py", ".pyi"],
      "languageId": "python",
      "rootMarkers": ["pyproject.toml"]
    },
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "fileTypes": [".cjs", ".cts", ".js", ".jsx", ".mjs", ".mts", ".ts", ".tsx"],
      "rootMarkers": ["package.json", "tsconfig.json"]
    },
    "gopls": {
      "command": "gopls",
      "fileTypes": [".go"],
      "languageId": "go",
      "rootMarkers": ["go.mod"]
    }
  }
}
```

The catalog is a starting point. Check the OMP LSP configuration reference before adding a
server-specific field or changing root detection.

## What does not work

- Two servers for one file extension.
- A project config without a root marker that identifies the intended workspace.
- Absolute binary paths when the project-local binary or `PATH` resolution is sufficient.
