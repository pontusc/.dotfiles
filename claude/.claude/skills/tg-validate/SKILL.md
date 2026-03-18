---
name: tg-validate
description: Validate Terragrunt/Terraform modules — runs terragrunt validate, terraform fmt -check, and checks for common IaC issues in the current or specified directory.
user-invocable: true
model-invocable: true
allowed-tools: Read, Glob, Grep, Bash
agent: infra
model: sonnet
---

# Terragrunt/Terraform Validation

Validate a Terragrunt module or Terraform directory. Accept an optional path argument; default to the current working directory.

## Process

### 1. Locate the module

- If a path argument is given, use it. Otherwise use `$PWD`.
- Confirm the directory contains `terragrunt.hcl` (Terragrunt module) or `*.tf` files (plain Terraform).
- If neither exists, report "no TF/TG module found" and stop.

### 2. Format check (non-destructive)

Run `terraform fmt -check -diff -recursive` on the directory.

- If it reports diffs, list the files that need formatting.
- Do NOT auto-format — just report.

### 3. Validate

For Terragrunt modules (`terragrunt.hcl` present):

```bash
terragrunt validate --terragrunt-working-dir <path>
```

For plain Terraform directories:

```bash
terraform -chdir=<path> validate
```

Report any validation errors verbatim.

### 4. Static checks

Grep the module for common issues:

- **Missing `prevent_destroy`** on stateful resources (`google_storage_bucket`, `google_sql_database_instance`, `google_container_cluster`, `aws_s3_bucket`, `aws_rds_instance`, `aws_dynamodb_table`)
- **Hardcoded project/region** — look for string literals that should be variables (e.g., `project = "my-project"` instead of `project = var.project`)
- **Missing description on variables** — variables without `description` field
- **Wide-open IAM bindings** — `roles/owner`, `roles/editor`, `allUsers`, `allAuthenticatedUsers`

### 5. Report

Provide a concise summary:

```
Module: <path>
Format:  OK | <N files need formatting>
Validate: OK | FAILED
Issues:   <list or "none found">
```

Only list actual findings. Skip sections with no issues.
