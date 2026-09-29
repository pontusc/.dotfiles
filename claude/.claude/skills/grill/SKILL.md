---
name: grill
description: Grill the user relentlessly about a plan, decision, or idea until nothing is left assumed. Use when the user wants their thinking stress-tested or says grill.
---

Interview the user until you share one understanding. Treat it as a design tree, every decision branches into the decisions that hang off it.

Work in rounds. The frontier is every decision whose prerequisites are settled, the questions you can ask now without guessing at answers you have not heard. Ask the whole frontier in one round, then wait for the answers.

Format each question as:

**Q1 <title>**
<body, with the options when there are any>
Recommended: <your answer>

Answers reshape the tree. Settled decisions push the frontier outward and unblock what depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another still open in this round belongs to a later round.

Facts are your job, never the user's. When a question needs a fact from the environment, dispatch a subagent for it and do not block the rest of the frontier on it, only the questions downstream of it wait. Decisions are the user's, put each one to them.

Done when the frontier is empty and nothing is silently assumed. Say that a shared understanding is reached and stop. Do not act on it until the user confirms.
