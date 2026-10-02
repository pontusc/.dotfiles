Ticket {key} is closed. Write its archive entry at `{archive_root}/tickets/{key}.md` so a later agent working near this area finds what this ticket learned. You write nothing else, you never change a worktree, a repo or the ticket directory.

## Inputs

- The ticket directory `{ticket_root}`: spec.md, spec-context.md, plan.md, phase files, progress.md, research.md and any loose notes. Phase Outcomes in plan.md and Rulings in progress.md carry the most.
- `{inputs}/git/<n>-<repo>.md`: the commits the ticket branch added in each worktree, with pull requests and their state. The full patch sits beside it as `<n>-<repo>.patch`, read the hunk of a commit whose message leaves the change unclear, never the whole file.
- `{inputs}/transcripts/`: the conversations with the operator, reduced to text. Long. Grep for `ruling`, `decided`, `instead`, `because`, `rejected`, `gotcha`, `surprise`, `turned out` and read around the hits, never the whole file.
- The Linear issue {key} and its comments, through the Linear tools, for the problem statement and anything the operator wrote there.
- `{archive_root}/tags.md`: the tag vocabulary, one `- <tag>: <what it covers>` line per tag. Read it first, or create it when missing. Reuse a tag whenever one fits. Add a tag only when none does, as a new line in the same form.
- Other entries under `{archive_root}/tickets/`: grep them for the same repos and tags to fill `related`.

## Entry

Only knowledge that is not in the code, the commits or the issue: why a choice was made over its alternative, what surprised the implementers, what was verified and how, what remains open. A line a later agent would learn from `git log` or `ls` is noise, leave it out. Short sentences, commas, no semicolons, no dashes used as punctuation.

```markdown
---
key: {key}
title: <the work in one line>
closed: <today, YYYY-MM-DD>
repos: [<repo>, ...]
branches: [<branch>, ...]
prs:
  - url: <url>
    state: <merged, open or closed>
tags: [<tag>, ...]
related: [<key>, ...]
---

# {key} <title>

## Problem

<What was wrong or missing, from the issue and the spec, a few lines.>

## What changed

<Per repo, the shape of the change in a few lines. Not the file list.>

## Decisions

- <The choice, the rejected alternative, why. One line each.>

## Gotchas

- <What surprised the work, what a later agent in this area must know. One line each.>

## Verification

<How the result was confirmed, and what was never verified.>

## Open

- <Questions or work left undone, one line each. Omit the section when empty.>
```

Write the entry with the Write tool. Edit tags.md only to append. Then stop.
