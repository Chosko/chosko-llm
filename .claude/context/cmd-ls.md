# cmd-ls

## Overview

`scripts/cmd-ls.sh` list features visible in managed clone or `$CLAUDE_HOME`, installed version + latest (managed-clone) version side by side.

## Public API

CLI:
- `chosko-llm ls` — all features.
- `chosko-llm ls --installed` — only features w/ installed version.
- `chosko-llm ls --available` — only features present in managed clone.
- `chosko-llm ls --all` — same as no flag.
- `chosko-llm ls --local` / `--global` — scope, see below.
- `-h` / `--help` — print local usage, exit 0.
- Any other flag → `die`.

Output: `Home: <scope_label>` line, blank line, then text table, header
`NAME KIND INSTALLED LATEST STATUS`. `KIND` is `command`, `skill`,
`claude-md`, or `statusline`. Missing values render `—`. Installed file w/
no `version` frontmatter shows `unversioned`. On interactive terminal,
suggestions block follows table (install / update hints, plus
always-present `show` inspect hint); suppressed when stdout piped or
redirected.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`, so
the rest of the script's flag parsing is unaware scope flags ever existed.
No flag = `--global`, byte-identical to pre-103 behavior. `--local` repoints
`CLAUDE_HOME` at `<cwd>/.claude` (`resolve_scope` in `lib.sh`, task 102) and
requires `<cwd>/CLAUDE.md`. `list_all` prints `scope_label` above the table.
In local scope, the statusline listing pass is skipped entirely (wrapped in
`if ! scope_is_local`) — statusline is global-only. The claude-md pass reads
`claudemd_target_path` (task 103, in `lib.sh`) instead of a hardcoded
`$CLAUDE_HOME/CLAUDE.md`, since local scope's claude-md target is
`<cwd>/CLAUDE.md`, not `<cwd>/.claude/CLAUDE.md`.

## Internal patterns

- **Four-pass listing**: commands, then skills, then claude-md artifacts,
  then statusline scripts. Names within each pass sorted + deduped across
  two homes (managed clone + `$CLAUDE_HOME`). claude-md "installed" state
  detected by managed section markers in `$CLAUDE_HOME/CLAUDE.md`, not file;
  statusline plain file check like commands/skills.
- **No version comparison.** `cmd-ls` only prints two version strings
  side by side; no `[new]` / `[upgradable]` markers.
- **Filenames are the truth.** File named `foo.md` w/ frontmatter
  `name` is `bar` listed as `foo` (basename) — matches what
  `cmd-add` / `cmd-update` resolve against. Authoring guide warns
  against this mismatch.
- **Footer suggestions TTY-gated.** After table, `cmd-ls` prints
  actionable hints on stdout only when stdout is terminal (`[ -t 1 ]`);
  piped/redirected output stays clean table. Block contains `add`
  hint for installable features, `update` hint for outdated ones (or
  `Everything is up to date.` when neither applies), ALWAYS ends w/
  `Run 'chosko-llm show <feature>' to inspect a feature.` Installable +
  updatable names accumulated from filtered rows during three
  listing passes — counts reflect what actually shown.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is source of truth, no lockfile". Script
  implements that by walking both directories.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `src_command_path`, skill equivalents, `read_frontmatter_field`, and
  scope helpers `resolve_scope` / `scope_is_local` / `scope_label` /
  `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — features
  `ls` shows produced/consumed by these.
- [cmd-show.md](./cmd-show.md) — single-feature deep-dive footer's
  inspect hint points at; shares status/kind vocabulary.

## When to read the source

- Changing column layout, filter flags, output formatting →
  `scripts/cmd-ls.sh`.
- Changing how names deduped across two homes → `collect_names`
  function in `cmd-ls.sh`.
- Changing scope behavior (home line, statusline omission, claude-md
  target) → `resolve_scope` call and `list_all` in `cmd-ls.sh`.