---
name: bash
description: Shell scripting conventions — applied when writing or editing .sh/.bash files or inline shell scripts.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---

# Bash / Shell Scripting Conventions

Conventions for new files and the lines you're changing — on existing files stay surgical and suggest divergences rather than migrating.

## Script Header

Every script starts with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e` — exit on error
- `set -u` — error on undefined variables
- `set -o pipefail` — propagate pipe failures
- Caveat: `set -e` does not fire inside `if`/`while`/`until` conditions or `&&`/`||` chains — don't rely on it catching failures there. If you add an `ERR` trap, also set `-E` so it's inherited by functions and subshells.

## Style

- **Quoting**: Always double-quote expansions — `"${var}"`, `"${arr[@]}"`, `"$(cmd)"`. Leave a value unquoted only deliberately (e.g. splitting a flag string into words) — and comment why.
- **Variable names**: `snake_case` for locals, `UPPER_SNAKE_CASE` for exported/env vars.
- **Functions**: Use `function_name() {` syntax (no `function` keyword). Declare local variables with `local`.
- **Conditionals**: Prefer `[[ ]]` over `[ ]` for bash scripts. Use `[ ]` only in POSIX sh scripts.
- **Command substitution**: Use `$(cmd)`, never backticks.
- **Indentation**: 2 spaces.

## Error Handling

- Use `trap` for cleanup: `trap cleanup EXIT`
- Validate required arguments early, print usage and exit 1 on failure.
- Prefer `die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }` pattern for fatal errors.
- Redirect error messages to stderr: `echo "error: ..." >&2`

## POSIX Compatibility

- Match the shebang to the features used: bashisms (`[[ ]]`, arrays, `local`) require `#!/usr/bin/env bash`, never `#!/bin/sh`.

## Best Practices

- **ShellCheck compliant**: All scripts must pass `shellcheck`. Satisfy the rule rather than disabling it — e.g., for SC2155, separate declaration and assignment instead of adding a disable directive.
- **printf needs `\n`**: `printf` does not append a newline like `echo`. Always include `\n` in the format string: `printf 'message\n'`.
- **No useless cat**: Use `< file` instead of `cat file |`.
- **Avoid needless subprocesses**: use parameter expansion over forking — `${var%pattern}` not `sed`/`cut` for simple string ops.
- **Temp files**: Use `mktemp` and clean up via trap.
- **Readonly**: Only use `readonly` when the variable genuinely needs protection from reassignment. Don't apply it by default to every variable.
