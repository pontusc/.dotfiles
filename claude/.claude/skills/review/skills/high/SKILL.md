---
name: high
description: Spawn 6+ independent, context-free reviewers in a thorough audit (full lens set, double-staffed risk areas, devil's-advocate and alternatives reviewers) over the recent changes. Use for high-stakes changes that need maximum scrutiny before calling them done.
user-invocable: true
allowed-tools: Bash, Agent, Read, Grep, Glob
effort: high
---

# review:high (thorough independent audit)

Six or more independent reviewers in an audit pattern. For high-stakes changes
where you want maximum scrutiny before calling it done.

## Run it

1. **Build the change set.** `git diff HEAD --stat`, then `git diff HEAD` (or
   `git diff HEAD~1 HEAD` if the tree is clean). For a large diff, also group the
   touched files into coherent areas: you'll partition deep-dive reviewers across
   them.

2. **State the intent, neutrally.** Write what the change was *meant* to
   accomplish and any constraints, framed as the goal, not a defense. Do NOT feed
   reviewers your own reasoning for why it's correct: every reviewer reaches its
   own verdict.

3. **Design the audit.** Staff 6+ agents: `reviewer`s plus, where it helps, a
   `chaos` agent. Cover the full lens set (correctness, security, design / simpler
   alternatives, edge cases, language idiom, interface / naming, test coverage),
   and add depth:
   - **Double-staff the highest-risk lens** for this change: two reviewers, so a
     miss by one is caught by the other.
   - **Devil's advocate**: one reviewer tasked solely with building the strongest
     case that this change is wrong or should not ship.
   - **Alternatives**: one reviewer to propose at least one materially different
     approach and argue its trade-offs against what was built.
   - **Chaos**: spawn a `chaos` agent (not a reviewer) to actively try to break
     the change with hostile inputs and exploit attempts. Fold its confirmed breaks
     into the report.
   - For large diffs, assign reviewers to **file-group slices** so each goes deep
     rather than skimming everything.

4. **Spawn them in parallel**: one message, all `reviewer` Agent calls. Each gets
   the neutral intent, the changed files, `git diff HEAD`, and its specific charge.
   Blind to each other and to your reasoning.

5. **Synthesize into an audit report.** Group findings by severity. Note consensus
   versus lone-voice concerns (a single reviewer's blocking finding still blocks).
   Capture the devil's-advocate and alternatives arguments even if you ultimately
   reject them. End on a combined verdict: **ship / fix-then-ship / rework**.

## As a done-criterion

When a `goal` uses this as a completion check, "ship" means the criterion is met.
"fix-then-ship" or "rework" means it is not: list the blocking items.
