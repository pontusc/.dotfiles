---
name: medium
description: Spawn ~3 independent, context-free reviewers over the recent changes, each scoped to a distinct lens (security, correctness, design, alternatives, edge cases…). Use for a broader independent review when a single pass isn't enough.
user-invocable: true
allowed-tools: Bash, Agent, Read, Grep, Glob
effort: high
---

# review:medium — multi-lens independent review

Three independent reviewers, each looking at the recent changes through a
different lens. Broader than a single pass: catches what a reviewer fixated on
correctness would miss on security, and vice versa.

## Run it

1. **Build the change set.** Default to the uncommitted working tree:
   `git diff HEAD --stat`, then `git diff HEAD`. If the tree is clean, review the
   last commit instead: `git diff HEAD~1 HEAD`. Note the touched files.

2. **State the intent — neutrally.** In two or three sentences, write what the
   change was *meant* to accomplish and any constraints. Frame it as the goal, not
   a defense: do NOT include your own reasoning for why the implementation is
   correct. Each reviewer has to reach its own verdict.

3. **Pick the ~3 lenses that fit THIS change.** Inspect the diff and choose the
   three most relevant viewpoints — don't spawn three generic reviewers.
   Candidates:
   - **Correctness / logic** — does it do what intent says, edge cases included?
   - **Security** — secrets hygiene, injection, least-privilege, supply chain.
   - **Design / approach** — is this the right shape? Is there a simpler one?
   - **Edge cases / failure modes** — bad inputs, errors, concurrency, rollback.
   - **Language idiom / conventions** — fits the surrounding code and the skill.
   - **Interface / naming** — API, flags, names, backward-compatibility.
   - **Test coverage** — is the change actually verified?

4. **Spawn the reviewers in parallel** — one message, three `reviewer` Agent
   calls. Each gets the neutral intent, the changed files, `git diff HEAD`, and its
   single assigned lens (tell it to go deep on that lens, not review everything).
   They are blind to each other and to your reasoning.

5. **Synthesize — don't average.** Report consensus, where reviewers disagree, and
   any single-reviewer blocking concern surfaced prominently. End on a combined
   verdict: **ship / fix-then-ship / rework**.

## As a done-criterion

When a `goal` uses this as a completion check, "ship" means the criterion is met;
"fix-then-ship" or "rework" means it is not — list the blocking items.
