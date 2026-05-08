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

## Notes

- Test with `/context-build "hint about project layout"` to verify $ARGUMENTS is passed.
- Run on a repo with an existing `.claude/` folder to confirm domain files are left untouched.
