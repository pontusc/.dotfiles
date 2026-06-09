---
name: write-plan
description: Author a multi-section plan or design document as Markdown in ~/plans/src; it auto-renders to a navigable dark-themed HTML view served at http://plans.claude. Use for deployment plans, architecture proposals, investigations, and any deliverable the user reads in the browser.
user-invocable: true
model-invocable: true
allowed-tools: Bash, Agent
---

Write the plan as **Markdown**; the `plans-render` watcher turns it into the house-themed HTML view. You author content — never write HTML, never touch the theme.

## Save (MUST)

- Write to `~/plans/src/<kebab-slug>.md`. The slug is the plan's identity — revise in place, never spawn `-v2`.
- Never write into a project repo or the cwd. Rendered HTML lands at `~/plans/<slug>.html`, served at **http://plans.claude**.

## Render

- **Automatic** — the `plans-render` watcher re-renders on every save; just write the `.md`.
- **Manual** (complex plan you want to verify now, or the watcher isn't running): `~/.config/plans-server/render.sh ~/plans/src/<slug>.md`.

## Frontmatter (drives the hero header)

```yaml
---
title: actions-runner-controller on the IAT Talos cluster
subtitle: Deployment plan, gap analysis & sizing
date: 2026-06-09
scope: talos-infrastructure
---
```

## Authoring

- One `# Heading` per section → nav entry + auto-numbered section; `## Heading` for subsections. Give stable ids for cross-refs: `# Networking {#networking}`.
- Lead with `# Executive summary` answering the user's explicit questions, each linking to its detail with `[§](#slug)` (auto-renumbered to §N).

## Components — use the house classes, don't invent

| Need              | Markdown                                                                                   |
| ----------------- | ------------------------------------------------------------------------------------------ |
| Status pill       | `[decided]{.pill .ok}` · `[gap]{.pill .gap}` · `[partial]{.pill .partial}`                 |
| Callout           | `::: {.callout .warn}` … `:::`, first line `[Label]{.t}` (variants `.good` `.warn` `.bad`) |
| Side-by-side      | `::: {.grid2}` wrapping two `::: {.card}`                                                  |
| Comparison matrix | standard Markdown table                                                                    |
| Inline annotation | `[…]{.muted}` · `[…]{.src}` · `[v1.13]{.tag}`                                              |
| Verbatim config   | fenced code block (Pandoc escapes `<`/`&` — never hand-escape)                             |

Use `.callout .warn` / `.bad` to flag unverified or risky claims explicitly.
