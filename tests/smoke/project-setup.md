# Smoke test: project-setup

**Type:** command
**Source:** commands/project-setup.md

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- Two scratch projects to exercise both VCS paths:
  - **git-project** — a fresh `git init` directory, no CLAUDE.md yet.
  - **plastic-project** — a directory under Plastic control (`.plastic/`
    present, `cm` on PATH). If Plastic is unavailable, simulate by telling
    the wizard "Plastic" at the VCS prompt — project-setup never runs a VCS
    command, so the only Plastic-specific output to verify is the injected
    CLAUDE.md `## VCS` section.

## Steps

1. In **git-project**, run `/project-setup`.
   - Confirm the upfront "leaves everything uncommitted" notice appears
     before any question.
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
   - An upfront notice states the wizard leaves everything uncommitted and
     will decline task-setup's commit prompt.
   - GATHER asks exactly, in order: VCS, seed-CLAUDE.md (+paste), AGENTS.md,
     task-backlog, context-layer. No extra prompts.
   - CONFIRM prints the full plan with execution order 1-6, no "commit via"
     line, and the closing "All changes are left UNCOMMITTED" note. No file
     is written before approval.
   - EXECUTE order is observable:
     - CLAUDE.md is seeded with a synthesized project-info section (prose,
       NOT the pasted text verbatim) — and the wizard does NOT spelunk the
       codebase to fill it.
     - **No** `## VCS` section is injected (git needs none).
     - AGENTS.md is created pointing at CLAUDE.md.
     - `/task-setup` runs; its "commit scaffolding? [y/N]" prompt is
       DECLINED automatically — its files are left uncommitted.
     - `/context-build` runs LAST, honors its own STOP gates, and leaves its
       output uncommitted.
   - **End state: zero commits.** `git status` shows the wizard's files,
     task-setup's scaffolding, and context-build's output all uncommitted.
     The final report reminds the user to review and commit in one pass.
2. **plastic-project:**
   - CONFIRM shows VCS = Plastic SCM and "inject Plastic mapping into
     CLAUDE.md". No "commit via" line.
   - Seeding is skipped (nothing pasted); a minimal CLAUDE.md skeleton is
     created because the VCS section needs somewhere to live (Step 1 path).
   - CLAUDE.md carries the `## VCS` section with the git→`cm` substitution
     table exactly as in the command body.
   - AGENTS.md is created; task-setup runs with its commit prompt declined.
   - **No `cm` command is ever run by project-setup itself** — everything is
     left uncommitted for the user's review.
3. The wizard re-asks the questions; declining everything at CONFIRM writes
   nothing. Existing CLAUDE.md / AGENTS.md are left untouched (no clobber, no
   duplicate sections).
4. Abort path: silence / unrelated reply at CONFIRM stops the run with no
   files written.

## Notes

- project-setup is a pure authoring command: it NEVER commits. The only VCS
  interaction is read-only detection in GATHER, used solely to decide whether
  to inject the Plastic mapping section.
- The VCS section is injected for any non-git VCS and omitted for git.
- CLAUDE.md seeding uses ONLY user-pasted material — never a codebase read,
  never verbatim insertion. Eyeball the project-info section to confirm.
- context-build runs LAST so its interactive, context-hungry flow can't
  strand the wizard's earlier steps.
- Verify the end state has no new commits in either project — the whole point
  of the authoring model is one final user-driven review-and-commit.
