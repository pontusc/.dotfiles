# Plan: ticket-grouped worktree layout

Working doc for one approved change to the tmux workspace tool. Delete it once the work
lands. The tool itself is documented in `README.md` next to this file, read that first.

Status: all changes are implemented, smoke-tested, and the migration has run. Nothing in
this doc is outstanding, it exists only until the driver deletes it.

## Approved scope

Tool-created worktrees move from a per-repo tree to a per-ticket tree, so every repo a
ticket touches sits side by side. Nothing else changes.

```
now   Work/<repo>.worktrees/<branch>      Work/Alchemy.worktrees/ALC-1030-restructure-manifests
after Work/tickets/<session>/<repo>       Work/tickets/ALC-1030/Alchemy
```

`<session>` is the tmux session name, which `Ticket.session_name` already returns as the
ticket key when keyed and the slug when keyless (`.config/tmux/workspace/ticket.py:21`).
The group directory needs no separate concept.

Three prompt outcomes feed this, from `compose._resolve_ticket`:

- Ticket and Branch both blank: no worktree at all, windows open at repo roots, no group
  directory.
- Ticket blank, Branch filled: keyless, worktree created, group directory is the slug.
- Both filled: branch is `<KEY>/<slug>`, group directory is the key.

## Decisions already made

Do not reopen these.

| Decision | Answer |
|---|---|
| Group directory for a keyless session | the branch slug |
| Flat or nested | nested under `Work/tickets/` |
| Migrate the worktrees already on disk | yes, but only when the driver asks by name |
| Peer directories read-only | no, full read and write inside a ticket is wanted |
| Old layout for leader+W | permanent, not transitional |

## Changes

### 1. Path derivation

`worktree.path_for(repo_root, branch)` becomes `path_for(work_root, session, repo)`
returning `work_root / "tickets" / session / repo`. Its one call site is
`compose.prepare_windows` (`.config/tmux/workspace/compose.py:79`), which already holds
`work_root` and the session name.

Behavior change to state in the README: the path no longer encodes the branch, so a ticket
gets one worktree per repo. Reopening a ticket with a different slug hits the existing
branch-mismatch check and fails per repo until leader+X removes the old worktrees. Before,
a second slug silently created a sibling worktree.

### 2. Ownership lookup via git

`repo.owner_of` (`.config/tmux/workspace/repo.py:24`) stops matching path shapes and asks
git instead: the parent of `git rev-parse --path-format=absolute --git-common-dir` is the
owning repo for any layout, including old-layout worktrees and half-migrated sessions. The
git call lives in `worktree.py` next to the other git plumbing. `WORKTREES_SUFFIX` stays
only for the `repo.discover` exclusion, since leader+W keeps creating those directories.

`repo.discover` (`.config/tmux/workspace/repo.py:12`) needs no change. It requires
`<entry>/.git`, and `Work/tickets/` has none, so the group tree never reaches the repo
picker.

### 3. Claude invocation

`layout.arrange` (`.config/tmux/workspace/layout.py:11`) gains an optional group directory
and sends:

```
claude --model opus -n <session>-<repo> [--add-dir <group dir>]
```

Opus is pinned per invocation, so the driver's selected default is untouched and no global
config changes. `--add-dir` is passed only for ticket worktree windows, with the explicit
group path: a bare `..` would grant the whole work root from a repo-root window. It must
come last, see the gotcha below.

### 4. Empty container directories

`worktree.remove` best-effort rmdirs the parent after a successful removal, so an emptied
`tickets/<session>/` (or `<repo>.worktrees/`) does not linger.

### 5. State saves at mutation time

`materialize_workspace`, `add_repo` and `cleanup_session` call `persist.save_state()` when
done. Waiting for continuum's 15-minute tick is what lost fresh sessions on reboot.

### 6. Docs

`README.md`: the layout in Use, the one-worktree-per-ticket semantics, a constraint
covering the two coexisting layouts, and the Pending swap entry reduced to the `layout`
subcommand alone. Retiring the bash scripts is off the table.

### 7. Migration, on explicit request only

`git worktree move` for the tool-created worktrees, currently ALC-1030 in two repos and
ALC-1061 in one. `General:976:update-de` predates the tool and stays where it is.
Afterwards re-tag the moved windows with `@worktree` and re-run `main.py state-save`.

## Verified facts

Each of these was checked in this environment. Trust them instead of re-deriving.

- The driver's global allow list already grants read and write anywhere on disk. A session
  started in a child directory created a file in a sibling directory with no `--add-dir`
  and no prompt. `--add-dir` is kept for self-documentation and to survive a future
  tightening, not because it grants anything today.
- `--add-dir` is variadic and swallows a following positional argument. It goes last.
- `--model` accepts an alias, so `opus` resolves to the current Opus.
- `permissions.additionalDirectories` accepts relative paths and resolves them per session,
  so one relative entry would work across every ticket directory. Unused here, the driver
  does not want global config changes.
- Subagents inherit the parent session's directory access. Observed, not documented.
- `git worktree remove` succeeds with ignored files present, no `--force` needed.
- tmux-resurrect drops every user option on restore. `persist.py` mirrors `@slot`,
  `@ticket_slug` and `@worktree` to `$XDG_STATE_HOME/tmux-workspace/state.json` and reapplies
  them by session and window name, wired through the resurrect hooks at
  `.config/tmux/tmux.conf:108`. A rename between the last periodic save and a reboot comes
  back untagged.
- A `display-popup` opened from inside a popup modifies the popup already up, which is why
  leader+T is `run-shell -b` into `flow` and hands its selection over through a file.
- Popup transparency needs `-s "bg=terminal"`, not `bg=default`. tmux treats `default` as
  the option default and `terminal` as the terminal default, and only the latter is what
  the terminal blends. tmux-powerkit re-sets an opaque `popup-style` on every full render,
  so per-popup flags are the only durable fix.
- `ruff` ignores the PEP 723 script header. `.config/tmux/workspace/ruff.toml` carries
  `target-version` so bare `ruff check` works.
- `mise` shims shadow `grep`, `find` and `ls`. Use the `/usr/bin` paths in shell commands.

## Constraints

- Leader+W and leader+A keep `worktree-new.sh` and `dev-layout.sh` untouched, including
  their own claude invocation. Both layouts coexist by design.
- `~/.config/tmux/workspaces.toml` is machine-local and must never enter the repo.
- `~/.config/tmux/tmux.conf` is a real file, not a symlink, and differs from the repo copy
  by two trailing OSC-52 lines. Edit both, keep the drift.
- Interactive tmux testing runs on a throwaway `-L` socket server with `env -u TMUX`. Never
  set options on the live server during testing. Read-only queries and an explicit config
  reload are fine.
- Git state belongs to the driver. No commits, no remote operations.
- Every window the tool creates is tagged `@worktree` with its path. Nothing else may kill
  or retag those windows.

## Gate

From `.config/tmux/workspace`:

```
ruff check .
ruff format --check .
```

There is no test suite. Behavioral changes get exercised on a throwaway socket server.

## Out of scope

`done` teardown, and the swap that gives leader+A a `layout` subcommand.
