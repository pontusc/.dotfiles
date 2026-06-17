---
name: makefile
description: Makefile conventions — applied when writing or editing Makefiles and .mk includes.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# Makefile Conventions

Apply these conventions when writing or editing `Makefile` or `*.mk` files.

## Targets

- **`.PHONY`**: Declare all non-file targets as `.PHONY`. Group the declaration above the target, or use a single block at the top.
- **Naming**: Use `kebab-case` for target names (e.g., `docker-build`, `run-tests`).
- **Default target**: First target should be `help` or `all`. If `help`, auto-generate from comments:

```makefile
.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-20s %s\n", $$1, $$2}'
```

- **Target comments**: Use `## Description` after the target/deps for self-documenting targets.

## Variables

- **User-overridable**: Use `?=` for variables the caller might override (e.g., `IMAGE_TAG ?= latest`).
- **Internal**: Use `:=` for immediately expanded variables.
- **Naming**: `UPPER_SNAKE_CASE` for all variables.

## Recipes

- **One logical action per target** — keep recipes focused.
- **Portable commands**: Prefer `printf` over `echo` in recipes. Avoid GNU-only flags unless the Makefile is Linux-only.
- **Multiline**: Use backslash continuation or `.ONESHELL` when a recipe needs shared shell state.
- **Silence**: Use `@` prefix only for output/echo lines, not for commands that might fail (hides errors).

## Includes

- Use `-include` (dash prefix) for optional includes so missing files don't break the build.
- Keep shared logic in `*.mk` files and include them.
