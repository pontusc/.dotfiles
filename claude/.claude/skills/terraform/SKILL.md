---
name: terraform
description: Terraform/Terragrunt conventions — applied when writing or editing .tf, .hcl, and terragrunt.hcl files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# Terraform / Terragrunt Conventions

Apply these conventions when writing or editing `*.tf`, `*.hcl`, or `terragrunt.hcl` files.

## File Structure

Standard module layout:

- `main.tf` — primary resources
- `variables.tf` — all input variables
- `outputs.tf` — all outputs
- `versions.tf` — `terraform {}` block with required providers and version constraints
- `locals.tf` — local values (if needed, keep minimal)
- `data.tf` — data sources (if more than 1-2, otherwise inline in `main.tf`)

## Variables

- **Every variable MUST have a `description`**.
- Use `type` constraints — prefer specific types (`string`, `number`, `list(string)`) over `any`.
- Use `validation` blocks for input constraints (e.g., regex for naming patterns).
- **No hardcoded values**: Projects, regions, zones, account IDs must be variables or locals derived from variables.
- Defaults should be sensible for the most common use case, or omitted to force the caller to provide a value.

## Resources

- **Naming**: Use `snake_case`. Resource names should describe purpose, not repeat the resource type (e.g., `google_storage_bucket.artifacts`, not `google_storage_bucket.google_storage_bucket_artifacts`).
- **`prevent_destroy`**: Add `lifecycle { prevent_destroy = true }` on stateful resources (databases, storage buckets, clusters).
- **Tags/Labels**: All resources must have labels/tags. At minimum: `managed-by = "terraform"`, plus project/environment labels.

## Security

- **No wide IAM bindings**: Never use `roles/owner`, `roles/editor`, `allUsers`, or `allAuthenticatedUsers` unless explicitly justified.
- **Least privilege**: Prefer granular roles over broad ones.
- **No secrets in state**: Use `sensitive = true` on outputs containing secrets. Reference secrets from a secret manager, never inline.

## Terragrunt

- Keep `terragrunt.hcl` DRY — use `include` blocks to inherit common config.
- Use `dependency` blocks to reference outputs from other modules.
- Inputs should be flat and explicit — avoid deep nesting.

## State

- Remote state only — never commit `.tfstate` files.
- State bucket must have versioning enabled.
- Use state locking.
