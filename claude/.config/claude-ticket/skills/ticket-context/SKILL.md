---
name: ticket-context
description: Gather the context for work in a ticket workspace. Use on the first prompt describing what to build or change, or when the user mentions the ticket or Linear.
---

The Linear issue key is the name of the current directory. Read the issue and its comments, then the parts of each worktree the request touches.

Reply with, in this order: what the issue asks, what the user's prompt adds or changes, the current state per repo, constraints found, and the questions neither the issue nor the code answers. Facts only, no proposals, no next steps.
