# Plan / document authoring reference

How to write Markdown that the plans site (MkDocs + Material) renders at **http://plans.claude**. Applies to every skill that writes into `~/plans/src/`. The component classes below come from Material plus `assets/extra.css` — use these, don't invent new ones.

## Save & render

- Write to `~/plans/src/<kebab-slug>.md`. The slug is the document's identity — revise in place, never spawn `-v2`. Never write into a project repo or the cwd.
- Author via Bash (heredoc / `tee`), not the `Write`/`Edit` tools. The markdown formatter hook fires on `Write`/`Edit` and re-indents list continuations to 2 spaces, which breaks python-markdown structures (card grids, nested lists). The `present-*` and `review-plan` skills omit `Write`/`Edit` from `allowed-tools` deliberately — keep it that way. For in-place revisions of an existing document, use targeted `sed -i` / `perl -i` substitutions, or regenerate the whole file via heredoc.
- The `plans-render` MkDocs dev server live-rebuilds on every save → served at **http://plans.claude/<slug>.html**.
- When creating a NEW document, also add its card to the landing page `~/plans/src/index.md`.
- Manual build check: `~/.config/plans-server/venv/bin/mkdocs build -f ~/.config/plans-server/mkdocs.yml`.

## Frontmatter

```yaml
---
title: actions-runner-controller on the IAT Talos cluster
---
```

`title` is required (page title + nav entry). Put subtitle/date/scope context in a short intro paragraph under the first heading — they are not rendered from frontmatter.

## Structure

- Do NOT use `# ` headings in the body — the page h1 comes from the frontmatter `title`. One `## Heading` per major section → sidebar TOC entry; `### Heading` for subsections.
- Give sections stable ids for cross-refs: `## Networking {#networking}`.
- Cross-ref with a descriptive anchor link: `[Networking](#networking)`. There is no auto-numbering.

## Components

| Need              | Markdown                                                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Status pill       | `<span class="pill ok">decided</span>` · `<span class="pill gap">gap</span>` · `<span class="pill partial">partial</span>` |
| Callout           | `!!! warning "Label"` + body indented 4 spaces (types: `note` `success` `warning` `danger`; collapsible: `???`)            |
| Card grid         | raw-HTML card block — copy the template in the "Card grids" section below                                                  |
| Comparison matrix | standard Markdown pipe table — header row + `--- ` separator row                                                           |
| Inline annotation | `<span class="muted">…</span>` · `<span class="src">…</span>` · `<span class="tag">v1.13</span>`                           |
| Verbatim config   | fenced code block with a language tag (highlighted, copy button)                                                           |

- Inline classed text MUST be a raw HTML `<span>` — Pandoc-style `[text]{.class}` does NOT render here.
- Tables MUST be pipe tables with a header row and a separator row. Never space-separated — that flattens to a broken paragraph.
- Use `!!! warning` / `!!! danger` to flag risky or unverified claims explicitly.
- Write real em-dash characters (`—`) in prose. Literal `---` / `--` are NOT smart-converted here and render as plain hyphens.
- Markdown links between documents target the `.md` file (`[title](other-doc.md)`) — MkDocs rewrites and validates them. Raw-HTML `href`s (card grids) target the `.html`.

## Card grids

Use this raw-HTML block verbatim (one `<li>` per card; `href` targets the rendered `.html`; no blank lines inside the div). Do NOT use Material's list-based `markdown` grid syntax — the markdown formatter hook re-indents lists and breaks the cards.

```html
<div class="grid cards">
  <ul>
    <li>
      <p>
        <strong><a href="some-doc.html">Document title</a></strong>
      </p>
      <hr />
      <p>One-line description</p>
      <p>
        <span class="tag">scope</span> <span class="muted">2026-06-10</span>
      </p>
    </li>
  </ul>
</div>
```
