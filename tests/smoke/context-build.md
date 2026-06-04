# Smoke test: context-build

**Type:** command
**Source:** commands/context-build.md

## Setup

- A project repo that does NOT already have a `.claude/context/` folder.
- `install.sh` has been run and `chosko-llm add context-build` completed.

## Steps

1. Open Claude Code in the target project.
2. Run `/context-build`.
3. Review the Phase 1 report and approve to continue.
4. Review the Phase 2 report and approve to continue.
5. Review the Phase 3 report.

## Expected

- Phase 1 produces a proposed layout and file list before writing anything.
- Phase 2 creates `.claude/context/INDEX.md` and at least one area context file.
- Each context file contains the six required sections (OVERVIEW, PUBLIC API,
  INTERNAL PATTERNS, DOMAIN DEPENDENCIES, CROSS-REFERENCES, WHEN TO READ THE SOURCE).
- Phase 3 updates (or creates) CLAUDE.md with the navigation instruction referencing
  `.claude/context/INDEX.md`.
- No source files are modified.
- No domain knowledge files (e.g. existing `.claude/*.md` outside context/) are modified.
- Default run (no `--commit`): the context layer and CLAUDE.md edit are left
  UNCOMMITTED in the working tree — `git status` shows them, `git log` has no
  new commit.

## --commit flag

- Run `/context-build --commit`. After Phase 3, a single new commit appears
  (subject names the context layer). `git show --stat HEAD` lists ONLY the
  files the run wrote — `.claude/context/INDEX.md`, the context files, and
  CLAUDE.md — and no unrelated dirty files. The reported hash matches
  `git rev-parse --short HEAD`.
- Run `/context-build --commit --no-commit`: the command stops with
  "`--commit and --no-commit cannot be combined. Pick one.`" and writes
  nothing.

## Notes

- Test with `/context-build "hint about project layout"` to verify $ARGUMENTS is passed.
- Run on a repo with an existing `.claude/` folder to confirm domain files are left untouched.
- Pre-commit-hook failure under `--commit`: install a failing hook, run
  `/context-build --commit`, confirm the hook output is surfaced and the
  command does NOT retry / `--amend` / `--no-verify`.
