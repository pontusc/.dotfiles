---
name: plan
description: Plan the work in spec.md as plan.md plus one phase-N.md per detailed phase, detailing only the next phase to work on. Invoked by work when a phase ends, never to start a plan.
---

Without `plan.md`, run only when the user typed `/ticket:plan`, that is the sign the spec is reviewed. Invoked any other way, stop and say so.

Read `spec.md`, `spec-context.md` and `research.md`. Write `plan.md` beside them, and `phase-N.md` for the phase being detailed.

`plan.md` is the overview and stays short. Every phase has a goal, what it should accomplish on its own, stated in a few lines. Later phases carry a few notes about what happens there, based on the phases before them. A finished phase carries its outcome instead. The full detail of a phase, its tasks, test and exit criteria, lives in `phase-N.md` and is written only for the next phase to work on.

A phase is detailed only after the previous one is done and its outcome is recorded in `plan.md`. When `plan.md` exists, read it and the newest `phase-N.md`. Record the outcome of the finished phase if it is missing, then write the next phase file, revising the later goals when the outcome changed them. The outcome must carry everything the next phase needs, so an earlier phase file is read only when an outcome points at it. Ask before rewriting a phase file that already exists.

Use exactly this structure. Text in angle brackets describes what goes there.

`plan.md`:

```markdown
# <KEY> plan

## Phase 1: <the end state of this phase in a few words>

### Goal

<What this phase accomplishes on its own, a few lines. Why it comes first when that is not obvious.>

### Outcome

<Empty until the phase is done. Then: what was done, what differed from the plan and why, and what the next phase must know.>

## Phase 2: <the end state of this phase in a few words>

### Goal

<A few lines.>

### Notes

- <A few points on what happens here, based on the phases before.>
```

`phase-1.md`:

```markdown
# <KEY> phase 1: <the same heading as in plan.md>

### Tasks

- <One action per bullet. The code, config or command shape it needs sits inline under the bullet, trimmed to what the implementer would otherwise guess.>
- <Mark a task the operator must run themselves, and say why.>
- <Mark a task that must wait for another because both touch the same state, root module or lockfile, and name the task it waits for.>

### Test

<Where this phase gets exercised: the environment, branch, PR or deployment used to try it, and how it is exercised there.>

### Exit criteria

#### Automated

- <A command an agent runs, with the expected result.>

#### Manual

- <A check only the operator can make, and how.>
```

The phase being worked on has Goal and Outcome in `plan.md` and its own phase file. Every later phase has Goal and Notes only, and gains its phase file when its turn comes.

Before presenting a phase file, a reviewer checks it against `spec.md` and `spec-context.md`. Fix its findings first.
