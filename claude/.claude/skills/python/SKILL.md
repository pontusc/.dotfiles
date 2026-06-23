---
name: python
description: Python project conventions — applied when writing or editing Python projects (pyproject.toml, src/, tests/) or .py files.
user-invocable: false
model-invocable: true
allowed-tools: Read, Glob, Grep
---

# Python Project Conventions

Apply when writing or editing Python projects — `pyproject.toml`, `src/`, `tests/`, or `.py` files.

## Scope of changes (read first)

These are conventions for **new** projects and for the code you are **already changing**.
When editing an existing project:

- **Stay surgical.** Match the project's existing tooling, layout, and style. A fix applies to
  the lines you're changing — don't restructure the project or swap its toolchain to match this
  skill.
- **Suggest, don't migrate.** If the project diverges (pip/poetry, flat layout, floating
  versions), note it as a suggestion — don't fold an unrequested migration into the edit.
  Migrate only when the user explicitly asks.
- **Use the structure below for greenfield projects, or where no convention is established.**

## Tooling

- **uv** manages dependencies, the lockfile (`uv.lock`), and the venv. Prefer it over `poetry` / `pip-tools`.
- **ty** is the type checker (+ LSP); **ruff** is both the linter (`ruff check`) and the
  formatter (`ruff format`).
- `uv sync` provisions the env from `uv.lock`, so local and CI run identical tool versions (see Quality gate).
- **If a preferred tool isn't available in the project**, fall back to this structure with
  whatever it has — don't block on the exact toolchain.

## Dependencies & pinning

- **Pin every direct dependency to an exact version** (`==`); `uv.lock` pins transitives.
  Nothing floats (`>=` / `~=` / `@latest`) — bumps are deliberate.
- **Bound `requires-python` on both ends** (cap to a single minor, e.g. `>=3.12,<3.13`) so the local resolve matches
  CI and the image — applications only; libraries shouldn't cap the upper bound. Patches float;
  crossing a minor is deliberate.
- Dev tools go in `[dependency-groups] dev`, not runtime dependencies.

## Project layout

- **src layout**: importable packages under `src/`, tests under `tests/` (outside the package).
- Shared models/contracts imported by both a service and its client live in their own leaf
  package so the two can't drift.
- `tests/` mirrors intent (`unit/`, `integration/`, `fixtures/`).

## pyproject.toml

- **Build**: hatchling; map each `src/<pkg>` to its import name under
  `[tool.hatch.build.targets.wheel]`.
- **Entry points**: `[project.scripts]` point at a `module:function` callable.
- **ruff**: set `src = ["src", "tests"]` and `[tool.ruff.lint] select`. Omit `target-version`
  — ruff infers it from `requires-python`.
- **pytest**: `testpaths = ["tests"]`, `pythonpath = ["src"]`, `asyncio_mode = "auto"` for async.
- **ty**: point its environment root at `./src` (the src-layout import root).

## Code style

- **Keep it stupid simple**: the most direct implementation that works. No clever tricks or
  premature abstraction.
- **Strong modularization.** One module/class does one job and owns it behind a clear
  boundary — narrow public surface, internals kept private. Well-bounded concerns let multiple
  people/agents work their piece in parallel without colliding.
- **Names say exactly what the thing does.** Comments explain **why**, not what.
- **Strongly typed.** Annotate every function signature (params + return) and class attribute;
  let ty infer locals — don't annotate the obvious. Avoid `Any` / bare `object`; `ty check`
  passes clean — earned, not silenced.
- **Type the seams precisely**: `Protocol` for structural (duck-typed) interfaces, `ABC` for
  nominal base classes; a typed sentinel over `str | object`.
- **Fix the cause a warning names, never silence the symptom.** A linter or type-checker
  flag is evidence of a real defect; understand *why* the tool fires before you act. Inline
  ignore/disable comments, blanket `except`, config loosening, or scaffolding added only to
  quiet a tool are not fixes — an unjustifiable suppression is itself a defect.
- **Every construct must have a purpose you can state plainly.** No symbol, parameter,
  constant, or abstraction exists merely to satisfy a tool or carried along out of habit. If
  you can't articulate what a thing is for, that's the signal to delete or refactor it — not
  to keep it.

## Testing

- `pytest`. Start with a smoke test (packages import, app builds, key seams behave) before
  deep tests.
- Exercise CLIs in-process (via a test runner), not via subprocess.

## Quality gate

Run the same four locally and in CI — all must pass:

```
ruff check src tests
ruff format --check src tests
ty check src tests
pytest
```
