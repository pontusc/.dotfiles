---
name: python
description: Python project conventions, applied when writing or editing Python projects (pyproject.toml, src/, tests/) or .py files.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python Project Conventions

## Tooling

- **uv** manages dependencies, the `uv.lock` lockfile, and the venv, over `poetry` or `pip-tools`. `uv sync` provisions the env.
- **ty** is the type checker and LSP. **ruff** is both linter (`ruff check`) and formatter (`ruff format`).
- Where a preferred tool is absent from the project, fall back to this structure with whatever it has rather than blocking on the toolchain.

## Layout

- src layout: importable packages under `src/`, tests under `tests/` outside the package.
- `tests/` mirrors intent: `unit/`, `integration/`, `fixtures/`.
- Cross-cutting models and constants live in a dedicated leaf package that imports nothing else from the project.

## pyproject.toml

- Build backend `uv_build`, bounded to the uv minor in use: `requires = ["uv_build>=0.12.5,<0.13"]`, `build-backend = "uv_build"`. Hatchling only for extension modules, build scripts, or a layout `uv_build` cannot express.
- `requires-python` bounded on both ends, capped to a single minor (`>=3.12,<3.13`), for applications only. Libraries leave the upper bound open.
- Dev tools live in `[dependency-groups] dev`, not runtime dependencies.
- pytest: `testpaths = ["tests"]`, `pythonpath = ["src"]`, and `asyncio_mode = "auto"` for async.
- Omit ruff `target-version`, inferred from `requires-python`, and `src`, already `[".", "src"]`. A src layout needs no `ty` environment root.

## Testing

- `pytest`. Start with a smoke test covering package import, app build, and key seams before deep tests.
- Exercise CLIs in-process through a test runner, never via subprocess.
- `conftest.py` holds fixtures only. Shared helpers and constants go in a small `_helpers` module, never pinned inside one test module.

## Before reporting

- All four pass: `ruff check src tests`, `ruff format --check src tests`, `ty check src tests`, `pytest`.
- No `pyproject.toml` key you added restates a tool default.
- `grep -rnE 'type: ignore|noqa' src tests` shows no suppression you added.
