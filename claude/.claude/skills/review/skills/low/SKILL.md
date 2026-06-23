---
name: low
description: Spawn ONE independent, context-free reviewer over the recent changes for a fast second-opinion pass on correctness and design. Use when you want a quick independent gut-check that the implementation matches intent before calling it done.
user-invocable: true
allowed-tools: Bash, Agent, Read, Grep, Glob
---

# review:low — single independent reviewer

A fast, independent second opinion on the recent changes. One reviewer subagent,
no session context, judges whether the implementation matches intent and the
choices are sound.

Use when the change is small or localized, or you just want one more pair of eyes
before calling it done.

## Run it

1. **Build the change set.** Default to the uncommitted working tree:
   `git diff HEAD --stat`, then `git diff HEAD`. If the tree is clean, review the
   last commit instead: `git diff HEAD~1 HEAD`. Note the touched files.

2. **State the intent — neutrally.** In two or three sentences, write what the
   change was *meant* to accomplish and any constraints. Frame it as the goal, not
   a defense: do NOT include your own reasoning for why the implementation is
   correct. The reviewer has to reach its own verdict — feeding it your
   justifications defeats the purpose.

3. **Spawn one `reviewer` agent.** Hand it the neutral intent, the list of changed
   files, and `git diff HEAD` as the way to see the change. Ask for a holistic pass
   — correctness, design, edge cases — and a verdict.

4. **Relay the verdict.** Pass the reviewer's findings through honestly, including
   any concern you disagree with. End on its verdict:
   **ship / fix-then-ship / rework**.

## As a done-criterion

When a `goal` uses this as a completion check, "ship" means the criterion is met;
"fix-then-ship" or "rework" means it is not — list the blocking items.
