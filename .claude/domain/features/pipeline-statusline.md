# Pipeline status line

A Claude Code status line that shows the session on its first line and the
progress of the project's pipeline — the current runbook, the task backlog
in scope, and every task in flight — on the lines below it, packaged as a
statusline feature (the renderer) plus a global command,
`/pipeline-statusline`, that wires it into the user settings, backs up
whatever it replaces, restores it on `uninstall`, and verifies the result.

## Purpose

A director running the pipeline across several terminals has no ambient
view of where a run stands: which runbook is executing, how far it got, how
much of the backlog it covers is done, and which tasks are being
implemented right now. The status bar is the one surface Claude Code keeps
on screen, so the pipeline's progress belongs there, next to the session
facts the director already watches — model, folder, branch, context, cost,
rate limits.

The feature also makes the status line installable. The CLI copies status
line scripts but, by design, never edits `settings.json`; wiring, replacing
a previous status line and undoing that replacement are work an agent can do
surgically, so a command owns them.

## Scope and non-goals

In scope:

- The renderer: session line, pipeline progress line, one line per in-flight
  task in scope.
- The wiring command: install into the user settings, replace-or-abort when
  another status line is configured, backup and exact restore, idempotent
  re-runs, `--no-nerd-font`, verification with timing.
- Windows under git-bash as a first-class platform alongside macOS and Linux.

Non-goals:

- **Retiring `session-statusline`.** The two coexist; its line 1 is
  duplicated here, not shared — copy-on-install leaves no way to share code
  between features, and retiring it is a separate decision.
- **Touching superseded or foreign files.** The command never modifies or
  deletes `statusline-progress.sh`, `statusline-combined.sh`, the installed
  `statusline/session-statusline.sh`, or the leftover debug capture
  `statusline-last-input.json`, which it mentions to the user and may read as
  a fixture shape.
- **Removing the renderer on `uninstall`.** The script belongs to the CLI;
  `uninstall` restores the settings and points at
  `chosko-llm rm statusline:pipeline-statusline`.
- **Project-scoped status lines.** The statusline kind is global-only, and
  the command inherits that: a `--local` install of it fails on its
  `requires:`.
- **Writing anything in the project.** The renderer reads the pipeline's
  indexes and never writes; it is not a second `/production-status`.
- **New dependencies.** No jq, no git binary, no Python.

## Architecture

Built on bash and awk per `technical-direction.md`, with Windows reached
through git-bash. The feature extends the statusline kind and the
`requires:` mechanism exactly as they stand
(`.claude/context/claude-md-hook-statusline.md`,
`.claude/context/shared-lib-requires.md`); the CLI changes nothing.

### Renderer — `statusline:pipeline-statusline`

A statusline feature, installed by the CLI beside the other status line
scripts. It reads Claude Code's status JSON on stdin and prints up to N
lines.

