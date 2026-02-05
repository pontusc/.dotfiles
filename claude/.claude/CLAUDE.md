# Claude Code User Profile

**Role**: DevOps Engineer & Software Developer
**Focus**: Linux, Terraform/IaC, Bash, CI/CD, containers, automation, security

## Environments
- **Work**: macOS (professional development, enterprise tooling)
- **Home**: Arch Linux (omarchy) + Hyprland (personal projects, dotfiles)

## Tools
- **Editor**: Neovim (LazyVim + Lua configs)
- **IaC**: Terraform, Terragrunt
- **Containers**: Docker, Kubernetes, Podman
- **Automation**: Bash, CI/CD pipelines, Makefiles

## Communication
- Ask questions rather than assume. Provide context when helpful, but stay concise.
- After completing tasks, offer session retrospective (`/session-retrospective`)
- After iterative work with many corrections, offer to document learnings in this file
- Two course corrections in same session → stop and ask what's wrong

### Summary Generation (ctrl+o)
- Key decisions (WHY, not just WHAT)
- Error corrections and course corrections
- Critical file paths with line numbers
- Architectural choices and trade-offs

## Coding Principles
- **Security first**: OWASP, no injection/XSS vulnerabilities
- **Minimal dependencies**: Standard tools, containerized implementations
- **IaC best practices**: Modular, reusable, proper state management
- **Shell scripting**: `set -euo pipefail`, ShellCheck compliant, POSIX when possible
- **Simplicity**: Don't over-engineer. Most direct solution first.
- **Validate before proposing**: Confirm tool/service capabilities before suggesting solutions. Don't assume features exist.

## Working Guidelines
- **Ask before changing** files/configs (especially system-critical dotfiles)
- **NEVER run state-changing commands**: No deployment commands, no git state changes, no remote/production modifications. Only modify local files.
- **Avoid**: Unsolicited refactoring, unrequested features, assumptions
- **"simple/basic/barebones" signals** → user wants MINIMAL scope, propose the most direct solution
- **Docker-first project** → version management solved, no need for Mise/asdf/rtx

## Plan Mode Workflow

**When to use**: ONLY for complex/multi-phase work (5+ files, architectural decisions, needs user buy-in)

**2-Step Approval**:
1. **High-level outline**: Approach, phases, critical files, trade-offs. No code snippets. Readable in 1-2 minutes.
2. **Implementation details** (only if step 1 approved): Key code snippets for complex parts only.

**Avoid in plans**: Full file contents, step-by-step for obvious tasks, over-engineering.

*Last updated: 2026-02-05*
