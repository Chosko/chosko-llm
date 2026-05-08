# Smoke test: context-update

**Type:** command
**Source:** commands/context-update.md

## Setup

- A project repo with an existing `.claude/context/INDEX.md` (run `/context-build` first).
- `install.sh` has been run and `chosko-llm add context-update` completed.

## Steps

1. Make a small code change in the project and commit it.
2. Open Claude Code in the target project.
3. Run `/context-update` (smart update, no args).
4. Review the scope report and confirm the correct context files are targeted.
5. Approve to continue through Phase 1 and Phase 2.

## Expected

- PREPARATION reads INDEX.md and identifies the "Last updated" date.
- Mode A is selected; a git log command is reported showing files changed since that date.
- Only context files whose OVERVIEW covers the changed source files are in scope.
- Phase 1 produces a per-file diff summary without modifying any files.
- Phase 2 updates only the in-scope context files and bumps the INDEX "Last updated" date.
- Files with no changes are skipped and reported as such.
- No domain knowledge files outside `.claude/context/` are modified.

## Notes

- Test Mode B: `/context-update full` — all context files should be in scope.
- Test Mode C with files: `/context-update files=<name>` — only that file updated.
- Test Mode C with git ref: `/context-update git=uncommitted` — detects staged changes.
- Test `-y` flag: `/context-update -y` — no confirmation prompts, runs to completion.
- Run when context is already up to date to verify the "Context is up to date" exit path.
