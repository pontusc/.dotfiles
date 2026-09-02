---
name: terraform
description: Terraform and Terragrunt conventions, applied when writing or editing .tf, .tfvars, .hcl, and terragrunt.hcl files.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
---

# Terraform and Terragrunt Conventions

## Module layout

- `main.tf` for resources, `variables.tf` for inputs, `outputs.tf` for outputs, `locals.tf` for locals, `data.tf` once there are more than two data sources, otherwise inline them in `main.tf`.

## Variables and resources

- Every variable carries a `description` and a specific `type` (`string`, `number`, `list(string)`), never `any`. Add a `validation` block for input constraints such as naming patterns.
- `lifecycle { prevent_destroy = true }` on stateful resources: databases, storage buckets, clusters.
- `for_each` keyed by a stable map or set by default, so adding or removing one element does not reindex the rest. `count` only for an on/off toggle (`count = var.enabled ? 1 : 0`).

## Terragrunt

- `include` blocks inherit common config, `dependency` blocks reference another module's outputs. Inputs stay flat and explicit.
- Generate the provider block, with a pinned provider version, in a `generate` block rather than a per-module `versions.tf`.
- To attach a resource to a called module, a firewall for a GKE cluster module, define a new `firewall.tf` in the calling directory. Terragrunt copies every file there, so the module itself stays untouched.

## Addressing and destruction

- Additive by default. Removing a managed resource triggers a destroy, so never remove one unless instructed.
- Converting `count` to `for_each`, renaming a resource, or moving it between modules ships a `moved {}` block in the same change. Without it Terraform destroys and recreates.
- `prevent_destroy` is evaluated at plan time and cannot be bypassed programmatically. A change that requires destroying such a resource stops and gets flagged, never a removed lifecycle block.
- Check both sides of coupled resources before editing, a DNS record pointing at an external IP or a firewall rule scoped to a target tag, and flag the dependency.
- Do not suggest `apply -target=...` outside genuine recovery from broken state.

## Plan verification

- For a change touching stateful resources (databases, clusters, buckets, load balancers, DNS) or resource addressing, state the expected plan impact as counts of create, update, destroy, and replace before editing.
- After editing, delegate to the `validator` agent with the sequence `fmt -check`, `validate`, `plan` plus the stated change intent. Use `terragrunt` in a Terragrunt module, `terraform` otherwise. The task is not done until that plan is reviewed.
- On an unintended destroy or replace, a `prevent_destroy` conflict, or out-of-scope drift, stop and wait for the user.

## Before reporting

- Name every resource the plan would destroy or replace, or state that there are none.
- Every addressing change has a matching `moved {}` block.
- Every new variable has both `description` and `type`.
