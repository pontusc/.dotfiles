---
name: retro
description: Analyze a materially corrected Codex session and propose focused configuration improvements in a separate session. Use after repeated course corrections or when asked to review what went wrong.
---

# Retro

Use a separate Codex session so incident analysis does not displace the original task context.

## Select the mode

- If the request includes a `retros/*.md` path, read [instructions/retro-agent.md](instructions/retro-agent.md) and follow it.
- Otherwise, follow the main-thread workflow below.

## Main-thread workflow

1. Offer a retro after two material course corrections. Continue only when the user confirms or explicitly invokes `$retro`.
2. Write `retros/YYYY-MM-DD-<slug>.md` under the dotfiles repository. Use a two to four word lowercase slug naming the failure rather than the original task.
3. Record the date, project working directory, original request, approach taken, user corrections, and the corrected result. Quote the user's correction exactly when it is available in the current context. State when details are unavailable instead of reconstructing them.
4. Start a detached tmux session in the dotfiles repository. Use a `retros` session and the slug as the window name. Run Codex with a prompt that invokes `$retro` and passes the handoff path. If the `retros` session exists, create a new window in it.
5. Return one line with the handoff path and tmux target, then resume the original task.

Use this command shape, with the actual path and slug substituted safely:

```bash
codex -C /home/pontusc/dotfiles '$retro retros/<file>.md'
```
