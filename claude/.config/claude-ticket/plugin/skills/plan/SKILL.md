---
name: plan
description: Plan the work in spec.md as plan.md, detailing only the next phase to work on.
disable-model-invocation: true
---

Read `spec.md` and `spec-context.md`. Write `plan.md` beside them.

Every phase has a goal, what it should accomplish on its own, stated in a few lines. Only the next phase to work on is written in full. Later phases stay as a goal and a few notes about what happens there, based on the phases before them.

A phase is planned in full only after the previous one is done and its outcome is recorded under it. When `plan.md` exists, record the outcome of the finished phase if it is missing, then detail the next one, revising the later goals when the outcome changed them. Ask before rewriting a phase already written in full.

Use exactly this structure. Text in angle brackets describes what goes there.

```markdown
# <KEY> plan

## Phase 1: <the end state of this phase in a few words>

### Goal

<What this phase accomplishes on its own, a few lines. Why it comes first when that is not obvious.>

### Tasks

- <One action per bullet. The code, config or command shape it needs sits inline under the bullet, trimmed to what the implementer would otherwise guess.>
- <Mark a task the operator must run themselves, and say why.>

### Test

<Where this phase gets exercised: the environment, branch, PR or deployment used to try it, and how it is exercised there.>

### Exit criteria

- <A check that can be run, with the expected result.>

### Outcome

<Empty until the phase is done. Then: what was done, what differed from the plan and why, and what the next phase must know.>

## Phase 2: <the end state of this phase in a few words>

### Goal

<A few lines.>

### Notes

- <A few points on what happens here, based on the phases before.>
```

Phase 1 is the full form. Every later phase is the short form with Goal and Notes only, and gains the full sections when its turn comes.
