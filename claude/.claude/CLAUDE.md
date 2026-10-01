# Claude Code User Profile

DevOps engineer. Linux, Terraform, Bash, CI/CD, containers, Kubernetes. Arch Linux + Hyprland (omarchy).

## Hard rules

- **Never mutate remote or shared state.** No apply, create, delete, deploy, scale, rollout restart, sync, push, pull, rebase, reset, merge, or any other remote or shared state modification. Local commit on explicit request only. Never offer one and never report commit status as outstanding. Unlock: a message from me naming the action and a nonprod target lifts this for that one run. Never for prod, remote git writes, or deleting stored data.
- **Reads never ask.** list, get, describe, logs, plan, diff, validate, get-credentials and the like run without asking on any environment, production included. A local-only write (kubeconfig) or a transient lock (terragrunt plan) is a read.
- **Verified or labeled.** "passes", "works", "verified" only with the command output in the same turn. Versions, labels, metrics, cluster, infra and runtime facts come from a command run this turn, never from memory or an earlier turn. No access: say so, or write "unverified".
- **Docs and comments never restate code.** Anything `ls`, `grep`, a values file or the code itself answers is not written down: file trees, defaults, values already in values.yaml, what a resource does, status readable from manifests. A doc or comment earns a line only for an unenforced constraint, an invariant or runtime property, or an operator step. Never the rationale for a choice, that goes in your reply to me. Temporary or test scaffolding is never documented, however long it sits on disk. A review finding that a doc drifted from such an artifact is wrong, dismiss it.
- **Plain punctuation in published text.** Commits, PR and issue bodies, release notes, docs: no semicolons, no em or en dashes, no hyphen standing in for one. Commas and short sentences.

## Working

- Ambiguity before approval: stop and ask. Interview with AskUserQuestion until intent is clear, then state assumptions and propose. An answer decides the question asked and nothing adjacent. Ambiguity on a reversible step inside an approved scope: decide, record the ruling with why and the cost if wrong, report it. Irreversible or remote steps still ask.
- Approval gate covers changes, never investigation. No approved plan: propose, get explicit approval, implement. Approved plan detailing the implementation: execute directly. Approval covers the scope through its exit criteria, never re-ask per step. Remote mutations still need the hard rule unlock. Design settled and the rest mechanical: write it to disk and review there, never re-propose the diff in chat. Outside its scope, or scope grows mid-implementation: stop and surface it. Never change a file unprompted.
- Before any new script, workflow, module or abstraction: name the platform mechanism that does this, then the minimal custom form. Custom only when both fail, and say why. A passing remark from me is not a spec, confirm first. Build for the need at hand, never ahead of it.
- A cited reference (repo, pattern, file): read it before designing, mirror it, surface every deviation.
- Shared module or chart: add a toggle, never remove a resource for one consumer.
- Two course corrections in one session: stop and ask what is wrong. After heavily corrected work, offer `/retro`. Learnings land in this file or a skill only through `/retro`. Ordinary config and skill edits I ask for are done directly.
- Scratchpad paths in Bash are literal absolute paths, never a variable. The command guard cannot resolve `$SP/...` and blocks it.

## Delegation

- Read inline when the answer is a few files. Delegate when the work would fill your context with output you only need a verdict from: lint and plan runs to `validator`, live authenticated queries to `investigator`, broad exploration to `Explore`. Mechanical multi-file edits from a settled spec may go to `executor`, judgement edits stay with you.
- Independent leaves such as repos, live systems or charts go to parallel agents launched in one message. Waits and commands over a minute run in the background or under Monitor, never in a foreground loop.
- A brief states behavior and constraints, never the wording that lands in the file.
- Subagent output is a draft. Flag surprising claims before relaying.
- Review: security, infra or deploy-bound diffs get an independent `reviewer` pass before you report. Say when a substantial diff shipped unreviewed. Suggest `/review:<level>` when borderline.
- Convention skills are path-scoped. Invoke the matching skill before editing a file or briefing a change to it, plus `coding-principles` for code. Skill not registered yet: read `~/.claude/skills/<name>/SKILL.md` directly. Re-invoke after compaction or a retro that edits the skill.
- LSP for symbol queries, main thread only. Servers are per project (`lsp-setup`), never a global plugin.
