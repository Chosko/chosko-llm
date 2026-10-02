# Shared library: changelog readout

## Overview

Covers the changelog readout in `scripts/lib.sh`: parsing, selecting and
rendering `CHANGELOG.md` sections for `upgrade` and `changelog`. The rest of
`lib.sh`: [shared-lib.md](./shared-lib.md).

## Public API

### Changelog readout

Two consumers: `cmd-upgrade.sh` (stderr, range just pulled) and
`cmd-changelog.sh` (stdout, user-chosen selection). Everything below is shared
between them except the colour gate.

Parser contract for `CHANGELOG.md`: `^## ` introduces a section, the first
whitespace-delimited token after it is the version, everything until the next
`^## ` is the body, and anything above the first `## ` is preamble and never
printed.

- `_render_changelog_sections <body> <fd> <color-predicate>` → **the single
  formatter.** Writes raw section text to file descriptor `<fd>` in the shared
  layout: two-space version indent, four-space bullets, blank line between
  sections and one after the block; version bold, ` — <date>` dim, bullet's
  leading ASCII `- ` marker cyan, bullet's `**Subject**` span bold, rest of the
  bullet text default; unrecognised line inside a section passed through
  indented and uncoloured rather than dropped.
  Bold spans go through `_render_bullet_markup <text> <on> <off>`, which returns
  its result in `_BULLET_MARKUP_OUT` — **not on stdout**: a command substitution
  would fork a subshell per bullet. With colour off `<on>`/`<off>` are empty, so
  the `**` markers are **stripped**, never printed literally; an unpaired `**`
  is left as the source wrote it.
  `<color-predicate>` is the NAME of a function returning 0 when colour applies
  to that stream. **It is a parameter, not read off `<fd>`, on purpose**:
  `changelog --since` may hand its output to a pager, at which point fd 1 is a
  pipe, and gating on the write fd would silently strip every escape from
  exactly the case that wants them. Both callers go through here so the two
  presentations cannot drift.
- `print_changelog_range <old-version> <new-version>` → writes `CHANGELOG.md`
  sections for versions just pulled to **stderr**; returns 0 when it printed at
  least one section, 1 otherwise. Caller (`cmd-upgrade.sh`) uses return value to
  decide whether to fall back to raw `git log --oneline` dump.
  Range two-sided: new version's header inclusive, down to but **excluding** old
  version's — the user already had that one. File descending semver, so single
  forward `awk` scan — no sort, no second pass, no temp file. Prints framing
  line via `log_info`, then delegates layout to `_render_changelog_sections`
  with fd 2 and `_use_color`.
  **Degrades, never fails**: missing/malformed/unreadable `CHANGELOG.md` returns
  1 silently (clones predating the feature are normal); missing header for new
  version logs one line and prints nothing; missing header for old version
  prints only the newest section. Never changes caller's exit code.
- `changelog_since_kind <value>` → classifies a `changelog --since` value into
  one of three **disjoint** forms and prints it: `version` (`1.10.0`), `date`
  (`2026-08-01`), `duration` (`30d` / `2w` / `6mo` / `1y`). Returns 1, printing
  nothing, on anything else. Disjointness is why `--since` auto-detects instead
  of carrying one flag per form.
- `changelog_duration_to_date <duration>` → the `YYYY-MM-DD` that many units
  before today. GNU `date -d` first, BSD `date -v` second, pure-awk
  civil-calendar conversion (Howard Hinnant's `days_from_civil` /
  `civil_from_days`) last, so a shell with neither still answers — **no new
  dependency for date maths**. The awk fallback approximates a month as 30 days
  and a year as 365; the two `date` paths do real calendar arithmetic.
- `select_changelog_sections <kind> <value>` → prints matching sections
  verbatim on stdout. `version`
  kind takes every section from the newest down to and **including** `<value>`'s
  (matched on the header's first token, so a version absent from the file
  matches nothing rather than guessing); `date` kind takes every section whose
  header carries a date on or after `<value>`, string-compared — and scans the
  whole file, not a prefix, because descending-semver order is
  non-chronological at this repo's one history merge. Returns 1, printing
  nothing, when the file is missing or nothing matched; the caller's handling:
  [cmd-changelog.md](./cmd-changelog.md) § Public API.
  Inclusive version bound is the deliberate mirror of `print_changelog_range`'s
  exclusive one: "since 1.10.0" reads as "1.10.0 and everything after".
- `terminal_height` → `$LINES`, else `tput lines`, else the constant 24. Used
  to decide whether a rendered block fits one screen. Falls back to a constant
  rather than taking a dependency — `tput` is absent often enough on the bare
  git-bash that is this CLI's primary platform.

**Lives in `lib.sh`, not in either `cmd-*.sh`**, for two reasons: this is where
colour handling belongs (`cmd-*.sh` never inline `\033[` escapes — see
[shared-lib.md](./shared-lib.md) § Stdout color variables), and the two streams
need different gates. Stderr output gates on `_use_color`, the predicate
`log_info` and friends use ([shared-lib.md](./shared-lib.md) § Logging);
stdout output gates on the stdout predicate (`_use_color_stdout` / the `C_*`
variables' condition), captured before any redirection — and that is the
predicate each caller hands `_render_changelog_sections`. Using either on the
wrong stream produces escapes in redirected output. Colour off → every escape
empty string, layout and bullet markers unchanged.

## Internal patterns

- None beyond [shared-lib.md](./shared-lib.md) § Internal patterns.

## Domain dependencies

- None beyond [shared-lib.md](./shared-lib.md) § Domain dependencies.

## Cross-references

- [shared-lib.md](./shared-lib.md) — § Logging and § Stdout color variables,
  the two colour gates the readout picks between.
- [cmd-upgrade.md](./cmd-upgrade.md), [cmd-changelog.md](./cmd-changelog.md) —
  the two consumers.

## When to read the source

- Changing changelog range extraction or its degrade-never-fail branches →
  `print_changelog_range` in `lib.sh`; the caller's suppression rule lives in
  `cmd-upgrade.sh`.
- Changing the changelog block's layout or colours → `_render_changelog_sections`
  in `lib.sh` (inline markup: `_render_bullet_markup` beside it).
- Changing which sections `changelog --since` selects, how its value is
  classified, or how a duration resolves to a date → `select_changelog_sections`
  / `changelog_since_kind` / `changelog_duration_to_date` in `lib.sh`. The
  argument parsing, editor chain and paging rule live in `cmd-changelog.sh` —
  see [cmd-changelog.md](./cmd-changelog.md).
