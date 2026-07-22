# Dispatcher (sonnet subagent)

Turn the incident description + session log into a handoff doc, then spawn the
retro agent. Facts only — root-causing is the retro agent's job.

## 1. Extract facts from the log

The log is JSONL and can be large — filter, don't read whole:

```bash
# user turns (content is a string or an array of blocks — flatten to text)
jq -r 'select(.type == "user") | .message.content
       | if type == "array" then (.[] | select(.type == "text").text) else . end' <log>
grep -n '<phrase from incident>' <log>                     # locate the correction
```

Pull: the original request, the assistant's approach around the incident,
the user's correction messages — verbatim quotes, with file:line refs where
the log shows edits.

## 2. Write the handoff doc

Path: `~/dotfiles/retros/YYYY-MM-DD-<slug>.md` (slug: 2-4 words naming the
failure, not the task — lowercase, hyphen-joined). Create the dir if missing.

```markdown
# Retro: <slug>

<date> · <project cwd> · session log: <path>

## Incident (main-thread view)

<the incident description you were given, verbatim>

## Task

<what the user asked for, quoted from the log>

## What happened

<the approach taken, with file:line refs from the log>

## Correction

<user's correction messages, quoted; how the corrected version differed>
```

## 3. Spawn the retro agent

```bash
cmd="claude --model opus '/retro retros/<file>.md'"
tmux new-session -d -s retros -n <slug> -c ~/dotfiles "$cmd" 2>/dev/null \
  || tmux new-window -t retros -n <slug> -c ~/dotfiles "$cmd"
```

The initial CLI prompt is processed like typed input, so `/retro` runs as a
slash command and the doc path routes it to the retro-agent instructions.

## 4. Report

Return exactly one line: `Retro doc: <path> — session at retros:<slug>`.
