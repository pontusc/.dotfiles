---
name: work
description: Run the next phase of the ticket plan or the phase the operator names, to its exit criteria.
disable-model-invocation: true
---

Without `plan.md`, stop. The operator reviews the spec and runs `/ticket:plan`.

Read `plan.md` and the phase file to run: phase N when the user names it, otherwise the phase whose Outcome in `plan.md` is `None yet.` When that phase has no file yet, invoke `ticket:plan` first.

A `HANDOFF.md` in the ticket root is read at the start, then deleted.

## Ledger

The phase file is the ledger. A rerun or a session after compaction resumes at the first unchecked box and trusts checked boxes and `git log` over memory.

- A box is checked with Edit on its own line, its evidence appended in the same edit, in the same message as the work that produced it. Never a heredoc or a script rewrite of the file.
- A decision inside the approved scope, a deviation from a task, or a dismissed review finding appends one line under Rulings: `- Ruling: <decision>. Why: <reason>. Cost if wrong: <cost>.` Rulings are never edited after the fact, a reversal is a new Ruling.

## Task groups

Tasks joined by a Waits for edge form one group, run in order. Groups with no edge between them run in parallel, one fresh executor each, launched in one message. Never `isolation: worktree`, it branches from the default branch and not the ticket branch.

A brief holds the group's tasks verbatim with their inline shapes, the worktree path, and the convention skills to invoke for the files it touches. Operator tasks are never briefed.

Before an executor creates a new file, script, workflow or dashboard whose shape the phase file's Shape section does not fix, state the shape in at most five lines and stop for the operator.

## After each group

One message launches a validator on the touched files and one reviewer. Its brief covers spec compliance, quoting the phase line each finding concerns, and quality. Every Agent call passes `effort`, `medium` for a small group. Findings go to a fresh executor. After three fix rounds, stop and report each remaining finding as Expected, Found, Why this matters.

## Phase end

- A reviewer on the phase's full diff in each worktree, only when the phase spans more than one group or touches an infrastructure apply.
- Each repo's pre-push hook and Makefile validation targets, run for real through a validator.
- Every Automated exit criterion checked, the command and its result as evidence.
- The Verdict line replaced with `VERIFIED`, `NOT VERIFIED` or `INCONCLUSIVE`, then the evidence or the gap. VERIFIED only when every box is checked except Operator tasks and Manual criteria, which the Outcome lists as open. INCONCLUSIVE is not a pass.
- On VERIFIED, the full Outcome in the phase file and its one line Outcome in `plan.md`.

A phase that is not VERIFIED does not end. Report the verdict and the unchecked boxes and stop. When a `/goal` is active, work the gap instead.

Then invoke `ticket:plan` for the next phase and stop. Ask before running it and list the Manual exit criteria and the Review gate for the operator to confirm. When a `/goal` is active, run the next phase without asking until the goal's exit criteria are met, whatever the Review gate says.

## Stops

Stop only for an Operator task, a remote mutation that needs the hard rule unlock, a new shape Shape does not fix, the fix round cap, a review finding that removes the purpose of a planned task, or a verdict that is not VERIFIED outside a `/goal`. For an Operator task, give the exact command and why it is the operator's.