Its one hard constraint is speed: **one awk process and no other fork.**
Claude Code drops a render that arrives late and keeps the stale one, and on
Windows under load every fork costs about half a second, so bash does
nothing but hand stdin to a single awk under `LC_ALL=C`. Awk does all the
rest itself: it parses the JSON, normalises a backslashed `current_dir`,
reads `.git/HEAD` (following a worktree's `gitdir:` file) for the branch or
detached SHA, and opens each pipeline file with `getline`, testing for
existence by attempting the read. Output stays byte-safe for UTF-8 under the
C locale: glyphs are octal escapes, and truncation backs off continuation
bytes so a multi-byte character is never split.

Inside the awk program, five concerns:

- **Label and glyph table** — every user-visible word (`ctx`, `until reset`,
  `task`, `in progress`) and both glyph sets in one table at the top. The
  default set is Nerd Font (folder, git branch, git commit, hourglass, play,
  check, cog), all single-cell; `--no-nerd-font` selects single-width Unicode
  (`▶ ✔ ↳`). Never emoji, never `⚙`, whose ambiguous width breaks the column
  alignment between lines 2 and 3.
- **Session line** — model, folder, branch or SHA, context percentage, cost,
  5h limit with time-to-reset, 7d limit, separated by a dim `·`, each item
  omitted when its field is absent. Colour thresholds as the spec states:
  context green < 70, yellow < 90, red otherwise; rate limits green < 50,
  yellow < 80, red otherwise.
- **Runbook reader** — picks the first `[RUNNING]` block in `RUNBOOKS.md`,
  else the last block; takes its name, title, status, `File:` and
  `Steps: d/t`; reads that body's step headings and `Done:` lines up to
  `## Do not re-propose`.
- **Scope resolver** — decides which task ids count, first rule that
  applies: (a) a range in the runbook's title; (b) the union of ranges and
  ids named in its step headings or, when no heading names one, in its
  steps' `Done:` lines — a step's prompt and `Context:` are never read, as
  they cite tasks of other steps; (c) the tasks of the features listed by
  the `[ACTIVE]` milestone in `PLAN.md`, through each feature's `Tasks:` line
  in `FEATURES.md`; (d) every task in `TASKS.md`. Ranges accept an en dash or
  a hyphen.
- **Progress renderer** — the tasks summary (done = `[DONE]` or `[SKIP]`, an
  id in scope absent from `TASKS.md` but present in the task archive counts
  done, `[IN PROGRESS]` counted separately), the 10-cell eighth-block bars
  (any non-zero value shows at least one eighth), and one line per
  `[IN PROGRESS]` task in scope, its title cut to 90 bytes at a word
  boundary.

### Wiring command — `/pipeline-statusline`

A global command declaring `requires: statusline:pipeline-statusline`, so
installing the command installs the renderer first. The executing agent
does the work; the command body is the procedure.

- **Locate** — resolves the renderer's absolute path and the user
  `settings.json` in the user scope, `${CLAUDE_HOME:-$HOME/.claude}`, as the
  home-path guard's exception for global-only kinds allows.
- **Install** — reads the current `statusLine`. Absent: writes the new value.
  Already ours: refreshes the script and reports. Anything else: shows it,
  asks replace or abort, and on replace backs it up before writing. The
  edit is surgical — the `statusLine` key alone changes; every other key and
  the file's formatting survive.
- **Refresh** — on a re-run, when `chosko-llm` is on the PATH it runs
  `chosko-llm update statusline:pipeline-statusline` and reports `already
  installed, script updated` or `unchanged` from the outcome; without the CLI
  it reports the installed version and says how to update.
- **Uninstall** — restores the backed-up `statusLine` value and script
  exactly, or removes the key when there was nothing before; deletes the
  backup; leaves the renderer installed and names the `chosko-llm rm`
  command that removes it.
- **Verify** — writes a realistic status payload to a temporary file, runs
  the installed renderer against it in the current project and in a
  temporary directory with no `.claude/`, times each run, and prints both
  outputs and timings.

## Data and state

- **The project's pipeline indexes** — `RUNBOOKS.md`, the runbook body its
  `File:` names, `TASKS.md`, `PLAN.md`, `FEATURES.md`, the task archive. The
  source of truth for everything on lines 2 and beyond; read on every render,
  never cached, never written.
- **Claude Code's status JSON** — the source of truth for line 1; fields used:
  model display name, `current_dir`, context `used_percentage`, total cost,
  the 5h and 7d rate-limit percentages and the 5h `resets_at`.
- **`.git/HEAD`** — the branch, or a detached SHA shown short; a worktree's
  `.git` file redirects through `gitdir:`.
- **The `statusLine` setting** — `type: command`, the command string
  `bash <absolute renderer path>` plus `--no-nerd-font` when chosen,
  `padding: 1`, `refreshInterval: 10`. The glyph choice lives here, never in
  the installed script, so `chosko-llm update` cannot undo it.
- **The backup** — a dedicated folder beside the status line scripts, one
  level down so `chosko-llm ls` never lists it: the replaced `statusLine`
  value verbatim, and a copy of the script it pointed to under its original
  name together with that original path. Present exactly while a replaced
  status line awaits restoration; its presence is how `uninstall` knows
  there is something to restore. No other state exists.

## Interfaces and contracts

- **Renderer** — `pipeline-statusline.sh [--no-nerd-font]`, status JSON on
  stdin, ANSI-coloured lines on stdout, exit 0. Any missing file, field or
  malformed block degrades by omission: no error text ever reaches the bar,
  and stderr stays silent. Target runtime under one second on Windows with a
  build running.
- **Command** — `/pipeline-statusline [--no-nerd-font]` installs or
  refreshes; `/pipeline-statusline uninstall` restores. Reports one of:
  installed; already installed, script updated; already installed,
  unchanged; replaced (with the backup's location); aborted; restored;
  nothing to uninstall. A `settings.json` that does not parse stops the run
  with the file untouched. Re-running `--no-nerd-font` on an installed status
  line changes only the flag in the command string.
- **Backup contract** — a second replace never overwrites an existing
  backup: the backup always holds the status line that predates this
  feature.

## Dependencies

- **Statusline kind and `requires:`** — the CLI installs, updates, lists and
  removes the renderer and installs it ahead of the command; nothing in the
  CLI changes.
- **runbook-suite**, **task-archive**, **production-plan** — the formats the
  renderer reads: the `RUNBOOKS.md` block and step markers, the archive's
  referenced-but-absent rule, the `PLAN.md` milestone block. A change to any
  of those formats is a change to this renderer.
- **session-statusline** — none at run time; line 1 is a deliberate copy of
  its behaviour.
- **Nerd Font** in the user's terminal for the default glyph set; the
  `--no-nerd-font` set needs only Unicode.
