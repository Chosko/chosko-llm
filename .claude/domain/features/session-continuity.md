# Session continuity

Two commands, `/session-save` and `/session-resume`, that write and read a
per-project handoff file so work survives the end of a conversation. The file
lives beside the project's other `.claude/` artifacts, links to whatever
document the session was working on, and shrinks to a pointer when the running
skill already keeps its own resume artifact.

## Purpose

A conversation ends and its context dies with it. The task backlog records
*what* was done; `.claude/context/` records *where things are*. Neither records
the middle: what was tried and failed, what was deliberately not tried, which
files are half-finished, and what the exact next step was. That knowledge is
re-derived from scratch every time a session ends mid-flight, at full token
cost and with no guarantee the re-derivation matches.

This feature captures it once, at the moment it is still known.

The schema is borrowed from ECC's `save-session` / `resume-session` pair, with
three deliberate departures: the store is per-project rather than global, the
file links to the project document the work belongs to, and a session running a
skill that already has a resume artifact writes a pointer instead of a
duplicate.

## Scope and non-goals

In scope: the `.claude/sessions/` store, the two commands, the full and pointer
file forms, artifact detection, and the resolution rules `/session-resume` uses
to pick a file.

Deliberately out:

- **A global session store.** ECC writes to `~/.claude/session-data/`, which
  mixes every project into one bucket and puts runtime state inside the
  directory `chosko-llm` installs features into. Sessions are per-project, full
  stop. See [technical-direction.md](../technical-direction.md).
- **State the CLI reads.** No `chosko-llm` subcommand walks `.claude/sessions/`.
  Session files are context for an agent, never input to the tooling. The hard
  rule that filesystem plus frontmatter is the only state stands unchanged.
- **Automatic saving.** No hook, no Stop trigger, no autosave. The user decides
  a session is worth preserving. An automatically written handoff nobody asked
  for is the same rot the feature exists to prevent.
- **Duplicating a skill's own resume artifact.** When one exists, the session
  file points at it and says nothing else. Two accounts of the same state that
  can disagree is worse than one.
- **Committing.** `/session-save` writes the file and reports its path. It does
  not commit, does not push, and offers no `--commit`. See open questions on
  whether the directory should be gitignored by default.
- **Cross-machine or cross-project handoff.** A session file is readable by
  anyone given the path, but nothing in the feature moves it anywhere.

## Architecture

Two commands (`commands/session-save.md`, `commands/session-resume.md`), not
skills: each is a single-pass reporter with no conversation and no supporting
files, the same register `/task-list` and `/production-status` occupy.

### The store

`.claude/sessions/`, created on first save. One file per save:

```
.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md
```

`<slug>` is a two-or-three word kebab-case summary of the work, not a random
id — it makes the directory listing readable, which is the only way the user
finds an old session. The timestamp prefix sorts chronologically and prevents
same-day collisions without a hash. Markdown, not `.tmp`: the file is a
document, and the extension should say so.

### Two file forms

`/session-save` picks the form by detecting whether the work in flight already
has a resume artifact. **The command detects; the skills declare nothing.** A
skill that gains a resume artifact later needs no change here, and a skill that
loses one degrades to the full form on its own.

**Pointer form** — written when an artifact is found. The whole file:

```markdown
# Session: 2026-08-24 14:32

Work: task 118
Running: /task-implement
Resume from: ./delegated-runs.md

Read that file. It holds the state; this one only says where it is.
```

No narrative, no file table, no decisions. Anything more would be a second
account of state the artifact already owns.

**Full form** — written when no artifact is found, which is the generic case.
Nine sections, in this order, adapted from ECC's schema:

1. **What we are building** — the goal in the session's own terms.
2. **What worked (with evidence)** — each claim carries the command output,
   test name, or file that proves it. A claim without evidence is a guess and
   is written as one.
3. **What did not work (and why)** — the highest-value section. This is what
   the next session would otherwise repeat.
4. **What has not been tried yet** — the approaches considered and skipped, so
   they are not mistaken for approaches already ruled out.
5. **Current state of files** — table: file, status
   (Complete / In progress / Broken / Not started), notes.
6. **Decisions made** — with the reason, so they can be revisited rather than
   silently inherited.
