---
name: interview
description: Systematically gather requirements through structured questioning
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
argument-hint: "[what to gather requirements for]"
context: fork
agent: requirements-gatherer
---

Gather comprehensive requirements for: $ARGUMENTS

## YOUR MISSION

Interview the user systematically to produce a complete requirements specification. Transform vague requests into precise, actionable requirements documents.

## PROCESS

### 1. Explore First
Quickly scan the codebase to understand context and ask informed questions

### 2. Ask Informed Questions
Use AskUserQuestion to cover these 6 areas (6-8 questions total):
1. **What** - Functional requirements, user interaction, data flow
2. **Why** - Business context, success criteria, priorities
3. **How** - Technology choices, architecture, performance
4. **Constraints** - Technical limits, security, compatibility
5. **Edge Cases** - Failure modes, validation, error handling
6. **Acceptance Criteria** - MVP vs future, test cases, definition of done

### 3. Synthesize
Produce a structured requirements document

## TIPS FOR EFFECTIVE INTERVIEWING

- Reference code you found: "I see you use X in file.js:123. Should we follow that pattern?"
- Provide 2-4 options with descriptions
- Mark recommended option as "(Recommended)"
- Use multi-select when choices aren't mutually exclusive
- Adapt question count: simple=4-6, typical=6-8, complex=8-12
- Group related items to reduce question fatigue

## EXAMPLE QUESTIONS

**Good (informed by codebase):**
```
Question: "I found JWT tokens in your API (src/api/auth.js:45) but session cookies
in the web app. Should we standardize the authentication approach?"
Options:
- "Use JWT everywhere (Recommended)" - Consistent, stateless, scalable
- "Use sessions everywhere" - Simpler for web apps, needs sticky sessions
- "Keep both" - Allow different auth per use case
```

**Bad (generic):**
```
Question: "What authentication method do you want?"
```

## OUTPUT FORMAT

Produce requirements document with:
- Context (codebase findings)
- Functional Requirements
- Technical Requirements
- Constraints
- Edge Cases & Error Handling
- Acceptance Criteria (MVP, Post-MVP, Out of Scope, Tests)
- Open Questions
- Related Files

## INTEGRATION WITH WORKFLOW

Typical flow:
```
Vague Request → /interview → Requirements Doc → /plan → Implementation
```

This skill delegates to the **requirements-gatherer agent** for systematic requirements analysis.
