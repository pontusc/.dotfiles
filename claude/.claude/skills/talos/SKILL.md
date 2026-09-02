---
name: talos
description: 'Talos Linux cluster operations, talosctl targeting safety, and machine config conventions. Apply when a file carries `machine:` and `cluster:` top-level keys, a top-level `kind: MachineConfig` or `version: v1alpha1`, or a Talos machine config patch, whatever the filename.'
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/controlplane.yaml"
  - "**/worker.yaml"
  - "**/talconfig.yaml"
  - "**/talos/**/*.yaml"
---

# Talos Linux

talosctl has no confirmation prompts. Verify flags against the live docs:

- CLI reference: https://www.talos.dev/latest/reference/cli/
- Machine config reference: https://www.talos.dev/latest/reference/configuration/

## Targeting

- `-e/--endpoints` is the node talosctl connects through, a control-plane node or LB, which proxies the request. `-n/--nodes` is where the command executes, resolved as the endpoint sees it, not from your client.
- With `--nodes` omitted the command targets the endpoint itself, so a destructive op can land on a control-plane node. On a 3-node control plane, taking 2 members down at once kills etcd quorum, and recovery then needs a snapshot restore.
- Always name the exact target nodes and confirm none is a control-plane member before proposing a destructive command.

## Command safety

- Destructive commands (reset, upgrade, bootstrap, reboot, etcd membership changes) are hard-denied in settings.json. Surface them for the user to run, never attempt them.
- `apply-config`, `patch`, `edit`, and `rollback` are not denied by settings.json but are state-changing. Run them only with `--dry-run` to preview.
- On the apply you hand over, recommend `--mode=try` over `--mode=reboot`, it auto-reverts after `--timeout` (default 1m) unless a confirming config is applied.

## Machine config and secrets

- Patches carry `${VAR}` placeholders, real values come from a vault such as GCP Secret Manager at apply time.
- Inject with `envsubst` into a base from `talosctl gen config --with-secrets`, merge with `talosctl machineconfig patch`, then wipe the materialized config immediately. The secrets bundle is full cluster-takeover material, so prefer in-memory over touching disk.

## Before reporting

- Confirm every proposed command names `--nodes` explicitly.
- Confirm no target node is a control-plane member, or that the user was told it is.
- Confirm no committed config holds a real secret in place of a `${VAR}` placeholder.
