---
name: rust
description: Rust project conventions — applied when writing or editing Rust projects (Cargo.toml, rust-toolchain.toml, src/) or .rs files.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Rust Project Conventions

Apply when writing or editing Rust projects — `Cargo.toml`, `src/`, `tests/`, or `.rs` files.

## Scope of changes (read first)

These are conventions for **new** projects and for the code you are **already changing**.
When editing an existing project:

- **Stay surgical.** Match the project's existing layout, error-handling style, and
  toolchain. A fix applies to the lines you're changing — don't restructure crates or swap
  error libraries to match this skill.
- **Suggest, don't migrate.** If the project diverges (floating deps, `unwrap`-heavy code,
  no clippy config), note it as a suggestion — don't fold an unrequested migration into the
  edit. Migrate only when the user explicitly asks.
- **Use the structure below for greenfield projects, or where no convention is established.**

## Toolchain & dependencies

- Pin the compiler in `rust-toolchain.toml` (`channel = "1.xx"`, current stable) so local
  and CI build identically. Bumps are deliberate.
- Set the current stable `edition` in `Cargo.toml`.
- **Pin direct dependencies to a specific version** (`"1.2.3"`, never `"*"` or a bare
  major); commit `Cargo.lock` so transitives are pinned too. Bumps are deliberate.
- **Minimal features**: `default-features = false` with an explicit `features = […]` list
  where practical — smaller supply-chain and compile surface. Vet every new crate
  (maintenance, `unsafe` usage, transitive weight) before adding.

## Project layout

- Binaries: thin `main.rs` — parse args/config, call into `lib.rs`; logic lives in the
  library so it's testable.
- Multi-crate repos: a workspace with `[workspace.dependencies]` so versions are declared
  once.
- Modules: `foo.rs` over `foo/mod.rs`. Re-export the public surface from `lib.rs`; keep the
  rest `pub(crate)`.

## Code style

- `rustfmt` defaults; `cargo clippy` passes clean. Fix the cause, don't silence the
  symptom — a justified `#[allow(…)]` carries a reason comment.
- **Everything fallible returns `Result`.** Libraries: concrete error types (`thiserror`).
  Binaries: `anyhow` with `.context(…)` at the edges is fine.
- **No `.unwrap()` outside tests.** When an invariant genuinely can't fail,
  `.expect("why it can't fail")` states the reason.
- Don't clone to appease the borrow checker — restructure ownership; clone only when the
  sharing (and its cost) is deliberate.
- `unsafe` is a last resort; every block carries a `// SAFETY:` comment proving the
  invariant it relies on.
- Derive, don't hand-write: `Debug`, `Clone`, `PartialEq`, serde traits via `#[derive(…)]`.

## Testing

- Unit tests in `#[cfg(test)] mod tests` beside the code; integration tests in `tests/`
  exercise the public API only.
- Name `tests/` files for the API area they cover (`tests/config.rs`, not `tests/e2e.rs`) —
  per coding-principles (test-file organization). Shared harness code goes in
  `tests/common/mod.rs`, never pinned inside one test file.
- Test error paths, not just the happy path — `Result`-returning code makes them cheap to
  reach.

## Quality gate

Run the same three locally and in CI — all must pass:

```
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test
```
