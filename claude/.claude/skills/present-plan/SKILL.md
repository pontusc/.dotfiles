---
name: present-plan
description: Author an actionable implementation plan as Markdown in ~/plans/src; it auto-renders to a navigable dark-themed HTML view at http://plans.claude. Turns a discussion — or an existing present-research document — into ordered, concrete implementation steps with decisions and details.
user-invocable: true
model-invocable: false
allowed-tools: Bash, Agent, Read, Write, Edit
---

Produce an **actionable** implementation plan, authored as Markdown per `~/.config/plans-server/AUTHORING.md` — never write HTML, never touch the theme. Author the file with the `Write`/`Edit` tools, never `cat >` heredocs — the guard-sensitive hook scans Bash command content and will false-positive on document text. This is the action-oriented half of the pipeline: where `present-research` gathers _what's possible_ (options, docs, links), `present-plan` decides _what to do_ and _how_.

## Input — where the plan comes from

- **From the conversation:** structure the plan we've worked out.
- **From a research doc:** given a slug (e.g. `present-plan arc-research`), delegate a Haiku `Agent` to read `~/plans/src/<slug>.md` and return its options, recommendations, links, and constraints. Convert that into decisions and steps — don't just restate it.
- **From the repo:** any codebase context-gathering goes to `scout` agents — never `Explore` or `general-purpose` defaults.

Expect to iterate: the user reviews and discusses while the plan is constructed.

## Make it actionable

- Lead with `## Executive summary` answering the user's explicit questions, each linking to its detail section via a descriptive anchor link (`[Networking](#networking)`).
- Order the work: an implementation roadmap with the exact commands, config, file paths, and version pins to apply.
- Mark decision status inline: `<span class="pill ok">decided</span>` · `<span class="pill gap">gap</span>` · `<span class="pill partial">partial</span>`; close with a gap/decision checklist.
- Flag unverified or risky claims with `!!! warning` / `!!! danger` admonitions.
- Link back to the source research (`http://plans.claude/<research-slug>.html`) for background rather than duplicating it.
