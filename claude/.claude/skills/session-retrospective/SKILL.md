---
name: session-retrospective
description: Use when the user asks to "review the session", "evaluate our conversation", "improve the workflow", "analyze what went wrong", or mentions session quality/efficiency
disable-model-invocation: true
version: 1.0.0
---

# Session Retrospective

Evaluate the current session and optimize CLAUDE.md/skills for future interactions.

## Process

### 1. Gather Context
- Read `~/.claude/CLAUDE.md`
- Check existing skills in `~/.claude/skills/`
- Review project `CLAUDE.md` if exists

### 2. Analyze Pain Points

Review conversation for:
- **Repeated corrections** - Same issue corrected 2+ times
- **Ignored constraints** - User said "simple" 3+ times, I over-engineered
- **Wasted work** - Discarded implementations, wrong approach
- **Token waste** - Unnecessary verbosity, redundant exploration
- **Missed context** - Failed to apply existing CLAUDE.md guidance

Use [references/evaluation-checklist.md](references/evaluation-checklist.md) for systematic review.

### 3. Determine Actions

For each issue:

**Add to CLAUDE.md**: New patterns, recognition signals, principles
**Create/Update Skill**: Repeatable workflows (3+ times)
**Compact/Remove**: Merge similar learnings, remove outdated items, generalize examples

**Token Budget**: CLAUDE.md should stay ~800-1200 tokens. If over, consolidate.

### 4. Present Recommendations

```markdown
## Pain Points
1. [Issue] - [Impact]

## Root Cause
[What guidance was missing/ignored]

## Proposed Changes

### CLAUDE.md
[Specific edits]

### Skills
[Create/update what]

### Removals
[What's redundant/outdated]

Token Impact: -/+ [delta]
```

### 5. Implement (After Approval)

Edit files, update timestamps, verify changes.

## Guidelines

**Be ruthless**:
- Every token costs money
- Principles > Examples
- Merge similar learnings
- Remove obvious items
- CLAUDE.md readable in <60s

**Focus**:
- Prevent repeated corrections
- Recognition signals that save back-and-forth
- High-impact patterns only

See [references/claude-md-best-practices.md](references/claude-md-best-practices.md) for structure guidelines.
