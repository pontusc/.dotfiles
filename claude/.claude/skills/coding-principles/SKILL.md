---
name: coding-principles
description: Cross-cutting rules for any code, config, or infrastructure definition, in any language. Apply alongside the language skill whenever writing, editing, or reviewing.
user-invocable: false
---

# Coding Principles

Less is more. The smallest change that satisfies the request, with structure and names carrying the meaning, and almost no comments. Language skills own syntax and idiom.

## Scope

- Implement only what was asked. No guards, fallbacks, flags, modes, config keys, or hardening beyond the request. Offer omissions as a one-line menu afterwards.
- Standard mechanism before custom code: the platform or tool feature first, then the standard library, then your own code. Say which you checked.
- A config key set to the tool's default is noise. Check the default, or omit the line.
- A passing remark from the user is not a requirement. Confirm before building on it.

## Structure and names

- One responsibility per function and module, reached only through its public interface.
- Group files by the concern they serve. Split a file along the same lines when it becomes a catch-all. A reader locates a concern by its path.
- Test files are split by the behavior under test, never by the harness that drives them. Shared fixtures live in the language's shared location.
- Names spell out purpose in full. Case follows the language. `i`, `j`, `id`, `url`, `ctx` are fine.
- Match the file's indentation. Default to 2 spaces. Never mix tabs and spaces.

## Comments

- Default is none. Names and placement carry intent.
- A comment stays only for what code cannot express: a constraint, an invariant, a runtime property. One line.
- Never: rationale for a choice, provenance ("mirrors X"), tool basics, restating the line below, section banners, TODO scaffolding, docstrings that repeat the signature. Rationale goes in chat or the plan doc.
- A construct you want to excuse in a comment is a signal to verify the assumption, not to annotate it.

## Correctness

- Explicit types on signatures, public APIs, and data structures. Do not restate types the language infers for obvious locals. Parse external data into typed values at the boundary. No `Any`, `interface{}`, or unchecked casts.
- Immutable by default. Reassignment is an explicit opt-in.
- Validate at trust boundaries only. Inside, trust your invariants and fail loud where one is relied on.
- Environment-specific values come from env vars with sane defaults. Secrets come from a secret manager or mounted file, never a default credential, never exposed or committed.
- Fix the cause a linter or type checker names. Never suppress, loosen config, or add scaffolding to quiet a tool.
- Least privilege, pinned and verified dependencies, standard injection defenses.

## Before reporting

- List every comment you added. Delete any that is not a constraint, invariant, or runtime property.
- Name the purpose of every new symbol, parameter, and config key. Delete what you cannot name.
- Confirm the change is the minimal form. If a simpler standard mechanism exists, say so instead of shipping the custom one.
