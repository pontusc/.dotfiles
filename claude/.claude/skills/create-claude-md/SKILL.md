---
name: create-claude-md
description: This skill MUST be used whenever Claude is asked to create, write, edit, update, or generate a CLAUDE.md file for any project. Also invocable directly. Triggers on any request involving CLAUDE.md content generation or modification.
---

# Create CLAUDE.md

Generate or edit a CLAUDE.md file that gives Claude effective project context. The output must be concise, navigational, and general-purpose -- useful across sessions without going stale.

## Discovery Phase

Before writing anything, gather project context. Run these in parallel where possible:

1. **Project identity**: Read README.md, package.json, Cargo.toml, pyproject.toml, go.mod, or equivalent
2. **Directory structure**: `find . -maxdepth 2 -type d` (meta-structure, not full tree)
3. **Build/test/lint**: Read Makefile, justfile, package.json scripts, CI configs (.github/workflows/, .gitlab-ci.yml)
4. **Existing conventions**: Check for .editorconfig, .prettierrc, eslint configs, rustfmt.toml, .clang-format
5. **Existing CLAUDE.md**: Read if present (preserve user customizations)
6. **Git context**: `git log --oneline -10` for recent activity patterns
7. **Dependency management**: Lock files, .tool-versions, mise.toml, .nvmrc, rust-toolchain.toml

## Output Structure

The generated CLAUDE.md MUST follow this section order. Omit sections that don't apply. Every section should be 2-8 lines unless complexity demands more.

### 1. Project Overview (WHAT + WHY)

One paragraph: what this project is, what problem it solves, who it serves. No marketing language.

### 2. Architecture (WHAT)

Describe the **meta-structure**, not individual files:

- "src/ contains application code organized by domain (auth/, billing/, api/)"
- "Infrastructure lives in infra/ as Terraform modules, one per service"
- NOT a full directory listing

State the key boundaries: what talks to what, where the entry points are, how data flows if non-obvious.

### 3. Tech Stack (WHAT)

List language, framework, and major dependencies. For versions:

- **DO**: "Node version is pinned in .nvmrc"
- **DO**: "Terraform version defined in .terraform-version"
- **DON'T**: "Uses Node 20.11.1" (goes stale)

### 4. Development Workflow (HOW)

Commands to build, test, lint, format, and run locally. Reference the source of truth:

- "Build commands are in the Makefile"
- "CI pipeline defined in .github/workflows/ci.yml"
- "Test runner config in jest.config.ts"

Include only commands a developer runs frequently. Not setup guides.

### 5. Conventions & Patterns (HOW)

Project-specific patterns Claude should follow:

- Naming conventions (file naming, function naming, branch naming)
- Error handling patterns
- Import ordering rules
- Testing patterns (unit vs integration, fixture locations)
- Code organization rules

Only include patterns that are non-obvious or project-specific. Skip universal best practices.

### 6. Key Files & Entry Points (WHAT)

Point to files that matter for navigation:

- Main entry point(s)
- Configuration files that control behavior
- Where environment variables are defined/documented
- Where types/interfaces/schemas live

Use relative paths. Brief annotation per file.

### 7. Gotchas & Context (WHY)

Things that would surprise or trip up Claude (or a new developer):

- Non-obvious dependencies between components
- Legacy patterns that differ from the rest of the codebase
- Environment-specific behavior
- Known limitations or technical debt areas

## Writing Rules

These rules are mandatory for all generated CLAUDE.md content:

- **Pointers over content**: Reference where information lives, don't duplicate it
- **No version pinning**: Say where versions are defined, not what they are
- **No full file trees**: Describe structure patterns, not every file
- **Dense formatting**: Use bold, short bullets, tables where they compress information
- **Imperative tone**: "Run `make test`" not "You can run `make test`"
- **No em dashes**: Use commas, semicolons, or parentheses instead
- **Under 150 lines**: If exceeding, split into supplementary docs and reference them
- **Present tense**: "The API validates input at the controller layer"
- **No hedging**: State facts. If uncertain, investigate first or omit.

## Edit Mode

When editing an existing CLAUDE.md:

1. Read the entire file first
2. Preserve user customizations and sections not covered by this template
3. Merge new discoveries with existing content (don't overwrite wholesale)
4. Flag sections that appear stale: "This section may need updating: [reason]"
5. Maintain the existing file's style if it differs from this template

## Validation

Before presenting the CLAUDE.md to the user:

- [ ] Every section answers WHAT, WHY, or HOW (not just WHAT)
- [ ] No hardcoded versions (only pointers to where versions live)
- [ ] No full directory listings (only meta-structure descriptions)
- [ ] Under 150 lines
- [ ] All referenced files actually exist in the project
- [ ] Commands listed are accurate (verify by checking Makefile/package.json/CI)
