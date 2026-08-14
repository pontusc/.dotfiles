---
name: lsp-setup
description: Scaffold or extend a project's Claude Code LSP configuration, a project-local skills-dir plugin with .lsp.json, one correctly-rooted language server per language. Use when wiring code intelligence into a project or adding a service/language to an existing setup.
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash
---

# Per-Project LSP Setup

Wires the Claude Code `LSP` tool into the current project via a project-local skills-dir
plugin. LSP servers are **always defined per project, never globally**.

## Why per-project (don't relitigate)

- A globally installed LSP plugin roots its server at the launch directory and cannot
  re-root to subfolders: broken in multi-service monorepos.
- Disabling a marketplace plugin per-project (`"…@marketplace": false`) corrupts the global
  install registry: it re-scopes the plugin to that project on every restart, breaking it
  in other repos. So globals aren't disabled: they're never installed.
- The global prerequisite (`ENABLE_LSP_TOOL=1`) is already set in `~/.claude/settings.json`.
  The variable is undocumented (accurate as of 2026-07, CC 2.1.19x). Re-verify if LSP
  stops appearing after an update.
- The LSP tool is **main-thread-only**: as of 2026-07 (CC 2.1.196, no fix in changelog) it
  never reaches subagents. Don't try to fix that via agent `tools:` frontmatter (proven
  futile, see cc-lsp/subagent-lsp-inheritance).

## Loading conditions

- Skills-dir plugins load only from the **launch directory's** `.claude/skills/` (and
  `~/.claude/skills/`): no walking up, no recursing down. Start CC from the repo root.
- The workspace must be trusted. A restart is needed after creating the plugin.

## Scaffold

1. Detect languages: Glob for `Cargo.toml`, `go.mod`, `pyproject.toml`,
   `tsconfig.json`/`package.json`, and where each lives (one service or several per language).
2. Verify each needed server binary exists (`command -v rust-analyzer ty
   typescript-language-server gopls`). Report missing ones. Don't install anything.
3. Create, after confirming content with the user:

   `.claude/skills/lsp/.claude-plugin/plugin.json`
   ```json
   { "name": "lsp" }
   ```

   `.claude/skills/lsp/.lsp.json`: entries from the catalog below.
4. Tell the user: restart Claude Code from the repo root to load `lsp@skills-dir`.

## .lsp.json rules

- Routing is `extension → language → ONE server`. A second server for an already-mapped
  extension collides: never register two.
- **One service owns the language** → pin the server to it:
  `"workspaceFolder": "${CLAUDE_PROJECT_DIR}/services/<svc>"`.
- **Several services share a language** → drop `workspaceFolder`, root at the repo root
  using the server's own multi-project support:
  - Rust: `initializationOptions.linkedProjects` listing every `Cargo.toml`, plus
    `"cargo": { "targetDir": true }` so each crate keeps its own `target/`.
  - TS/JS: `typescript-language-server` discovers each `tsconfig.json`/`package.json` natively.
  - Python: `ty` handles multiple `pyproject.toml` as a workspace.

  These multi-root wirings come from the reference repo's README and the servers' own
  documented multi-project support, but are unverified through the CC LSP tool: confirm
  on first use (as with gopls below).

## Server catalog (verified blocks)

```json
"rust-analyzer": {
  "command": "rust-analyzer",
  "extensionToLanguage": { ".rs": "rust" },
  "workspaceFolder": "${CLAUDE_PROJECT_DIR}/services/<svc>"
},
"ty": {
  "command": "ty",
  "args": ["server"],
  "extensionToLanguage": { ".py": "python", ".pyi": "python" },
  "workspaceFolder": "${CLAUDE_PROJECT_DIR}/services/<svc>"
},
"typescript": {
  "command": "typescript-language-server",
  "args": ["--stdio"],
  "extensionToLanguage": {
    ".cjs": "javascript", ".cts": "typescript", ".js": "javascript",
    ".jsx": "javascriptreact", ".mjs": "javascript", ".mts": "typescript",
    ".ts": "typescript", ".tsx": "typescriptreact"
  },
  "workspaceFolder": "${CLAUDE_PROJECT_DIR}/services/<svc>"
},
"gopls": {
  "command": "gopls",
  "extensionToLanguage": { ".go": "go" },
  "workspaceFolder": "${CLAUDE_PROJECT_DIR}/services/<svc>"
}
```

Rust/Python/TS single-service blocks are verified live (three-service monorepo, 2026-06).
The gopls entry and all multi-root variants are unverified: confirm on first use.

## What does NOT work

- Per-service plugins (`services/<svc>/.claude/skills/`): invisible when CC launches from
  the repo root.
- Two servers for one extension.
- Disabling a global plugin per-project (registry corruption, see above).
