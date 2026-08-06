# cmd-add

## Overview

`scripts/cmd-add.sh` copy one or more features from managed clone into
`$CLAUDE_HOME`. Refuse overwrite already-installed feature — for
that, use `update`.

## Public API

CLI:
- `chosko-llm add <feature> [<feature> ...]` — `<feature>` is `<name>`,
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, or
  `statusline:<name>`. One or more space-separated specs (task 105);
  each resolved/installed independently via `add_one` (function, runs
  each name in its own subshell so an internal `die` aborts only that
  name — see Internal patterns).
- `chosko-llm add --all` — install every feature in managed clone
  (commands, skills, claude-md artifacts, AND statusline scripts) not
  yet installed; already-installed skipped with info log. Dies if
  combined with any explicit feature name (checked before the `--all`
  branch runs).
- `chosko-llm add <feature> --local` / `--global` — scope, see below.

Exit codes:
- 0 if every name succeeded (or `--all` with nothing new to install).
- 1 if `--all` combined with explicit names, no argument, or **any**
  name in the list failed (feature not in managed clone, source
  missing required frontmatter, target already installed, or a
  `statusline` request with `--local`) — best-effort: other names in
  the same invocation still run; each failure logs via `log_error`
  (through `die` inside the per-name subshell) and the run continues.

Side effects:
- Creates `$CLAUDE_HOME/commands/` or `$CLAUDE_HOME/skills/` if missing
  (`$CLAUDE_HOME` is `<cwd>/.claude` in local scope).
- Commands: copies one `.md` file.
- Skills: recursive copy (`cp -R`) of entire skill directory.
- claude-md: injects managed section into `claudemd_target_path` via
  `inject_section` (no file copy); refuses if section already exists.
  `claudemd_target_path` is `$CLAUDE_HOME/CLAUDE.md` globally but
  `<cwd>/CLAUDE.md` in local scope (task 103).
- Statusline: copies `.sh` file to `$CLAUDE_HOME/statusline/<name>.sh`,
  `chmod +x`'s it, then calls `print_statusline_prompt` — prints
  copy-pasteable prompt for wiring `"statusLine"` key in
  `$CLAUDE_HOME/settings.json` — no settings.json edit here. Global-only:
  never reachable in local scope (see below).
- Logs single `Installed <kind> '<name>' v<version> -> <path> (scope:
  <scope>)` line.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`;
existing flag parsing runs unchanged on the cleaned arguments. No flag =
`--global`, byte-identical to pre-103 behavior. Single-feature path: after
`resolve_feature` returns `kind`, `scope_supports_kind "$kind"` gates the
install — `die`s naming statusline global-only if it fails. `--all` path:
the statusline block is guarded by `scope_is_local` — in local scope it
logs one info line and skips the whole pass rather than failing the run;
in global scope it behaves as before.
- Single-feature path only: after install, `apply_replaces` honours the
  source's optional `replaces: <kind>:<name>` — removes that artifact if
  installed, logs `Migrated <old-kind> '<name>' -> <new-kind> '<name>'`.
  Silent when key absent or old artifact not installed. `--all` loop does
  **not** call it; a stale artifact left that way is picked up by
  `update --all`'s migration path.

## Internal patterns

- **Resolution delegated** to `resolve_feature` in
  [shared-lib.md](./shared-lib.md). Script never parses
  `command:` / `skill:` prefix itself.
- **Validation precedes copy.** `require_versioned_source` runs before any
  filesystem mutation — missing-frontmatter source cannot half-install.
- **Refuses to clobber.** If target file/dir exists, `die`s with
  pointer to `chosko-llm update`. Contract distinguishes
  `add` from `update` — keep it.
- **Skills copy recursively.** Any supporting files alongside `SKILL.md`
  ride along. Authoring guide documents this for skill authors.
- **Per-name isolation via subshell (task 105).** `add_one` wraps its
  whole body in `( ... )` so any `die` inside — `resolve_feature`,
  `require_versioned_source`, the "already installed" checks —
  terminates only that subshell, not the parent script; the caller's
  `for spec in "$@"` loop keeps going and tracks a `failed` flag.
  `resolve_feature` failure is doubly nested (its own `die` fires
  inside the `<(...)` process substitution feeding `mapfile`), so
  `add_one` explicitly checks `kind`/`name` came back non-empty rather
  than relying on `mapfile` raising an error.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter contract
  `require_versioned_source` enforces lives here.
- `../../CLAUDE.md` — "copy, never symlink" hard rule.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, `src_*` / `inst_*` path helpers, scope
  helpers `resolve_scope` / `scope_supports_kind` / `claudemd_target_path`.
- [cmd-update.md](./cmd-update.md) — "refresh / reinstall" counterpart;
  `update` installs if missing, usable in place of `add`.
- [cmd-rm.md](./cmd-rm.md) — inverse operation.

## When to read the source

- Changing "already installed → error" policy (e.g. adding `--force`
  flag) → `scripts/cmd-add.sh`.
- Changing multi-name looping or best-effort/continue-on-error
  semantics → `add_one` function and the trailing `for spec in "$@"`
  loop in `cmd-add.sh`.
- Changing what gets copied for skill (e.g. excluding patterns) →
  `cp -R` call in `skill)` branch and `--all` loop of `cmd-add.sh`.
- Tweaking success log line format → `cmd-add.sh`.
- Changing kind-migration behavior on install → `apply_replaces` call after
  the `esac` in `cmd-add.sh`, and `apply_replaces` in `lib.sh`.
- Changing `--all` enumeration or skip logic → `--all` block in `cmd-add.sh`.
- Changing scope behavior (statusline refusal, `--all` skip logic) →
  `resolve_scope` call, `scope_supports_kind` check, and the `--all`
  statusline block in `cmd-add.sh`.