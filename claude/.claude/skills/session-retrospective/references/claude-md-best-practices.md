# CLAUDE.md Maintenance (for retrospectives)

For general CLAUDE.md writing rules (pointers over content, dense formatting, no version pinning, section structure), use the `create-claude-md` skill. This file covers only what's specific to maintaining a CLAUDE.md over time.

## Structure
- **Target**: under ~200 lines
- **Priority**: Communication > Guidelines > Principles > Learnings
- **Session Learnings**: Max 3-5 recent, rotate out after 30 days

## Maintaining Learnings
- **Principles, not examples**: "Plans: outline only" not "When creating Docker plans..."
- **Merge similar**: 3 related learnings → 1 principle

## Session Learnings Format
```markdown
### YYYY-MM-DD: [Brief Title]
**Issues**: [1 sentence]
**Fix**: [What changed]
```

## Compaction Triggers
When CLAUDE.md exceeds the target:
1. Merge overlapping learnings
2. Remove items not referenced in 30+ days
3. Generalize specific examples
4. Move project-specific to project CLAUDE.md

## Good vs Bad

**Good** (60 tokens):
```
**Trigger**: Complex work (5+ files, arch decisions)
**Process**: Outline → approval → details
**Avoid**: Full file contents in plans
```

**Bad** (180 tokens):
```
When working on complex tasks (defined as >5 files or
architectural decisions), use 2-step process. First create
outline with approach, phases, files. Don't include complete
file contents (creates 400+ line plans)...
```
