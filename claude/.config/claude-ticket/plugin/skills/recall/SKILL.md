---
name: recall
description: Find archived tickets that touched a topic, repo or tag and report what they learned. Use when the user asks about earlier work, or from context before research starts.
---

The archive is the `archive_root` setting in `~/.config/tmux/workspaces.toml`. Without it, say the archive is not configured and stop.

Each entry is `<archive_root>/tickets/<KEY>.md` with YAML frontmatter (key, title, closed, repos, tags) and sections. Problem states the issue, every other section holds what the ticket learned. `<archive_root>/tags.md` defines the tags, each line names a tag and the other names it goes by. An entry is a snapshot as of its `closed` date.

## Search

The query is the user's words, or the repos and nouns the caller passes. Run one Explore agent with the archive root, the query, and these instructions:

1. Read tags.md. A tag matches when its name or its description contains a query word. Collect the matching tags.
2. Keep only the specific query terms, identifiers, hostnames, product and service names, ticket keys. Drop words that name a kind of thing, such as dev, infra, cluster, service, config, repo, and anything under four characters that is not an identifier.
3. Find entries by `rg -ilw` for each kept term across `tickets/`, and by `rg -l` for each matching tag inside the `tags:` line.
4. Rank by the number of distinct terms and tags an entry matched, a repo match only breaks ties. At most ten entries.
5. Return per entry the key, title, closed date, tags, and every line outside Problem that concerns the query, each with its section name.

## Reply

One block per entry in rank order: key, title and closed date on the first line, then the lines that apply, grouped by section. Nothing else from the entry, the caller reads the file when it needs more. No hits: say so in one line.
