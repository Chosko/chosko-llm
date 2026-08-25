# cmd-changelog

## Overview

`scripts/cmd-changelog.sh` — read-only view onto managed clone's `CHANGELOG.md`.
No arg opens whole file in user's editor; `--since <value>` prints selected
sections to **stdout**. Never pulls, never writes, never touches `$CLAUDE_HOME`.

Complements [cmd-upgrade.md](./cmd-upgrade.md)'s readout, which covers only
versions one pull moved through. This is user asking for whole file, or for
range of own choosing.

## Public API

CLI:
- `chosko-llm changelog` — open `$CHOSKO_LLM_HOME/CHANGELOG.md` in editor.
- `chosko-llm changelog --since <value>` / `--since=<value>` — print sections
  from that point forward, stdout.
- `chosko-llm changelog --print` — full file to stdout, no editor, no pager.
  Composes w/ `--since`: forces that range out unpaged.
- `chosko-llm changelog -h` / `--help` — one usage line, exit 0.

`--since <value>` auto-detected, three disjoint forms — no flag per form:
- version `1.10.0` — that section and everything newer, **inclusive**.
- date `2026-08-01` — every section whose header date on or after it.
- duration `30d` / `2w` / `6mo` / `1y` — same, counted back from today.

Exit codes:
- 0 on success, **including a `--since` matching no section** (says so via
  `log_info` on stderr, prints nothing to stdout).
- 1 (via `die`) on unknown argument, `--since` w/o value, unparseable `--since`
  (message names all three forms), unresolvable duration, or missing
  `CHANGELOG.md` in clone.

Env read: `VISUAL`, `EDITOR`, `PAGER`, `NO_COLOR`, `LINES`.

## Internal patterns

- **Colour captured from ORIGINAL stdout, before anything redirects it.**
  `STDOUT_WAS_TTY` set at top of script, `_changelog_use_color` closes over it,
  and that predicate is what's handed to the renderer. Deciding from write fd
  would strip every escape in exactly the pager case, since fd 1 is a pipe
  there. Don't "simplify" this into `_use_color_stdout`.
- **Renderer shared w/ `upgrade`, gate is not.** Layout comes from
  `_render_changelog_sections` in `lib.sh` — same two-space version indent,
  four-space bullets, blank line between sections and after block, bold version
  / dim ` — <date>` / accent ASCII `- ` marker. Only difference from
  `upgrade`'s block is which stream + which colour predicate.
- **Filtered output on stdout, deliberately.** `--since` output is the
  command's product and must pipe into `grep`; `upgrade`'s readout stays on
  stderr because it's commentary on another action. Every diagnostic here
  (no-match notice, errors) goes to stderr, so stdout stays greppable.
- **Paged only on overflow, only on TTY, never under `--print`.** Block
  rendered into variable first, measured against `terminal_height`, then either
  written straight out (no child process) or piped to `$PAGER`, else `less -R`.
  Short range — common case — never pushes user into `less` for four lines; a
  pipe or redirect stays plain stream whatever the length. Default pager
  carries `-R` so escapes pass through.
- **Command substitution strips block's trailing blank line; script puts it
  back** (`"$(...)"$'\n'`), so the block is byte-identical to `upgrade`'s.
- **Editor chain degrades, never refuses.** `$VISUAL` → `$EDITOR` →
  `git var GIT_EDITOR` → `less -R` → `cat`. Bare git-bash on Windows commonly
  has neither variable; erroring would fail first run on repo's primary
  platform. `git var GIT_EDITOR` answers even when nothing configured — that's
  the point, not a bug.
- **Whole interactive chain gated on `[ -t 1 ]`.** Non-TTY stdout takes the
  `cat` path, so `chosko-llm changelog | head` never launches an editor into a
  pipe. `--print` short-circuits the same way.
- **Editor + pager both invoked through `sh -c`, not word-split.** That's git's
  own contract for `GIT_EDITOR` — it runs the value via `sh -c` — so the
  configured string may carry flags (`code -w`) *and* quoting, which is the form
  git writes on Windows (`'"C:\Program Files\...\code" --wait'`). Plain
  `exec $editor` handles the flags and mangles the quoted path into a
  nonexistent `argv[0]`, and since `exec` replaces the process, the `less` /
  `cat` fallbacks below can't catch it. Don't "simplify" either call back to a
  bare word-split.
- **Pager failure falls through to plain output, never swallows.** Pipeline
  status is inspected instead of blanket `|| true`: 126/127 mean the pager
  couldn't run at all, so the block is written out plainly; every other status
  (incl. the 141 `pipefail` reports when a reader quits early and SIGPIPEs the
  `printf`) means it ran. An unusable `$PAGER` must never cost the user the
  output they asked for.
- **`--since` given-ness tracked separately from its value** (`since_given`).
  `--since=` with an empty value is a malformed request, not an absent one: it
  takes the same `die` as `banana`, rather than falling through to the
  whole-file view a bare `changelog` gets.
- **Missing `CHANGELOG.md` dies here, unlike in `upgrade`** which is silent
  about it. Silence is right when the readout is a side effect of another
  action; wrong when the file is the thing the user asked for.
- **Not scope-aware.** No `resolve_scope` call — `CHANGELOG.md` lives in the
  managed clone and is never installed, so `--local` / `--global` mean nothing
  here.

## Domain dependencies

- `../domain/features/version-changelog.md` — the feature this extends: the
  file's schema, its descending-semver ordering, the maintenance rule, and the
  `upgrade` readout this subcommand shares a renderer with.
- `../../CHANGELOG.md` — the file being read. Parser contract: `^## `
  introduces a section, first whitespace-delimited token after it is the
  version, everything until next `^## ` is the body, anything above the first
  `## ` is preamble and never printed.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `src_changelog_path`,
  `_render_changelog_sections`, `changelog_since_kind`,
  `changelog_duration_to_date`, `select_changelog_sections`,
  `terminal_height`. All selection and rendering lives there; this script is
  argument parsing, stream choice and delivery.
- [cmd-upgrade.md](./cmd-upgrade.md) — the other consumer of the renderer, and
  the origin of the tip that points users here.
- [cli-entry.md](./cli-entry.md) — proxy routing, and the auto-upgrade skip
  list this subcommand is on.

## When to read the source

- Changing `--since` forms, their detection, or the unparseable-value message →
  `scripts/cmd-changelog.sh` for the dispatch, `changelog_since_kind` in
  `lib.sh` for the classifier.
- Changing the editor chain or its TTY gate → the no-`--since` block in
  `scripts/cmd-changelog.sh`.
- Changing when paging happens, or which pager → the `--since` block in
  `scripts/cmd-changelog.sh`; the height probe is `terminal_height` in
  `lib.sh`.
- Changing which sections a `--since` value selects → `select_changelog_sections`
  in `lib.sh` (two awk scans, one per kind).
- Changing the block's layout or colours → `_render_changelog_sections` in
  `lib.sh`. It is shared with `upgrade`; a change there moves both.
