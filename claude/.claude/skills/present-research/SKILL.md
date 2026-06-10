---
name: present-research
description: Research a topic and present the findings as a Markdown document in ~/plans/src that auto-renders to a dark-themed HTML view at http://plans.claude. Use to investigate a question, compare options, or gather and cite sources into a browsable deliverable.
user-invocable: true
model-invocable: false
allowed-tools: Bash, Agent
---

Gather material on a topic, then present it as a **Markdown** findings document authored per `~/.config/plans-server/AUTHORING.md` — never write HTML, never touch the theme. This is the reference half of the pipeline: it captures _what's possible_ (options, docs, links) for `present-plan` to turn into action.

## 1 — Gather (delegate; don't read in the main thread)

Spawn `general-purpose` agents (`model: haiku`) to do the reading and web lookups:

- **Find the official docs / primary source first.** Verify any blog/third-party against official sources; if none cover the point, third-party is acceptable but MUST be flagged unverified.
- Have agents return verbatim specifics (versions, flags, exact config, URLs) — not paraphrase.
- Capture each claim's source for citation.

## 2 — Present the findings

Author `~/plans/src/<slug>.md`:

- `## Executive summary` answering the question up front.
- A section per sub-topic; pipe tables for option comparisons.
- Cite inline: `[official docs](url)`, `<span class="src">…</span>` for provenance.
- Mark every unverified / third-party claim: `<span class="tag">unverified</span>` and/or a `!!! warning` admonition.
- Close with a recommendation and open questions.

## 3 — Hand off (optional)

When the research should drive decisions, point `present-plan` at this doc.
