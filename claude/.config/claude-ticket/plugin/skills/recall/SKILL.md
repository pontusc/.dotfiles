---
name: recall
description: Find archived tickets that touched a topic, repo or tag and report what they learned. Use when the user asks about earlier work, or from context before research starts.
---

The archive is the `archive_root` setting in `~/.config/tmux/workspaces.toml`. Without it, say the archive is not configured and stop.

Each entry is `<archive_root>/tickets/<KEY>.md` with YAML frontmatter and the sections Problem, What changed, Decisions, Gotchas, Verification and Open. `<archive_root>/tags.md` defines the tags.

## Search

The query is the user's words, or the repos and nouns the caller passes. Run one Explore agent with: the archive root, the query terms, and the instruction to `rg -il` each term across `tickets/`, to read the frontmatter of every hit, to rank a hit by tag or repo match over a body match, and to return per entry the key, title, closed date, tags and the Decisions and Gotchas lines that concern the query. At most ten entries.

## Reply

One block per entry, newest first: key and title on the first line, then the Decisions and Gotchas that apply. Nothing else from the entry, the caller reads the file when it needs more. No hits: say so in one line.
