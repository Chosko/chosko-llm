# Smoke test: colors

**Type:** CLI (cross-command)
**Source:** scripts/lib.sh, scripts/cmd-ls.sh, scripts/cmd-show.sh, scripts/cmd-add.sh,
           scripts/cmd-rm.sh, scripts/cmd-update.sh, scripts/cmd-upgrade.sh, scripts/cmd-help.sh

## Setup

- `install.sh` has been run (managed clone at `~/.chosko-llm`).
- At least one feature installed; at least one available but not installed; at
  least one installed feature with a newer version in the managed clone
  (bump the version in the source manually to create this state).
- Terminal that supports ANSI color (e.g. iTerm2, gnome-terminal, Windows Terminal).

## Steps

### TTY output (color enabled)

1. Run `chosko-llm ls` in an interactive terminal.
2. Run `chosko-llm show <up-to-date-feature>`.
3. Run `chosko-llm show <updatable-feature>`.
4. Run `chosko-llm show <not-installed-feature>`.
5. Run `chosko-llm add <not-installed-feature>`.
6. Run `chosko-llm rm <installed-feature>`.
7. Run `chosko-llm update <installed-feature>` (use one whose source version differs).
8. Run `chosko-llm update --all`.
9. Run `chosko-llm upgrade` when the managed clone is already up to date.
10. Run `chosko-llm help`.

### Piped / redirected output (color disabled)

11. Run `chosko-llm ls | cat`.
12. Run `chosko-llm ls > /tmp/ls-out.txt && cat /tmp/ls-out.txt`.
13. Run `chosko-llm show <feature> | cat`.

### NO_COLOR (color disabled)

14. Run `NO_COLOR=1 chosko-llm ls`.
15. Run `NO_COLOR=1 chosko-llm show <feature>`.
16. Run `NO_COLOR=1 chosko-llm help`.

## Expected

### TTY color checks (steps 1–10)

1. `chosko-llm ls`:
   - Header row (NAME KIND INSTALLED LATEST STATUS) is **bold**.
   - `up-to-date` STATUS values are **green**.
   - `updatable` STATUS values are **yellow**.
   - `not installed` STATUS values are **dim** (greyed out).
   - `local only` STATUS values are **cyan**.
   - KIND column: `command` is **blue**, `skill` is **magenta**, `claude-md` is **cyan**.
   - `—` placeholder values in INSTALLED or LATEST columns are **dim**.
   - All columns remain aligned (colors must not break fixed-width padding).
2. `chosko-llm show <up-to-date-feature>`:
   - Header line is **bold**.
   - `Kind:` value uses its kind color (blue/magenta/cyan per kind).
   - `Status:` value is **green** (`up-to-date`).
   - Footer message "This feature is up to date." is **green**.
3. `chosko-llm show <updatable-feature>`:
   - `Status:` value is **yellow** (`updatable`).
   - Footer tip prefix is **yellow**; old version is **dim**, new version is **green**.
4. `chosko-llm show <not-installed-feature>`:
   - `Status:` value is **dim** (`not installed`); `Installed:` value is **dim** (`—`).
   - Footer tip prefix is **dim**.
5. `chosko-llm add`: the "Installed …" success line on stderr uses **green** `[ok]`
   prefix. "Already installed" lines (if any) use blue `[info]`.
6. `chosko-llm rm`: the "Removed …" success line uses **green** `[ok]`.
7. `chosko-llm update <feature>`: "Updated …" line uses **green** `[ok]`.
   "Local version ahead" warning uses **yellow** `[warn]`.
   "Already up-to-date" info uses **blue** `[info]`.
8. `chosko-llm update --all`: same per-feature prefix rules as step 7.
9. `chosko-llm upgrade` (no new commits): "Already up to date." uses **green** `[ok]`.
10. `chosko-llm help`: the `Usage:` heading is rendered **bold**; the rest of the
    text is plain.

### Piped / redirected checks (steps 11–13)

11–12. `ls` output is pure plain text — no ANSI escape sequences. The table columns
       are still aligned. Verify with:
       `chosko-llm ls | cat | grep -P '\x1b'` should return nothing.
13. `chosko-llm show <feature> | cat` output is pure plain text — metadata block
    and footer contain no ANSI escape sequences.

### NO_COLOR checks (steps 14–16)

14. `chosko-llm ls` output has no escape codes; looks identical to piped output.
15. `chosko-llm show <feature>` output has no escape codes; metadata block is plain.
16. `chosko-llm help` output has no escape codes; `Usage:` heading is plain.

## Notes

- `NO_COLOR` suppresses both stdout and stderr coloring.
- Stderr coloring (log prefixes) is gated on `[ -t 2 ]`; stdout coloring
  (`ls` table, `help` heading) is gated on `[ -t 1 ]`. These are checked
  independently: piping stdout still shows colored stderr when stderr is
  a TTY.
- Check alignment carefully for `claude-md` rows — this kind name is 9 chars
  and overruns the 8-char KIND field; this is pre-existing behavior.
