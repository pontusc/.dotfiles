# Ticket Sessions

One tmux session shows everything a ticket touches, one window per repo worktree. Repos
are discovered under the work root and composed into a session by hotkey. The tool is the
Python CLI in `workspace/` (a uv script, stdlib only), deployed by the stow package as one
folded symlink.

## Use

- **leader+T** opens an fzf multi-select over every discovered repo plus the saved
  templates (space toggles, enter accepts the hovered row without unmarking). A template
  row stands for its member repos, and mixing templates with loose repos unions the
  selection. A second popup then prompts for the ticket (a bare number gets the configured
  `ticket_prefix`, so 1026 becomes ABC-1026) and the branch slug. The tool creates the
  session, one window per repo with a worktree on branch `KEY/slug`, the 3-pane layout,
  and a named claude in each.
- Empty ticket with a branch given: worktrees on the bare branch, session named by the
  branch. Both prompts empty: windows at repo roots, no worktrees, session named by the
  template, the sole repo, or a prompt, in that order.
- **leader+E** adds a repo to the current session: fzf over the repos not yet in it,
  worktree on the session's ticket branch, window and agent join in place. In a non-ticket
  session the repo opens at its root.
- **leader+X** closes every window in the current session that loses nothing (repo-root
  windows, worktrees with a clean tree, ignored files count as loss). The worktree is
  removed, its branch kept. Dirty windows stay open and are reported.
- **leader+s** picks another session: digits jump straight to a slot, letters fuzzy-find.
  Slots stick to a session for its lifetime and free up when it dies.
- `list` prints templates, discovered repos, and the materialized sessions.
- Cancelling any prompt (fzf abort, escape, ctrl-d) exits silently. Re-running the flow
  for an existing ticket attaches and fills in only what is missing.

Naming: session = ticket key (or workspace name when ticketless), window = repo, claude
session = `<KEY>-<repo>`. Renaming a ticket session breaks `add`, which derives the ticket
from the session name.

## Config

`~/.config/tmux/workspaces.toml`. Machine-local, never enters the repo (the per-entry
symlinks under `~/.config/tmux` let it sit next to the stowed scripts). Human-edited,
read-only to the tool.

The repo universe is not in the config: every direct child of `work_root` containing
`.git` is a repo (`*.worktrees` directories are skipped). The whole file is optional, a
missing or empty config still gives the full dynamic flow.

```toml
[settings]
work_root = "~/Work"                 # default, override per machine
ticket_prefix = "ABC"                # optional, expands bare ticket numbers
# ticket_pattern = "[A-Z]+-[0-9]+"   # default shown, uppercase keys are the contract

[repos]
cluster = "k8s manifests + Helm values"
infrastructure = "Terraform IaC"

[workspaces.platform]
repos = ["cluster", "infrastructure"]
```

A template is nothing but a saved selection. Repos may appear in several templates.

`[repos]` is the single source of repo descriptions: the tool shows them inline on picker
rows and in `list`, and the peer-roster plugin reads the same table to annotate sibling
sessions. Descriptions are optional and may cover repos outside any workspace.

The peer-roster plugin keeps its own built-in ticket pattern, so a machine that overrides
`ticket_pattern` to a non-Jira scheme loses roster grouping until the plugin learns the
same override.

## Constraints

- Every window the tool creates is tagged `@worktree` with its path. The tags are the
  runtime truth: idempotent re-open, cleanup scope, and de-dupe against the old leader+W
  flow all read them. Nothing else may kill or retag those windows. tmux-resurrect drops
  all user options on restore, so the resurrect hooks mirror the tags plus `@slot` and
  `@ticket_slug` to a state file and reapply them by session and window name. A session or
  window renamed after the last periodic save comes back untagged.
- The leader+T binding must stay `run-shell -b` into `flow`: a `display-popup` opened from
  inside another popup modifies the popup that is already up, so the picker and prompt
  popups have to be opened server-side, one after the other.
- Nothing checks the versions, so keep them in mind: uv, tmux 3.2 or newer for
  `display-popup`, and an fzf recent enough for the `enter:select+accept` bind.

## Pending

- `done`: teardown of one session, worktrees removed, branch deletion prompted, session
  killed.
- The swap: a `layout` subcommand replaces `dev-layout.sh`, leader+W and leader+A rebind
  to the tool, both bash scripts retire. Requires resolving the tmux.conf drift first (the
  deployed `~/.config/tmux/tmux.conf` is a real file that differs from the repo copy).
