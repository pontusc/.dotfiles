# Evaluation Checklist

## Corrections
- [ ] Ignored explicit constraints (user said X, I did Y)
- [ ] Missed simplicity signals (simple/basic/minimal repeated 3+ times)
- [ ] Over-engineered despite requests
- [ ] Failed to apply existing CLAUDE.md guidance
- [ ] Made wrong tech assumptions

## Efficiency
- [ ] Unnecessary file reads
- [ ] Verbose outputs for simple requests
- [ ] Plan mode for trivial tasks
- [ ] Overly detailed plans (400+ lines)
- [ ] Redundant exploration/work

## Context Application
- [ ] Violated communication preferences
- [ ] Ignored coding principles
- [ ] Repeated previously corrected mistakes
- [ ] Missed documented patterns
- [ ] Failed to recognize user expertise level

## Pattern Recognition
- [ ] Repeated keywords missed (simple, basic, etc.)
- [ ] Frustration indicators ("no, just...", "I already said...")
- [ ] Course corrections that should trigger re-evaluation
- [ ] Explicit constraints stated upfront

## Structure
- [ ] A CLAUDE.md or skill rule that never took effect (violated after it landed): a check replaces it, or it is deleted
- [ ] Steering a hook, permission or test could enforce: move it there and delete the prose

## Synthesis

**Top 3 Issues**: [Highest impact problems]
**Root Causes**: [Communication / Technical / Process / Context]
**Quick Wins**: [Changes that prevent recurrence]
**Token Savings**: [Where to compact]
