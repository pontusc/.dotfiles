---
name: docker
description: Container build conventions, applied when writing or editing Dockerfiles.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
  - "**/Containerfile"
---

# Docker

## Base images

- Pin by specific tag, or by `@sha256:` digest for immutability. Never `latest`.
- Official or verified-publisher images only. Flag the publisher and the supply-chain risk before using a community base.
- Prefer `-slim`, `alpine`, or `distroless` where the toolchain allows.

## Build structure

- Multi-stage, with a minimal runtime stage.
- Omit the `# syntax=` directive unless a labs-only feature requires it.
- A `--mount=type=cache` earns its place on a heavy dependency install, measure before adding one.
- Install a CLI tool with `COPY --from` off its official image, digest-pinned, rather than curling an installer: `COPY --from=ghcr.io/astral-sh/uv:0.11.23@sha256:... /uv /usr/local/bin/uv`. An installer script is the fallback when an image reference must be avoided.

## Secrets

- Define the secret on a Bake target sourced from a host env var, `secret = [{ type = "env", id = "registry-token", env = "REGISTRY_TOKEN" }]` in `docker-bake.hcl`, and consume it with `RUN --mount=type=secret,id=registry-token,env=REGISTRY_TOKEN`.

## Before reporting

- Run `docker build --check -f <file> .` and fix every reported rule.
- Grep the file for `latest` and for any `FROM` without a tag or digest.
- Confirm every `COPY --from` external image reference carries a digest.
