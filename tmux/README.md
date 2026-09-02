# Ticket Sessions

One tmux session shows everything a ticket touches, one window per repo worktree. Repos
are discovered under the work root and composed into a session by hotkey. The tool is the
Python CLI in `workspace/` (a uv script, stdlib only), deployed by the stow package as one
folded symlink.

## Use

- **leader+T** opens an fzf multi-select over every discovered repo (space toggles, enter
  accepts the hovered row without unmarking). A second popup then prompts for the ticket
  (a bare number gets the configured
  `ticket_prefix`, so 1026 becomes ABC-1026) and the branch slug. The tool creates the
  session, one window per repo with a worktree on branch `KEY/slug` at
  `tickets/<session>/<repo>` under the work root, the 3-pane layout, and a named claude in
  each, pinned to opus with the ticket directory passed via `--add-dir`. A ticket owns one
  worktree per repo, so reopening it with a different slug fails per repo until the old
  worktrees are gone. leader+X only reaches the windows of a live session, so a worktree
  whose session is already gone needs a manual `git worktree remove` until `done` exists.
- Empty ticket with a branch given: worktrees on the bare branch, session named by the
  branch. Both prompts empty: windows at repo roots, no worktrees, session named by the
  sole repo or a prompt.
- **leader+E** adds a repo to the current session: fzf over the repos not yet in it,
  worktree on the session's ticket branch, window and agent join in place. In a non-ticket
  session the repo opens at its root.
- **leader+X** closes every window in the current session that loses nothing (repo-root
  windows, worktrees with a clean tree). The worktree is removed, its branch kept.
  Uncommitted changes keep a window without asking. Ignored files only prompt, since a
  build cache is disposable but a local `.env` is not.
- **leader+s** picks another session: digits jump straight to a slot, letters fuzzy-find.
  Slots stick to a session for its lifetime and free up when it dies.
- `list` prints the discovered repos and the materialized sessions.
- Cancelling any prompt (fzf abort, escape, ctrl-d) exits silently. Re-running the flow
  for an existing ticket attaches and fills in only what is missing.

Naming: session = ticket key (or workspace name when ticketless), window = repo, claude
session = `<KEY>-<repo>`. Renaming a ticket session makes `add` refuse with an error until
it is renamed back, since it derives the ticket and the `tickets/<session>` directory from
the session name.

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
```

`[repos]` is the single source of repo descriptions: the tool shows them inline on picker
rows and in `list`, and the peer-roster plugin reads the same table to annotate sibling
sessions. Descriptions are optional.

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
- Two worktree layouts coexist by design: the tool writes `tickets/<session>/<repo>`,
  leader+W keeps writing `<repo>.worktrees/<branch>`. Ownership is resolved by asking git
  for the main repo, so cleanup and de-dupe must keep working for both.
- The leader+T binding must stay `run-shell -b` into `flow`: a `display-popup` opened from
  inside another popup modifies the popup that is already up, so the picker and prompt
  popups have to be opened server-side, one after the other.
- Nothing checks the versions, so keep them in mind: uv, tmux 3.2 or newer for
  `display-popup`, and an fzf recent enough for the `enter:select+accept` bind.
- The Claude flag segment and the picker markers read the window option `@claude`, set to
  `ask` or `done` by `~/.claude/hooks/notify.sh` in the claude package. Renaming the option
  or its values breaks both sides. The segment is a powerkit `external()` entry because
  powerkit rewrites `status-right` on every render, and it lags a flag by up to 10 seconds.
  The clearing hooks in tmux.conf take no `-t` target, `set-option` does not expand formats
  there and a literal `#{window_id}` raises a blocking error view on every focus change.

## Pending

- `done`: teardown of one session, worktrees removed, branch deletion prompted, session
  killed.
- The swap: a `layout` subcommand replaces `dev-layout.sh` for leader+A. Leader+W keeps
  its own script and the `<repo>.worktrees` layout permanently.
