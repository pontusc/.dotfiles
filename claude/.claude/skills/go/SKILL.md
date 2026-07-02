---
name: go
description: Go project conventions — applied when writing or editing Go projects (go.mod, cmd/, internal/) or .go files.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Go Project Conventions

Apply when writing or editing Go projects — `go.mod`, `go.sum`, or `.go` files.

## Scope of changes (read first)

These are conventions for **new** projects and for the code you are **already changing**.
When editing an existing project:

- **Stay surgical.** Match the project's existing layout, module structure, and style. A fix
  applies to the lines you're changing — don't restructure packages or swap tooling to match
  this skill.
- **Suggest, don't migrate.** If the project diverges (flat layout, ad-hoc goroutines, no
  linter config), note it as a suggestion — don't fold an unrequested migration into the
  edit. Migrate only when the user explicitly asks.
- **Use the structure below for greenfield projects, or where no convention is established.**

## Toolchain & dependencies

- Declare the compiler in `go.mod` (`go 1.x` + `toolchain go1.x.y`) so local and CI build
  with the same version. Bumps are deliberate.
- `go.mod`/`go.sum` are the lockfile — never edit them by hand. Change deps via
  `go get pkg@vX.Y.Z` (exact version, never `@latest`), then `go mod tidy`.
- Vet every new dependency (maintenance, transitive weight) before adding — and prefer the
  stdlib; it covers more than you think.

## Project layout

- One `cmd/<binary>/main.go` per binary; `main` stays thin — flag/config wire-up only,
  logic lives in packages so it's testable.
- `internal/` for packages other modules must not import. Reach for `pkg/` only when
  something is deliberately public API.
- Package names: short, lower-case, no underscores; no stuttering (`chat.Server`, not
  `chat.ChatServer`).

## Code style

- `gofmt`/`goimports` formatting is non-negotiable; `golangci-lint` passes clean. Fix the
  cause, don't silence the symptom — a justified `//nolint:<linter>` carries a reason comment.
- **Accept interfaces, return structs.** Define interfaces where they're consumed, not next
  to the implementation, and keep them small (1–3 methods).
- **Errors are values.** Wrap with `fmt.Errorf("doing x: %w", err)`; branch with
  `errors.Is`/`errors.As`. No `panic` for expected failures. Sentinel errors
  (`var ErrX = errors.New(…)`) only when callers must branch on them.
- `context.Context` is the first parameter of anything that blocks or crosses a boundary —
  never stored in a struct.
- Make the zero value useful; add a `NewX` constructor only when invariants demand it.
- Every goroutine has a defined exit path. Prefer `errgroup` / worker patterns over ad-hoc
  channel + `WaitGroup` plumbing.

## Testing

- Standard `testing` package: table-driven tests with subtests (`t.Run`); helpers call
  `t.Helper()`.
- Tests live beside the code (`foo_test.go`); use `package foo_test` to exercise only the
  public surface. When one outgrows that, split by feature (`foo_parse_test.go`), not by
  harness — per coding-principles (test-file organization).
- Shared test helpers live in a `helpers_test.go` in the package (or an `internal/testutil`
  package when cross-package), never pinned inside one feature's test file.
- Run with `-race` — data races are failures, not flakes.

## Quality gate

Run the same three locally and in CI — all must pass:

```
test -z "$(gofmt -l .)"
golangci-lint run ./...
go test -race ./...
```
