# cmd-update

## Overview

`scripts/cmd-update.sh` re-copy one or more features from managed clone into
`$CLAUDE_HOME`, replace whatever there. Install if missing —
unlike `add`, no refuse on absence.

## Public API

CLI:
- `chosko-llm update <feature> [<feature> ...]` — one or more
  space-separated specs, same spec syntax as `add` (`<name>`,
  `command:`/`skill:`/`claude-md:`/`statusline:`/`hook:` prefixed). Each name
  resolved/updated independently via `update_one_spec` (see Internal
  patterns); install if missing.
- `chosko-llm update --all` — iterate installed commands
  (`$CLAUDE_HOME/commands/*.md`), skills (`$CLAUDE_HOME/skills/*/`),
  claude-md sections (markers in `claudemd_target_path`), hooks
  (`$CLAUDE_HOME/hooks/*.sh`, skipped entirely in GLOBAL scope — the mirror
  rule), statusline scripts (`$CLAUDE_HOME/statusline/*.sh`; in local scope
  the whole pass is skipped up front with one info log), update only those
  whose managed-clone source version **newer** than installed.
- `chosko-llm update <feature> --local` / `--global` — scope, see below.

Exit codes:
- 0 if every name succeeded, including `--all` with nothing to update — an
  `--all` skip is a warning, never an error, so a run that skipped every
  candidate still exits 0.
- 1 if `--all` combined with explicit names, no argument, or **any**
  name in the list failed (missing source, missing/invalid frontmatter,
  or a kind the scope does not support: `statusline` with `--local`, `hook`
  with `--global`) — best-effort: each failure logs via `log_error`
  (through `die` inside the per-name subshell) and other names in the same
  invocation still run.

Side effects:
- Single feature: delete existing target (`rm -f` for command/statusline/hook,
  `rm -rf` for skill), copy fresh (`chmod +x` for statusline and hook);
  a hook prints its settings.json wiring prompt when it was NOT already
  installed, and ALSO when its `event:` / `matcher:` changed — re-copying a
  script cannot re-wire JSON, so a body-only change stays quiet but a moved
  hook would otherwise fire on the wrong tool or not at all. The installed
  copy's own frontmatter is read BEFORE the overwrite; it is the only record
  of what was merged into settings.json, which has no version. The warning
  names both slots via `hook_wiring_label`;
  claude-md re-inject via `inject_section` into `claudemd_target_path`.
  Then `apply_replaces` (see [shared-lib.md](./shared-lib.md) § Kind
  migration).
- `--all`: per installed feature, compare versions with `version_cmp`,
  log `Already up-to-date` (equal), `Local version ahead … — skipping`
  (installed newer), or update (source newer). When source disappeared,
  try `migrate_stale` first (below); only on no replacement emit
  `Skipping <kind> '<base>': no source in managed clone.`.
  `Skipping … version unreadable` when version unparseable.
- One `Updated <kind> '<name>' -> v<version> (scope: <scope>)` log line
  per actual update.

**Scope (`--local` / `--global`).** Resolved per
[shared-lib.md](./shared-lib.md) § Scope resolution. Single-feature path:
after `resolve_feature` returns `kind`, `scope_supports_kind "$kind"` gates
the update — `die`s with `scope_violation_message` if it fails (both scope
rules: [shared-lib.md](./shared-lib.md) § Public API › Scope resolution),
before `update_one` runs.

## Internal patterns

- **Replace, not merge.** A file removed from the source skill folder
  disappears from the installed one. By design.
- **Validation before mutation.** Same `require_versioned_source` guard as
  `cmd-add`.
- **`--all` version-aware.** `version_cmp` (awk semver comparator,
  expects `x.y.z`) gates each update; logs `Nothing to update.` only when
  no candidates touched.
- **Single-feature path uses `resolve_feature`** (managed clone).
- **Per-name isolation via subshell.** `update_one_spec`
  wraps `resolve_feature` + `scope_supports_kind` + `update_one` +
  `apply_replaces` in `( ... )` so any `die` inside terminates only that
  subshell; the caller's `for spec in "$@"` loop keeps going and tracks
  a `failed` flag. Same pattern as `cmd-add.sh`'s `add_one` — see that
  file's Internal patterns for the `resolve_feature`/`mapfile`
  double-nesting note.
- **`migrate_stale <kind> <name>`** (script-local, defined above
  `version_cmp`). Calls `find_replacement`; on hit runs `update_one` for the
  replacement then `apply_replaces` to drop the stale artifact, and sets
  `any=1`. Returns 1 on no hit so the `elif` falls through to the no-source
  warning. Globs expand before the loop body runs, so deleting the current
  entry mid-loop is safe.

## Domain dependencies

- `../../docs/authoring-guide.md` — versioning rules. `update --all` is
  user's primary mechanism for picking up new versions; an unbumped
  `version` makes `update --all` skip the feature as up-to-date — only an
  explicit `update <name>` re-copies it.
- `../../CLAUDE.md` — "filesystem is source of truth".

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, path helpers, scope helpers `resolve_scope` /
  `scope_supports_kind` / `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) — installs-only-if-absent counterpart.
- [cmd-upgrade.md](./cmd-upgrade.md) — typical user flow:
  `upgrade` (refresh source) then `update --all` (refresh installs).

## When to read the source

- Change `--all` version-comparison semantics → `version_cmp` and
  per-kind `--all` blocks in `scripts/cmd-update.sh`.
- Change kind-migration behavior on `--all` → `migrate_stale` in
  `cmd-update.sh` and `find_replacement` / `apply_replaces` in `lib.sh`.
- Change skill-update merge vs. replace behavior → `skill)` branch's
  `rm -rf && cp -R` in `cmd-update.sh`.
- Add `--dry-run` → `cmd-update.sh`.
- Changing multi-name looping or best-effort/continue-on-error
  semantics → `update_one_spec` function and the trailing
  `for spec in "$@"` loop in `cmd-update.sh`.
- Change scope behavior (scope refusal/skip) → `resolve_scope` call,
  `scope_supports_kind` check, and the `--all` statusline block in
  `cmd-update.sh`.
