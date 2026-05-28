# Smoke test: cmd-add --all

**Type:** CLI command
**Source:** scripts/cmd-add.sh

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- For the "partially installed" scenario, remove one or more features from
  `~/.claude/commands/` or `~/.claude/skills/` before running.

## Steps

1. **All already installed:** Ensure every feature in the managed clone is
   already installed. Run `chosko-llm add --all`. Confirm each feature appears
   as `Already installed: <kind> '<name>' — skipping` and the run ends with
   `Nothing to install — all features already installed.`

2. **One uninstalled command:** Remove an installed command file from
   `~/.claude/commands/`. Run `chosko-llm add --all`. Confirm:
   - The removed command is reinstalled with an `Installed command '<name>' v<ver> -> ...` log line.
   - All already-installed features show the skip message.
   - Exit code is 0.

3. **One uninstalled skill:** Remove an installed skill directory from
   `~/.claude/skills/`. Run `chosko-llm add --all`. Confirm the skill is
   reinstalled and the log line appears.

4. **Missing version in frontmatter:** Temporarily remove the `version:` line
   from a source `.md` in `~/.chosko-llm/commands/`. Run `chosko-llm add --all`.
   Confirm a `Skipping command '<name>': missing version in frontmatter` warning
   is emitted and the run does not abort.

5. **claude-md not installed:** Ensure a claude-md entry is absent from
   `~/.claude/CLAUDE.md`. Run `chosko-llm add --all`. Confirm the section is
   injected and the log line `Installed claude-md '<name>' v<ver> -> ...CLAUDE.md`
   appears.

## Expected

1. All skip messages + `Nothing to install.` line.
2. Exactly one `Installed` log line for the removed command; others skipped.
3. Exactly one `Installed` log line for the removed skill; others skipped.
4. Warning line for the bad feature; other features still processed; exit 0.
5. claude-md section injected correctly; log line emitted.

## Notes

- Unlike `update --all`, which iterates *installed* features, `add --all`
  iterates the *managed clone* source directories. Features present only in
  `~/.claude/` (locally added, no source) are never touched.
- `add --all` never updates a feature that is already installed — use
  `update --all` for that.
