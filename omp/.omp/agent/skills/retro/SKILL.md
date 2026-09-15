---
name: retro
description: Post-incident config tuning in a separate OMP session (replaces
  session-retrospective). Trigger when the user has materially corrected your work
  (redone/reverted approach, "no, that's wrong" repeatedly, two course corrections),
  or asks to "review the session" / "analyze what went wrong". Offer first
  ("spawn a retro session?"). Invoke on confirmation or when the user runs `$retro`.
---

# Retro: spawn a config-tuning session

Three tiers:

1. **Main thread**: offer → on confirm, fire one background OMP dispatcher
   and return to the real task.
2. **Dispatcher** (OpenAI subagent): reads the session log, writes the handoff
   doc, spawns the retro agent in tmux.
3. **Retro agent** (OpenAI model, interactive omp in tmux): root-causes the incident
   against the config and proposes a diff. The user reviews there.

## Which tier are you?

Check the invocation args:

- `dispatcher` → follow [instructions/dispatcher.md](instructions/dispatcher.md)
- a `retros/*.md` doc path → follow [instructions/retro-agent.md](instructions/retro-agent.md)
- neither → you are the main thread. Continue below.

## Main thread

1. Derive the session log path: `~/.omp/agent/sessions/<cwd-slug>/<session-id>.jsonl`
   where `<cwd-slug>` is the cwd with `/` → `-` and `<session-id>` is the UUID
   in your session directory path. Verify it exists (fallback: newest
   `.jsonl` in that project dir).
2. Spawn ONE `task` agent, model `openai-codex/gpt-5.6-luna`, in the background,
   with this prompt (fill the brackets):

   > Invoke the `retro` skill with args `dispatcher` and follow its
   > dispatcher instructions.
   > Session log: `[path]`
   > Incident: [a couple sentences: what was asked, what you did wrong, how the
   > user corrected it. Name the failure, not just the task.]

3. Return to the original task immediately. When the dispatcher's completion
   notification arrives, relay its one-line report (doc path + tmux target)
   to the user.
