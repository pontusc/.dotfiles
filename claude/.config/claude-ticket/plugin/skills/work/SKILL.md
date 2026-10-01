---
name: work
description: Run the next phase of the ticket plan to its exit criteria. Use in a ticket workspace when the user says go, next phase, go next phase, run phase N or similar.
---

Without `plan.md`, stop. The operator reviews the spec and runs `/ticket:plan`.

Read `plan.md`, `progress.md` when it exists, and the phase file to run: phase N when the user names it, otherwise the phase whose Outcome in `plan.md` is empty. When that phase has no file yet, invoke `ticket:plan` first.

## Ledger

`progress.md` in the ticket root holds one line per task of the phase with its state, todo, running, done or blocked, and a Rulings section. A ruling records the decision, why, and the cost if wrong. A rerun resumes from the ledger.

## Task groups

Tasks joined by a blocking edge form one group, run in order. Groups with no edge between them run in parallel, one fresh executor each, launched in one message. Never `isolation: worktree`, it branches from the default branch and not the ticket branch.

A brief holds the group's tasks verbatim with their inline shapes, the worktree path, and the convention skills to invoke for the files it touches. Manual tasks are never briefed.

## After each group

One message launches a validator on the touched files and two reviewers. One checks spec compliance and quotes the phase line each finding concerns, one checks quality. Findings go to a fresh executor. After three fix rounds, stop and report each remaining finding as Expected, Found, Why this matters.

## Phase end

- A reviewer on the phase's full diff in each worktree.
- Each repo's pre-push hook and Makefile validation targets, run for real through a validator.
- Every Automated exit criterion, its command output quoted.
- The Outcome in `plan.md`.

Then invoke `ticket:plan` for the next phase and stop. Ask before running it and list the Manual exit criteria for the operator to confirm. When a `/goal` is active, run the next phase without asking.

## Waits and stops

A wait or command over a minute runs as a background agent or under Monitor, never a foreground loop.

Stop only for a Manual task, a remote mutation that needs the hard rule unlock, or the fix round cap. For a Manual task, give the exact command and why it is the operator's.
