# cmd-add

## Overview

`scripts/cmd-add.sh` copy one or more features from managed clone into
`$CLAUDE_HOME`. Refuse overwrite already-installed feature — for
that, use `update`.

## Public API

CLI:
- `chosko-llm add <feature> [<feature> ...]` — `<feature>` is `<name>`,
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`,
  or `hook:<name>`. One or more space-separated specs; each
  resolved/installed independently via `add_one` (see Internal patterns).
  Anything the source names in `requires:` is installed first — see
  Dependencies below.
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
  missing required frontmatter, target already installed, a kind the scope
  does not support (`statusline` with `--local`, `hook` with `--global`), a
  malformed `requires:` entry, or a
  requirement that could not be installed) — best-effort: each failure logs
  via `log_error` (through `die` inside the per-name subshell) and the other
  names in the same invocation still run.

Side effects:
- Creates `$CLAUDE_HOME/commands/` or `$CLAUDE_HOME/skills/` if missing.
- Commands: copies one `.md` file.
- Skills: recursive copy (`cp -R`) of the entire skill directory, so
  supporting files alongside `SKILL.md` ride along (the authoring guide
  documents this for skill authors).
- claude-md: injects managed section into `claudemd_target_path` via
  `inject_section` (no file copy); refuses if section already exists.
- Hook: copies `.sh` file to `$CLAUDE_HOME/hooks/<name>.sh`, `chmod +x`'s it,
  then calls `print_hook_prompt` for the settings.json wiring. Validated by
  `require_hook_source` on top of `require_versioned_source`: no `event:` in
  frontmatter, no install.
- Statusline: copies `.sh` file to `$CLAUDE_HOME/statusline/<name>.sh`,
  `chmod +x`'s it, then calls `print_statusline_prompt` — no settings.json
  edit here.
- Logs single `Installed <kind> '<name>' v<version> -> <path> (scope:
  <scope>)` line.

**Scope: two mirrored kind rules.** Scope flags are resolved before any other
flag parsing, and the kinds each scope supports are defined, in
[shared-lib.md](./shared-lib.md) § Public API › Scope resolution.
Single-feature path: after `resolve_feature` returns `kind`,
`scope_supports_kind "$kind"` gates the install, and on failure it `die`s via
`scope_violation_message "$kind"`, which words both the statusline-global-only
and hook-local-only rules. The `--all` path guards the statusline pass with
`scope_is_local` and the hook pass with `! scope_is_local`, logging one info
line and skipping rather than failing the run.

**Dependencies (`requires:`).** Single-feature path only: `--all` does no
`requires:` resolution and needs none — it installs every feature in the
clone, so every requirement is satisfied incidentally, and copy order is
irrelevant because a feature resolves its requirement's path when an agent
runs it, not when it is installed; a comment above the `--all` branch says
so, so nobody adds resolution there. `install_requires <kind> <name>` runs
between validation and copy (ordering: § Internal patterns). Reads the
source's `requires:` via `requires_specs` (command substitution, so its `die`
on a malformed entry aborts the dependent too), then per spec:
- Already installed (`artifact_is_installed`) → one info line, skipped.
- Not installed → info line, then **recursive `add_one "$spec"`** — not a
  second install path. That reuse is why a requirement gets the same scope,
  the same `scope_supports_kind` rule and the same `scope_violation_message`
  wording as anything else. Failure `die`s the dependent naming the spec.
- Missing from the managed clone → `resolve_feature` fails inside the nested
  `add_one`, which fails, which `die`s the dependent. Nothing copied for it.

**One level deep, deliberately.** A requirement's own `requires:` is not
followed; flagged in the source comment as a thing not to "fix" later.

- Single-feature path only: after install, `apply_replaces` honours the
  source's optional `replaces: <kind>:<name>` (behaviour:
  [shared-lib.md](./shared-lib.md) § Public API › Kind migration). `--all`
  loop does **not** call it; a stale artifact left that way is picked up by
  `update --all`'s migration path.

## Internal patterns

- **Resolution delegated** to `resolve_feature` in
  [shared-lib.md](./shared-lib.md). Script never parses
  `command:` / `skill:` prefix itself.
- **Validation precedes copy, and requirements sit between the two.**
  `require_versioned_source` runs before any filesystem mutation —
  missing-frontmatter source cannot half-install. `install_requires` runs
  inside `add_one`'s subshell after the validations that can refuse the
  feature (scope gate, `require_versioned_source`, `require_hook_source`) and
  before the `case` that copies anything, so a feature those refuse neither
  copies nor drags its dependencies onto the machine. The "already installed"
  refusal is the exception: it lives in the `case` branch and fires *after*
  requirements were resolved, so re-adding an installed feature can install a
  missing requirement before failing.
- **Refuses to clobber.** If target file/dir exists, `die`s with pointer to `chosko-llm update`. Contract distinguishes `add` from `update` — keep
  it.
- **Per-name isolation via subshell.** `add_one` wraps its
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
- Changing scope behavior (scope refusal, `--all` skip logic) →
  `resolve_scope` call, `scope_supports_kind` check, and the `--all`
  statusline block in `cmd-add.sh`.