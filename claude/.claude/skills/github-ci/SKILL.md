---
name: github-ci
description: GitHub Actions conventions, applied when writing or editing workflow YAML under .github/workflows.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/.github/workflows/*.yml"
  - "**/.github/workflows/*.yaml"
---

# GitHub Actions

- Scope `on:` triggers tightly, with `paths:` filters so unrelated changes do not trigger a run.
- `runs-on: ubuntu-latest` for GitHub-hosted runners. Pin a version like `ubuntu-24.04` only for self-hosted runners or a job needing a fixed toolchain.
- `concurrency:` with `group: ${{ github.workflow }}-${{ github.ref }}` and `cancel-in-progress: true` for CI, `false` for deploy and release jobs, since cancelling mid-deploy can leave infra half-applied.
- Declare `permissions:` at workflow or job level, starting from `permissions: {}`.
- Cloud auth uses OIDC: `permissions: id-token: write` plus the provider's federated-login action, never static credentials.
- Pin actions by full commit SHA, not tag: `uses: actions/checkout@<full-sha>`. SHAs go stale, so let Dependabot or Renovate (`github-actions` ecosystem) keep them current.
- An inline `run:` step before a third-party action. `actions/*` and first-party vendor actions before community ones.
- `set -euo pipefail` in every multi-line `run:` block, GitHub defaults to `set -e` only. `run:` blocks are bash, load the `bash` skill before writing one.
- Under a job `working-directory`, a script outside that dir resolves as `$GITHUB_WORKSPACE/tools/scripts/my-script.sh`. Never `./`, and never quoted, which is a YAML syntax error.
- `vars.FOO` passes to a reusable workflow through `with:` as an `inputs:` string, `secrets.FOO` through `secrets:`. They are separate channels and mixing them fails silently, so moving a value between them means changing caller and callee together.

## Before reporting

- Run `actionlint` on the changed workflow.
- Every `uses:` in the changed workflow is pinned to a full commit SHA.
- Confirm the workflow or every job declares `permissions:`.
