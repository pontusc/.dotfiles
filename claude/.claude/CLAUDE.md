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
- **After completing tasks**: Offer session retrospective (`/session-retrospective`) to improve workflow
- After iterative work with many corrections, offer to document learnings:
  - Default: Add to this file for general patterns and preferences
  - Create skill: Only for workflows repeated 3+ times

### Summary Generation (ctrl+o)
- Include key decisions made (WHY, not just WHAT)
- Track error corrections and course corrections
- Reference critical files with paths and line numbers
- Capture architectural choices and trade-offs discussed

### Pattern Recognition Signals
- **"simple/basic/barebones" repeated 3+ times** → User wants MINIMAL scope, avoid over-engineering
- **Docker-first project** → Version management solved, no need for Mise/asdf/rtx
- **Two course corrections in same session** → Stop and ask what's wrong rather than continuing
- **Explicit constraints ignored** → Re-read user's original request and stated preferences

## Coding Principles
- **Security first**: Avoid vulnerabilities (injection, XSS, etc.), follow OWASP
- **Minimal dependencies**: Standard tools, containerized implementations
- **IaC best practices**: Modular, reusable, proper state management
- **Shell scripting**: `set -euo pipefail`, ShellCheck compliant, POSIX when possible
- **Simplicity**: Don't over-engineer, stay focused on the task

## Working Guidelines
- **Ask before changing** files/configs (especially system-critical dotfiles)
- **Avoid**: Unsolicited refactoring, adding unrequested features, assumptions
- **Git**: Clear commits, conventional format when appropriate
- **Cross-platform**: Verify commands work on target environment (macOS vs Linux)

## Plan Mode Workflow

**When to use**: ONLY for complex/multi-phase work (5+ files, architectural decisions, needs user buy-in)

**2-Step Approval Process**:
1. **High-level outline phase**:
   - Present approach, phases, critical files to modify
   - Include architectural decisions and trade-offs
   - NO full code snippets (unless demonstrating a critical pattern)
   - Think: "tech lead planning doc" not "implementation guide"
   - Goal: User can read in 1-2 minutes and approve/reject approach

2. **Implementation details phase** (only if step 1 approved):
   - Provide detailed implementation guidance
   - Can include key code snippets for complex parts
   - Still avoid dumping complete file contents for straightforward code

**What to avoid in plans**:
- Complete file contents for every file (generates 400+ line plans)
- Detailed step-by-step instructions for straightforward tasks
- Extensive verification steps (save for implementation phase)
- Over-engineering when user emphasizes simplicity

**Example**: "Create Docker setup" → Plan should outline services, networking approach, Makefile targets. NOT include every line of every Dockerfile.

---

## Session Learnings

### 2026-02-01: Homelab Monitoring Project
**Issues identified**:
- Over-engineered initial plan (included monitoring stack when just wanted basic structure)
- Proposed Mise when Docker already handles version management
- Created 497-line plan with full file contents when user wanted high-level outline
- Missed repeated "simple/basic/barebones" signals (said 5+ times)

**Corrective actions**: Added Plan Mode Workflow section, Pattern Recognition Signals

---

*Last updated: 2026-02-01*
