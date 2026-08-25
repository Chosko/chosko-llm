# Version changelog

A curated `CHANGELOG.md` at the repo root, one section per root `VERSION`
value, newest first — plus the rule that keeps it honest at every bump, a
repo-local guard that catches a missed entry before it ships, and a coloured
readout that `chosko-llm upgrade` prints for exactly the versions the user
just pulled.

## Purpose

`chosko-llm` ships roughly a hundred small releases and tells its users
nothing about any of them. `chosko-llm upgrade` runs `git pull --ff-only`
and dumps `git log --oneline` — commit subjects written for the repo's
author, not for someone who wants to know whether the CLI they use every day
behaves differently this morning. The repo-level version the installer
reports moves constantly and means nothing to the person it moves for.

This feature closes that gap in three places at once, because closing it in
one would not hold:

- **A file** that records, per version, what changed for a user of the CLI
  or of the shipped features.
- **A rule** that makes writing that record part of what a `VERSION` bump
  *is*, rather than a courtesy someone remembers.
- **A readout** that puts the record in front of the user at the one moment
  they are demonstrably interested — the upgrade that just changed their
  tools underneath them.

A changelog nobody is obliged to write goes stale in three versions. A
changelog nobody reads changes no decisions. All three parts, or none.

## Scope and non-goals

In scope:

- `CHANGELOG.md` at the repo root, its schema, and its ordering rule.
- The maintenance rule, recorded in `CLAUDE.md` § Versioning and mirrored in
  `docs/authoring-guide.md` § Versioning.
- `scripts/check-changelog.sh` — a repo-local, authoring-time guard.
- A coloured range readout in `scripts/cmd-upgrade.sh`, with its extraction
  and formatting helper in `scripts/lib.sh`.
- A one-time backfill of every past version, read out of `git log` by an
  agent at implementation time.

Explicit non-goals:

- **No automation that writes entries from commit messages.** Entries are
  curated prose written by whoever bumps the version. A generated changelog
  is a second, worse `git log`.
- **No changelog for per-feature frontmatter versions.** Root `VERSION`
  only. The `version:` field on a command or skill is `cmd-add` /
  `cmd-update`'s bookkeeping and has its own visible surface in
  `chosko-llm ls`.
- **Nothing in the shipped commands or skills.** No feature body gains a
  changelog step, no new command, no new skill. This is repo-level and
  CLI-level only.
- **No new flag on `upgrade`.** Its readout is unconditional behaviour of a
  version-changing pull; there is no `--changelog` and no `--no-changelog`.
  *(Amended 2026-08-25, task 150: this originally read "No new CLI flag and no
  new subcommand", which no longer holds. `chosko-llm changelog`, with its
  `--since` and `--print` flags, now exists and is in scope — see § Interfaces
  and contracts. The half that still stands is the one above: `upgrade` itself
  gained no flag.)*
- **`CHANGELOG.md` is not a shipped feature.** No frontmatter, never copied
  into `$CLAUDE_HOME`, never listed by `chosko-llm ls`, not added to
  `cmd-export.sh`'s selection. It lives in the managed clone and is read
  from there.
- **No backfill script ships.** The backfill is authoring work done once by
  an agent reading `git log`; nothing in the repo replays it.
- **`chosko-llm channel <branch>` prints nothing.** A channel switch can
  move `VERSION` in either direction and is a developer action, not an
  upgrade.
