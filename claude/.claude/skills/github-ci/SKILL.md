---
name: github-ci
description: GitHub Actions CI/CD conventions — applied when writing or editing .github/workflows/*.yml files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# GitHub Actions CI/CD Conventions

Apply these conventions when writing or editing `.github/workflows/*.yml` files.

## Workflow Structure

- **One workflow per concern** — don't combine CI, CD, and release in a single file.
- **Descriptive `name:`** — visible in the GitHub UI, keep it short and clear.
- **Trigger scoping**: Be specific with `on:` triggers. Use `paths:` filters to avoid running workflows on unrelated changes.

```yaml
on:
  pull_request:
    paths:
      - "src/**"
      - "Dockerfile"
```

## Actions

- **Pin actions by SHA**, not tag: `uses: actions/checkout@<full-sha>` — prevents supply chain attacks from tag mutation.
- **Minimize third-party actions**: Prefer inline `run:` steps for simple operations. Only use actions when they provide real value.
- **Official actions first**: Prefer `actions/*` and first-party vendor actions over community alternatives.

## Secrets and Security

- **Never hardcode secrets** — use `${{ secrets.NAME }}`.
- **Least privilege `permissions:`** — always define `permissions:` at the workflow or job level. Start with `permissions: {}` and add only what's needed.
- **No `pull_request_target` with checkout** — avoid checking out PR code in `pull_request_target` workflows (code injection risk).

## Jobs

- **`runs-on:`** — use specific runner versions (e.g., `ubuntu-24.04`), not `ubuntu-latest` (reproducibility).
- **Job dependencies**: Use `needs:` to express dependencies. Keep the DAG shallow.
- **Concurrency**: Use `concurrency:` to prevent duplicate runs on the same branch/PR.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## Steps

- **Name every step** — unnamed steps are hard to debug in the UI.
- **Fail fast**: Use `set -euo pipefail` in multi-line `run:` blocks (GitHub defaults to `set -e` only).
- **Cache wisely**: Use `actions/cache` for dependencies. Always include a hash of the lockfile in the cache key.
- **Artifacts**: Use `actions/upload-artifact` for build outputs needed by downstream jobs, not for logs.

## Environment Variables

- Define shared env vars at workflow level, job-specific at job level.
- Use `$GITHUB_OUTPUT` for passing values between steps (not deprecated `::set-output`).
- Use `$GITHUB_ENV` sparingly — prefer explicit step outputs.
