---
name: coding-principles
description: Cross-cutting code-quality principles (KISS, modularity, descriptive naming, test-file organization, env-var configuration, minimal guarding) — apply whenever writing, editing, refactoring, or reviewing source code, configuration, or infrastructure definitions, in any language, alongside any language-specific skill.
user-invocable: false
---

# Coding Principles

General principles for any code you write or edit. Language-specific conventions
(terraform, bash, kubernetes, …) are owned by their own skills — defer to those for
syntax and idiom; this skill covers the cross-cutting practice.

These apply to new code and the lines you're changing — on existing code stay surgical and
suggest divergences rather than refactoring working code to match them.

Code is read and reviewed far more than it's written — favor the choice that's obvious to the
next reader (human or agent). Every principle below serves that.

- **KISS — and minimal first.** Pick the most direct solution that solves the actual
  problem. No speculative abstraction, no patterns the problem doesn't demand. A new
  script/tool's first version implements only the explicitly requested core — no
  speculative guards, fallbacks, config knobs, or modes. Offer the omitted hardening
  as a short menu and let the user pick.
- **Write like an expert using only the basics.** Reach for plain language features
  and the standard library before clever constructs or extra dependencies.
- **Comments serve the next reader, not the reviewer.** A comment earns its place only by
  stating what the code can't show — a constraint, an invariant, a runtime property. Change
  rationale, provenance ("mirrors X", "same as Y"), comparisons to other files, and answers
  to review questions are addressed to *me*: they go in chat or the plan doc, never into the
  file. A construct that needs excusing in a comment is the signal to verify the assumption
  behind it, not to annotate it.
- **Modular.** Each function/module owns one responsibility and does it well, behind a
  clear boundary. All interaction with a module goes through its public interface — never
  reach into another module's internals or reimplement logic that lives behind its
  interface. Compose small pieces rather
  than growing one large unit. Compartmentalize and document each module's interface so
  independent contributors or agents can work on separate modules in parallel without
  conflict.
- **Structure by domain.** Mirror the logical decomposition in the file tree: group files
  by the concern they serve, and split a file along the same lines (by subdomain) once it
  grows into a catch-all. A reader should locate a concern by its path, not by scrolling one
  giant file.
- **Test files are organized by covered behavior.** Name and split test files by the
  feature/behavior under test, never by the mechanism that drives them — a file named for
  its harness ("e2e", "cli-runner") has no axis to narrow along, grows without bound, and
  every branch collides in it. Shared test plumbing (fixtures, helpers, constants) lives in
  the language's shared location, never pinned inside one test module, so any test file can
  split along feature lines. Size is the symptom, not the rule: one file spanning many
  independent feature groups is the signal to split.
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
- **Type the boundaries.** Give function signatures, public APIs, and data structures
  explicit types; don't restate types the language can already see for obvious locals. Parse
  external data into typed structures at the boundary rather than threading raw dicts/JSON
  inward — the typed value is what lets inner code trust its invariants. Prefer precise types
  over escape hatches (`Any`, `any`, `interface{}`, unchecked casts).
- **Don't over-guard.** Validate at trust boundaries (external input, untrusted
  callers); inside that boundary, trust your own invariants. Skip defensive checks
  for conditions that can't occur — but where you rely on an invariant, fail loud
  (assert/panic) rather than silently omitting the check.
- **Security first.** Secrets hygiene — never expose or commit credentials.
  Least-privilege by default (IAM, tokens, file perms). Supply-chain care — pinned,
  verified dependencies. Standard injection/XSS defenses apply to all application code.
