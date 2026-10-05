---
name: weekly-review
description: Weekly review of Claude Code usage, started by claude-review.timer or by hand as /weekly-review <monday date>.
disable-model-invocation: true
---

# Weekly review

The argument is the Monday that opens the reviewed week. The window is that Monday 00:00 local to the next Monday 00:00, converted to UTC before filtering log timestamps. `WEEK` is its ISO week, for example `2026-W40`.

You run unattended. The user attaches to this session afterwards and asks what a proposed change entails, so keep every finding answerable from this conversation. Propose only. Never edit, install or commit anything. The one private artifact below is the only remote write this run is authorized to make.

## Inputs

Read all of these before forming any finding.

- Session logs: every `~/.claude/projects/*/*.jsonl` with entries whose `timestamp` falls in the window. The directory name is the cwd with `/` replaced by `-` and starts with a hyphen, so quote and prefix it with `./` or `--` in shell tools. Filter with jq or python, never read a log whole. Write scratch scripts with the Write tool and capture command output with an appending redirect, the command guard blocks truncating redirects under home.
- `~/.claude/history.jsonl`: the prompts typed, with project and session id.
- `~/dotfiles/retros/*.md`: pain points already root caused, do not rediscover them, check whether they recurred.
- `~/weeklies/reviews/*.md` and `~/weeklies/reviews/ledger.md`: earlier reviews and the candidate ledger, so proposals are not repeated.
- `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/skills/*/SKILL.md`, `~/.claude/agents/*.md`, `~/.claude/hooks/`, `~/.config/claude-ticket/plugin/skills/*/SKILL.md`, `~/.claude/plugins/installed_plugins.json`: the current config a finding is judged against.
- Built in insights: run `claude -p --model sonnet "/insights"` in the background from `~/dotfiles`. If a new file appears under `~/.claude/usage-data/`, read it as one more input. If nothing appears within a few minutes, continue without it and say so in the appendix.

## Analysis

Week in numbers, computed from the logs: sessions and user turns per project, tool calls, tokens by model from the assistant `usage` fields, web searches, subagent runs, compactions.

Friction signals, each with session id, project and a short quote:

- Corrections: short negations, "no", "wrong", "I said", "why did you", repeated instructions, redone work.
- Permission prompts and rejections, tool results saying the user did not want to proceed.
- Tool errors, retries of the same command, interrupted requests.
- Guard blocks: count one only when the tool result is the hook's own deny, not output that quotes a rule id. Replay each command against the installed guard from its logged cwd and report the ones that now pass as fixed upstream, not as pain.
- Rules in CLAUDE.md or a skill that were not applied, or applied in a way that cost time.
- Waits: long foreground commands, polling loops, sessions idle on a question.
- Repeated manual steps across sessions that a skill, hook, git hook or small tool could absorb.
- Context pressure: compactions, very long sessions, large pasted outputs.

Group signals into pain points. A pain point names the pattern, how often it hit, and what it cost. One off model errors are noted, not proposed against.

## Sources

Scan these for solutions to the pain points found this week, then search the web freely per pain point for anything else that fits.

- github.com/mattpocock/skills and the feed at aihero.dev/rss.xml
- github.com/humanlayer/humanlayer and github.com/humanlayer/skills
- poteto: github.com/cursor/plugins/tree/main/pstack, github.com/poteto/how, github.com/poteto/noodle. Cursor format, note the porting cost.
- claude.dev/rss.xml
- github.com/ananddtyagi/cc-marketplace
- github.com/anthropics/claude-plugins-official and github.com/anthropics/skills, commits since the last review
- github.com/hesreallyhim/awesome-claude-code, github.com/obra/superpowers, github.com/wshobson/agents, github.com/davila7/claude-code-templates

Use the GitHub API and raw files unauthenticated, batch requests, the unauthenticated limit is 60 per hour. Delegate the scan to parallel subagents, one per source group, and ask each for candidates mapped to pain points, not inventories.

A candidate reaches the shortlist only if its license is MIT, Apache 2.0 or BSD, its repository was pushed within the last 90 days, and it does not contradict `~/.claude/CLAUDE.md` or duplicate an existing skill, agent or hook. Record every candidate you looked at in the ledger, including the rejected ones with the reason.

An internal solution, a new skill, hook, git hook or small script, competes with vendored ones on equal terms. Name the existing platform mechanism first when one covers the need.

## Outputs

Wait for every subagent and background command before writing. All three outputs exist before your final message.

1. Artifact. Load the `artifact-design` skill, then publish one private artifact titled `Weekly review <WEEK>`, no pin. Sections in order: week in numbers, pain points, misses, recommendations ranked by expected gain, appendix. A recommendation is the issue and the proposed solution with its source and effort. No commands, no diffs. The appendix holds the rest, collapsed.
2. Report file `~/weeklies/reviews/<monday>.md`. Line one `# Week <WEEK> review`, line two `Artifact: <url>`, then the artifact content as markdown.
3. Ledger `~/weeklies/reviews/ledger.md`, a table with the columns candidate, source, first proposed, state, note. One row per candidate. New candidates are appended as `proposed` or `rejected`. Only rows in state `proposed` may be updated, the user owns `adopted` and `rejected`.

Finish with a short message naming the top recommendations, it is the first thing the user sees when attaching. End with a statement, never a question.
