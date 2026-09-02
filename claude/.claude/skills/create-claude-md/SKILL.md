---
name: create-claude-md
description: Generate or edit a project's CLAUDE.md memory file. Use whenever asked to create, write, edit, update, or generate a CLAUDE.md for any project.
---

# Create CLAUDE.md

Output is concise, navigational, and general-purpose, useful across sessions without going stale.

## Discovery Phase

Gather project context before writing. Run these in parallel where possible:

1. **Project identity**: README.md, package.json, Cargo.toml, pyproject.toml, go.mod, or equivalent
2. **Directory structure**: `find . -maxdepth 2 -type d` (meta-structure, not full tree)
3. **Build/test/lint**: Makefile, justfile, package.json scripts, CI configs (.github/workflows/, .gitlab-ci.yml)
4. **Existing conventions**: .editorconfig, .prettierrc, eslint configs, rustfmt.toml, .clang-format
5. **Existing CLAUDE.md**: read if present, preserve user customizations
6. **Git context**: `git log --oneline -10` for recent activity patterns
7. **Dependency management**: lock files, .tool-versions, mise.toml, .nvmrc, rust-toolchain.toml

## Output Structure

Follow this section order. Omit sections that don't apply. Every section is 2 to 8 lines.

### 1. Project Overview

One paragraph: what this project is, what problem it solves, who it serves. No marketing language.

### 2. Architecture

The **meta-structure**, not individual files:

- "src/ contains application code organized by domain (auth/, billing/, api/)"
- "Infrastructure lives in infra/ as Terraform modules, one per service"
- NOT a full directory listing

State the key boundaries: what talks to what, where the entry points are, how data flows if non-obvious.

### 3. Tech Stack

Language, framework, and major dependencies. For versions:

- **DO**: "Node version is pinned in .nvmrc"
- **DO**: "Terraform version defined in .terraform-version"
- **DON'T**: "Uses Node 20.11.1" (goes stale)

### 4. Development Workflow

Commands to build, test, lint, format, and run locally, each pointing at the source of truth:

- "Build commands are in the Makefile"
- "CI pipeline defined in .github/workflows/ci.yml"
- "Test runner config in jest.config.ts"

Only commands a developer runs frequently. Not setup guides.

### 5. Conventions & Patterns

Project-specific patterns Claude should follow:

- Naming conventions (file naming, function naming, branch naming)
- Error handling patterns
- Import ordering rules
- Testing patterns (unit vs integration, fixture locations)
- Code organization rules

Only patterns that are non-obvious or project-specific. Skip universal best practices.

### 6. Key Files & Entry Points

Files that matter for navigation, relative paths, brief annotation each:

- Main entry point(s)
- Configuration files that control behavior
- Where environment variables are defined or documented
- Where types, interfaces, and schemas live

### 7. Gotchas & Context

Things that would surprise or trip up Claude or a new developer:

- Non-obvious dependencies between components
- Legacy patterns that differ from the rest of the codebase
- Environment-specific behavior
- Known limitations or technical debt areas

## Writing Rules

- **Pointers over content**: reference where information lives, don't duplicate it
- **No version pinning**: say where versions are defined, not what they are
- **No full file trees**: describe structure patterns, not every file
- **Dense formatting**: bold, short bullets, tables where they compress information
- **Imperative tone**: "Run `make test`" not "You can run `make test`"
- **Under 200 lines**: if exceeding, split into supplementary docs and reference them
- **Present tense**: "The API validates input at the controller layer"
- **No hedging**: state facts. If uncertain, investigate first or omit.

## Edit Mode

1. Read the entire file first
2. Preserve user customizations and sections not covered by this template
3. Merge new discoveries with existing content, don't overwrite wholesale
4. Flag sections that appear stale: "This section may need updating: [reason]"
5. Maintain the existing file's style if it differs from this template

## Validation

Before presenting the CLAUDE.md to the user:

- [ ] Every section gives reasoning or guidance, not just a bare fact
- [ ] No hardcoded versions (only pointers to where versions live)
- [ ] No full directory listings (only meta-structure descriptions)
- [ ] Under 200 lines
- [ ] All referenced files actually exist in the project
- [ ] Commands listed are accurate (verify by checking Makefile/package.json/CI)
