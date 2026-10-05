Ticket {key} is closed. Write its archive entry at `{archive_root}/tickets/{key}.md` so a later agent working near this area finds what this ticket learned. You write nothing else, you never change a worktree, a repo or the ticket directory.

## Inputs

- The ticket directory `{ticket_root}`: spec.md, spec-context.md, plan.md, phase files, research.md and any loose notes. Phase Outcomes in plan.md, Rulings in the phase files and any section marked as a decision of the user or operator carry the most.
- `{inputs}/git/<n>-<repo>.md`: the commits the ticket branch added in each worktree, with pull requests and their state. The full patch sits beside it as `<n>-<repo>.patch`, read the hunk of a commit whose message leaves the change unclear, never the whole file. Commits by other authors or under another ticket key are context, never this ticket's work.
- `{inputs}/transcripts/`: the conversations with the operator, reduced to text. Long. `## user` blocks are the operator, `## assistant` blocks are the assistant. Grep for `ruling`, `decided`, `instead`, `keep`, `skip`, `rejected`, `gotcha`, `turned out` and read the `## user` block after each hit, the operator's reply decides. Never read a whole file.
- The Linear issue {key} and its comments, through the Linear tools, for the problem statement and anything the operator wrote there.
- `{archive_root}/tags.md`: the tag vocabulary, one `- <tag>: <what it covers, and the other names it goes by>` line per tag. Read it first, or create it when missing.

## What goes in

Only knowledge that is not in the code, the commits, the pull requests or the issue. A line a later agent would learn from `git log`, `ls`, `grep` or the Linear tools is noise, leave it out.

- A decision is what the operator chose or confirmed. An assistant proposal the operator did not take is not a decision and is not knowledge. When the operator rejected it, record the rejection, as a rejection.
- Name an alternative only when the inputs name one. Never construct a weighed alternative for a choice that had none.
- A gotcha is something the work observed. Something concluded without observing it is labeled `inferred`.
- A fact that changes over time, a size, a count, the state of another repo's branch or pull request, a Linear status, carries the date it held or is left out.
- Everything is as of the close. A pull request still open, a branch unmerged or work cancelled is stated as that, nothing is predicted.

## Tags

Tag what the ticket changed or diagnosed, never everything it touched or read. Component level, a system, a service or a mechanism, never a GCP project, a repo or a team. Two or three tags, five at most. Reuse a tag whenever one fits. Add at most one tag, only when none fits, as a new line in the same form with the other names the thing goes by in its description.

## Entry

Short sentences, commas, no semicolons, no dashes used as punctuation. `repos` are the `<repo>` names from the git input filenames.

```markdown
---
key: {key}
title: <the work in one line>
closed: <today, YYYY-MM-DD>
repos: [<repo>, ...]
tags: [<tag>, ...]
---

# {key} <title>

## Problem

<The symptom and its cause, from the issue and the spec, a few lines.>

## Decisions

- <The operator's choice and why. One line each.>

## Gotchas

- <What surprised the work, what a later agent in this area must know. One line each.>

## State at close

<What was applied and where, what was changed by hand outside the commits, console, kubectl, gcloud or edits in another repo, and what did not land, unmerged, cancelled or reverted. Omit the section when the commits say it all.>

## Open

- <Questions, work left undone and what was never verified, one line each. Omit the section when empty.>
```

Write the entry with the Write tool. Edit tags.md only to append. Then stop.
