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
    section text (skip the actual `cm` commit).

## Steps

1. In **git-project**, run `/project-setup`.
   - At the VCS prompt, accept the auto-detected **git** default.
   - Choose to build the context layer: **yes**.
   - Seed CLAUDE.md: **yes**; paste a short README excerpt as source.
   - Create AGENTS.md: **yes**.
   - Initialize the task backlog: **yes**.
   - Approve the plan at the CONFIRM step.
2. In **plastic-project**, run `/project-setup`.
   - At the VCS prompt, accept the auto-detected **Plastic SCM** default.
   - Decline the context layer (**no**), but accept AGENTS.md (**yes**).
   - Initialize the task backlog: **yes**.
   - Approve the plan.
3. Run `/project-setup` once more in **git-project** (idempotency check) and
   decline everything at the CONFIRM step.
4. Run `/project-setup` and at CONFIRM answer with silence / an unrelated
   reply (abort path).

## Expected

1. **git-project:**
   - GATHER asks exactly: VCS, context-layer, seed-CLAUDE.md (+paste),
     AGENTS.md, task-backlog. No extra prompts.
   - CONFIRM prints the full plan with execution order 1-7 and "commit via
     git". No file is written before approval.
   - After approval: `/context-build` runs and commits its own artifacts;
     CLAUDE.md gains a synthesized project-info section (prose, NOT the
     pasted text verbatim); **no** `## VCS` section is injected (git needs
     none); AGENTS.md is created pointing at CLAUDE.md; `/task-setup` runs
     and commits its own scaffolding.
   - A final commit "Configure project via /project-setup" contains ONLY
     CLAUDE.md (project-info edit) and AGENTS.md — not the context-build or
     task-setup artifacts (those are in their own commits).
2. **plastic-project:**
   - CONFIRM shows "commit via cm" and "inject Plastic mapping into
     CLAUDE.md".
   - Context-build is skipped; a minimal CLAUDE.md skeleton is created
     (Step 1 path).
   - CLAUDE.md carries the `## VCS` section with the git→`cm` substitution
     table exactly as in the command body.
   - AGENTS.md is created.
   - The final check-in uses `cm checkin` against the explicit paths, and
     the run reports a changeset number (or, in simulation, reports the
     files as written).
3. The wizard re-asks the questions; declining everything at CONFIRM writes
   nothing and commits nothing. Existing CLAUDE.md / AGENTS.md are left
   untouched (no clobber, no duplicate sections).
4. Abort path: silence / unrelated reply at CONFIRM stops the run with no
   files written and no commit.

## Notes

- The VCS section is injected for any non-git VCS and omitted for git.
- User-pasted docs must be synthesized, never inserted verbatim — eyeball
  the CLAUDE.md project-info section to confirm.
- Step 7 stages only the explicit paths the command wrote; it must never run
  `git add -A` / `git add .` / `git add -u` or a Plastic catch-all.
- Sub-command commits (`/context-build`, `/task-setup`) are separate from
  project-setup's own commit — verify three distinct commits in the
  git-project happy path.
