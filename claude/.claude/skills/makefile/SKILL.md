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

- `printf` over `echo`. No GNU-only flags unless the Makefile is Linux-only.
- `@` prefix on recipe lines, plus `|| echo` where a failure must stay visible.

## Before reporting

- Confirm every recipe line starts with a tab character, not spaces.
- Confirm every non-file target appears in a `.PHONY` declaration.
