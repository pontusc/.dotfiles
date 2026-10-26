# Ticket workspace

The directory name is the Linear issue key. Each subdirectory is a git worktree of one repo on the ticket branch, the only branch the ticket uses in that repo. Every phase rebases it onto `origin/HEAD` and opens its next PR from it, so never plan or create another branch.
Files written here belong to the ticket, never to a repo. Never commit them.
Every Linear write, a comment, attachment or status change, needs the operator's explicit approval for that one write.
A worktree behind `origin/HEAD` is caught up before plan or apply, without asking: `git fetch`, then `git merge --ff-only origin/HEAD` when its branch has no commits of its own, otherwise `git rebase --autostash origin/HEAD`.
A fact the operator corrects gets a fresh read, then its entry in the dated research file that `research.md` points to is updated.
