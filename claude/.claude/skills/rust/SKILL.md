---
name: rust
description: Rust project conventions, applied when writing or editing Rust projects (Cargo.toml, rust-toolchain.toml, src/) or .rs files.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust Project Conventions

## Toolchain and dependencies

- Pin the compiler in `rust-toolchain.toml` (`channel = "1.xx"`, current stable) and set the current stable `edition` in `Cargo.toml`.
- `default-features = false` with an explicit `features = [...]` list where practical.

## Layout

- Binaries: a thin `main.rs` parses args and config and calls into `lib.rs`, where the logic lives so it is testable.
- Multi-crate repos use a workspace with `[workspace.dependencies]` so versions are declared once.
- Modules are `foo.rs`, not `foo/mod.rs`. Re-export the public surface from `lib.rs` and keep the rest `pub(crate)`.

## Code style

- Libraries use concrete error types via `thiserror`. Binaries may use `anyhow` with `.context(...)` at the edges.
- No `.unwrap()` outside tests. Where an invariant genuinely cannot fail, `.expect("why it cannot fail")` states the reason.
- Every `unsafe` block carries a `// SAFETY:` comment proving the invariant it relies on.

## Testing

- Unit tests in `#[cfg(test)] mod tests` beside the code. Integration tests in `tests/` exercise the public API only.
- Shared harness code goes in `tests/common/mod.rs`, never pinned inside one test file.

## Before reporting

- All three pass: `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`.
- No new `#[allow(...)]` and no `.unwrap()` outside tests.
- Every `unsafe` block you touched has a `// SAFETY:` comment.
