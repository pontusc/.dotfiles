# Ticket workspace

The directory name is the Linear issue key. Each subdirectory is a git worktree of one repo on the ticket branch.
Files written here belong to the ticket, never to a repo. Never commit them.
Linear is read only. Status changes and comments are the operator's.
A worktree behind `origin/HEAD` is caught up with `git fetch` then `git rebase --autostash origin/HEAD` before plan or apply, without asking.
A fact the operator corrects gets a fresh read, then its entry in `research.md` is updated.
