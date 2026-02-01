# CLAUDE.md Best Practices

## Structure
- **Target**: 100-200 lines (~800-1200 tokens)
- **Priority**: Communication > Guidelines > Principles > Learnings
- **Session Learnings**: Max 3-5 recent, rotate out after 30 days

## Content Rules
- **Principles, not examples**: "Plans: outline only" not "When creating Docker plans..."
- **Merge similar**: 3 related learnings → 1 principle
- **Remove obvious**: Basic programming practices don't need docs
- **Token estimate**: ~4 chars = 1 token

## Session Learnings Format
```markdown
### YYYY-MM-DD: [Brief Title]
**Issues**: [1 sentence]
**Fix**: [What changed]
```

## Compaction Triggers
When CLAUDE.md >200 lines:
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
