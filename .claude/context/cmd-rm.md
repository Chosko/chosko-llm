# cmd-rm

## Overview

`scripts/cmd-rm.sh` delete installed feature from `$CLAUDE_HOME`. Resolve names against **installed** state, not managed clone, and never check the source exists — a feature with no source in the managed clone (user-authored, or removed from it) is still removable.

## Public API

CLI:
- `chosko-llm rm <feature>` — `<feature>` = `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, `statusline:<name>`, or `hook:<name>`.
- `chosko-llm rm <feature> --local` / `--global` — scope, see below.
- `chosko-llm rm <feature> --force` — remove despite dependents, see below.
  Stripped from the arg list the same way `resolve_scope` strips
  `--local`/`--global`, so it may appear anywhere and never reaches the spec.
- `-h` / `--help` — usage, exit 0.

Exit codes:
- 0 success.
- 1 (via `die`) if: no arg, `<name>` ambiguous (more than one of
  command/skill/claude-md/statusline/hook installed) without prefix, nothing
  matching installed, the resolved kind is one the scope does not support
  (`statusline` with `--local`, `hook` with `--global`), or an
  installed feature still declares this one in `requires:` and `--force` was
  not passed.

Side effects:
- Commands: `rm -f` on `.md` file.
- Skills: `rm -rf` on whole skill directory.
- claude-md: `remove_section` strips managed section from
  `claudemd_target_path` (user content around preserved).
- hook: `rm -f` on `.sh` file, then warning — remind user to drop the entry
  from `hook_settings_path` too, since wiring pointing at a deleted script
  fails on every session.
- statusline: `rm -f` on `.sh` file, then warning — remind user update/remove
  `"statusLine"` key in `$CLAUDE_HOME/settings.json` if still pointing at
  deleted path.
- Logs one `Removed <kind> '<name>' (<path>) (scope: <scope>)` line.

**Scope (`--local` / `--global`).** Resolved per
[shared-lib.md](./shared-lib.md) § Scope resolution. Right after
`resolve_installed` determines `kind`, `scope_supports_kind "$kind"` gates the
removal — `die`s with `scope_violation_message` if it fails (both scope
rules: [shared-lib.md](./shared-lib.md) § Public API › Scope resolution),
before any filesystem check.

**Dependents guard (`requires:`).** Runs after the scope gate and
before any deletion. Scans the whole installed set for anything declaring
`<kind>:<name>` in `requires:` (`requires_specs` per candidate, exact-line
`grep -qxF` against the spec being removed); a feature naming itself is
skipped, or it would block its own removal forever. Non-empty result → `die`
naming every dependent and pointing at `--force`. With `--force` → same names,
as a `log_warn` about what is about to break, then the removal proceeds. A
malformed `requires:` in any scanned file aborts the whole `rm` (`die` via
command substitution) rather than deleting on a declaration nobody could read.

**Scan asymmetry — installed frontmatter, except claude-md.** Commands, skills,
statusline and hooks are scanned from `$CLAUDE_HOME`. claude-md is scanned from
the MANAGED CLONE (`$CHOSKO_LLM_HOME/claude-md/*.md`, filtered by
`claudemd_is_installed`) because `inject_section` strips frontmatter — an
installed claude-md section carries no `requires:` to read at all, so the
clone's copy of the same name is the only surviving declaration. Not an
oversight; flagged as such in the source.

**`uninstall.sh` is unaffected.** It never calls `cmd-rm` — it walks the
managed-clone listing and `rm -rf`s installed artifacts itself, so no
dependents guard applies. Correct: a bulk teardown removing everything has no
dependent left to break.

## Internal patterns

- **Resolution local, not via `resolve_feature`.** `cmd-rm.sh` parses
  `command:` / `skill:` / `claude-md:` / `statusline:` / `hook:` prefix itself
  (in `resolve_installed`), checks installed state direct
  (`inst_command_path`, `inst_skill_path`, `claudemd_is_installed`,
  `inst_statusline_path`, `inst_hook_path`). Its prefix-parsing case statement is one of the
  three parsers [shared-lib-kinds.md](./shared-lib-kinds.md) § Internal patterns keeps in
  sync.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is source of truth"; script's reliance on
  `installed_kind` over lockfile follows that.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `inst_skill_path` / `inst_skill_dir`, scope helpers
  `resolve_scope` / `scope_supports_kind` / `claudemd_target_path`.
- [shared-lib-kinds.md](./shared-lib-kinds.md) — uses `claudemd_is_installed` /
  `remove_section`, `requires_specs` (dependents guard).
- [cmd-add.md](./cmd-add.md) — inverse op.
- [cli-entry.md](./cli-entry.md) — `uninstall.sh`.

## When to read the source

- Changing disambiguation (e.g. interactive prompt instead of `die` on
  ambiguity) → `scripts/cmd-rm.sh`.
- Adding `--all` flag (currently absent — only `update` and `uninstall.sh`
  do bulk ops) → `cmd-rm.sh`.
- Changing scope behavior (scope refusal) → `resolve_scope` call and
  `scope_supports_kind` check in `cmd-rm.sh`.
- Changing the dependents guard (which kinds are scanned, where each is read
  from, self-reference handling, `--force` semantics) → the `dependents guard`
  block and `record_if_dependent` in `cmd-rm.sh`, plus `requires_specs` in
  `lib.sh`.