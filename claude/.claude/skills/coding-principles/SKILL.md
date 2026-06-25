---
name: coding-principles
description: Cross-cutting code-quality principles (KISS, modularity, descriptive naming, env-var configuration, minimal guarding) — apply whenever writing, editing, refactoring, or reviewing source code, configuration, or infrastructure definitions, in any language, alongside any language-specific skill.
user-invocable: false
model-invocable: true
---

# Coding Principles

General principles for any code you write or edit. Language-specific conventions
(terraform, bash, kubernetes, …) are owned by their own skills — defer to those for
syntax and idiom; this skill covers the cross-cutting practice.

These apply to new code and the lines you're changing — on existing code stay surgical and
suggest divergences rather than refactoring working code to match them.

- **KISS.** Pick the most direct solution that solves the actual problem. No
  speculative abstraction, no patterns the problem doesn't demand.
- **Write like an expert using only the basics.** Reach for plain language features
  and the standard library before clever constructs or extra dependencies.
- **Modular.** Each function/module owns one responsibility and does it well, behind a
  clear boundary. All interaction with a module goes through its public interface — never
  reach into another module's internals or reimplement logic that lives behind its
  interface. Compose small pieces rather
  than growing one large unit. Compartmentalize and document each module's interface so
  independent contributors or agents can work on separate modules in parallel without
  conflict.
- **Descriptive names — never shorthand.** Name variables, functions, and types for
  their purpose, spelled out in full (not `connTo` or `ct` for a connection timeout;
  case follows the language). Conventional loop indices (`i`, `j`) and established
  acronyms (`id`, `url`, `http`, `ctx`) are fine.
- **Indentation.** Match the language or file convention, where none is dictated, default to 2 spaces. Never mix tabs and
  spaces in one file.
- **Configuration via environment variables.** Anything that varies by environment —
  ports, hosts, paths, feature flags — is read from env vars, not hardcoded, with
  sensible defaults where appropriate. Secrets are the exception: prefer a secret
  manager or mounted secret file over env vars, and never ship a default credential.
- **Immutable by default.** Bind every value as a constant (`const`, `final`, `readonly`,
  `val` — whatever the language provides). Mutability is an explicit opt-in, used only where
  you genuinely reassign. A value that is never reassigned must never be left mutable.
- **Don't over-guard.** Validate at trust boundaries (external input, untrusted
  callers); inside that boundary, trust your own invariants. Skip defensive checks
  for conditions that can't occur — but where you rely on an invariant, fail loud
  (assert/panic) rather than silently omitting the check.
- **Security first.** Secrets hygiene — never expose or commit credentials.
  Least-privilege by default (IAM, tokens, file perms). Supply-chain care — pinned,
  verified dependencies. Standard injection/XSS defenses apply to all application code.
