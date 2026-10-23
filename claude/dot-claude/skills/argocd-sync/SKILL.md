---
name: argocd-sync
description: Refresh, sync and verify ArgoCD apps after the operator says a PR is merged.
disable-model-invocation: true
argument-hint: <app|all>
---

# ArgoCD sync

Typing `/argocd-sync` approves refresh and sync of the named apps, once. `all` means every app from `argocd app list --repo <url>` of a merged PR's repo whose path is a directory prefix of a file the PR changed, the PRs named by the operator or found with `gh pr list --state merged --search <KEY>`. An app with an empty or `.` path never matches. List the resolved apps and confirm through AskUserQuestion before any sync. `app diff` exit 2 is an error, not a diff.

Every argocd call passes `--argocd-context <server>`, the server name as `argocd context` lists it. The operator names it, or `argocd context` lists exactly one. Otherwise ask. Never `argocd context <name>`, it switches every other terminal. App names are as `argocd app list -o name` prints them.

An auth error stops the run. The operator logs in with `argologin <server>`.

## Per app

1. `argocd --argocd-context <server> app get <app> --refresh`.
2. `argocd --argocd-context <server> app sync <app> --timeout <seconds>`, then `argocd --argocd-context <server> app wait <app> --sync --health --timeout <seconds>`, together as one background command.
3. `argocd --argocd-context <server> app diff <app>`. Exit 0 is an empty diff, exit 1 is a diff.

A non-empty diff after sync is reported with its output, never fixed.

## Reply

Per app, each step with its command and output as evidence: sync revision, sync and health status, and the diff result.
