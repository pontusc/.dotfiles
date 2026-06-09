#!/usr/bin/env bash
# Render plan sources (~/plans/src/*.md) into themed, self-contained HTML
# (~/plans/*.html) via Pandoc + the house theme and the §N cross-ref filter.
#
#   render.sh <file.md>   render one source
#   render.sh --all       render every source
#   render.sh --watch     render all, then re-render on change (inotify)
set -euo pipefail

asset_dir="${PLANS_RENDER_DIR:-$HOME/.config/plans-server}"
src_dir="$HOME/plans/src"
out_dir="$HOME/plans"
template="$asset_dir/theme.html"
filter="$asset_dir/secrefs.lua"

render_one() {
  local md="$1" slug
  slug="$(basename "$md" .md)"
  pandoc --standalone --embed-resources \
    --template="$template" --lua-filter="$filter" \
    --section-divs --toc --toc-depth=1 \
    -f markdown -t html5 \
    "$md" -o "$out_dir/$slug.html"
  echo "rendered ${slug}.md -> ${slug}.html"
}

render_all() {
  shopt -s nullglob
  local md
  for md in "$src_dir"/*.md; do
    render_one "$md" || echo "render failed: ${md}" >&2
  done
}

watch() {
  if ! command -v inotifywait > /dev/null 2>&1; then
    echo "inotifywait not found; install inotify-tools" >&2
    exit 1
  fi
  mkdir -p "$src_dir"
  render_all
  inotifywait -m -e close_write,create,moved_to,delete \
    --format '%e %w%f' "$src_dir" |
    while read -r event path; do
      [[ "$path" == *.md ]] || continue
      if [[ "$event" == *DELETE* ]]; then
        rm -f "$out_dir/$(basename "$path" .md).html"
        echo "removed html for $(basename "$path")"
      else
        render_one "$path" || echo "render failed: ${path}" >&2
      fi
    done
}

case "${1:-}" in
--watch) watch ;;
--all | "") render_all ;;
-*)
  echo "usage: render.sh [<file.md>|--all|--watch]" >&2
  exit 2
  ;;
*) render_one "$1" ;;
esac
