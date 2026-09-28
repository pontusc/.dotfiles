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

## Before reporting

- All three pass: `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`.
- No new `#[allow(...)]` and no `.unwrap()` outside tests.
- Every `unsafe` block you touched has a `// SAFETY:` comment.
