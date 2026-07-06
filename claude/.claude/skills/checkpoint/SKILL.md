---
name: checkpoint
description: Persist session state to a durable artifact before compact/clear — plan doc if
  the session is plan-driven, otherwise a handoff .md. Use when the user says "checkpoint",
  "prepare to compact", "note this and update the plan", or hands over what's done / what's next.
user-invocable: true
disable-model-invocation: true
argument-hint: [what's done, what's next]
---

# Checkpoint

Persist session state so nothing depends on conversation memory surviving compact/clear.
The argument is the user's status note — merge it with your own knowledge of the session.

## 1. Pick the durable artifact (in priority order)

1. **Plan-driven session** (plan:* skills used, or a plan doc is loaded): update the plan
   doc — mark completed phases, note current position and next step. Do NOT restructure
   the doc; this is a position marker, not a rewrite. Suggest `/plan:review <slug>` if the
   doc has drifted from what was actually implemented.
2. **A handoff/notes .md already exists for this work**: update it in place.
3. **Neither**: create `CHECKPOINT.md` in the repo/project root. Overwrite on subsequent
   checkpoints — it is a baton, not a log. Delete it when the work fully completes.

## 2. What to capture (word economy applies)

- **Done** — completed steps, with outcomes.
- **Next** — the immediate next action, concrete enough to start cold.
- **Decisions** — choices made and WHY, incl. rejected alternatives.
- **Pointers** — critical file:line refs, commands that worked, live IDs/values resolved.
- **Gotchas** — anything that cost time this session and would again.
- **Resume** — one line: how to reload (`/prime` + `@CHECKPOINT.md`, or `/plan:prime <slug>`).

## 3. Commit

If the user's note asks for a commit (or the session convention is commit-per-phase),
commit the checkpoint writeback (and only it) with a message describing the phase state.
Otherwise leave it uncommitted and say so.

## 4. Confirm

Reply with: artifact path, one-line summary of what was persisted, whether committed,
and "safe to /compact or /clear".
