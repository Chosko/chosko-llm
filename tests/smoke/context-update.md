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
- Phase 3 commits the run: a single new commit appears whose subject names the
  context update. `git show --stat HEAD` lists ONLY the context files Phase 2
  wrote plus `INDEX.md` — no skipped context files, no unrelated dirty files.
  The reported commit hash matches `git rev-parse --short HEAD`.

## Notes

- Test Mode B: `/context-update full` — all context files should be in scope.
- Test Mode C with files: `/context-update files=<name>` — only that file updated.
- Test Mode C with git ref: `/context-update git=uncommitted` — detects staged changes.
- Test `-y` flag: `/context-update -y` — no confirmation prompts, runs to completion.
- Run when context is already up to date to verify the "Context is up to date"
  exit path — and confirm NO commit is made (no empty commit) in that case.
- Dirty-tree safety: pre-stage/modify an unrelated file, run `/context-update`,
  and confirm the auto-commit captures ONLY the context files it wrote — the
  unrelated change is left untouched in the working tree.
- Pre-commit-hook failure: install a failing `pre-commit` hook, run
  `/context-update`, and confirm the command surfaces the hook output, does NOT
  retry / `--amend` / `--no-verify`, and leaves the files staged-but-uncommitted.
- `--no-commit`: run `/context-update --no-commit` after a real code change.
  Phase 2 updates the context files (and bumps INDEX), but Phase 3 makes NO
  commit — `git log` is unchanged, `git status` shows the updated files
  uncommitted, and the report reminds the user. Combinable with any mode
  (e.g. `/context-update full --no-commit`).
- Mutual exclusivity: `/context-update --commit --no-commit` stops with
  "`--commit and --no-commit cannot be combined. Pick one.`".
