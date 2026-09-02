---
name: bash
description: Shell scripting conventions, applied when writing or editing .sh/.bash files or inline shell scripts.
user-invocable: false
allowed-tools: Read, Glob, Grep, Bash
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Bash Conventions

## Header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- Below the header, a comment of at most three lines states what the script does and how it is invoked (args, where it runs from). Nothing else in the script is narrated.
- A file meant to be sourced omits the `set` line, which would mutate the caller's shell, and says so up top: `# Source this file, it is not meant to be executed directly.`
- Functions are `function_name() {`, never the `function` keyword.
- `UPPER_SNAKE_CASE` for script-scope, constant, and exported variables, `snake_case` for function locals.
- Flags stay inline at the call site. No args array for a flag used twice.
- Prefer a `die()` helper for fatal errors: `die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }`.
- Validate inputs before any work runs: `PROTO_LANG="${1:?PROTO_LANG required}"`, `OUTPUT_DIR="${2:-src/generated}"`.
- `readonly` (or `declare -r`) after assignment, `GIT_ROOT="$(cmd)"` then `readonly GIT_ROOT`, so a command-substitution failure is not masked and SC2155 is satisfied without a disable directive. Skip it in sourced libraries, where re-sourcing a `readonly` var errors out.

## Pitfalls under `set -euo pipefail`

- `set -e` does not fire inside `if`, `while`, or `until` conditions, nor in `&&` and `||` chains. An `ERR` trap needs `-E` to reach functions and subshells.
- An empty-match `grep` in a pipeline exits 1 and kills the script. Collect lines with `readarray -t arr < <(cmd | grep …)`, never a bare `var=$(cmd | grep …)`. Process substitution keeps the grep status out of the script's exit path. Prefer the name `readarray` over `mapfile`, and prefer it over a `while read` loop.
- A bare `cond && action` leaves status 1 when cond is false, so as the last statement of a script or function it silently exits as a failure. Use an explicit `if`.
- Capturing stderr only is `output=$(cmd 2>&1 > /dev/null)`. The order is deliberate. Keep it despite ShellCheck SC2069.

## Before reporting

- `shellcheck` passes on every changed script, with no new disable directives.
- `grep -nE '=\$\(.*grep' <script>` returns nothing on every changed script.
- Every executable script you touched carries `set -euo pipefail` and a usage comment of at most three lines.