- **No line wrapping.** Bullets are short by schema; that is what makes
  wrapping unnecessary.
  *(Amended 2026-08-25, task 150: this originally read "No line wrapping and no
  pager". The no-pager half is falsified on both sides of `chosko-llm
  changelog` — the no-argument view falls back to `less -R` when no editor
  resolves, and `--since` pages when its block does not fit one screen. The
  no-wrapping half stands, everywhere.)*

## Architecture

Built on the repo's existing stack per `CLAUDE.md`'s hard rules: POSIX-ish
bash with awk/sed/grep, no new dependencies, every script under `scripts/`
starting `set -euo pipefail` and sourcing `lib.sh`, every path resolved
through a `lib.sh` helper rather than hardcoded.

### 1. `CHANGELOG.md` — the record

Repo root, beside `VERSION` and `README.md`. The preamble is one line —
what the file is and where its rules are documented — and nothing more: the
file is a record, and the rule, its converse and the ordering rationale live
in `CLAUDE.md` and the authoring guide, never restated here (amended
2026-08-25; the original design carried a multi-paragraph preamble). Then one
section per version:

```
## <version> — <YYYY-MM-DD>

- <short bullet>
- <short bullet>
```

- **The version is the first whitespace-delimited token after `## `.** That
  token is the only thing any parser reads; the em dash and the date exist
  for human readers and may be reformatted without breaking anything.
- **The date is the commit date of the commit that set that `VERSION`
  value.**
- **Bullets are short and user-facing.** Each names the feature, command or
  script touched and the change a user would notice. No prose paragraphs, no
  commit shas, no nested lists.
- **No `Added` / `Changed` / `Fixed` sub-headings.** With a hundred sections
  of two-to-five bullets each, sub-headings would roughly triple the file's
  line count and force a taxonomy judgement on every bullet, for a signal
  the bullet already carries by naming its artifact. Keep-a-Changelog's
  header shape, without its groupings.

**Ordering is descending semver, not chronological.** This is forced by the
repo's actual history, which is a DAG rather than a line: commit `13e01c3`
reset `VERSION` to `0.53.0` on a side branch that then ran up to `0.59.0`
while master independently ran `0.53.1` … `0.58.2`, the two merging at
`bd2a1cf`. Master's first-parent sequence jumps `0.53.0` → `0.59.0`.
Chronological order would interleave the two lines and make "everything
above the old version's header" wrong; descending semver makes it exactly
right, and coincides with chronology everywhere outside that merge.

**Every distinct `VERSION` value ever recorded gets a section, branch-only
values included.** `chosko-llm channel <branch>` exists precisely so a clone
can sit on unmerged work, so a clone can genuinely be at `0.55.0` or
`0.52.1`. Omitting those values would send exactly those users down the
degraded path in the readout below.

### 2. The maintenance rule

One line added to `CLAUDE.md` § Versioning and mirrored in
`docs/authoring-guide.md` § Versioning: **a `VERSION` bump without a
matching `CHANGELOG.md` section is an incomplete change.** `CLAUDE.md` is
the copy that matters operationally — every session reads it, including
`/task-implement` runs, so the rule applies to work already authored without
any of it being rewritten. The authoring-guide copy is where the schema, the
ordering rule and the guard are explained at length.

The rule's converse is stated with it, and stated generically: **a change
that does not bump `VERSION` gets no `CHANGELOG` entry.** The known instance
is `.claude/skills/` — this repo's own unshipped, unversioned audit skills,
which by their feature's contract never bump `VERSION` because no user
receives them. Phrasing it as a consequence of the general rule rather than
as a named special case means it holds whether or not that feature has
landed, and covers any future repo-local artifact on the same footing.

### 3. `scripts/check-changelog.sh` — the guard

A repo-local, authoring-time guard: sources `lib.sh`, resolves the repo root
from its own location, `die`s on the first violated invariant, exits 0 in
silence otherwise. It is not a subcommand — `bin/chosko-llm` dispatches only
its known subcommand list, so a script under `scripts/` that is not in that
list is inert for users. It is run by whoever bumps `VERSION` (a human or a
`/task-implement` run following `CLAUDE.md`), the way this repo has
historically run its guards: by hand, documented in the authoring guide.
There is no CI and no installed git hook to hang it on, and adding either is
out of scope.

Four cheap invariants:

1. `CHANGELOG.md` exists and has at least one section.
2. The **top** section's version token equals the trimmed contents of
   `VERSION`. This is the invariant that catches the actual mistake.
3. Version headers are strictly descending semver, with no duplicates.
4. The top section has at least one bullet — an empty section is a bump that
   forgot its content rather than one that had none.

It proves nothing about whether the bullets are *true*; it turns a silent
omission into a caught failure, which is the whole ambition.

**This guard is deliberately not a consumer-side warning.** A check in
`install.sh` or `cmd-upgrade.sh` fires on the user's machine, long after the
bump, at someone who cannot fix it — noise pointed at the wrong person.
Consumer-side detection already exists for free anyway: a missing header for
the newly-pulled version makes the readout say so in one line. The guard
belongs where the mistake happens, in the working repo.

The guard is modelled on the pattern `scripts/check-task-parity.sh`
established — a small, repo-local invariant checker under `scripts/` with
its own section in the authoring guide. It is a **standalone script with no
relationship to that file**, which task 118 deletes; it must not reference
it, source it, or share code with it.

### 4. The readout — `scripts/cmd-upgrade.sh`

`cmd-upgrade.sh` already resolves everything through `$CHOSKO_LLM_HOME` and
never hardcodes a path, so the `CHOSKO_LLM_HOME` override is **already
honoured** — this is a verified non-change, not work to do.

The mechanism:

1. **Before** `git pull --ff-only`, read the managed clone's raw `VERSION`.
2. Pull.
3. **After** the pull, read it again.
4. Print the range between them.

The two reads must use the **raw trimmed file contents, never
`resolve_version`** — that function appends ` (<git describe>)`, and with no
tags in this repo `git describe --tags --always` yields a bare sha, so its
output changes on every commit and is useless as a version comparison.

The range is **two-sided**: from the new version's header inclusive, down to
but excluding the old version's header. Because the file is descending
semver, that is "every section at or above the new version and strictly
above the old" — a single forward scan with awk over the file, matching
`^## ` headers and comparing the first token. No sorting, no second pass, no
temporary file.

Placement: after the pull and the existing pulled-commits reporting, before
the proxy refresh — so the news about what changed arrives before the
mechanical follow-up hints (`ls --available`, `update --all`).

**The raw `git log --oneline` dump is suppressed when a changelog range was
printed.** Exactly one of the two appears on any non-empty pull: the curated
bullets when the version moved, the commit list when it did not. A forty-line
subject dump alongside a curated summary is strictly worse for this audience,
and the commits stay one `git -C ~/.chosko-llm log` away.

**The readout also fires during daily auto-upgrade.** `auto-upgrade.sh`
invokes `cmd-upgrade.sh` directly and does not swallow its output, so a user
opted in to daily upgrades sees the block once, in front of whatever command
triggered it. This is intended: for most users that is the only moment an
upgrade ever happens.

### 5. `scripts/lib.sh` — three additions

Per `CLAUDE.md`'s hard rule that path assembly and colour handling live in
`lib.sh` and never inline in a `cmd-*.sh`:

- **A raw version reader** — the trimmed contents of the managed clone's
  `VERSION`, empty when absent. `resolve_version` is refactored to call it,
  so the trim and the path exist in exactly one place.
- **A changelog path helper**, resolving `CHANGELOG.md` under
  `$CHOSKO_LLM_HOME`, alongside the existing `src_*_path` family.
- **A changelog range printer**, owning both the awk extraction and the
  formatting below. It lives here rather than in `cmd-upgrade.sh` because
  this is where the colour helpers already are, and because
  `.claude/context/shared-lib.md` records the standing convention that
  `cmd-*.sh` scripts never inline `\033[` escapes.

*(Amended 2026-08-25, task 150: the range printer is no longer the only
consumer of the formatter. The formatting below was extracted into a shared
renderer parameterised by **output stream and colour gate**, which the range
printer calls with fd 2 and `_use_color` and `chosko-llm changelog --since`
calls with fd 1 and its own captured stdout predicate. `lib.sh` correspondingly
grew section-selection helpers for `--since` beyond the three additions listed
here. What did not change: everything still lives in `lib.sh` for the two
reasons given above.)*

### 6. The presentation

The block is written to **stderr**, like every other line `cmd-upgrade.sh`
emits, so redirecting stdout never splits the output in half.

Colour is gated by the **same `_use_color` predicate `log_info` and friends
use** — `NO_COLOR` unset *and* fd 2 is a TTY — and applied with the same
`printf '\033[...m'` escape handling. The existing `C_*` variables are the
wrong tool here: they are gated on *stdout* being a TTY, and this block goes
to stderr. When colour is off, every escape resolves to an empty string and
the layout, indentation and markers are unchanged, so piped or redirected
output is clean plain text.

*(Amended 2026-08-25, task 150: that gating statement now holds only for **this**
caller, the stderr readout. The renderer takes its colour gate as a parameter,
so `chosko-llm changelog --since`, which writes to stdout, passes the
stdout-gated predicate instead — and captures it from the command's *original*
stdout, before a pager can turn fd 1 into a pipe. The rule the original wording
was protecting is unchanged and now stated stream-wise: use the gate that
matches the stream, or redirected output carries escapes. Everything else in
this section — the layout, the ASCII marker, the no-wrapping decision — applies
identically to both blocks, which is why there is one renderer.)*

Layout, for a pull from `0.61.0` to `0.62.1`:

```
[info] What changed since 0.61.0 → 0.62.1

  0.62.1 — 2026-08-24
    - <bullet text>
    - <bullet text>

  0.62.0 — 2026-08-23
    - <bullet text>

  0.61.1 — 2026-08-22
    - <bullet text>

```

- The framing line goes through `log_info`, so it carries the standard
  `[info]` prefix and needs no colour of its own.
- One accent colour for the whole block, so there is no palette to learn:
  the version number **bold**, the ` — <date>` **dim**, the bullet's leading
  `- ` marker in the accent colour, the bullet text default. Deliberately
  uniform — no per-version highlighting, no distinction between the newest
  section and the older ones.
- Two-space indent for version headers, four for bullets; a blank line
  between sections and one after the block.
- **The marker stays ASCII `-`.** The CLI runs under git-bash on Windows,
  where a non-ASCII bullet glyph can mangle in a legacy codepage console.
  The source bullets already begin `- `, so the printer colours the existing
  two characters rather than substituting a glyph, which also leaves any
  inline backticks or punctuation in the bullet untouched.
- **No wrapping.** Terminal-width detection buys nothing when the schema
  already requires short bullets, and buys a dependency or a fragile `tput`
  probe when it does.

### 7. The backfill

A one-time authoring task at implementation time: an agent reads `git log`,
takes the `VERSION`-changing commits as boundaries, and writes each version's
bullets from the commits inside its boundary. Roughly 104 sections from
`0.1.0` to the version current when it lands.

Attribution rule: walk the `VERSION`-setting commits in topological order;
each version's bullets come from the commits between the previous such
commit (exclusive) and its own (inclusive). Where the merge at `bd2a1cf`
makes attribution ambiguous — the roadmap branch's own bumps already claimed
those commits — the branch's sections keep their bullets and the merge's
`0.59.0` section records only that the branch merged. Bullets are written
from the *effect* of each commit, not by paraphrasing its subject line.

Nothing about this ships. It runs once and leaves a file.

## Data and state

**No new state.** No lockfile, no cache, no state file — consistent with the
repo's standing rule that the filesystem is the state.

| Datum | Where it lives | Source of truth |
| --- | --- | --- |
| Current repo version | `VERSION` at repo root | itself |
| Per-version user-facing changes | `CHANGELOG.md` sections | itself, written by hand |
| Version before an upgrade | a shell variable, read before the pull | the clone's `VERSION` at that instant |
| Version after an upgrade | a shell variable, read after the pull | the clone's `VERSION` at that instant |
| Section date | the `## ` header | the commit date of the bump |

Both version values are transient and live only for the duration of one
`cmd-upgrade.sh` run. Nothing is persisted between upgrades, so nothing can
drift, and a user who has never upgraded has no prior state to be missing.

## Interfaces and contracts

### `chosko-llm upgrade`

No new flag, no new exit code, no change to the `--enable-auto` /
`--disable-auto` toggles, which still exit before any of this runs. The
difference is what a version-changing pull prints.

*(Amended 2026-08-25, task 150: this originally opened "Unchanged surface",
which no longer holds as written. `upgrade` now also prints one more TTY-gated
stderr tip — `Run 'chosko-llm changelog' to see the full changelog` — alongside
its existing `ls --available` / `update --all` tips, and `chosko-llm --version`
prints a TTY-gated stderr tip of its own after its stdout version line, which
is itself unchanged. Both are stderr and both are TTY-gated, so neither changes
what a script capturing stdout receives.)*

| Situation | Behaviour |
| --- | --- |
| `CHANGELOG.md` absent from the clone | **Silent.** No warning, no error. Clones predating this feature are the normal case. |
| Old and new version identical | Print nothing. The existing `git log --oneline` list prints as it does today. |
| Both headers present | Print the range: new inclusive, old exclusive. Suppress the commit list. |
| New version's header missing | One line saying `CHANGELOG.md` has no section for that version. Print no sections — there is nothing trustworthy to print. Commit list still prints. |
| Old version's header missing | Print **only the new version's section**, plus one line saying the earlier range could not be resolved. This is what caps the output for a clone that sat on an unknown or branch-only version. |
| Old version newer than new (a `channel` switch, a downgrade) | Empty range, so nothing prints. Falls out of the ordering rule without a special case. |
| `VERSION` unreadable before or after the pull | Treated as a missing header on that side, per the two rows above. |
| Range spans many versions | Print all of them. No cap: bullets are short by schema, this is the one moment the information is wanted, and daily auto-upgrade keeps real ranges to one or two sections. |
| `NO_COLOR` set, or stderr not a TTY | Same text, same layout, no escapes. |

**Failure contract: degrade, never fail.** Nothing in the readout may change
`upgrade`'s exit code or abort the run. A malformed, truncated or unreadable
`CHANGELOG.md` costs the user their release notes, never their upgrade. A
line inside a section that is neither a header nor a bullet is passed through
indented and uncoloured rather than dropped — losing content is worse than
printing something unexpected.

### `chosko-llm changelog`

*(Added 2026-08-25, task 150.)* A read-only view onto the managed clone's
`CHANGELOG.md`. It never pulls, writes nothing, and is on the daily
auto-upgrade's skip list beside `version` and `help`.

| Invocation | Behaviour |
| --- | --- |
| `changelog` | Opens `$CHOSKO_LLM_HOME/CHANGELOG.md` in `$VISUAL`, else `$EDITOR`, else `git var GIT_EDITOR`; when none resolves, `less -R` on a TTY and `cat` otherwise. **Never fails merely because no editor is configured** — a bare git-bash on Windows commonly has neither variable, and this CLI's primary platform must not fail on first run. |
| `changelog --print` | The full file on stdout. Never an editor, never a pager — this is what scripts use. |
| `changelog --since <value>` | The selected sections, rendered, on **stdout**. |
| `changelog --since <value> --print` | The same, forced unpaged. |

`--since` takes one value in three **disjoint** shapes, auto-detected, with no
flag per form: a version (`1.10.0`), a date (`2026-08-01`), or a duration
(`30d` / `2w` / `6mo` / `1y`, resolved against today).

- **The version bound is inclusive** — "since 1.10.0" means 1.10.0 and
  everything after. This is deliberately the opposite of the `upgrade` range's
  exclusive old bound, which is right there because the user already had that
  version.
- **Output goes to stdout**, unlike `upgrade`'s stderr readout, because it is
  this command's product and must pipe into `grep`. Every diagnostic — the
  no-match notice included — goes to stderr, so stdout stays greppable.
- **Paged only on overflow, and only on a TTY.** The rendered block is measured
  against the terminal height (`LINES`, else `tput lines`, else 24). Fits: written
  straight out, no child process. Does not fit: piped to `$PAGER`, else
  `less -R`, else written straight out. A pipe, a redirect, or `--print` never
  spawns a pager, so `changelog --since 30d | grep …` behaves the same whatever
  the content's length. The default pager carries `-R` so the escapes survive.
- **An unparseable `--since` dies** with a message naming all three forms. A
  value matching **no** section is not an error: it says so and exits 0.
- **A missing `CHANGELOG.md` dies here**, unlike in `upgrade`, which is silent
  about it. Silence is right when the readout is a side effect of another
  action, and wrong when the file is the thing the user asked for.

### `scripts/check-changelog.sh`

Exit 0 and silent when every invariant holds; non-zero via `die` naming the
first violation, in the style `check-task-parity.sh` established. Takes no
arguments. Reads only `VERSION` and `CHANGELOG.md`; writes nothing, and
never edits the changelog to fix what it found.

### `CHANGELOG.md`

The parser contract, stated so a future reader knows what is load-bearing:
`^## ` introduces a section; the first whitespace-delimited token after it is
the version; everything until the next `^## ` is that section's body.
Anything above the first `## ` is preamble and is never printed. Everything
else about the line — the separator, the date, the surrounding whitespace —
is presentational.

### `scripts/lib.sh`

Three additions, no signature changes to anything existing. `resolve_version`
keeps its current output format exactly; it is refactored to read through the
new raw reader, not to behave differently. `install.sh` and `cmd-version.sh`,
its two callers, are untouched.

## Dependencies

**No dependency on any other feature.** Nothing in `FEATURES.md` is a
precondition, and this feature is a precondition for nothing.

**It is implemented first, before tasks 118–145.** That sequencing is the
whole reason there is no retrofit problem: from the moment this lands, the
`CLAUDE.md` rule governs every subsequent bump, so each of those tasks writes
its own bullet as part of being complete. No task body is edited, no
precondition is added to any of them, and none of the 28 already-authored
tasks needs to know this feature exists — `/task-implement` reads `CLAUDE.md`,
and the guard catches a bump that forgot.

Two ordering constraints internal to this feature:

- The `CLAUDE.md` and authoring-guide rule must land **in the same `VERSION`
  bump** as `CHANGELOG.md` itself. A rule that is live before the file exists
  is a rule that is violated by the very change introducing it.
- The guard must land with or after the file, for the same reason.

One relationship worth naming, which is **not** a dependency: task 118
deletes `scripts/check-task-parity.sh`. `scripts/check-changelog.sh` is
modelled on the pattern that script established, but is standalone — it must
not reference, source, or share code with it, so the two features can land in
either order without either breaking.

**No external dependencies.** awk, sed, grep and bash are already required by
every script in the repo; nothing new is introduced, and `CHANGELOG.md` needs
no parser beyond what `parse_frontmatter` already proves is enough.

## Open questions

None outstanding. Every fork raised at architecture time was settled:
descending-semver ordering with branch-only versions included; an
authoring-time guard rather than a consumer-side warning; the raw commit list
suppressed when a changelog range prints; no cap on range length; and the
sequencing above, which removes the retrofit question entirely.
