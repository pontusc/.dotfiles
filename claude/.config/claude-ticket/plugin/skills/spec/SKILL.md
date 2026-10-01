---
name: spec
description: Crystallize the current conversation into spec.md and spec-context.md, the end state the ticket work must reach.
disable-model-invocation: true
---

Synthesize what the conversation has settled. Do not interview. A question still open goes under Open, never gets a guessed answer.

Write both files in the current directory. If either exists, show its first section and ask before overwriting.

Both describe the destination, never the route. No steps, no ordering, no file paths, no code. A shape that encodes a decision more precisely than prose, such as a schema, a state machine or an interface, may appear inline, trimmed to the decision.

Both are slim. One line per fact, no restating between sections or files, nothing the code or the issue already says. A section is a few lines, not a page.

`spec.md` is for the operator to verify:

- Goal: the end state from the operator's perspective.
- End state: per repo, the observable behaviour, infrastructure or user functionality once the work is done.
- Dangers: what the implementation itself can break while it happens, for users, data or environments, and where the operator must be present. Not the risks of the finished design.
- Verification: checks a person can run to confirm the goal, one per line.

`spec-context.md` is for agents that pick the work up later. Sections in this order, each omitted only when empty:

- Invariants: what must not change.
- Caveats: known limitations, what will surprise the implementer.
- Out of scope.
- Decisions: one line each, the choice and the rejected alternative.
- Open: questions the conversation did not settle.
