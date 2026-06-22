# Learning Format Examples

## Concise Pattern Recognition

**Good** (~30 tokens):
```
- "simple/basic" repeated 3+ times → MINIMAL scope
- Docker-first project → No Mise/asdf
- 2+ corrections on same issue → Stop, ask what's wrong
```

**Bad** (~120 tokens):
```
When user repeatedly says "simple", "basic", or "barebones"
(3+ times), this signals they want minimal scope. I should
avoid over-engineering. If project uses Docker, it likely
doesn't need Mise/asdf since Docker handles versions...
```

## Merging Similar Learnings

**Before** (3 entries, ~90 tokens):
```
2026-01-15: Used REST when GraphQL better → Check patterns
2026-01-20: Complex schema when simple works → Start simple
2026-01-28: OAuth when tokens suffice → Match complexity to scale
```

**After** (1 entry, ~40 tokens):
```
2026-01: Over-engineering (GraphQL, schemas, OAuth)
Fix: Check existing patterns, start simple, match scale
```
