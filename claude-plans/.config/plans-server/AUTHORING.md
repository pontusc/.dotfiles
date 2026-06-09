# Plan / document authoring reference

How to write Markdown that the `plans-render` pipeline turns into the house-themed HTML view. Applies to every skill that writes into `~/plans/src/`. The component classes below are defined in `theme.html` — use these, don't invent new ones.

## Save & render

- Write to `~/plans/src/<kebab-slug>.md`. The slug is the document's identity — revise in place, never spawn `-v2`. Never write into a project repo or the cwd.
- The `plans-render` watcher re-renders on every save → `~/plans/<slug>.html`, served at **http://plans.claude**.
- Manual render (verify a complex doc now, or the watcher is down): `~/.config/plans-server/render.sh ~/plans/src/<slug>.md`.

## Frontmatter (drives the hero header)

```yaml
---
title: actions-runner-controller on the IAT Talos cluster
subtitle: Deployment plan, gap analysis & sizing
date: 2026-06-09
scope: talos-infrastructure
---
```

## Structure

- One `# Heading` per section → nav entry + auto-numbered section; `## Heading` for subsections.
- Give sections stable ids for cross-refs: `# Networking {#networking}`.
- Cross-ref another section with `[§](#slug)` — auto-renumbered to `§N` at render.

## Components — use the house classes

| Need              | Markdown                                                                                   |
| ----------------- | ------------------------------------------------------------------------------------------ |
| Status pill       | `[decided]{.pill .ok}` · `[gap]{.pill .gap}` · `[partial]{.pill .partial}`                 |
| Callout           | `::: {.callout .warn}` … `:::`, first line `[Label]{.t}` (variants `.good` `.warn` `.bad`) |
| Side-by-side      | `::: {.grid2}` wrapping two `::: {.card}`                                                  |
| Comparison matrix | standard Markdown pipe table — header row + `--- ` separator row                           |
| Inline annotation | `[…]{.muted}` · `[…]{.src}` · `[v1.13]{.tag}`                                              |
| Verbatim config   | fenced code block (Pandoc escapes `<`/`&` — never hand-escape)                             |

- Tables MUST be pipe tables with a header row and a separator row. Never space-separated — that flattens to a broken paragraph.
- Use `.callout .warn` / `.bad` to flag risky or unverified claims explicitly.
