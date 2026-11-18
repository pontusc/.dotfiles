---
name: ship
description: Commit, push and open the PR for the ticket branch in each ticket worktree with changes, or in the repo the operator names, and rebase merge it when the operator asks.
disable-model-invocation: true
---

Typing `/ticket:ship` approves exactly the steps below, in each ticket worktree with uncommitted changes or commits ahead of `origin/HEAD`, or only in the ticket worktree the operator names. Nothing else.

The ticket branch is the output of `git -C <worktree> branch --show-current`. The target is the output of `git -C <worktree> symbolic-ref --short refs/remotes/origin/HEAD` without its `origin/` prefix. Never touch any other branch. Stop before any step unless the worktree sits under the ticket root and its branch starts with `<KEY>/`, KEY being the ticket directory name. A rebase or stash conflict stops and reports. Stage tracked changes only, untracked files stop and are listed for the operator.

## Per worktree

1. `git -C <worktree> fetch origin`, then `git -C <worktree> rebase --autostash origin/HEAD`.
2. Read `git -C <worktree> log -20 --format=%B origin/HEAD` and commit the worktree changes in that style. Published-text rules apply. Never commit ticket files.
3. `git -C <worktree> push origin <ticket branch>`. A push rejected as non fast forward stops and asks through AskUserQuestion before `git -C <worktree> push --force-with-lease origin <ticket branch>`.
4. `gh pr create --base <target> --head <ticket branch> --title <title> --body-file <body file>` from the worktree, with `--draft` only when the operator asks for a draft. The title names the change in the style of `gh pr list --state merged --limit 10 --json title`, the body fills the repo's PR template from the current phase file, terse, in a scratch file. Published-text rules apply to both. When `gh pr view <ticket branch>` shows an open PR, the push already updated it, skip the create.
5. `gh pr checks <ticket branch> --watch` from the worktree, as a background command.
6. Only when the operator asked for a merge and the checks passed: `gh pr merge <ticket branch> --rebase` from the worktree. Never `--admin` or `--delete-branch`, later phases reuse the branch.

## Reply

Per repo: the commit SHA, the PR URL, the checks result once the watch ends, and the merge result when merged.
