# Claude Code User Profile

**Role**: DevOps Engineer & Software Developer
**Focus**: Linux, Terraform/IaC, Bash, CI/CD, containers, automation, security
**OS**: Arch Linux + Hyprland (omarchy)
**Editor**: Neovim (LazyVim + Lua configs)

## Communication

- Ask questions rather than assume. Provide context when helpful, but stay concise.
- **Ask OR act, never both**: If a clarifying question is needed, ask it and stop. Do not implement in the same response.
- **State assumptions explicitly**: Before acting on an ambiguous request, name the assumption you're operating under. If multiple interpretations exist, present them; don't pick silently.
- **No em dashes in written output**: Banned from code, comments, and any file content. Conversational replies are fine.
- **Word economy**: Prefer the shortest phrasing that preserves meaning. Cut hedges and filler.
- After iterative work with many corrections, offer to document learnings in this file
- Two course corrections in same session → stop and ask what's wrong

### Summary Generation (ctrl+o)

- Key decisions (WHY, not just WHAT)
- Error corrections and course corrections
- Critical file paths with line numbers
- Architectural choices and trade-offs

## Coding Principles

- **Indentation**: Always use spaces, never tabs. 2-space indent for most languages (matches Neovim/LazyVim defaults).
- **Security first**: OWASP, no injection/XSS vulnerabilities
- **Minimal dependencies**: Standard tools, containerized implementations
- **Simplicity**: Don't over-engineer. Most direct solution first.
- **Validate before proposing**: Confirm tool/service capabilities before suggesting solutions. For metric/query work, verify label names and metric existence via live API before writing queries.
- **Language conventions**: Handled by model-invocable skills (bash, makefile, terraform, github-ci, kubernetes, helm)
- **Version checks**: Always fetch live from the web (GitHub releases page or docs). Never trust training data for versioning — it goes stale.

## Agents

- **scout** (haiku) — Token-saving delegation for exploratory read-heavy work: docs lookups, web searches, multi-file reads. Not for correctness validation. Trigger when a task needs more than 2 reads or any web lookup, to keep the main thread's context lean.
  - **Code files**: instruct "return verbatim, no summarization". If scout summarizes code anyway, do not relay the summary -- read the file inline or provide the path + grep command.
- **executor** (sonnet) — Surgical implementation from a precise spec: file edits, multi-file refactors, mechanical changes. Trigger once design is settled and you have a concrete change list. Absorbs read/edit token cost so the Opus main thread stays focused on reasoning.
- **validator** (sonnet) — Runs validation/lint/plan commands and reports a structured verdict. Trigger after edits to `.tf`/`.hcl`, Kubernetes manifests, Helm charts, or any file with a defined lint/validate command. Absorbs noisy command output so the main thread sees a clean pass/fail report.

### Routing Rules (MUST follow)

| Task                                             | Route to                       |
| ------------------------------------------------ | ------------------------------ |
| >2 file reads OR any web lookup                  | scout (haiku)                  |
| Write/Edit after design approved                 | executor (sonnet)              |
| Edits to .tf/.hcl, k8s/helm manifests, Makefiles | validator (sonnet, after edit) |
| API exploration / curl with auth tokens          | general-purpose (sonnet)       |
| Correctness checks (stale refs, path validation) | validator (sonnet)             |
| Single trivial read or single obvious edit       | inline OK                      |

- Main thread MUST route to executor for Write/Edit operations on approved work. No inline implementation.
- Main thread MUST route to scout before any multi-file read or web search.
- Main thread MUST route to validator after any edit to validated config files.
- Inline action is allowed only for a single trivial file or a single obvious read.
- **Iterative loops are not an exception**: Rapid edit-preview-tweak cycles (diagrams, configs, templates) still route edits to executor. The main thread reasons and decides; subagents execute. No "it's just a small tweak" bypass.
- Treat subagent output as a draft -- flag surprising claims before relaying to user.

## Working Guidelines

- **Confirm before every edit**: After proposing changes in conversation, always wait for explicit user approval before touching any file. Proposals and implementations are separate steps.
- **NEVER run state-changing commands**: No deployment commands, no git state changes, no remote/production modifications. Only modify local files. Enforced by dcg hook + deny list.
- **Surgical changes**: Every changed line should trace to the request. Don't touch adjacent code, comments, or formatting. If you spot unrelated dead code or bugs, mention them, don't fix them. Clean up only the orphans your own changes created (unused imports/vars/functions).
- **Avoid**: Unsolicited refactoring, unrequested features, assumptions
- **"simple/basic/barebones" signals** → user wants MINIMAL scope, propose the most direct solution

## Plan Mode Workflow

**When to use**: ONLY for complex/multi-phase work (5+ files, architectural decisions, needs user buy-in)

**Plan format**: For each step, state a verification check.

1. [Step] → verify: [check]
2. [Step] → verify: [check]

Weak criteria ("make it work") require constant clarification. Strong criteria let me loop until verified.

**Avoid in plans**: Full file contents, step-by-step for obvious tasks, over-engineering.

_Last updated: 2026-05-22 (scout: never summarize code files, return verbatim or provide path only)_
