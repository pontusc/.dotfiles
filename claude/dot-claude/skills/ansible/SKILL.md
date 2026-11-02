---
name: ansible
description: Ansible conventions for layout, environments, variables, playbooks, roles and secrets, applied when writing or editing playbooks, roles, inventories, group_vars, host_vars and ansible.cfg.
user-invocable: false
---

# Ansible Conventions

## Layout

- One Ansible root per repo holding the config, the inventories, the playbooks and the roles. Never a second config file elsewhere pointing back with relative paths.
- Never `group_vars` or `host_vars` next to a playbook, they outrank the inventory's and split a host's variables across two places.

## Environments

- One inventory directory per environment, each with its own hosts, group_vars and host_vars.
- The config sets no default inventory and every run passes exactly one, so a bare run has no hosts and one run never spans two environments.
- Groups inside an environment describe capability or function, never the environment itself.
- A value that is the same in every environment is a role default, not a shared inventory layer.

## Variables

- Each layer owns one kind of value:
  - Role defaults: every tunable the role exposes, with a working value.
  - Role vars: constants internal to the role, never meant to be overridden.
  - group_vars: values that differ by environment or capability.
  - host_vars: values unique to one host.
- Playbooks set no variables. Extra vars on the command line only for an ops one-off.
- Versions of images, binaries and packages are pinned in role defaults, one variable per version.

## Secrets

- Ansible never delivers a secret. The host retrieves its own secrets from the secret store using its own identity, and Ansible only configures that access: the identity, the permission scope, the fetch mechanism.
- A host without a platform-provided identity gets a short-lived federated one, never a long-lived key placed on disk.

## Playbooks

- A playbook selects hosts and sets play keywords (become, serial), then lists roles. No inline tasks. Logic that has no role yet gets one.
- Each role in a playbook is tagged with its own name so one component can be converged alone. No tags inside roles, a partial run skips the untagged tasks later tasks rely on.
- Converge playbooks describe desired state and are safe to rerun at any time. A top level playbook imports all of them.
- One-off operations (upgrade, backup, restore, reboot) live in separate ops playbooks and never run as part of converge.
- Ops playbooks take their target from a required variable with no default, so a run without one fails instead of hitting every host. They run with `serial: 1`, which stops the play at the first failed host.

## Roles

- One role per component or capability. The playbook composes roles into what a host is. No profile roles that only bundle others, no role dependencies in role metadata.
- Every input is declared in `meta/argument_specs.yml`. Required inputs without a sane default are `required: true`, a fixed set of values uses `choices`.
- A role that supports variants declares the variant in its argument spec, then loads a vars file and a task file named after it. Values that differ per variant live in those vars files, never in conditionals spread across defaults, tasks and handlers.

## Blocks

- A block is for error handling (rescue, always) or for several consecutive tasks sharing a keyword (when, become, vars).
- Never nest more than two levels. A deeper or reusable group becomes its own task file.
- A task file is pulled in with `import_tasks`, so a keyword on the import reaches every task. `include_tasks` only when the file name is a variable, with shared keywords under `apply`.
- A rescue that recovers state (restarts a stopped service) ends by failing with `ansible_failed_result`, so the run never reports success.

## Files on the host

- A role owns whole files. Template when the file has variables, copy when it is static.
- Prefer a drop-in directory or override file over editing a file a package ships.
- In-place line or block edits are the last resort, with a comment naming the runtime property that rules out owning the file, such as the package rewriting it on upgrade.

## Idempotency and check mode

- Every converge playbook passes a check run with diff without errors, and a second real run reports zero changes.
- A task that only reads state sets `check_mode: false` and `changed_when: false`.
- In a converge role, handlers restart services on config changes. A task never restarts unconditionally.

## Running

- Playbooks run through a wrapper that requires the environment with no default and installs pinned collections. It exposes generic converge, check and ops entry points, never one target per playbook.
- Lint at the strictest profile in CI. No suppressions, fix what the linter flags.

## Before reporting

- No playbook holds tasks or vars.
- Every new tunable has a role default, every new input an argument spec entry.
- Nothing in the change places a secret on a host.