7. **Blockers and open questions.**
8. **Exact next step** — one action, concrete enough to start on.
9. **Environment and setup notes** — anything non-obvious about how to run
   things.

ECC's rule is adopted verbatim and matters: **write every section, using
"N/A" or "nothing yet" where a section is genuinely empty.** A skipped section
is indistinguishable from an overlooked one; an honest empty section is
information.

### Artifact detection

`/session-save` resolves the artifact in two steps, in order:

1. **Known-artifact table**, carried in the command body — a small explicit map
   from skill to artifact path. Today: `/task-implement` → `./delegated-runs.md`
   (present only on a delegated run); `/product-design` →
   `.claude/domain/design-process.md` (its current-stage marker is a resume
   point). The table is short by design and grows only when a skill actually
   ships a resume artifact.
2. **Recency check** — if no table entry matches, look for a file written this
   session that carries a resume marker (a current-stage, phase, or
   next-step line). If found, offer the pointer form; if the user declines,
   write the full form.

No artifact found, or no skill running: full form.

### The `Work:` line

One typed line links the session to the document the work belongs to. Four
forms:

| Value | Written when | Points at |
|---|---|---|
| `task <n>` | a task was being implemented or authored | `.claude/tasks/<n>.md` |
| `feature <slug>` | `/architect` or feature-level design work | `.claude/domain/features/<slug>.md` |
| `document <path>` | product-design, roadmap, plan, or context work | that file |
| `none` | generic session with no anchor | — |

`none` is a first-class value, not a failure. A debugging session that touched
no backlog document is exactly the case the generic form exists for, and
inventing a link for it would make the link untrustworthy everywhere else.

### Resolution in `/session-resume`

| Argument | Behaviour |
|---|---|
| *(none)* | newest file in `.claude/sessions/` |
| `YYYY-MM-DD` | newest file from that date |
| a path | read that file directly |
| a task number | newest file whose `Work:` line names that task |

After reading, `/session-resume` emits a fixed briefing — what was being built,
what must not be retried, the exact next step — and then **stops and waits**.
It never starts work, never edits, never runs a command. Resuming into
unrequested action is the failure mode that makes handoff tooling untrustworthy.

Two edge cases are handled explicitly: a file older than 14 days is flagged as
stale before the briefing, and a file referencing paths that no longer exist
names each missing path rather than briefing as if they were there.

## Data and state

The session file is the only artifact. It is written once per invocation and
never updated in place — a second save writes a second file, because a handoff
is a snapshot and rewriting history in it defeats the purpose.

Nothing derives from session files. `/task-list`, `/production-status` and every
`chosko-llm` subcommand are unaffected and unaware.

## Interfaces and contracts

```
/session-save                      write a session file for the current session
/session-save <slug>               override the generated slug
/session-resume                    load the newest session file
/session-resume <date|path|task>   load a specific one
```

Both commands need `name`, `version`, `type`, `description` frontmatter per
[docs/authoring-guide.md](../../../docs/authoring-guide.md). Start at
`version: 0.1.0`. Root `VERSION` takes a minor bump — two new features.

Contract with the rest of the pipeline: session files are inputs to humans and
agents, never to tooling. Any future feature that parses them is a design
error to be caught in review.

## Dependencies

None. Both commands are self-contained markdown, read and write only inside the
project, and work on a project that has no backlog, no context layer, and no
domain layer.

## Open questions

- **Gitignore by default?** Session files are personal working state and will
  usually be noise in a diff, which argues for adding `.claude/sessions/` to
  `.gitignore` in `/task-setup` or `/project-setup`. Against: a session file is
  exactly what you would want to hand a colleague, and silently ignoring it
  makes that harder. Leaning: do not touch `.gitignore`; `/session-save` prints
  a one-line note that the file is untracked and leaves the decision open.
- **Pruning.** Nothing deletes old session files. At the observed cadence this
  directory grows without bound. A `--prune` flag or an age warning in
  `/session-resume` may be worth adding later; deliberately not in this slice.
- **Does `/session-save` know what skill is running?** The known-artifact table
  assumes the command can tell. In practice it infers from the conversation
  rather than reading state. If that proves unreliable, the fallback is to ask
  the user once, which is cheap and honest.
