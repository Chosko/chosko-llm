# Shared library: scope and paths

## Overview

Covers scope resolution and path resolution in `scripts/lib.sh`: where
`CLAUDE_HOME` points for a `--local` / `--global` run, and the helpers that
assemble every source, installed and export path. The rest of `lib.sh`:
[shared-lib.md](./shared-lib.md).

## Public API

### Scope resolution
Lets a caller install into a per-project `.claude/` instead of the global
one. `ls`, `add`, `rm`, `update`, and `show` all consume it — each calls
`resolve_scope "$@"` as the first line after sourcing `lib.sh`, then re-sets
its positional parameters from `SCOPE_ARGS` before its own flag parsing runs.
Sourcing `lib.sh` without calling `resolve_scope` changes nothing.
- `CHOSKO_LLM_SCOPE` — `local` or `global`, default `global`.
- `SCOPE_ARGS` — array, empty by default. Safe to expand under `set -u` via
  `set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}` even when never assigned.
- `resolve_scope "$@"` — scans every argument for `--local` / `--global`
  (order-agnostic — the flag may appear anywhere in the arg list); `die`s if
  both appear. Sets `CHOSKO_LLM_SCOPE` and `SCOPE_ARGS` (args with the scope
  flag stripped, order and embedded whitespace preserved). In local scope,
  requires `$PWD/CLAUDE.md` to exist — `die`s naming the missing file and
  pointing at `/project-setup` otherwise — then sets
  `CLAUDE_HOME="$PWD/.claude"`, overriding any inherited `CLAUDE_HOME`. In
  global scope, `CLAUDE_HOME` is left untouched (env override still
  honoured). Local root is always `$PWD`, never a VCS query or upward walk —
  `--local` is an explicit "you are at the project root" contract.
- `scope_is_local` — 0 in local scope, 1 otherwise.
- `scope_label` — human-readable scope for log lines, e.g.
  `local (/path/to/repo/.claude)`.
- `scope_supports_kind <kind>` — 1 for the two kinds that only make sense in
  one scope, 0 for every other kind/scope combination. Two mirrored rules:
  `statusline` is GLOBAL-only (a status bar belongs to a terminal, not a repo);
  `hook` is LOCAL-only (a hook must be committed to the repo it governs — a
  cloud container clones the repo and nothing else, so a globally wired hook
  can never fire there).
- `scope_violation_message <kind>` — the `die` text for a kind
  `scope_supports_kind` just rejected. Lives in `lib.sh` so `cmd-add`,
  `cmd-rm` and `cmd-update` word both rules identically.
- `claudemd_target_path` / `claudemd_target_path_var <outvar>` (the `_var`
  form takes the local-scope parent directory with parameter expansion rather
  than `dirname`, which would put an exec back in) — the CLAUDE.md file
  claude-md artifacts read/write: `$CLAUDE_HOME/CLAUDE.md` in global scope,
  but `<cwd>/CLAUDE.md` (one directory up from `$CLAUDE_HOME`, which is
  `<cwd>/.claude` in local scope) in local scope — a project's CLAUDE.md
  lives at its root, not nested under `.claude/`. `claudemd_is_installed`,
  `claudemd_installed_version`, `inject_section`, and `remove_section` all
  call this instead of hardcoding `$CLAUDE_HOME/CLAUDE.md`, so every
  claude-md-consuming subcommand is scope-aware for free.

### Path resolution
- `feature_path_var <outvar> <root> <kind> <name>` — **the one place a
  feature's path shape is written**; assigns rather than prints ([shared-lib.md](./shared-lib.md) § Internal
  patterns), and returns non-zero on an unknown kind. Kinds: `command`,
  `skill`, `skill-dir`, `claude-md`, `statusline`, `hook`. Every named helper
  below is a printing wrapper over it.

Source paths in managed clone:
- `src_command_path <name>`  → `$CHOSKO_LLM_HOME/commands/<name>.md`
- `src_skill_path <name>`    → `$CHOSKO_LLM_HOME/skills/<name>/SKILL.md`
- `src_skill_dir <name>`     → `$CHOSKO_LLM_HOME/skills/<name>`
- `src_claudemd_path <name>` → `$CHOSKO_LLM_HOME/claude-md/<name>.md`
- `src_statusline_path <name>` → `$CHOSKO_LLM_HOME/statusline/<name>.sh`
- `src_hook_path <name>`       → `$CHOSKO_LLM_HOME/hooks/<name>.sh`
- `src_changelog_path`         → `$CHOSKO_LLM_HOME/CHANGELOG.md`. Takes no name —
  one file, not a per-feature artifact. `CHANGELOG.md` never installed into
  `$CLAUDE_HOME`, so no `inst_` twin.

Installed paths under `$CLAUDE_HOME` mirror same shape:
- `inst_command_path <name>`, `inst_skill_path <name>`, `inst_skill_dir <name>`,
  `inst_statusline_path <name>`, `inst_hook_path <name>`.
- `hook_settings_path` → `$CLAUDE_HOME/settings.json`. Hooks being local-only,
  this is always `<cwd>/.claude/settings.json` — the file that travels with
  the repo.

Export output:
- `export_dir_path` → `$CHOSKO_LLM_EXPORT_DIR` if set, else `$HOME/claude-exports`.
  Only place that path assembled; used by `cmd-export.sh`.

## Internal patterns

- **Path helpers only place** `$CHOSKO_LLM_HOME` and `$CLAUDE_HOME` should
  concatenate with subpaths (`../../CLAUDE.md` § Hard rules).

## Domain dependencies

- None beyond [shared-lib.md](./shared-lib.md) § Domain dependencies.

## Cross-references

- [shared-lib.md](./shared-lib.md) — the hub: § Internal patterns (assigning
  vs printing helpers) and the callers.
- [shared-lib-kinds.md](./shared-lib-kinds.md) — the claude-md and hook kind
  helpers that consume `claudemd_target_path` and the scope-restricted kinds.

## When to read the source

- Changing scope semantics (flag parsing, local-root marker, which kinds are
  scope-restricted) → `resolve_scope` / `scope_is_local` / `scope_label` /
  `scope_supports_kind` in `lib.sh`.
- Changing where claude-md sections read/write in local scope →
  `claudemd_target_path_var` in `lib.sh`.
  `cmd-ls.sh::scan_claudemd` mirrors `claudemd_is_installed` /
  `claudemd_installed_version` — keep them in step per
  [cmd-ls-render.md](./cmd-ls-render.md) § Internal patterns.
