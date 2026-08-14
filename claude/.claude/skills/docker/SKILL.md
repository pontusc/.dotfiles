---
name: docker
description: Container build conventions, applied when writing or editing Dockerfiles and .dockerignore.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Dockerfile / Container Conventions

Apply when writing or editing `Dockerfile`, `*.dockerfile`, or `.dockerignore`.

## Scope of changes (read first)

These are conventions for **new** Dockerfiles and for the lines you are **already changing**.
When editing an existing file:

- **Stay surgical.** A minor fix applies to the changed lines only. Do not rewrite a working
  Dockerfile to conform to these conventions.
- **Suggest, don't migrate.** If the surrounding file diverges (e.g. runs as root, uses
  `latest`, single-stage), note it as a suggestion: don't fold an unrequested refactor into
  the edit. Migrate only when the user explicitly asks.

## Base Images

- **Pin the base**: specific tag, or `@sha256:...` digest for immutability. Never `latest`.
- **Verified-publisher / official images only.** If a base is from an unverified or community
  publisher, **flag it loudly**: call out the supply-chain risk and the publisher before
  using it.
- **Prefer minimal bases**: `-slim`, `alpine`, or `distroless` where the toolchain allows.

## Build Structure

- **Multi-stage builds**: build/compile in one stage, copy only artifacts into a minimal
  runtime stage. Keep build tools out of the final image.
- **Layer ordering**: rarely-changing layers (dependency installs) before frequently-changing
  ones (source copy) to maximize cache reuse.
- **Cleanup in the same layer**: chain related commands with `&&` and clean in that `RUN`
  (e.g. `apt-get clean && rm -rf /var/lib/apt/lists/*`). A separate cleanup `RUN` doesn't
  shrink the image.
- **BuildKit mounts** over manual cache juggling: `--mount=type=cache` for package caches,
  `--mount=type=bind` to read build inputs without persisting them in a layer.
- **`COPY` over `ADD`**: use `ADD` only for tar auto-extraction. `ADD <url>` does no checksum verification. Fetch remote files via a `RUN` with an explicit `sha256sum` check instead.
- **`WORKDIR`** with an absolute path instead of `cd` in `RUN`.

## Secrets

- **Only ever via Bake secret mounts.** Never `COPY` a secret or pass one through `ARG`/`ENV`:
  those persist in image history. Define the secret in `docker-bake.hcl`, sourced from a
  host env var, and consume it with `RUN --mount=type=secret`:

  ```hcl
  # docker-bake.hcl
  target "_secrets" {
    secret = [{ type = "env", id = "registry-token", env = "REGISTRY_TOKEN" }]
  }
  ```

  ```dockerfile
  # Dockerfile
  RUN --mount=type=secret,id=registry-token,env=REGISTRY_TOKEN \
      cargo build --release
  ```

## Security

- **Run as non-root**: create a dedicated user and set `USER` before the entrypoint.
  `COPY --chown` to give it ownership.
- **Pin package versions** where the package manager supports it.
- **`.dockerignore`**: deny-all first (`**`), then explicitly re-include what the build needs with `!` patterns.

## Runtime

- **Exec form** for `ENTRYPOINT`/`CMD` (`["bin", "arg"]`) so the process runs as PID 1 and
  receives signals (SIGTERM) directly. `ENTRYPOINT` = executable, `CMD` = default args.
- **`EXPOSE`** documents ports only: it does not publish them (that's `-p` / `ports:` at run time).

## Parser directive

- **Omit the `# syntax=` directive** unless a labs-only feature requires it.

## Installing CLI tools

- **`COPY --from` the tool's official image, pinned by digest**, rather than curling an
  installer in a `RUN`. It extracts just the binary, with no `curl`, no CA certs, no network call
  in a layer, and digest-pinned:
  `COPY --from=ghcr.io/astral-sh/uv:0.11.23@sha256:... /uv /usr/local/bin/uv`
- Installer-script route is a fallback only when an image reference must be avoided.
