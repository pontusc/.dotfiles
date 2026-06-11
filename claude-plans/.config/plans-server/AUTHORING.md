# Plan / document authoring reference

How to write Markdown that the plans site (MkDocs + Material) renders at **http://plans.claude**. Applies to every skill that writes into `~/plans/src/`. The component classes below come from Material plus `assets/extra.css` — use these, don't invent new ones.

## Save & render

- Write to `~/plans/src/<kebab-slug>.md`. The slug is the document's identity — revise in place, never spawn `-v2`. Never write into a project repo or the cwd.
- The `plans-render` MkDocs dev server live-rebuilds on every save → served at **http://plans.claude/<slug>.html**.
- The landing page is generated at build time from each document's frontmatter — no manual card edits. A NEW document must set `title`, `description`, `tag`, and `date` (`YYYY-MM-DD`) in frontmatter to appear; `date` falls back to the file's mtime if omitted.
- Manual build check: `~/.config/plans-server/venv/bin/mkdocs build -f ~/.config/plans-server/mkdocs.yml`.

## Frontmatter

```yaml
---
title: actions-runner-controller on the IAT Talos cluster
description: Deployment plan, gap analysis & sizing
tag: talos-infrastructure
date: 2026-06-09
---
```

`title` is required (page title + nav entry). `description`, `tag`, and `date` feed the document's card on the generated landing page — they are not rendered on the page itself. Put subtitle/scope context in a short intro paragraph under the first heading.

## Structure

- Do NOT use `# ` headings in the body — the page h1 comes from the frontmatter `title`. One `## Heading` per major section → sidebar TOC entry; `### Heading` for subsections.
- Give sections stable ids for cross-refs: `## Networking {#networking}`.
- Cross-ref with a descriptive anchor link: `[Networking](#networking)`. There is no auto-numbering.

## Components

| Need              | Markdown                                                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Status pill       | `<span class="pill ok">decided</span>` · `<span class="pill gap">gap</span>` · `<span class="pill partial">partial</span>` |
| Callout           | `!!! warning "Label"` + body indented 4 spaces (types: `note` `success` `warning` `danger`; collapsible: `???`)            |
| Comparison matrix | standard Markdown pipe table — header row + `--- ` separator row                                                           |
| Inline annotation | `<span class="muted">…</span>` · `<span class="src">…</span>` · `<span class="tag">v1.13</span>`                           |
| Verbatim config   | fenced code block with a language tag (highlighted, copy button)                                                           |

- Inline classed text MUST be a raw HTML `<span>` — Pandoc-style `[text]{.class}` does NOT render here.
- Tables MUST be pipe tables with a header row and a separator row. Never space-separated — that flattens to a broken paragraph.
- Use `!!! warning` / `!!! danger` to flag risky or unverified claims explicitly.
- Write real em-dash characters (`—`) in prose. Literal `---` / `--` are NOT smart-converted here and render as plain hyphens.
- Markdown links between documents target the `.md` file (`[title](other-doc.md)`) — MkDocs rewrites and validates them. Raw-HTML `href`s target the `.html`.
