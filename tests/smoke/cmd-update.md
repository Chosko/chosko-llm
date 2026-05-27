# Smoke test: cmd-update

**Type:** CLI command
**Source:** scripts/cmd-update.sh

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- At least one feature is installed.
- To simulate version states, temporarily edit the `version:` frontmatter
  field in the installed copy (under `~/.claude/`) or the source copy (under
  `~/.chosko-llm/`) as needed for each test scenario.

## Steps

1. **Single-feature path unchanged:** Identify a feature whose installed version
   equals the source version. Run `chosko-llm update <feature>`. Confirm it
   still re-copies the file (no skip).

2. **--all up-to-date skip:** Set up a feature where installed version ==
   source version. Run `chosko-llm update --all`. Confirm the output contains
   `Already up-to-date: <kind> '<name>' (v<ver>)` and the file's mtime did not
   change (it was not re-copied).

3. **--all locally-ahead skip:** Edit the installed copy to have a *higher*
   version than the source. Run `chosko-llm update --all`. Confirm the output
   contains `Local version ahead: <kind> '<name>' (local v<high>, latest v<low>)
   — skipping` and the installed file was not overwritten.

4. **--all updatable:** Edit the source copy to have a *higher* version than the
   installed copy. Run `chosko-llm update --all`. Confirm the output contains
   `Updated <kind> '<name>' -> v<new_ver>` and the installed file was replaced.

5. **--all nothing to update:** Ensure all installed features are either
   up-to-date or locally ahead. Run `chosko-llm update --all`. Confirm the
   output ends with `Nothing to update.`

6. **--all no source in managed clone:** Remove a feature from `~/.chosko-llm`
   (or use a locally-only installed feature). Run `chosko-llm update --all`.
   Confirm the output contains `Skipping <kind> '<name>': no source in managed
   clone.`

7. **--all unreadable version:** Edit an installed feature's file to remove the
   `version:` frontmatter line entirely. Run `chosko-llm update --all`. Confirm
   the output contains a warning like `Skipping <kind> '<name>': version
   unreadable — update manually` and the run does not abort with an error.

## Expected

1. Single-feature `update <feature>` always copies — version check does NOT
   apply to the single-feature path.
2. `Already up-to-date` log line; file not re-copied.
3. `Local version ahead … — skipping` log line; file not overwritten.
4. `Updated … -> v<ver>` log line; installed file updated.
5. `Nothing to update.` printed when all are skipped.
6. Warning about no source in managed clone; other features still processed.
7. Warning about unreadable version; run continues with other features.

## Notes

- The version comparison is pure MAJOR.MINOR.PATCH semver via awk (no `sort -V`).
- Pre-release or build-metadata suffixes are not handled — such versions appear
  as "unreadable" and are skipped with a warning.
- The `any` counter only increments when `update_one` is actually called, so
  features skipped for version reasons do not prevent `Nothing to update.` from
  printing when no updates occurred.
