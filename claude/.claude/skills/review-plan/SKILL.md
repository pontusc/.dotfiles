---
name: review-plan
description: Reconcile a saved plan in ~/plans/src against reality — verify which gaps and decisions were actually implemented, report the drift, and on approval revise the document in place. Takes a plan slug. Closes the loop after implementation.
user-invocable: true
model-invocable: false
allowed-tools: Bash, Agent
---

Audit a plan document against the current state of the world, then bring the document back in sync. This closes the lifecycle loop: `present-research` → `present-plan` → implement → **review-plan** → revised plan → `prime`.

## Input

Match the argument against `~/plans/src/*.md` — same rule as `prime`: no clear single match → `ls ~/plans/src/*.md` and ask. Don't guess.

## 1 — Extract claims (delegate, haiku)

Spawn one `Agent` (`general-purpose`, `haiku`) to read `~/plans/src/<slug>.md` and return verbatim:

- every `<span class="pill gap">` / `<span class="pill partial">` item with its surrounding sentence and section anchor;
- every roadmap step (commands, file paths, config blocks) and its stated target;
- every version pin;
- the closing gap/decision checklist, item by item.

## 2 — Verify against reality (delegate, sonnet)

For each claim, spawn read-only `general-purpose` (`sonnet`) agents to check what is actually true:

- Do the asserted files/configs/resources exist as the plan specifies?
- Were the `gap` / `partial` items built? Fully or partially?
- Are version pins still current? Check live (web/registry) — never trust training data.

Verdict per claim: **done** / **drifted** (exists but differs — say how) / **still open**.

## 3 — Report, then revise on approval

Present the drift as a pipe table (claim · plan said · reality · verdict) and STOP for the user's review. Do not edit the document before approval.

On approval, revise `~/plans/src/<slug>.md` **in place** per `~/.config/plans-server/AUTHORING.md` — never spawn a `-v2` document:

- Edit mechanism: only `Bash` is available (no `Write`/`Edit` — deliberate, see AUTHORING.md). Make targeted in-place substitutions with `sed -i` / `perl -i`; for larger rewrites, regenerate the whole file via heredoc. Verify each substitution landed (`grep`) before moving on.
- Flip pills for **done** items: `pill gap` / `pill partial` → `pill ok`; check off completed checklist items. **drifted** / **still open** items keep their pill.
- Where reality diverged from the plan, update the prose to match reality and mark it: `!!! note "Revised YYYY-MM-DD"` (ISO date).
- Append a dated entry to a `## Review log {#review-log}` section — create it if absent, placed after the closing checklist as the document's final section: what was verified, what changed, what remains open.
- Update the document's card date in `~/plans/src/index.md`.
