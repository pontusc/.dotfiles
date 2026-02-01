---
name: refactor
description: Plan and execute safe refactoring with impact analysis
user-invocable: true
disable-model-invocation: false
allowed-tools: All
argument-hint: [target-file or component]
context: fork
agent: planner
model: opus
---

Plan a refactoring for: $ARGUMENTS

## REFACTORING PROCESS

### 1. Analyze Current Implementation
- Read target code thoroughly
- Understand architecture and patterns
- Identify pain points and technical debt
- Document current behavior

### 2. Find All Usages
- Use Grep to find all references
- Check imports and dependencies
- Map dependency graph
- Identify public vs private APIs

### 3. Identify Affected Tests
- Find test files covering this code
- Check test coverage completeness
- Note missing test cases

### 4. Propose Approach
- Describe target architecture
- Explain benefits and tradeoffs
- Break down into incremental steps
- Identify risks and mitigation

### 5. Estimate Blast Radius
- List all files that will change
- Categorize: breaking vs non-breaking
- Note backwards compatibility concerns
- Identify potential side effects

### 6. Testing Strategy
- Which tests must pass before/after
- New tests needed to prevent regression
- Manual testing steps (if any)
- Rollback plan if issues arise

## OUTPUT FORMAT

```
## Current Analysis
[What code does now and why it needs refactoring]

## All Usages Found
- file1.py:23 - Usage context
- file2.py:45 - Usage context
[Total: X usages across Y files]

## Affected Tests
- tests/test_foo.py - Unit tests
- tests/integration/test_bar.py - Integration
⚠ Missing tests for: [scenarios]

## Proposed Refactoring
**Target Architecture:** [New design]
**Benefits:** [list]
**Tradeoffs:** [list]
**Incremental Steps:**
1. Step 1 (minimal change, low risk)
2. Step 2 (builds on step 1)
3. Step 3 (final state)

## Blast Radius
**Files to modify:** X files
**Breaking changes:** [list or "None"]
**Non-breaking changes:** [list]

## Testing Strategy
**Pre-refactor:** [ ] All tests pass, [ ] Document current behavior
**During:** [ ] Run tests after each step, [ ] Add regression tests
**Post-refactor:** [ ] All tests pass, [ ] Add new tests: [list]
**Rollback Plan:** [How to revert]
```

## SAFETY GUIDELINES

- Never make breaking changes without user approval
- Maintain backwards compatibility unless explicitly discussed
- Ensure tests pass before and after each step
- Provide clear rollback strategy
- Make incremental commits (one step at a time)

This skill delegates to the **planner agent** for thorough analysis before changes.
