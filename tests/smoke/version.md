# Smoke test: version

**Type:** CLI flag / subcommand
**Source:** scripts/cmd-version.sh, scripts/lib.sh (resolve_version), bin/chosko-llm

## Setup

- `install.sh` has been run (managed clone at `~/.chosko-llm` with a `VERSION`
  file and git history).

## Steps

1. Run `chosko-llm --version`.
2. Run `chosko-llm -v`.
3. Run `chosko-llm version`.
4. Compare the printed version against the banner from re-running `install.sh`.
5. In the managed clone, temporarily remove/rename `VERSION`, then run
   `chosko-llm --version`. Restore it afterward.
6. Run `chosko-llm --version` with the proxy pointed at a clone whose
   `scripts/cmd-version.sh` is absent (simulating an older install) — e.g.
   rename it briefly. Restore afterward.

## Expected

1. Prints `chosko-llm <version>`, where `<version>` is the `VERSION` contents
   plus ` (<git describe>)` when git is available, e.g.
   `chosko-llm 0.3.0 (0.3.0-2-gabc123)`. Exits 0.
2. Identical output to step 1.
3. Identical output to step 1.
4. The version string matches what `install.sh` logs as
   `Installed chosko-llm <version>` — both come from `resolve_version`.
5. Prints `chosko-llm unknown` (VERSION missing → "unknown" fallback). Exits 0.
6. The proxy's inline fallback runs: prints `chosko-llm <VERSION contents>`
   (no git-describe suffix). Exits 0.

## Notes

- `resolve_version` lives in `scripts/lib.sh` and is the single source of the
  format; `cmd-version.sh` and `install.sh` both call it (install.sh via an
  isolated subshell source so its own logging is unaffected).
- The proxy skips the daily auto-upgrade hook for the version verbs, so no
  "Auto-upgrading…" line precedes the output.
- Because this changes `bin/chosko-llm`, a pre-existing proxy only gains the
  flag after re-running `install.sh` (or one `upgrade`, which refreshes it).
