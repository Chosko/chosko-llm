# Session readers

Two read-only commands for the session store, `/session-list` and
`/session-describe`, built in the shape of `/runbook-list` and
`/runbook-describe`: a one-line-per-handoff listing, and a short plain
description of one handoff. Alongside them, every session command that names
a specific session — `/session-resume` and `/session-describe` — accepts the
same three argument forms: a path, a date, or a slug.

## Purpose

`.claude/sessions/` grows one file per save, and the directory listing is
the only way to find an old one. A filename carries a date and a slug, not
what the session was about or where it stopped, so finding the right
handoff means opening several. `/session-resume` is the only reader, and it
both picks a file and briefs from it — there is no way to look before
loading.

The two readers answer "what handoffs exist" and "what is this one about"
without loading a session into the conversation, at a cost that stays flat
in the size of the store.

## Scope and non-goals

In scope: the two commands; the shared argument resolution; the handoff
subfolders orchestrate-mode adds, as they appear to a reader.

Deliberately out:

- **A session index.** No `SESSIONS.md`, no counter. The filenames and each
  file's header lines are the whole state, read with search commands.
- **Writing anything.** Both readers write, delete, stage and commit
  nothing, and never correct a file however malformed it looks.
- **Briefing.** `/session-describe` describes; it does not load the session
  into the conversation or stop to wait for work, as `/session-resume`
  does. Resuming stays `/session-resume`'s job.
- **Pruning or filtering by status.** A session file carries no status.
- **The interaction policy's output rules.** Both are read-only listings,
  outside that policy by its own scope; they keep to its plain-language
  spirit without citing it.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: two single
markdown commands, no supporting files, no script, the same register as
`/session-save`, `/session-resume` and the runbook readers (see
`.claude/context/session-handoff.md` and
`.claude/context/runbook-readers.md`).

### The store, as readers see it

- **Handoff files** — `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`, in full
  or pointer form, each with its header block (`Work:`, `Running:`, and
  `Resume from:` in the pointer form) per
  [session-continuity](./session-continuity.md).
- **Handoff subfolders** — `.claude/sessions/<session-file-stem>/agent-<area>.md`,
  one per orchestrate-mode area, beside the handoff whose stem names the
  folder; and `.claude/sessions/pending/` holding area handoffs written
  before the first `/session-save`
  ([orchestrate-mode](./orchestrate-mode.md)). Readers list areas from the
  folder's filenames; they never read an area handoff's body.

Only top-level files carrying a `Work:` line are sessions — the existing
candidacy rule; subfolders and companion files are not, and are skipped
silently.

### Argument resolution — one rule

The rule lives once, in `/session-resume`'s body, and `/session-describe`
declares `requires: command:session-resume` and applies it by name, the way
`/task-implement` applies `/follow-ups`. Forms, tried in order:

1. **A path** — contains `/` or `\`, or ends `.md`: read as given, no
   candidacy check.
2. **A date** — `YYYY-MM-DD`: the newest candidate from that day.
3. **A slug** — anything else: the newest candidate whose filename's slug
   part equals it exactly. Several matches resolve to the newest, named on
   the first output line. A slug with no exact match lists the nearest
   slugs and stops; there is no substring fallback.
4. **Nothing** — the newest candidate.

A bare number is unrecognized. The no-match stop is the one exception to
`/session-resume`'s degrade-never-refuse contract, because guessing the
newest file for a typed name would load the wrong session.

### `/session-list`

One line per candidate, newest first:

```
<YYYY-MM-DD HH:MM>  <slug>  <Work: value>  — <first sentence of the next step>
```

A pointer-form file prints `→ <Resume from: path>` instead of a next step,
and is marked as a pointer. A handoff with area subfolders gets a trailing
`[areas: <n>]`. The read is header lines only: one search over the store
for `Work:`, `Resume from:` and the next-step section heading with the line
after it — never a full read of any file. Requires `command:session-save`
for the store and header schema. An empty or missing store prints one line
saying so.

### `/session-describe`

Resolves one handoff by the shared rule, then prints a short plain
description, about ten lines:

- what the session is about (from the preamble or *What we are building*);
- where it stopped and the very next step or steps;
- objectives still open;
- open blockers;
- the orchestrate-mode area handoffs, by area name, when a subfolder exists.

Read budget: the header block and the sections it summarises, extracted by
search; *What worked*, *What did not work*, the file table and the
environment notes are not read. A pointer-form file is described from its
header and the pointed-at artifact's resume marker line only. Never a wall
of text: a section too long to summarise in a line is summarised, not
quoted. Requires `command:session-resume` (resolution) and
`command:session-save` (schema).

## Data and state

None new. Inputs: filenames and header lines under `.claude/sessions/`, and
the names of files in its subfolders. In memory only: the resolved file.

## Interfaces and contracts

```
/session-list                         one line per handoff, newest first
/session-describe [<path|date|slug>]  short description of one handoff
/session-resume  [<path|date|slug>]   briefing, resolved by the same rule
```

Failure contract: missing store or no candidate — one line, no error; an
explicit path that does not exist — named, stop; a slug with no exact
match — nearest slugs named, stop; a malformed file — described as found, never
compensated by reading more.

## Dependencies

- [session-continuity](./session-continuity.md) — the store, file forms,
  header block and candidacy rule both readers rely on; `/session-resume`'s
  resolution gains the slug form.
- [orchestrate-mode](./orchestrate-mode.md) — the area handoff subfolders
  the readers list.
- [runbook-suite](./runbook-suite.md) — the reader pair whose shape and
  read-budget discipline these follow.
