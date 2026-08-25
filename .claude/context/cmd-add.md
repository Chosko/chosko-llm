# cmd-add

## Overview

`scripts/cmd-add.sh` copy one or more features from managed clone into
`$CLAUDE_HOME`. Refuse overwrite already-installed feature — for
that, use `update`.

## Public API

CLI:
- `chosko-llm add <feature> [<feature> ...]` — `<feature>` is `<name>`,
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`,
  or `hook:<name>`. One or more space-separated specs (task 105);
  each resolved/installed independently via `add_one` (function, runs
  each name in its own subshell so an internal `die` aborts only that
  name — see Internal patterns). Anything the source names in `requires:`
  is installed first (task 125) — see Dependencies below.
- `chosko-llm add --all` — install every feature in managed clone
  (commands, skills, claude-md artifacts, statusline scripts, AND hooks) not
  yet installed; already-installed skipped with info log. Dies if
  combined with any explicit feature name (checked before the `--all`
  branch runs).
- `chosko-llm add <feature> --local` / `--global` — scope, see below.

Exit codes:
- 0 if every name succeeded (or `--all` with nothing new to install).
- 1 if `--all` combined with explicit names, no argument, or **any**
  name in the list failed (feature not in managed clone, source
  missing required frontmatter, target already installed, a
  `statusline` request with `--local`, a malformed `requires:` entry, or a
  requirement that could not be installed) — best-effort: other names in
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
- Hook: copies `.sh` file to `$CLAUDE_HOME/hooks/<name>.sh` (i.e.
  `<cwd>/.claude/hooks/` — hooks are local-only), `chmod +x`'s it, then calls
  `print_hook_prompt` for the settings.json wiring. Validated by
  `require_hook_source` on top of `require_versioned_source`: no `event:` in
  frontmatter, no install.
- Statusline: copies `.sh` file to `$CLAUDE_HOME/statusline/<name>.sh`,
  `chmod +x`'s it, then calls `print_statusline_prompt` — prints
  copy-pasteable prompt for wiring `"statusLine"` key in
  `$CLAUDE_HOME/settings.json` — no settings.json edit here. Global-only:
  never reachable in local scope (see below).
- Logs single `Installed <kind> '<name>' v<version> -> <path> (scope:
  <scope>)` line.

**Scope: two mirrored kind rules.** `statusline` is global-only, `hook` is
local-only. Single-feature path `die`s via `scope_violation_message "$kind"`,
which words both rules; the `--all` path guards the statusline pass with
`scope_is_local` and the hook pass with `! scope_is_local`, logging one info
line and skipping rather than failing the run.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`;
existing flag parsing runs unchanged on the cleaned arguments. No flag =
`--global`, byte-identical to pre-103 behavior. Single-feature path: after
`resolve_feature` returns `kind`, `scope_supports_kind "$kind"` gates the
install — `die`s naming statusline global-only if it fails. `--all` path:
the statusline block is guarded by `scope_is_local` — in local scope it
logs one info line and skips the whole pass rather than failing the run;
in global scope it behaves as before.
**Dependencies (`requires:`).** Single-feature path only. `install_requires
<kind> <name>` runs inside `add_one`'s subshell AFTER every validation that
can refuse the feature (scope gate, `require_versioned_source`,
`require_hook_source`) and BEFORE the `case` that copies anything — so nothing
is copied for a feature that was going to be refused, and no requirement is
installed for a feature that cannot itself be installed. Reads the source's
`requires:` via `requires_specs` (command substitution, so its `die` on a
malformed entry aborts the dependent too), then per spec:
- Already installed (`artifact_is_installed`) → one info line, skipped.
- Not installed → info line, then **recursive `add_one "$spec"`** — not a
  second install path. That reuse is why a requirement gets the same scope,
  the same `scope_supports_kind` rule and the same `scope_violation_message`
  wording as anything else. Failure `die`s the dependent naming the spec.
- Missing from the managed clone → `resolve_feature` fails inside the nested
  `add_one`, which fails, which `die`s the dependent. Nothing copied for it;
  other names in the outer loop still run, exit code 1.

**One level deep, deliberately.** A requirement's own `requires:` is not
followed; flagged in the source comment as a thing not to "fix" later.

**`--all` does no `requires:` resolution and needs none** — it installs every
feature in the clone, so every requirement is satisfied incidentally, and copy
order is irrelevant because a feature resolves its requirement's path when an
agent runs it, not when it is installed. Stated in a comment above the `--all`
branch so nobody adds resolution there.

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
- **Validation precedes copy, and requirements sit between the two.**
  `require_versioned_source` runs before any filesystem mutation —
  missing-frontmatter source cannot half-install. `install_requires` runs
  after it and before the copy, for the same reason one step down: a feature
  that will be refused must not drag its dependencies onto the machine first.
  Note the ordering consequence — the "already installed" refusal lives in the
  `case` branch, so it fires *after* requirements were resolved; re-adding an
  installed feature can install a missing requirement before failing.
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
  `require_versioned_source`, `requires_specs` / `parse_replaces_spec` /
  `artifact_is_installed` (the dependency path), `src_*` / `inst_*` path
  helpers, scope helpers `resolve_scope` / `scope_supports_kind` /
  `claudemd_target_path`.
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
- Changing dependency-install behavior (depth, ordering relative to
  validation/copy, what an unresolvable requirement does, whether `--all`
  resolves) → `install_requires` and its call site inside `add_one` in
  `cmd-add.sh`, plus `requires_specs` in `lib.sh`.
- Changing `--all` enumeration or skip logic → `--all` block in `cmd-add.sh`.
- Changing scope behavior (statusline refusal, `--all` skip logic) →
  `resolve_scope` call, `scope_supports_kind` check, and the `--all`
  statusline block in `cmd-add.sh`.