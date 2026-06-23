---
name: terraform
description: Terraform/Terragrunt conventions — applied when writing or editing .tf, .hcl, and terragrunt.hcl files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# Terraform / Terragrunt Conventions

Conventions for new files and the lines you're changing — on existing files stay surgical and suggest divergences rather than migrating.

## File Structure

Standard module layout:

- `main.tf` — primary resources
- `variables.tf` — all input variables
- `outputs.tf` — all outputs
- `locals.tf` — local values (if needed, keep minimal)
- `data.tf` — data sources (if more than 1-2, otherwise inline in `main.tf`)

## Variables

- **Every variable MUST have a `description`**.
- Use `type` constraints — prefer specific types (`string`, `number`, `list(string)`) over `any`.
- Use `validation` blocks for input constraints (e.g., regex for naming patterns).
- **No hardcoded values**: Projects, regions, zones, account IDs must be variables or locals derived from variables.
- Defaults should be sensible for the most common use case.

## Resources

- **Naming**: Use `snake_case`. Resource names should describe purpose, not repeat the resource type (e.g., `google_storage_bucket.artifacts`, not `google_storage_bucket.google_storage_bucket_artifacts`).
- **`prevent_destroy`**: Add `lifecycle { prevent_destroy = true }` on stateful resources (databases, storage buckets, clusters).
- **`for_each` over `count`**: default to `for_each` (keyed by a stable map/set) so adding/removing one element doesn't reindex the rest; use `count` only for a simple on/off toggle (`count = var.enabled ? 1 : 0`).

## Security

- **No wide IAM bindings**: Never use `roles/owner`, `roles/editor`, `allUsers`, or `allAuthenticatedUsers` unless explicitly justified.
- **Least privilege**: Prefer granular roles over broad ones.
- **No secrets in state**: Use `sensitive = true` on outputs containing secrets. Reference secrets from a secret manager, never inline.

## Terragrunt

- Keep `terragrunt.hcl` DRY — use `include` blocks to inherit common config.
- Use `dependency` blocks to reference outputs from other modules.
- Generate the provider block — with a pinned provider version — via a terragrunt `generate` block, rather than a per-module `versions.tf`.
- Inputs should be flat and explicit — avoid deep nesting.
- When calling a module and resources have to be added (e.g. a firewall to a GKE Cluster module), don't edit the module itself. Utilize the fact that terragrunt just copies all files to a folder and define a new firewall.tf file in the calling directory instead to extend the module.

## State Changes

- **Additive by default**: Never remove existing resources unless explicitly instructed. Removing a managed resource triggers a destroy. New resources go alongside existing ones.
- **Addressing changes**: When converting `count` → `for_each`, renaming a resource, or moving it between modules, ALWAYS emit a `moved {}` block in the same change. Without it, Terraform destroys and recreates.
- **Stateful + `prevent_destroy`**: `prevent_destroy` is evaluated at plan time and cannot be programmatically bypassed. If a change requires destruction of a `prevent_destroy` resource, stop and flag it — don't propose removing the lifecycle block as a workaround.
- **Coupled resources**: When a resource's existence depends on another (e.g., a DNS record pointing to an external IP, a firewall rule scoped to a target tag), check both sides before proposing an edit. Flag the dependency explicitly.
- **`-target` flag**: Don't suggest `terraform apply -target=...` except for genuine recovery from broken state. It bypasses the dependency graph and is a smell, not a workflow.

## State

- Remote state only — never commit `.tfstate` files.
- State bucket must have versioning enabled.

## Plan Verification

For changes that touch stateful resources (databases, clusters, buckets, load balancers, DNS) or alter resource addressing:

**Before editing:**

- Summarize the expected plan impact: how many resources create / update / destroy / replace.
- If unsure, propose running `terragrunt plan` (or `terraform plan`) first and ask the user to confirm the diff matches intent.
- Never propose an edit that would silently destroy a `prevent_destroy` resource — surface the conflict and stop.

**After editing — required:**

- The task is not done until plan has been run and reviewed.
- Delegate to the `validator` agent (Agent tool, `subagent_type: "validator"`). Hand it the sequence `fmt -check` → `validate` → `plan` — run via `terragrunt` in a Terragrunt module (it wraps Terraform), or `terraform` directly otherwise — plus the stated change intent so it can flag mismatches.
- Report the validator's structured verdict to the user. If it flags an issue (unintended destroy/replace, `prevent_destroy` conflict, out-of-scope drift), stop and wait for user input.
