---
name: prime
description: Bootstrap session context by reading and summarizing a source. No argument primes from the local project (READMEs, file listings, config markers, git log); a plan name primes from a saved document in ~/plans/src. Delegates the reading to a Haiku agent.
user-invocable: true
model-invocable: true
allowed-tools: Bash, Agent
model: haiku
---

Load context by delegating the reads to a Haiku agent — never read large files in the main thread. Pick the source from the argument.

## Local project (no argument, `.`, or `here`)

Spawn one `Agent` (`general-purpose`, `haiku`) to gather and summarize:

1. List files in cwd (non-recursive, then one level deep).
2. Read any README / CONTRIBUTING / similar.
3. Read present markers: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `justfile`, `flake.nix`; `.claude/CLAUDE.md`, `CLAUDE.md`; `.envrc`, `.tool-versions`, `mise.toml`.
4. If a git repo: `git log --oneline -10`.

Return a dense summary: what the project is, key directories, language/framework/tooling, visible conventions, recent git activity.

## Saved plan / document (a slug, or `plan <name>`)

- Match the name against `~/plans/src/*.md`. No clear single match → `ls ~/plans/src/*.md` and ask. Don't guess.
- Spawn one `Agent` (`general-purpose`, `haiku`) to read `~/plans/src/<slug>.md` and return a DENSE briefing: title/subtitle/scope/date; section list (level-1 `#`) in order; locked decisions (`[…]{.pill .ok}`); open gaps/caveats (`.pill .gap`/`.partial`, `::: {.callout .warn}`/`.bad`); verbatim config/commands/paths/version pins.

Either way, relay the result as restored context and continue.
