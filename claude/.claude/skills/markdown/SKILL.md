---
name: markdown
description: Markdown authoring rules for READMEs, docs, plan docs, and CLAUDE.md. Apply when writing or editing any .md file.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.md"
---

# Markdown

A README holds what an operator needs to know and the final state of the thing. Nothing else.

## Content

- Operator knowledge: how to run it, what must not be broken, unenforced constraints, the entry point you check when it breaks.
- Final state: what is true now. Never how it got here, migration notes, or "considerations" describing the current setup.
- Delete anything `ls`, `grep`, or the code answers: directory tables, file-tree narration, consumers and call sites, values declared in config, defaults, what deploys the thing, status readable from manifests (RBAC, probes, replicas).
- A constraint the code enforces is inventory too. Only unenforced constraints earn a sentence.
- Write about your own level only. A README covers its directory. Children document themselves.
- Mechanics of a file belong in that file as a comment, not in the README.
- Plan docs and CLAUDE.md record decisions, state, and route by design. They follow the form and punctuation rules only.
- Terse over complete. Short sentences and commas. No semicolons, no em or en dashes, no hyphen standing in for one.

## Form

- Read a sibling `.md` first. Heading depth, tone, wrapping, and section names follow the repo, not this skill.
- One line per paragraph and bullet, unless the target is consistently hard-wrapped. Then match its column.
- Never reflow lines you were not asked to change.

## Before reporting

- Reread every sentence. Delete it if removing it costs an operator nothing, or if the code answers it.
- Grep the file for `;`, `—`, `–`, and a spaced hyphen mid-sentence. Fix every hit.
- Compare heading depth and wrapping with the sibling you read.
