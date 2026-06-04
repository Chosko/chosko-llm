# Smoke test: auto-upgrade

**Type:** CLI feature
**Source:** bin/chosko-llm, scripts/auto-upgrade.sh, scripts/lib.sh,
scripts/cmd-upgrade.sh, install.sh

## Setup

- `install.sh` has been run (managed clone exists at `~/.chosko-llm`).
- The state file lives at `$CHOSKO_LLM_HOME/.auto-upgrade-state` (default
  `~/.chosko-llm/.auto-upgrade-state`).

## Scenarios

### 1. Install opts the user in

1. Run `install.sh` on a machine with no prior state file.
2. Inspect `~/.chosko-llm/.auto-upgrade-state`. It exists and contains
   `enabled=true` and a `last_run=<today's date>` line (YYYY-MM-DD).
3. The installer prints a line noting auto-upgrade is enabled and how to
   disable it.

### 2. State file is gitignored

1. From inside `~/.chosko-llm`, run `git status --porcelain`.
2. `.auto-upgrade-state` does NOT appear (it is ignored), so
   `chosko-llm upgrade`'s `git pull --ff-only` is never blocked by it.

### 3. First command of the day auto-upgrades

1. Edit the state file so `last_run` is an earlier date (e.g. yesterday) and
   `enabled=true`.
2. Run any non-upgrade command, e.g. `chosko-llm ls`.
3. Before the `ls` output, an "Auto-upgrading…" line appears and a
   `git pull` runs. After it, in an interactive terminal, a suggestion notes
   it can be disabled (`chosko-llm upgrade --disable-auto`).
4. The state file's `last_run` is now today's date.
5. Run `chosko-llm ls` again the same day — NO second auto-upgrade fires
   (already ran today).

### 4. `last_run` is stamped before the upgrade

1. Simulate a failing upgrade (e.g. temporarily make the managed clone's
   remote unreachable) with `last_run` set to yesterday.
2. Run `chosko-llm ls`. The upgrade fails but the command still completes,
   and `last_run` is updated to today — so subsequent commands that day do
   NOT keep retrying the failing upgrade.

### 5. `upgrade`/`help`/empty never auto-upgrade (no recursion)

1. With `last_run` set to yesterday, run `chosko-llm upgrade`. It performs a
   single normal upgrade — it does NOT trigger a nested auto-upgrade.
2. `chosko-llm help` and `chosko-llm` (no args) do not trigger an
   auto-upgrade either.

### 6. Missing state file defaults to enabled

1. Delete `~/.chosko-llm/.auto-upgrade-state`.
2. Run a non-upgrade command. Auto-upgrade is treated as enabled (opt-in
   default): it fires (once) and recreates the state file.

### 7. Toggle flags are toggle-only

1. Run `chosko-llm upgrade --disable-auto`. It reports auto-upgrade disabled,
   sets `enabled=false`, and does NOT perform a pull/upgrade.
2. Run `chosko-llm upgrade --enable-auto`. It reports enabled, sets
   `enabled=true`, and does NOT perform a pull/upgrade.
3. Run `chosko-llm upgrade --enable-auto --disable-auto`. It stops with
   "`--enable-auto and --disable-auto cannot be combined. Pick one.`" and
   changes nothing.

### 8. Opt-in tip on manual upgrade when disabled

1. With `enabled=false`, run a plain `chosko-llm upgrade` (no flags).
2. After the upgrade, in an interactive terminal, a tip suggests enabling
   daily auto-upgrade (`chosko-llm upgrade --enable-auto`).
3. With `enabled=true` (the default), the same plain upgrade prints NO such
   tip.

### 9. `CHOSKO_LLM_NO_AUTO_UPGRADE` escape hatch

1. With `enabled=true` and `last_run` set to yesterday, run
   `CHOSKO_LLM_NO_AUTO_UPGRADE=1 chosko-llm ls`.
2. No auto-upgrade fires; `last_run` is unchanged. Useful for CI /
   non-interactive use.

## Expected (cross-cutting)

- Auto-upgrade fires at most once per calendar day, only when enabled, and
  never for `upgrade`/`help`/empty subcommands.
- The automatic run never aborts the user's actual command — a failed
  upgrade is surfaced as a warning and the command still runs.
- Suggestion / tip text is shown only on an interactive terminal; the
  automatic `git pull` itself runs regardless of TTY (unless
  `CHOSKO_LLM_NO_AUTO_UPGRADE` is set).
- `--enable-auto` / `--disable-auto` only change the stored preference; they
  never perform an upgrade.

## Notes

- The proxy `bin/chosko-llm` changed, so existing users only gain the hook
  after one `chosko-llm upgrade` (which refreshes the proxy) or re-running
  `install.sh`. New users get it at install.
