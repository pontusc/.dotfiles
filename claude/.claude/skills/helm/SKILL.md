---
name: helm
description: Consuming third-party Helm charts through values overrides and install or upgrade, not authoring charts.
user-invocable: false
allowed-tools: Read, Glob, Grep, Bash
paths:
  - "**/values*.yaml"
  - "**/values*.yml"
  - "**/helmfile.yaml"
---

# Consuming Helm Charts

- Trace the values chain before changing anything: the chart's `values.yaml` and any env-specific files (`values-prod.yaml`, `values.<env>.yaml`).
- Read `helmfile.yaml` when present, it composes which values files apply, in what order, per release.
- `helm show values <chart>` and `helm show chart <chart>` before overriding.
- Override only the keys that differ from upstream. Never paste the whole upstream values file into an override, it silently pins defaults you did not mean to own and drifts on chart upgrade.
- HTTP repos: `helm repo add <name> <url>` then `helm repo update`. OCI charts take the full ref as the chart argument: `oci://registry/repo/chart`.
- `--version <ver>` on every install and upgrade, an exact tag rather than a semver range. Without it Helm resolves to the latest available version.
- Idempotent apply: `helm upgrade --install <release> <chart> -n <ns> --create-namespace --version <ver> -f values.yaml`. `--create-namespace` only acts alongside `--install`.
- `-f`/`--values` is repeatable, later files win.
- Merge on upgrade is conditional: with any `-f` or `--set`, Helm takes chart defaults plus this run's overrides only, so prior overrides you do not re-specify are dropped, while with no `-f` and no `--set` it reuses the whole prior release config. Pass the full values file every run rather than relying on `--reuse-values` or `--reset-then-reuse-values`.
- `helm template <chart> -f values.yaml` renders manifests locally with no cluster. `--dry-run=server` simulates against the cluster so server-side validation and admission apply.
- The diff check needs the plugin: `helm plugin install https://github.com/databus23/helm-diff`.
- Check the rendered manifests against the `kubernetes` skill's conventions before applying.

## Before reporting

- Run `helm diff upgrade <release> <chart> -f values.yaml`, the `helm-diff` plugin, or `helm template` when no release exists.
- Confirm every key in the override differs from `helm show values` output, or earlier in the override chain.
- Confirm the install or upgrade command carries `--version`.
