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

## Refactoring Process

### 1. Analyze Current Implementation
- Read target code thoroughly
- Understand current architecture and patterns
- Identify pain points and technical debt
- Document current behavior

### 2. Find All Usages
- Use Grep to find all references to functions/classes
- Check imports and dependencies
- Map out the dependency graph
- Identify public vs. private APIs

### 3. Identify Affected Tests
- Find test files that cover this code
- Check test coverage completeness
- Identify integration vs. unit tests
- Note missing test cases

### 4. Propose Refactoring Approach
- Describe the target architecture
- Explain benefits and tradeoffs
- Break down into incremental steps
- Identify risks and mitigation strategies

### 5. Estimate Blast Radius
- List all files that will change
- Categorize changes: breaking vs. non-breaking
- Identify backwards compatibility concerns
- Note potential side effects

### 6. Recommend Testing Strategy
- Which tests must pass before/after
- New tests needed to prevent regression
- Manual testing steps (if any)
- Rollback plan if issues arise

## Output Format

```
## Current Analysis
[What the code does now and why it needs refactoring]

## All Usages Found
- file1.py:23 - Usage context
- file2.py:45 - Usage context
[Total: X usages across Y files]

## Affected Tests
- tests/test_foo.py - Unit tests
- tests/integration/test_bar.py - Integration tests
⚠ Missing tests for: [scenarios]

## Proposed Refactoring
### Target Architecture
[Description of the new design]

### Benefits
- Benefit 1
- Benefit 2

### Tradeoffs
- Tradeoff 1
- Tradeoff 2

### Incremental Steps
1. Step 1 (minimal change, low risk)
2. Step 2 (builds on step 1)
3. Step 3 (final state)

## Blast Radius
**Files to modify:** X files
**Breaking changes:** [list or "None"]
**Non-breaking changes:** [list]

Affected files:
- src/foo.py: [change description]
- src/bar.py: [change description]

## Testing Strategy
### Pre-refactor
- [ ] All existing tests pass
- [ ] Document current behavior

### During refactor
- [ ] Run tests after each step
- [ ] Add regression tests for edge cases

### Post-refactor
- [ ] All tests still pass
- [ ] Add new tests: [list]
- [ ] Manual verification: [if needed]

### Rollback Plan
[How to revert if issues arise]
```

## After Planning

After presenting the plan, ask:

```
This is the refactoring plan. Would you like me to:
1. Proceed with the refactoring
2. Adjust the plan first
3. Start with just the first step
```

## Safety Guidelines

- Never make breaking changes without user approval
- Always maintain backwards compatibility unless explicitly discussed
- Ensure tests pass before and after each step
- Provide a clear rollback strategy
- Make incremental commits (one step at a time)

This skill delegates to the **planner agent** for thorough analysis before any changes.
