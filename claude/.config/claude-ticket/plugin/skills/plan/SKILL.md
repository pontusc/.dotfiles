---
name: plan
description: Plan the work in spec.md as plan.md plus one phase-N.md per detailed phase, detailing only the next phase to work on. Invoked by work when a phase ends, never to start a plan.
---

Without `plan.md`, run only when the user typed `/ticket:plan`, that is the sign the spec is reviewed. Invoked any other way, stop and say so.

Read `spec.md`, `spec-context.md` and `research.md`. Write `plan.md` beside them, and `phase-N.md` for the phase being detailed.

`plan.md` is the overview and stays short. Every phase has a goal, what it should accomplish on its own, stated in a few lines, and a few notes about what happens there, based on the phases before it. A finished phase also carries its outcome. The full detail of a phase, its tasks, test and exit criteria, lives in `phase-N.md` and is written only for the next phase to work on.

A phase is detailed only after the previous one is done and its outcome is recorded in `plan.md`. When `plan.md` exists, read it and the newest `phase-N.md`. Record the outcome of the finished phase if it is missing, then write the next phase file, revising the later goals when the outcome changed them. The outcome must carry everything the next phase needs, so an earlier phase file is read only when an outcome points at it. Ask before rewriting a phase file that already exists.

Both files are written once and then changed line by line with Edit. Every placeholder line stays in place so a change is an edit of that line. A revised goal or note is an edit of its own lines, never a rewrite of the file.

Use exactly this structure. Text in angle brackets describes what goes there.

`plan.md`:

```markdown
# <KEY> plan

## Phase 1: <the end state of this phase in a few words>

### Goal

<What this phase accomplishes on its own, a few lines. Why it comes first when that is not obvious.>

### Notes

- <A few points on what happens here, based on the phases before.>

### Outcome

None yet.
```

The Outcome stays `None yet.` until the phase verdict is VERIFIED. Then it holds what was done, what differed from the plan and why, and what the next phase must know.

`phase-1.md`:

```markdown
# <KEY> phase 1: <the same heading as in plan.md>

### Tasks

- [ ] <One unit of work per box. The code, config or command shape it needs sits inline under the box, trimmed to what the implementer would otherwise guess.>
  - [ ] <A nested box is a sub-step of the box above it.>
- [ ] Operator: <a task the operator must run themselves, and why.>
- [ ] <A task that must wait for another because both touch the same state, root module or lockfile.> Waits for: <the task it waits for>.

### Test

<Where this phase gets exercised: the environment, branch, PR or deployment used to try it, and how it is exercised there.>

### Exit criteria

#### Automated

- [ ] <A command an agent runs, with the expected result.>

#### Manual

- [ ] <A check only the operator can make, and how.>

### Review gate

<What the operator reviews before the next phase starts. Or None, and why no operator review is needed.>

### Verdict

None yet.

### Rulings
```

A box is checked only with its evidence on the same line, appended after the text as ` Evidence: <file path, commit SHA, or command and its result>.` A box without evidence stays unchecked. A box checked for the operator's word cites it, ` Evidence: operator confirmed.`

The phase being worked on has Goal, Notes and Outcome in `plan.md` and its own phase file. Every later phase has Goal, Notes and an Outcome of `None yet.`, and gains its phase file when its turn comes.

Before presenting a phase file, a reviewer checks it against `spec.md` and `spec-context.md`. Fix its findings first.
