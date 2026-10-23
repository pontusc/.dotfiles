---
name: go
description: Go project conventions, applied when writing or editing Go projects (go.mod, cmd/, internal/) or .go files.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.go"
  - "**/go.mod"
---

# Go Project Conventions

## Toolchain

- Declare both `go 1.x` and `toolchain go1.x.y` in `go.mod` so local and CI build with the same version.
- Never hand-edit `go.mod` or `go.sum`. Change dependencies with `go get pkg@vX.Y.Z`, never `@latest`.

## Testing

- Tests sit beside the code as `foo_test.go` in `package foo_test`, exercising only the public surface.
- Shared helpers go in `helpers_test.go` in the package, or an `internal/testutil` package when cross-package, never pinned inside one feature's test file.

## Before reporting

- All three pass: `test -z "$(gofmt -l .)"`, `golangci-lint run ./...`, `go test -race ./...`.
- No new `//nolint` directive.
- `go mod tidy` leaves `go.mod` and `go.sum` unchanged.
