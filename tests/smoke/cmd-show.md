# Smoke test: cmd-show

**Type:** CLI command
**Source:** scripts/cmd-show.sh

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- Prepare four feature states (use `add` / `rm` / manual version bumps in the
  clone to create them):
  - **up-to-date** — installed, same version as the clone.
  - **updatable** — installed, clone has a newer version.
  - **not installed** — present in the clone, not installed.
  - **local only** — installed, absent from the clone.

## Steps

1. Run `chosko-llm show <updatable-feature>` (no flags).
2. Run `chosko-llm show <not-installed-feature>` (no flags).
3. Run `chosko-llm show <feature> --installed` on a not-installed feature.
4. Run `chosko-llm show <feature> --latest` on a local-only feature.
5. Run `chosko-llm show <feature> --content` on an installed feature.
6. Run `chosko-llm show <updatable-feature> --diff`.
7. Run `chosko-llm show <updatable-feature> --diff --content`.
8. Run `chosko-llm show <feature> --installed --latest` (two selection flags).
9. Run `chosko-llm show` with no feature, and `chosko-llm show -h`.
10. Run `chosko-llm show <ambiguous-name>` (a name that is both a command and a
    skill), then re-run with `command:<name>`.

## Expected

1. A metadata block prints: `Name`, `Kind`, `Installed`, `Latest`, `Status`,
   `Description`, `Path`. A header says it is showing the **installed** copy.
   Status is `updatable`. A footer suggests `chosko-llm update <name>`.
2. The header shows the **latest** copy (because it is not installed). Status is
   `not installed`. A footer suggests `chosko-llm add <name>`.
3. The metadata still prints, plus a note that the feature is not installed
   (nothing to show for `--installed`).
4. A note that there is no managed/latest copy (local only).
5. After the metadata, the feature's body is printed under a content header.
6. After the metadata, a one-line `installed <v> vs latest <v> (updatable)`
   summary prints, plus a tip to pass `--content`. No line diff yet.
7. A unified `diff -u` between the installed and latest bodies is printed.
8. Errors out: "Choose only one of --installed, --latest, --diff." (exit 1).
9. No feature → usage error (exit 1). `-h` → full usage on stdout (exit 0).
10. Ambiguous bare name errors with a disambiguation hint; the `command:<name>`
    form resolves and prints the command's metadata.

## Color checks (TTY vs piped)

Run these in an interactive terminal that supports ANSI color:

- `chosko-llm show <command-feature>`: header line is **bold**; `Kind:` value is
  **blue**; `Status:` color matches its value (green / yellow / dim / cyan).
  `—` placeholders in `Installed:` or `Latest:` are **dim**.
- `chosko-llm show <skill-feature>`: `Kind:` value is **magenta**.
- `chosko-llm show <claude-md-feature>`: `Kind:` value is **cyan**.
- `chosko-llm show <up-to-date-feature>`: footer "This feature is up to date." is **green**.
- `chosko-llm show <updatable-feature>`: footer tip prefix is **yellow**;
  old version token is **dim**; new version token is **green**.
- `chosko-llm show <not-installed-feature>`: footer tip prefix is **dim**.

Piped and `NO_COLOR` checks:

- `chosko-llm show <feature> | cat` — output is pure plain text, no ANSI codes.
- `NO_COLOR=1 chosko-llm show <feature>` — same, no ANSI codes.

## Notes

- Status vocabulary matches `ls`: `up-to-date` / `updatable` / `not installed`
  / `local only`. The `—` sentinel is an em-dash (U+2014).
- `--content` is additive: without it only metadata (and the diff summary)
  prints; with it the selected body (or the line diff) is shown.
- For a `claude-md` feature, `Path` points at the `CLAUDE.md` section anchor and
  the version comes from the section's begin tag.
- Kind colors match `ls`: `command` = blue, `skill` = magenta, `claude-md` = cyan.
  The `claude-md` kind and `local only` status both use cyan — this is intentional
  (they appear in separate fields and remain unambiguous).
