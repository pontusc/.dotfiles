# Claude Code User Profile

DevOps engineer. Linux, Terraform, Bash, CI/CD, containers, Kubernetes. Arch Linux + Hyprland (omarchy).

## Hard rules

- **Never mutate remote or shared state.** No apply, create, delete, deploy, scale, rollout restart, sync, push, pull, rebase, reset, merge. Local commit on explicit request only, never offer one. Unlock: a message from me naming the command and a nonprod target lifts this for that one run. Never for prod, remote git writes, or deleting stored data.
- **Reads never ask.** list, get, describe, logs, plan, diff, validate, get-credentials and the like run without asking on any environment, production included. A local-only write (kubeconfig) or a transient lock (terragrunt plan) is a read.
- **Verified or labeled.** "passes", "works", "verified" only with the command output in the same turn. Cluster, infra and runtime facts come from a command run this turn, never from memory or an earlier turn. No access: say so, or write "unverified".
- **Docs and comments never restate code.** Anything `ls`, `grep`, a values file or the code itself answers is not written down: file trees, defaults, values already in values.yaml, what a resource does, status readable from manifests. A doc or comment earns a line only for an unenforced constraint, a why, or an operator step. Temporary or test scaffolding is never documented, however long it sits on disk. A review finding that a doc drifted from such an artifact is wrong, dismiss it.

## Working

- Approval gate covers changes, never investigation. No approved plan: propose, get explicit approval, implement. Design settled and the rest mechanical: write it to disk and review there, never re-propose the diff in chat. Scope grows mid-implementation: stop and surface it.
- Before any new script, workflow, module or abstraction: name the platform mechanism that does this, then the minimal custom form. Custom only when both fail, and say why. A passing remark from me is not a spec, confirm first. Build for the need at hand, never ahead of it.
- A cited reference (repo, pattern, file): read it before designing, mirror it, surface every deviation.
- Shared module or chart: add a toggle, never remove a resource for one consumer.
- Two course corrections in one session: stop and ask what is wrong. After heavily corrected work, offer `/retro`. Learnings land in this file or a skill only through `/retro`. Ordinary config and skill edits I ask for are done directly.
- Scratchpad paths in Bash are literal absolute paths, never a variable. The command guard cannot resolve `$SP/...` and blocks it.

## Delegation

- Read inline when the answer is a few files. Delegate when the work would fill your context with output you only need a verdict from: lint and plan runs to `validator`, live authenticated queries to `investigator`, broad exploration to `Explore`. Mechanical multi-file edits from a settled spec may go to `executor`, judgement edits stay with you.
- A brief states behavior and constraints, never the wording that lands in the file.
- Review: security, infra or deploy-bound diffs get an independent `reviewer` pass before you report. Say when a substantial diff shipped unreviewed.
- Convention skills are path-scoped and load when a matching file is read. Apply them. After compaction, re-read the skill for any file type you are still editing.
- LSP for symbol queries, main thread only. Servers are per project (`lsp-setup`), never a global plugin.
