---
name: markdown
description: Markdown authoring conventions (wrapping, structure, terseness), applied when writing or editing .md files (READMEs, docs, plan docs, CLAUDE.md).
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Markdown Conventions

Apply when authoring or editing any `.md` file.

## Match the target before writing

Read a sibling `.md` in the same repo/dir first. Wrapping, heading depth, tone, and section
naming are per-repo conventions, not personal defaults. A new file that reads unlike its
neighbours is a defect even when its content is right. Where the target has no markdown yet,
the defaults below apply.

## Wrapping

- **Let the renderer wrap.** One line per paragraph and per bullet, never breaking
  mid-sentence to hit a column.
- **A consistently hard-wrapped target wins.** Match its column and continuation-line
  indentation (agent-instruction trees are often wrapped this way).
- **Never reflow what you weren't asked to change.** Rewrapping turns a one-word fix into a
  whole-paragraph diff.

## Prose

Terse over complete. State intent, caveats, and non-obvious constraints, and drop what the
file tree or the code already says.

**Plain punctuation.** No semicolons, no em or en dashes, no hyphen standing in for one.
Commas and short sentences carry the same meaning without reading as generated text.
Hyphens inside compound words are fine.

**Inventory is not a caveat.** If `ls`, `grep`, or the code itself answers it, cut it:
subdirectories, consumers, call sites, and values declared in config (retention days,
schedules, IPs, thresholds) are all inventory. This binds hardest on facts you just
established by reading or searching: the source informed *you*, it is not content to
report. State the constraint that survives those specifics changing ("retention is capped
by the lifecycle rules"), never the specifics. A number earns its place only as an
operational entry point, the ASN you check when BGP breaks, never as restatement.

A constraint the code already enforces is inventory too: a version floor in the config, a
pattern the module makes impossible. The reader cannot violate it, so prose about it is only
a second copy to maintain. Only unenforced constraints earn a sentence.

**Write about your own level only.** A README covers the directory it sits in. Anything true
of a subdirectory belongs to that subdirectory's README. A parent explaining its children
duplicates docs that then drift apart.

**Document the end state, not the route to it.** Migration, import, refactor: how the thing
got here is changelog material, dead the moment it ships. Write what is true now and what a
reader must not break.
