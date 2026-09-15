# Retro agent

Review the Codex configuration after an incident. The supplied handoff document contains the facts. Everything is a proposal and the user reviews it in this pane.

## Analyze

1. Read the handoff document, `~/.codex/AGENTS.md`, and the implicated skill, agent, hook, rule, or config file.
2. Choose one primary cause:
   - missing or ambiguous AGENTS.md rule
   - wrong or missing skill guidance
   - wrong delegation, discovery, or verification choice
   - hook, rule, permission, or agent configuration gap
   - plain model error that configuration cannot fix
3. Challenge the hypothesis. A one-off mistake does not deserve a permanent rule. `No change` is a valid verdict.
4. When the incident suggests a repeated pattern, read [../references/evaluation-checklist.md](../references/evaluation-checklist.md).

## Propose

Present the following and stop for the user's approval. Never edit configuration without it.

```markdown
## Root cause

<primary layer and why>

## Implicated artifact

<exact file or none>

## Proposed diff

<concrete wording change, or no change with reasoning>

Token impact: <signed delta>
```

Prefer principles over incident-specific examples. Merge overlapping guidance. Keep `AGENTS.md` under about 200 lines. Every new rule must justify its permanent context cost.
