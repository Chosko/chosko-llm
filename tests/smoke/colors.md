# Smoke test: colors

**Type:** CLI (cross-command)
**Source:** scripts/lib.sh, scripts/cmd-ls.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh,
           scripts/cmd-update.sh, scripts/cmd-upgrade.sh, scripts/cmd-help.sh

## Setup

- `install.sh` has been run (managed clone at `~/.chosko-llm`).
- At least one feature installed; at least one available but not installed; at
  least one installed feature with a newer version in the managed clone
  (bump the version in the source manually to create this state).
- Terminal that supports ANSI color (e.g. iTerm2, gnome-terminal, Windows Terminal).

## Steps

### TTY output (color enabled)

1. Run `chosko-llm ls` in an interactive terminal.
2. Run `chosko-llm add <not-installed-feature>`.
3. Run `chosko-llm rm <installed-feature>`.
4. Run `chosko-llm update <installed-feature>` (use one whose source version differs).
5. Run `chosko-llm update --all`.
6. Run `chosko-llm upgrade` when the managed clone is already up to date.
7. Run `chosko-llm help`.

### Piped / redirected output (color disabled)

8. Run `chosko-llm ls | cat`.
9. Run `chosko-llm ls > /tmp/ls-out.txt && cat /tmp/ls-out.txt`.

### NO_COLOR (color disabled)

10. Run `NO_COLOR=1 chosko-llm ls`.
11. Run `NO_COLOR=1 chosko-llm help`.

## Expected

### TTY color checks (steps 1–7)

1. `chosko-llm ls`:
   - Header row (NAME KIND INSTALLED LATEST STATUS) is **bold**.
   - `up-to-date` STATUS values are **green**.
   - `updatable` STATUS values are **yellow**.
   - `not installed` STATUS values are **dim** (greyed out).
   - `local only` STATUS values are **cyan**.
   - KIND column values (`command`, `skill`, `claude-md`) are **dim**.
   - `—` placeholder values in INSTALLED or LATEST columns are **dim**.
   - All columns remain aligned (colors must not break fixed-width padding).
2. `chosko-llm add`: the "Installed …" success line on stderr uses **green** `[ok]`
   prefix. "Already installed" lines (if any) use blue `[info]`.
3. `chosko-llm rm`: the "Removed …" success line uses **green** `[ok]`.
4. `chosko-llm update <feature>`: "Updated …" line uses **green** `[ok]`.
   "Local version ahead" warning uses **yellow** `[warn]`.
   "Already up-to-date" info uses **blue** `[info]`.
5. `chosko-llm update --all`: same per-feature prefix rules as step 4.
6. `chosko-llm upgrade` (no new commits): "Already up to date." uses **green** `[ok]`.
7. `chosko-llm help`: the `Usage:` heading is rendered **bold**; the rest of the
   text is plain.

### Piped / redirected checks (steps 8–9)

8–9. Output is pure plain text — no ANSI escape sequences. The table columns are
     still aligned. No `[ok]`, `[info]`, `[warn]`, `[error]` prefixes appear in
     stdout (those go to stderr). Verify with:
     `chosko-llm ls | cat | grep -P '\x1b'` should return nothing.

### NO_COLOR checks (steps 10–11)

10. `chosko-llm ls` output has no escape codes; looks identical to piped output.
11. `chosko-llm help` output has no escape codes; `Usage:` heading is plain.

## Notes

- `NO_COLOR` suppresses both stdout and stderr coloring.
- Stderr coloring (log prefixes) is gated on `[ -t 2 ]`; stdout coloring
  (`ls` table, `help` heading) is gated on `[ -t 1 ]`. These are checked
  independently: piping stdout still shows colored stderr when stderr is
  a TTY.
- Check alignment carefully for `claude-md` rows — this kind name is 9 chars
  and overruns the 8-char KIND field; this is pre-existing behavior.
