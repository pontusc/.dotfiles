---
name: phases
description: Plan the work in spec.md as phases.md, detailing only the next phase to work on.
disable-model-invocation: true
---

Read `spec.md` and `spec-context.md`. Write `phases.md` beside them.

Every phase has a goal, what it should accomplish on its own, stated in a few lines. Only the next phase to work on is written in full: the tasks, code or config shapes, what to deploy and where to test it, and the exit criteria as checks that can be run. Later phases stay as a goal and a few points about what happens there, based on the phases before them.

A phase is planned in full only after the previous one is done and its outcome is recorded under it. When `phases.md` exists, record the outcome of the finished phase if it is missing, then detail the next one, revising the later goals when the outcome changed them. Ask before rewriting a phase already written in full.
