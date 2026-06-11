import datetime
import html
from pathlib import Path

import yaml

MARKER = "<!-- CARDS -->"


def _frontmatter(text):
  if not text.startswith("---"):
    return {}
  parts = text.split("---", 2)
  if len(parts) < 3:
    return {}
  try:
    data = yaml.safe_load(parts[1])
  except (yaml.YAMLError, ValueError):
    return {}
  return data if isinstance(data, dict) else {}


def _date(value, fallback):
  if isinstance(value, datetime.date):
    return value.isoformat()
  if isinstance(value, str) and value:
    return value
  return fallback


def _cards(docs_dir):
  cards = []
  for path in sorted(Path(docs_dir).glob("*.md")):
    if path.name == "index.md":
      continue
    fm = _frontmatter(path.read_text(encoding="utf-8"))
    stem = path.stem
    mtime = datetime.date.fromtimestamp(path.stat().st_mtime).isoformat()
    cards.append({
      "href": f"{stem}.html",
      "title": fm.get("title") or stem,
      "description": fm.get("description") or "",
      "tag": fm.get("tag"),
      "date": _date(fm.get("date"), mtime),
    })
  cards.sort(key=lambda c: c["title"])
  cards.sort(key=lambda c: c["date"], reverse=True)
  return cards


def _render(cards):
  lines = ['<div class="grid cards">', "  <ul>"]
  for c in cards:
    title = html.escape(c["title"])
    description = html.escape(c["description"])
    tag = (
      f'<span class="tag">{html.escape(c["tag"])}</span> '
      if c["tag"]
      else ""
    )
    date = html.escape(c["date"])
    lines.append("    <li>")
    lines.append(f'      <p><strong><a href="{c["href"]}">{title}</a></strong></p>')
    lines.append("      <hr />")
    lines.append(f"      <p>{description}</p>")
    lines.append(f'      <p>{tag}<span class="muted">{date}</span></p>')
    lines.append("    </li>")
  lines.append("  </ul>")
  lines.append("</div>")
  return "\n".join(lines)


def on_page_markdown(markdown, page, config, files):
  if page.file.src_uri != "index.md":
    return markdown
  if MARKER not in markdown:
    return markdown
  return markdown.replace(MARKER, _render(_cards(config["docs_dir"])))
