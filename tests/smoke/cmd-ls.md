# Smoke test: cmd-ls

**Type:** CLI command
**Source:** scripts/cmd-ls.sh

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- At least one feature is installed (`chosko-llm add <feature>` was run).

## Steps

1. Run `chosko-llm ls` and inspect the output.
2. Identify a feature that is installed and at the same version as the managed
   clone (installed version == latest version).
3. Identify a feature that is installed but the managed clone has a newer
   version (e.g. bump the version in the source clone manually for testing).
4. Identify a feature that exists only in the managed clone but is not yet
   installed (`chosko-llm rm <feature>` to create this state).
5. Identify a feature that is installed but NOT present in the managed clone
   (manually remove from `~/.chosko-llm` to create this state).
6. Run `chosko-llm ls --installed`.
7. Run `chosko-llm ls --available`.
8. In an interactive terminal, run `chosko-llm ls` with at least one
   `not installed` and one `updatable` feature present.
9. Pipe the same command: `chosko-llm ls | cat`.
10. Run `chosko-llm ls` when every installed feature is up-to-date and nothing
    is installable.

## Expected

1. The header row contains the column `STATUS` (fifth column after LATEST).
2. A feature with installed == latest shows `up-to-date` in the STATUS column.
3. A feature with installed < latest shows `updatable` in the STATUS column.
4. A feature with installed == `—` (not installed) shows `not installed`.
5. A feature with latest == `—` (no source in managed clone) shows `local only`.
6. `chosko-llm ls --installed` output includes the STATUS column; rows with
   `—` INSTALLED are omitted but STATUS column is still present on shown rows.
7. `chosko-llm ls --available` output includes the STATUS column; rows with
   `—` LATEST are omitted but STATUS column is still present on shown rows.
8. Below the table, separated by one blank line, a suggestions block appears:
   an install hint (`Run 'chosko-llm add <name>' to install it.` for exactly
   one, or `... add --all to install all N.` for two or more) and an update
   hint (`Run 'chosko-llm update <name>' to update it.` for one, or
   `Run 'chosko-llm update --all' to update all N updatable features.` for two
   or more). Counts reflect the filtered, displayed rows. The block also ends
   with the inspect hint `Run 'chosko-llm show <feature>' to inspect a
   feature.` — printed last, regardless of whether any add/update hint fired.
9. No suggestion lines appear — the piped output is only the table, byte-for-byte
   the same as before this feature. (Suggestions are gated on `[ -t 1 ]`.) The
   `show` inspect hint is suppressed too — it is part of the gated block.
10. The `Everything is up to date.` line appears below the table, followed by
    the `Run 'chosko-llm show <feature>' to inspect a feature.` inspect hint
    (the inspect hint is always present when the suggestions block renders).
    Under `--installed` the install hint never appears; under `--available`
    it may.

## Notes

- The `—` sentinel is an em-dash (U+2014), not a regular hyphen.
- `unversioned` appears when a file exists but has no `version` frontmatter
  field; this should not crash and produces `updatable` when a source version
  exists or `local only` when no source is present.
