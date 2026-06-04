# Smoke test: cmd-uninstall

**Type:** CLI command
**Source:** scripts/cmd-uninstall.sh → uninstall.sh

## Setup

- `install.sh` has been run: proxy at `~/bin/chosko-llm`, managed clone at
  `~/.chosko-llm`, and at least one feature installed under `~/.claude/`.
- Do these checks in a throwaway environment (or with `CHOSKO_LLM_HOME` /
  `CLAUDE_HOME` / `BIN_DIR` pointed at scratch dirs) — the flow deletes things.

## Steps

1. Run `chosko-llm uninstall` and answer **N** to the first prompt.
2. Run `chosko-llm uninstall` again; answer **y** to the top-level prompt,
   then **N** to the "remove installed features" and "remove managed clone"
   prompts.
3. Re-install (`install.sh`), then run `chosko-llm uninstall` and answer **y**
   to every prompt.
4. Re-install, then run `chosko-llm uninstall -y` (and once more with `--yes`).
5. Run `chosko-llm uninstall -h` (or `--help`).
6. From a working copy, run `./uninstall.sh` directly and answer **N** first.

## Expected

1. Nothing is removed — not even the proxy. Prints "Aborted — nothing was
   changed." and exits 0. `~/bin/chosko-llm` still works.
2. The proxy (and `chosko-llm.cmd` on Windows) is removed; installed features
   and the managed clone are left in place.
3. Proxy removed, all matching features removed from `~/.claude/` (user-authored
   files untouched), and the managed clone at `~/.chosko-llm` removed. Ends with
   "Done." even though the clone it ran from was deleted (the script was exec'd,
   so the running process keeps its handle).
4. Same full teardown as step 3 but with no prompts at all — every step is
   auto-confirmed. Both `-y` and `--yes` behave identically.
5. Prints a short usage block on stdout and exits 0 without removing anything.
6. Same behavior as step 1 via the proxy — the standalone script and
   `chosko-llm uninstall` share one implementation.

## Notes

- `cmd-uninstall.sh` is a thin wrapper: it resolves the repo root from its own
  location and `exec`s `uninstall.sh "$@"`. It deliberately does NOT source
  `lib.sh` (uninstall must run while the clone is being torn down).
- The proxy skips the daily auto-upgrade hook for `uninstall`, so no
  "Auto-upgrading…" line appears before the teardown.
- The top-level confirmation closes the old gap where the proxy was removed
  unconditionally; `git status`/feature deletion prompts still apply on top.
