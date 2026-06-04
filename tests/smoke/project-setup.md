# Smoke test: project-setup

**Type:** command
**Source:** commands/project-setup.md

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- Two scratch projects to exercise both VCS paths:
  - **git-project** — a fresh `git init` directory, no CLAUDE.md yet.
  - **plastic-project** — a directory under Plastic control (`.plastic/`
    present, `cm` on PATH). If Plastic is unavailable, simulate by telling
    the wizard "Plastic" at the VCS prompt and verify only the CLAUDE.md
    section text (skip the actual `cm` check-in).

## Steps

1. In **git-project**, run `/project-setup`.
   - At the VCS prompt, accept the auto-detected **git** default.
   - Seed CLAUDE.md: **yes**; paste a short README excerpt as source.
   - Create AGENTS.md: **yes**.
   - Initialize the task backlog: **yes**.
   - Build the context layer: **yes**.
   - Approve the plan at the CONFIRM step.
2. In **plastic-project**, run `/project-setup`.
   - At the VCS prompt, accept the auto-detected **Plastic SCM** default.
   - Seed CLAUDE.md: **no** (paste nothing).
   - Create AGENTS.md: **yes**.
   - Initialize the task backlog: **yes**.
   - Build the context layer: **no**.
   - Approve the plan.
3. Run `/project-setup` once more in **git-project** (idempotency check) and
   decline everything at the CONFIRM step.
4. Run `/project-setup` and at CONFIRM answer with silence / an unrelated
   reply (abort path).

## Expected

1. **git-project:**
   - GATHER asks exactly, in order: VCS, seed-CLAUDE.md (+paste), AGENTS.md,
     task-backlog, context-layer. No extra prompts. The context-layer
     question notes that context-build runs last and is left uncommitted.
   - CONFIRM prints the full plan with the two-part execution order
     (wizard's own artifacts 1-5, then sub-commands 6-7) and "commit via
     git". No file is written before approval.
   - EXECUTE order is observable:
     - CLAUDE.md is seeded with a synthesized project-info section (prose,
       NOT the pasted text verbatim) — and the wizard does NOT spelunk the
       codebase to fill it.
     - **No** `## VCS` section is injected (git needs none).
     - AGENTS.md is created pointing at CLAUDE.md.
     - A commit "Configure project via /project-setup" lands containing ONLY
       CLAUDE.md and AGENTS.md — and it happens BEFORE task-setup and
       context-build run.
     - `/task-setup` then runs and commits its own scaffolding (separate
       commit).
     - `/context-build` runs LAST, honors its own STOP gates, and leaves its
       output (`.claude/context/` + CLAUDE.md nav edit) UNCOMMITTED. The
       final report reminds the user to review and commit it.
   - Net: two commits (project-setup's own, then task-setup's) plus an
     uncommitted context layer.
2. **plastic-project:**
   - CONFIRM shows "commit via cm" and "inject Plastic mapping into
     CLAUDE.md".
   - Seeding is skipped (nothing pasted); a minimal CLAUDE.md skeleton is
     created because the VCS section needs somewhere to live (Step 1 path).
   - CLAUDE.md carries the `## VCS` section with the git→`cm` substitution
     table exactly as in the command body.
   - AGENTS.md is created.
   - The wizard's check-in uses `cm checkin` against the explicit paths and
     reports a changeset number (or, in simulation, reports the files as
     written). task-setup runs after and manages its own check-in. Context
     layer was declined, so context-build does not run.
3. The wizard re-asks the questions; declining everything at CONFIRM writes
   nothing and commits nothing. Existing CLAUDE.md / AGENTS.md are left
   untouched (no clobber, no duplicate sections).
4. Abort path: silence / unrelated reply at CONFIRM stops the run with no
   files written and no commit.

## Notes

- The VCS section is injected for any non-git VCS and omitted for git.
- CLAUDE.md seeding uses ONLY user-pasted material — never a codebase read,
  never verbatim insertion. Eyeball the project-info section to confirm.
- context-build runs LAST specifically so the wizard's own artifacts are
  committed before the most context-hungry, gated sub-command starts. It has
  no commit phase — its output is always left for the user to review.
- Step 5 stages only the explicit paths the command wrote; it must never run
  `git add -A` / `git add .` / `git add -u` or a Plastic catch-all.
- Commit boundaries in the git happy path: project-setup's own commit and
  task-setup's commit are distinct; the context layer is uncommitted.
