# Dotfiles

Personal dotfiles for Arch Linux + Hyprland (omarchy) and CachyOS + KDE Plasma machines,
deployed with GNU Stow. Each top-level directory is a **stow package**; the path inside it
mirrors the destination relative to `$HOME` (`claude/.claude/settings.json` →
`~/.claude/settings.json`). Required tools are listed in `readme.md`.

## Stow mechanics

- Run from the repo root: `stow <package>` creates the symlinks, `stow -D <package>` removes
  them, `stow -R <package>` restows (picks up added/removed files).
- **Tree folding**: stow links the highest directory it can own outright — a package whose
  target doesn't exist gets one symlink for the whole tree. When the target already exists as
  a real directory, stow *unfolds* and links each entry inside it individually.
- Packages are machine/role-specific (`hypr-desktop` vs `hypr-laptop` vs `hypr-work`,
  `bash-linux` vs `bash-work`, `kde-*`) — install only what applies to the host.

## The claude package (partially folded — read before adding files)

`~/.claude` is a real directory owned by Claude Code runtime state (history, projects,
plugins), so the `claude` package deploys **per-entry** symlinks: `~/.claude/agents`,
`~/.claude/hooks`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`,
`~/.claude/statusline-command.sh`. One level deeper, `~/.claude/skills/` is also real (it
hosts the external `omarchy` skill from `~/.local/share/omarchy/`), so **each skill has its
own symlink**.

Consequences:

- **A new skill does not deploy itself.** After creating `claude/.claude/skills/<name>/`,
  run `stow -R claude` or link manually:
  `ln -s ../../dotfiles/claude/.claude/skills/<name> ~/.claude/skills/<name>`
- **Drift hazard**: a real (non-symlink) directory inside `~/.claude/skills/` shadows the
  repo and silently diverges. If `ls -la ~/.claude/skills` shows a plain directory, replace
  it with a symlink.
- `claude/.config/dcg` → `~/.config/dcg` is fully folded (one symlink for the directory);
  its runtime file `pending_exceptions.jsonl` lives inside the repo tree but is gitignored.

## Key files

- `claude/.claude/CLAUDE.md` — global user instructions (orchestration/delegation rules)
- `claude/.claude/settings.json` — permissions, deny list, hook registration
- `claude/.claude/hooks/HOOKS.md` — hook architecture and design rules
- `claude/.config/dcg/config.toml` — destructive-command-guard packs (PreToolUse Bash hook)
