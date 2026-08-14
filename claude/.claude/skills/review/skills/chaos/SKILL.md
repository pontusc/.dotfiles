---
name: chaos
description: Adversarially stress-test the recent changes, spawn chaos agent(s) that actively try to break the intended behavior with hostile inputs, edge cases, races, and exploit attempts, and report reproducible failures. Use to pressure-test correctness and security before calling a change done.
user-invocable: true
allowed-tools: Bash, Agent, Read, Grep, Glob
effort: high
---

# review:chaos (adversarial stress test)

Turn the recent changes over to the attacker. One or more `chaos` agents try to
*break* the intended behavior (not review its design) and report reproducible
failures. Use when correctness or security matters more than style.

## Run it

1. **Build the change set.** `git diff HEAD --stat`, then `git diff HEAD` (or
   `git diff HEAD~1 HEAD` if the tree is clean). Note the touched files.

2. **State the intended behavior, concretely.** Chaos needs to know what "working"
   means to know what counts as broken: the contract, invariants, valid input
   ranges, and the trust / security assumptions. Be specific: vague intent yields
   vague attacks.

3. **Pick the attack surfaces** that fit the change, e.g.:
   - **Input / parsing**: malformed, oversized, empty, Unicode, boundary values.
   - **Injection**: shell, path, SQL, template, argument smuggling.
   - **State / concurrency**: ordering, re-entrancy, races, partial failure, rollback.
   - **Resources**: exhaustion, large inputs, unbounded loops, leaks.
   - **Trust / secrets**: privilege boundaries, secret exposure, auth gaps.

4. **Spawn `chaos` agent(s)**: for a broad surface, one per major surface in
   parallel (single message). For a small change, one agent suffices. Give each the
   intended behavior, the changed files, `git diff HEAD`, and its assigned surface.
   Tell it to PROVE breaks by running them, not just hypothesize.

5. **Synthesize a break report.** Order by severity (exploitable / data-loss /
   crash / wrong-result first). For each: repro, what broke vs. intended, the
   violated assumption. End on a verdict: **ship / fix-then-ship / rework**, with
   confirmed breaks as the blocking items.

## As a done-criterion

When a `goal` uses this as a completion check, "ship" means no blocking break was
found. Any confirmed exploit / data-loss / crash means **not done**: list them.
