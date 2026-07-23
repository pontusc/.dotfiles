---
name: github-ci
description: GitHub Actions CI/CD conventions — applied when writing or editing .github/workflows/*.yml files.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# GitHub Actions CI/CD Conventions

Conventions for new files and the lines you're changing — on existing files stay surgical and suggest divergences rather than migrating.

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

- **Pin actions by SHA**, not tag: `uses: actions/checkout@<full-sha>` — prevents supply-chain attacks from tag mutation. SHAs go stale; let Dependabot or Renovate (`github-actions` ecosystem) keep them current.
- **Minimize third-party actions**: Prefer inline `run:` steps for simple operations. Only use actions when they provide real value.
- **Official actions first**: Prefer `actions/*` and first-party vendor actions over community alternatives.

## Secrets and Security

- **Never hardcode secrets** — use `${{ secrets.NAME }}`.
- **Least privilege `permissions:`** — define `permissions:` at the workflow or job level. Start with `permissions: {}` and add only what's needed.
- **No `pull_request_target` with checkout** — avoid checking out PR code in `pull_request_target` workflows (code injection risk).
- **Prefer OIDC over long-lived secrets**: for cloud auth (GCP/AWS/Azure), use `permissions: id-token: write` plus the provider's federated-login action instead of static credentials in `secrets.*`.

## Jobs

- **`runs-on:`** — use `ubuntu-latest` for GitHub-hosted runners (GitHub maintains and patches the image). Pin a specific version (e.g., `ubuntu-24.04`) only for self-hosted runners or when a job needs a fixed toolchain.
- **Job dependencies**: Use `needs:` to express dependencies. Keep the DAG shallow.
- **Concurrency**: Use `concurrency:` to prevent duplicate runs. `cancel-in-progress: true` for CI (superseded runs are wasted work); set it `false` for deploy/release jobs — cancelling mid-deploy can leave infra half-applied.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # false for deploy/release jobs
```

## Steps

- **Name every step** — unnamed steps are hard to debug in the UI.
- **Fail fast**: Use `set -euo pipefail` in multi-line `run:` blocks (GitHub defaults to `set -e` only).
- **`run:` blocks are bash** — load the `bash` skill before writing them.
- **Cache wisely**: Use `actions/cache` for dependencies; key on a hash of the lockfile, with `restore-keys:` as a partial-hit fallback.
- **Artifacts**: Use `actions/upload-artifact` for build outputs needed by downstream jobs, not for logs.

## Environment Variables

- Define shared env vars at workflow level, job-specific at job level.
- Use `$GITHUB_OUTPUT`/`$GITHUB_STATE` for step outputs/state (not the deprecated `::set-output`/`::save-state`).
- Use `$GITHUB_ENV` sparingly — prefer explicit step outputs.

## Script Paths with `working-directory`

When a job sets `working-directory` to a subdirectory, scripts outside that dir must use `$GITHUB_WORKSPACE` for absolute resolution:

```yaml
run: $GITHUB_WORKSPACE/tools/scripts/my-script.sh
```

Do NOT use `./` (resolves relative to the working dir) or quote the variable (causes YAML syntax error).

## `vars.*` vs `secrets.*` — Distinct Channels

GHA variables and secrets flow through separate channels in reusable workflows:

- `vars.FOO` → pass via `with:` as a workflow `inputs:` (type: string)
- `secrets.FOO` → pass via `secrets:` as a workflow `secrets:`

Mixing them causes silent failures or lint errors. When a value moves from a secret to a variable, update both the caller (`with:` instead of `secrets:`) and the called workflow (`inputs:` instead of `secrets:`).
