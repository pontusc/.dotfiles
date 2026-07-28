---
name: markdown
description: Markdown authoring conventions — wrapping, structure, terseness — applied when writing or editing .md files (READMEs, docs, plan docs, CLAUDE.md).
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Markdown Conventions

Apply when authoring or editing any `.md` file.

## Match the target before writing

Read a sibling `.md` in the same repo/dir first. Wrapping, heading depth, tone, and section
naming are per-repo conventions, not personal defaults — a new file that reads unlike its
neighbours is a defect even when its content is right. Where the target has no markdown yet,
the defaults below apply.

## Wrapping

- **Let the renderer wrap.** One line per paragraph and per bullet — never break
  mid-sentence to hit a column.
- **A consistently hard-wrapped target wins.** Match its column and continuation-line
  indentation (agent-instruction trees are often wrapped this way).
- **Never reflow what you weren't asked to change.** Rewrapping turns a one-word fix into a
  whole-paragraph diff.

## Prose

Terse over complete. State intent, caveats, and non-obvious constraints; drop what the file
tree or the code already says.

**Inventory is not a caveat.** If `ls`, `grep`, or the code itself answers it, cut it —
subdirectories, consumers, call sites, and values declared in config (retention days,
schedules, IPs, thresholds) are all inventory. This binds hardest on facts you just
established by reading or searching: the source informed *you*, it is not content to
report. State the constraint that survives those specifics changing ("retention is capped
by the lifecycle rules"), never the specifics. A number earns its place only as an
operational entry point — the ASN you check when BGP breaks — never as restatement.
