---
name: makefile
description: Makefile conventions, applied when writing or editing Makefiles and .mk includes.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/Makefile"
  - "**/makefile"
  - "**/GNUmakefile"
  - "**/*.mk"
---

# Makefile

- Declare every non-file target `.PHONY`, either grouped above the target or in one block at the top.
- `kebab-case` target names (`docker-build`, `run-tests`), `UPPER_SNAKE_CASE` variables.
- `?=` for anything the caller may override (`IMAGE_TAG ?= latest`), `:=` for internal immediate expansion.
- `printf` over `echo`. No GNU-only flags unless the Makefile is Linux-only.
- `@` prefix on recipe lines, plus `|| echo` where a failure must stay visible.

## Before reporting

- Confirm every recipe line starts with a tab character, not spaces.
- Confirm every non-file target appears in a `.PHONY` declaration.
