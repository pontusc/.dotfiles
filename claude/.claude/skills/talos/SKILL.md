---
name: talos
description: "Talos Linux cluster operations, command-targeting safety and machine-config conventions. Applied when proposing or running talosctl commands, or editing Talos machine config YAML (controlplane.yaml, worker.yaml, talconfig.yaml, or any YAML with top-level `version: v1alpha1` / `kind: MachineConfig` / `machine:` / `cluster:`)."
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Talos Linux: Safety & Conventions

talosctl has no confirmation prompts, and several operations can destroy etcd quorum or wipe
node state. The destructive commands are hard-denied in settings.json. This skill covers the
judgment those denies can't: *which node you target* and *how config and secrets are
handled*. Verify flags against the live docs:

- CLI reference: https://www.talos.dev/latest/reference/cli/
- Machine config reference: https://www.talos.dev/latest/reference/configuration/
- Getting started: https://www.talos.dev/latest/introduction/getting-started/

## Targeting: the foot-gun

- `-e/--endpoints` is the node talosctl *connects through* (a control-plane node or LB): it
  proxies the request. `-n/--nodes` is where the command actually *executes*.
- Node addresses resolve **as seen by the endpoint**, not from your client.
- With `--nodes` omitted, the command targets the endpoint itself, so a destructive op with
  no `--nodes` can land on a control-plane node. On a 3-node control plane, taking 2 members
  down at once kills etcd quorum, and recovery then needs a snapshot restore.
- **Always name the exact target node(s) and confirm they aren't control-plane members
  before proposing a destructive command.**

## Command safety

- Destructive commands (reset, upgrade, bootstrap, reboot, etcd membership changes, …) are
  hard-denied in settings.json: surface them for the user to run. Don't try to execute them.
- Config-mutating commands (`apply-config`, `patch`, `edit`, `rollback`) are **not** denied
  by settings.json, but treat them as state-changing: **NEVER run the mutating form
  yourself.** You may run them only with `--dry-run` to preview. Surface the real apply for
  the user to run (recommend `--mode=try`, which auto-reverts after `--timeout`, default 1m,
  unless a confirming config is applied, over `--mode=reboot`).

## Secret handling

- Keep secrets out of committed config: patches use `${VAR}` placeholders. Real values come
  from a vault (e.g. GCP Secret Manager) at apply time.
- Inject with `envsubst` into a base from `talosctl gen config --with-secrets`, merge via
  `talosctl machineconfig patch`, then wipe the materialized config immediately: the secrets
  bundle is full cluster-takeover material, so prefer in-memory over touching disk.
