---
name: context
description: Gather the context for work in a ticket workspace. Use on the first prompt describing what to build or change, or when the user mentions the ticket or Linear.
---

The Linear issue key is the name of the current directory. You read the issue, its comments and the prompt. Never read code or query a system yourself, agents answer everything else.

## Refresh, at the start

Before reading the issue, start one background Bash command running `git -C <checkout> fetch origin` for every git checkout directly under the work root, the parent of the tickets directory. Spell out each path, dcg blocks a git command built from a shell variable. Never pull or merge, agents read the origin refs. Never discard stderr.

A checkout's target is the output of `git symbolic-ref refs/remotes/origin/HEAD` in it, never an assumed `main`.

## Questions

Write neutral questions to `research.md`. A question names what to find, never the intent or the ticket. Tag each one:

- `code <repo>`: answered from that worktree.
- `code all`: identifiers the ticket depends on, searched across every checkout under the work root, including repos outside the ticket.
- `live <system>`: a GCP project, cluster or other running system. Identifiers the work depends on, such as project ids, groups, VPCs, namespaces, hostnames and ports, are always live questions.
- `upstream <chart or module>@<version>`: behaviour of a third party chart or module at the version the repos pin.

## Prior work

Before wave 1, invoke `ticket:recall` with the repos in the ticket and the nouns of the issue. Its hits go under `### Prior work` in `research.md`, one line per item that applies, prefixed with the ticket key and its closed date. A gotcha that bears on a question sharpens that question's brief.

## Wave 1

One message launches every agent. A brief holds the questions, the path or system to answer them from, and the demand for file:line references or command output. Never the ticket, the issue text or the intent.

- One Explore, very thorough, per worktree with `code` questions. Over about five questions, split them by topic across several agents.
- One Explore for `code all`, running `git grep` at each checkout's origin/HEAD target, after the fetch has finished.
- One investigator per live system, all of that system's questions in one brief.
- One Explore per upstream, reading the source at the pinned version from a temporary directory outside the ticket.

## Wave 2

Questions that wave 1 answers raise go out in one more message, once. A question still unanswered after it goes under Open, never a guess or a placeholder.

## research.md

```markdown
# <KEY> research

## <date>

| Repo | HEAD | Target | Target commit |
| --- | --- | --- | --- |

### <question> `<tag>`

<The agent's answer verbatim, with its references.>

### Open

- <Question no answer resolved.>
```

A rerun appends a new dated section with its own table. Earlier sections stay.

## Reply

From `research.md`, in this order: what the issue asks, what the user's prompt adds or changes, the current state per repo, constraints found, and the open questions. Facts only, no proposals, no next steps.
