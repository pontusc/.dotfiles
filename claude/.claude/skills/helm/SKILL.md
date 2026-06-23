---
name: helm
description: Consuming third-party Helm charts via values files and install/upgrade. Applied when editing Helm values/override files (values.yaml, values-*.yaml, values.<env>.yaml, helmfile.yaml) or running helm install/upgrade on a release/package.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---

# Consuming Helm Charts

These conventions cover installing and configuring upstream charts through values overrides — not authoring charts.

## Before Making Changes

Trace the values chain first so you override at the right layer and don't duplicate an existing setting.

1. Find the chart's `values.yaml` (the override target) and any env-specific files (`values-prod.yaml`, `values.<env>.yaml`).
2. If `helmfile.yaml` is present, read it — it composes which values files apply, in what order, per release. (helmfile is a separate declarative tool layered on the `helm` CLI: https://github.com/helmfile/helmfile.)
3. Confirm the value isn't already set upstream or earlier in the override chain before adding it.

## Know the Upstream Defaults

- `helm show values <chart>` prints the chart's full `values.yaml`; `helm show chart <chart>` prints its `Chart.yaml`. Read these before overriding.
- Override **only the keys that differ** from upstream. Never paste the entire upstream values file into your override — it silently pins defaults you didn't mean to own and drifts on chart upgrades.
- If the chart ships a `values.schema.json`, your final values must satisfy it. The schema is validated on `install`, `upgrade`, `lint`, and `template` (including `--set` overrides); a mismatch fails the command.

## Sourcing and Pinning

- HTTP repos: `helm repo add <name> <url>` then `helm repo update`. OCI charts use the full ref as the chart argument: `oci://registry/repo/chart`.
- Always pin `--version <ver>` on install/upgrade — prefer an exact tag for reproducibility (the flag also accepts semver ranges). Without it Helm resolves to the latest available version.

## Installing and Upgrading

- Idempotent apply: `helm upgrade --install <release> <chart> -n <ns> --create-namespace --version <ver> -f values.yaml`. `--install` installs if the release is absent; `--create-namespace` only acts when `--install` is set.
- Supply values with `-f`/`--values` (repeatable, later files win) and `--set key=val` for one-offs.
- Values-merge footgun on upgrade: the default is conditional. With **no** `-f`/`--set`, Helm carries over the entire prior release config (reuse-like); with **any** `-f`/`--set`, it uses chart defaults plus only this run's overrides, so **prior overrides you don't re-specify are dropped** (reset-like). `--reuse-values` forces reuse with your overrides merged on top; `--reset-values` forces chart defaults; `--reset-then-reuse-values` (Helm 3.14+) resets to chart defaults, re-applies the last release's values, then merges your CLI overrides. If a previously-set override vanishes on upgrade, this is why — pass the full values file each time rather than relying on the implicit merge.

## Preview and Validate

- `helm diff upgrade <release> <chart> -f values.yaml` shows what an upgrade would change against the live release. It's the `helm-diff` plugin, not core Helm: `helm plugin install https://github.com/databus23/helm-diff`.
- `helm template <chart> -f values.yaml` renders manifests locally (no cluster). `--dry-run=server` on install/upgrade simulates server-side against the cluster (so server-side validation/admission applies); `--dry-run=client` skips the cluster.
- Sanity-check the rendered manifests against the same Kubernetes conventions you'd apply to hand-written manifests before applying.

## Secrets

Never commit plaintext secrets to a values file. Reference ExternalSecrets, SealedSecrets, or the Secrets Store CSI driver and let those reconcile the actual secret material.
