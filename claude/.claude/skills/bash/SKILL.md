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

- Caveat: `set -e` does not fire inside `if`/`while`/`until` conditions or `&&`/`||` chains — don't rely on it catching failures there. If you add an `ERR` trap, also set `-E` so it's inherited by functions and subshells.
- After the header, add a short comment block stating what the script does and how it's invoked (args, where it's run from) — the *why* and the contract, not line-by-line narration.
- **Sourced libraries are the exception.** A file meant to be `source`d, not executed, omits `set -euo pipefail` (it would mutate the caller's shell) and says so up top: `# Source this file; it is not meant to be executed directly.`

## Style

- **Quoting**: Always double-quote expansions — `"${var}"`, `"${arr[@]}"`, `"$(cmd)"`. Leave a value unquoted only deliberately (e.g. splitting a flag string into words) — and comment why.
- **Variable names**: `UPPER_SNAKE_CASE` for script-scope variables, constants, and exported/env vars; `snake_case` for function-local variables. Case signals scope — uppercase = top-level, lowercase = local. Don't mix the two rules within a project.
- **Functions**: `snake_case` names with `function_name() {` syntax (no `function` keyword). Declare locals with `local`; grouping related ones on one line is fine (`local env_key="$1" secret_id="$2"`).
- **Conditionals**: Prefer `[[ ]]` over `[ ]` for bash scripts. Use `[ ]` only in POSIX sh scripts.
- **Command substitution**: Use `$(cmd)`, never backticks.
- **Indentation**: 2 spaces.

## Error Handling

- Use `trap` for cleanup: `trap cleanup EXIT`
- **Validate inputs early**, before any work runs. Idioms:
  - Required positional → `PROTO_LANG="${1:?PROTO_LANG required}"` to fail fast with a message.
  - Optional with fallback → `OUTPUT_DIR="${2:-src/generated}"`.
  - When you want a full usage line, guard on arg count:

    ```bash
    if [[ $# -lt 1 ]]; then
      echo "Usage: script.sh <arg>" >&2
      exit 1
    fi
    ```
- Prefer `die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }` pattern for fatal errors.
- Redirect error messages to stderr: `echo "error: ..." >&2`

## POSIX Compatibility

- Match the shebang to the features used: bashisms (`[[ ]]`, arrays, `local`) require `#!/usr/bin/env bash`, never `#!/bin/sh`.

## Best Practices

- **ShellCheck compliant**: All scripts must pass `shellcheck`. Satisfy the rule rather than disabling it — e.g., for SC2155, separate declaration and assignment instead of adding a disable directive.
- **No useless cat**: Use `< file` instead of `cat file |`.
- **Avoid needless subprocesses**: use parameter expansion over forking — `${var%pattern}` not `sed`/`cut` for simple string ops.
- **Temp files**: Use `mktemp` and clean up via trap.
- **Readonly**: realize the immutability principle with `readonly` (or `declare -r`). Assign first, then mark — `GIT_ROOT="$(cmd)"` then `readonly GIT_ROOT` — so command-substitution failures aren't masked under `set -e`. Skip it in sourced libraries, where re-sourcing a `readonly` var errors out.
- **Comment the non-obvious**: explain *why* above a block and decode unusual constructs (yq operators, scratch-image `docker cp`, parameter-expansion idioms). Don't narrate self-evident lines.
