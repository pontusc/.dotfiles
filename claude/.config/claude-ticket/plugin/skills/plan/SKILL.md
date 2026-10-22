---
name: plan
description: Plan the work in spec.md as plan.md plus one phase-N.md per detailed phase, detailing only the next phase to work on. The operator starts the plan with /ticket:plan once the spec is reviewed, work invokes it for every later phase.
---

Without `plan.md`, run only when the user typed `/ticket:plan`, that is the sign the spec is reviewed. Invoked any other way, stop and say so.

Read `spec.md`, `spec-context.md`, `research.md` and the dated research files it points to. Write `plan.md` beside them, and `phase-N.md` for the phase being detailed.

`plan.md` is the index and stays short. Every phase has a goal, what it should accomplish on its own, stated in a few lines, and a few notes about what happens there, based on the phases before it. A finished phase also carries its outcome in one line. The full detail of a phase, its tasks, test, exit criteria and full outcome, lives in `phase-N.md` and is written only for the next phase to work on.

A phase is detailed only after the previous one is done and its outcome is recorded in its phase file and `plan.md`. When `plan.md` exists, read it and the newest `phase-N.md`. Record the outcome of the finished phase if it is missing, then write the next phase file, revising the later goals when the outcome changed them. The newest phase file's outcome must carry everything the next phase needs, so an earlier phase file is read only when that outcome points at it. Ask before rewriting a phase file that already exists.

Both files are written once and then changed line by line with Edit. Every placeholder line stays in place so a change is an edit of that line. A revised goal or note is an edit of its own lines, never a rewrite of the file.

Before the first phase file of a design that spans several files, workflows or modules, list the structure choices it makes, such as file split, workflow count and triggers, job and module boundaries, naming, each with a stated default, in one AskUserQuestion, and ask which the operator decides. The answers and the remaining defaults go under Shape in the phase file. A later phase reuses them and asks again only for a choice that is new.

Use exactly this structure. Text in angle brackets describes what goes there.

`plan.md`:

```markdown
# <KEY> plan

## Phase 1: <the end state of this phase in a few words>

### Goal

<What this phase accomplishes on its own, a few lines. Why it comes first when that is not obvious.>

### Notes

- <A few points on what happens here, based on the phases before.>

### Outcome

None yet.
```

The Outcome stays `None yet.` until the phase verdict is VERIFIED. Then it holds one line pointing at the phase file. The phase file's Outcome holds what was done, what differed from the plan and why, and what the next phase must know.

`phase-1.md`:

```markdown
# <KEY> phase 1: <the same heading as in plan.md>

### Shape

- Budget: <the platform form in a few lines of yq, jq or gh, the expected file and line count, and the reason if it must be larger.>
- <One structure choice per line, the option taken, and operator or default.>

### Tasks

- [ ] <One unit of work per box. The code, config or command shape it needs sits inline under the box, trimmed to what the implementer would otherwise guess.>
  - [ ] <A nested box is a sub-step of the box above it.>
- [ ] Operator: <a task the operator must run themselves, and why.>
- [ ] <A task that must wait for another because both touch the same state, root module or lockfile.> Waits for: <the task it waits for>.

### Test

<Where this phase gets exercised: the environment, PR or deployment used to try it, and how it is exercised there.>

### Exit criteria

#### Automated

- [ ] <A command an agent runs, with the expected result.>

#### Manual

- [ ] <A check only the operator can make, and how.>

### Review gate

<What the operator reviews before the next phase starts. Or None, and why no operator review is needed.>

### Verdict

None yet.

### Outcome

None yet.

### Rulings
```

A box is checked only with its evidence on the same line, appended after the text as ` Evidence: <file path, commit SHA, or command and its result>.` A box without evidence stays unchecked. A box checked for the operator's word cites it, ` Evidence: operator confirmed.`

Tasks never commit or push. A phase leaves its changes uncommitted for the operator to review, and a commit comes only from the operator or from their explicit approval.

The phase being worked on has Goal, Notes and Outcome in `plan.md` and its own phase file. Every later phase has Goal, Notes and an Outcome of `None yet.`, and gains its phase file when its turn comes.

Before presenting a phase file, a reviewer checks it against `spec.md`, `spec-context.md` and its own Shape. A task list several times the budget, a task that settles a structure choice Shape does not name, or a phase file over 400 lines, is a finding. Fix its findings first.

When the operator invoked it, the reply ends with this line: Next step: the operator runs `/ticket:work`. Nothing runs until then.
