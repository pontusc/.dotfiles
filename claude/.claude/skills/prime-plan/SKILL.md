---
name: prime-plan
description: Re-prime the session with a previously authored plan. Reads the Markdown source from ~/plans/src and loads its decisions, structure, and open items so work continues where the plan left off.
user-invocable: true
model-invocable: true
allowed-tools: Bash, Agent
model: haiku
---

Load context from a plan's Markdown source in `~/plans/src`. Delegate the read to a Haiku agent — keep the source out of the main thread.

## Select the plan

- User named one (e.g. `arc`) → match against `~/plans/src/*.md`.
- No argument or no clear single match → `ls ~/plans/src/*.md` and ask which. Don't guess.

## Delegate

Spawn one `Agent` (`subagent_type: "general-purpose"`, `model: "haiku"`) to read `~/plans/src/<slug>.md` and return a DENSE briefing (not a paraphrase):

- Title, subtitle, scope, date; the section list (level-1 `#` headings) in order.
- Every locked decision and its rationale — the `[…]{.pill .ok}` items.
- Open gaps, TODOs, unverified caveats — the `.pill .gap`/`.partial` items and `::: {.callout .warn}`/`.bad` blocks.
- Any verbatim config, commands, file paths, or version pins — exactly as written.

This is for reloading working context: preserve specifics (names, numbers, paths, flags) over summary prose. Relay the briefing as the restored context, then continue from there.
