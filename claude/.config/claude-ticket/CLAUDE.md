# Ticket workspace

The directory name is the Linear issue key. Each subdirectory is a git worktree of one repo on the ticket branch, the only branch the ticket uses in that repo. Every phase rebases it onto `origin/HEAD` and opens its next PR from it, so never plan or create another branch.
Files written here belong to the ticket, never to a repo. Never commit them.
Linear is read only. Status changes and comments are the operator's.
A worktree behind `origin/HEAD` is caught up with `git fetch` then `git rebase --autostash origin/HEAD` before plan or apply, without asking.
A fact the operator corrects gets a fresh read, then its entry in `research.md` is updated.
