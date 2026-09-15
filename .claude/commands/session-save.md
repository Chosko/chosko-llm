---
name: session-save
version: 0.2.1
type: command
description: Capture what this conversation knows — what was tried, what failed, what was deliberately not tried, which files are half-finished, and the exact next step — into a timestamped handoff file under .claude/sessions/, written in full nine-section form or shrunk to a pointer when the work already has its own resume artifact. Never rewrites a file in place. Commits and pushes the handoff it wrote by default, since a handoff usually crosses machines; pass --no-commit to leave it uncommitted, or --no-push to commit without pushing. --commit is accepted and changes nothing.
---

# /session-save
# Global command: write a per-project handoff file so the state of an
# in-flight conversation survives the end of that conversation. Single pass —
# no phases, no conversation, no supporting files.
# Usage: /session-save
#        /session-save <slug>
#        /session-save [<slug>] --no-commit  (write the handoff, skip the commit and push)
#        /session-save [<slug>] --no-push    (commit as usual, skip the push)
# Examples: /session-save
#           /session-save ecc-import-architecture

GOAL
Write one file under `.claude/sessions/` capturing what this session knows and
nothing else knows: what was tried, what failed and why, what was deliberately
not tried, which files are half-finished, and the exact next step. The task
backlog records *what* was done and `.claude/context/` records *where things
are*; neither records the middle, so it is re-derived from scratch at full
token cost every time a session ends mid-flight, with no guarantee the
re-derivation matches.

This command **writes** a handoff and commits it — it does not finish the
work, and does not clean up after itself beyond the one deletion described
under SUPERSESSION DELETE. A handoff exists to cross the gap between sessions,
which is usually a gap between machines, and an untracked file crosses
nothing.

$ARGUMENTS

---

ARGUMENT PARSING

First scan `$ARGUMENTS` for the flags below and strip whichever appear:

| Flag | Effect |
|---|---|
| `--no-commit` | Set COMMIT = false. Write the handoff, but make no commit and no push. Implies NO_PUSH. |
| `--no-push` | Set NO_PUSH = true. Commit as usual, skip the pull/re-sync/push. |
| `--commit` | Accepted and changes nothing — COMMIT is already true. |

COMMIT is true unless `--no-commit` is passed. `--commit` and `--no-commit`
together stop the run with:
`--commit and --no-commit cannot be combined. Pick one.` That is the only
argument this command refuses over.

What is left is either empty or a single slug.

- Empty — generate the slug yourself (see WHERE THE FILE GOES).
- A slug — use it verbatim as `<slug>`, lower-casing it and replacing spaces
  with hyphens if it is not already kebab-case.

Anything else is not a recognized argument. Say so in one line and carry on
with a generated slug — this command never refuses over any other argument.

**Pull at start.** Unless COMMIT is false or NO_PUSH is true, run `git pull`
on the current branch once, before anything is written. A conflict stops the run there: report the output and tell
the user to resolve manually and re-run. On a non-git VCS (a `## VCS` section
in `CLAUDE.md`) skip it.

---

WHERE THE FILE GOES

```
.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md
```

- `.claude/sessions/` is created on the first save. Writing the file creates
  the directory; no separate `mkdir` step.
- `YYYY-MM-DD-HHMM` is the local date and time now. Read the clock **once**:
  use the date and time the session context already carries if it has them,
  otherwise run `date` a single time. That clock read and the git commands of
  the commit-and-push protocol (ARGUMENT PARSING's pull at start, COMMIT AND
  PUSH) are the only
  shell commands this command is allowed to run — it runs no `ls`, no `grep`,
  and no other `git`.
- `<slug>` is a **two-or-three-word kebab-case summary of the work**, not a
  random id and not a generic word like `session` or `handoff`. The directory
  listing is the only way the user ever finds an old session, so the slug has
  to say what the session was about: `ecc-import-architecture`,
  `upgrade-readout-bug`, `roadmap-milestones`.

**Never update a session file in place.** A second `/session-save` in the same
conversation writes a second file with a later timestamp. A handoff is a
snapshot; rewriting history inside one defeats the point of taking it. The
only file this command ever removes is the one named under SUPERSESSION
DELETE, and it removes it whole — it never edits it.

Write nothing outside `.claude/sessions/`. Do not touch `.gitignore`, do not
edit `TASKS.md`, `FEATURES.md`, a feature document, or a context file, and do
not create a placeholder anywhere.

A session file is context for a human or an agent and never input to tooling.
No `chosko-llm` subcommand walks `.claude/sessions/`, and nothing derives from
what is written here — `/task-list`, `/production-status` and every CLI
subcommand are unaffected and unaware. Write for a reader, not for a parser.

---

THE HEADER BLOCK — both forms

Every session file, full form or pointer form, opens with the same three
lines:

```markdown
# Session: 2026-08-24 14:30

Work: task 118
Running: /task-implement
```

**`Work:`** takes exactly one of four values — it is the one typed line that
links this session to the document the work belongs to:

| Value | Written when | Points at |
|---|---|---|
| `task <n>` | a task was being implemented or authored | `.claude/tasks/<n>.md` |
| `feature <slug>` | `/architect` or feature-level design work | `.claude/domain/features/<slug>.md` |
| `document <path>` | product-design, roadmap, plan, or context work | that file |
| `none` | a generic session with no anchor | — |

`none` is a **first-class value, not a failure**. A debugging session that
touched no backlog document is exactly the case the generic form exists for,
and inventing a link for an anchorless session would make the link
untrustworthy everywhere else. `none` may carry a short trailing explanation
after an em dash:

```
Work: none — cross-feature architecture session, five features authored
```

Never write two `Work:` values, never write a list, and never guess a task
number to avoid writing `none`.

**`Running:`** names the skill or command in flight — `/task-implement`,
`/product-design`, `/architect` — or what the session was doing when there was
none (`free-form debugging`, `/claude-council, then free-form architecture`).
Infer it from the conversation. **Do not read any state to find out**; if the
inference is not clear, ask the user once, which is cheap and honest.

---

WHICH FORM — artifact detection

The command picks the form by detecting whether the work in flight already has
a **resume artifact**: a project-scoped state document that carries a resume
marker — a current-stage, phase, or next-step line a later session reads to
know where the last one stopped. Two properties are required, and both matter:
it lives inside the user's project (not inside an installed skill folder), and
its marker is rewritten as the work progresses.

**The command detects; skills declare nothing.** A skill that gains a resume
artifact later needs no change here, and a skill that loses one degrades to
the full form on its own.

Resolve in two steps, in this order:

**1. The known-artifact table.**

| Skill in flight | Resume artifact |
|---|---|
| `/product-design` | `.claude/domain/design-process.md` |

That is the whole table today. It is short by design and grows **only** when a
skill actually ships a project-scoped state document carrying a resume marker
— nothing else qualifies for a row. A static instruction file that ships with
an installed skill is not a resume artifact: it holds no session state, and
its path is relative to the installed skill folder rather than to the project.
`/task-implement` deliberately has no entry — its state is a half-finished
working tree plus what was tried, not a file — so its sessions take the full
form.

**2. The recency check.** If no table row matches, look for a file **written
during this session** that carries a resume marker. If one is found, offer the
pointer form:

> `<path>` was written this session and carries a resume marker, so it already
> holds the state. Write a pointer to it instead of a full handoff? [Y/n]

On yes, write the pointer form. On no, or on anything unclear, write the full
form.

No table row and no recent artifact, or no skill running at all: **full form**.
That is the generic case and the common one.

---

FULL FORM

The header block, then an **optional one-paragraph preamble** framing the
handoff, then all nine sections below, in this order, as `##` headings:

1. **What we are building** — the goal in the session's own terms.
2. **What worked (with evidence)** — every claim carries the command output,
   test name, or file that proves it.
3. **What did not work (and why)** — the highest-value section. This is what
   the next session would otherwise repeat, at full cost, before discovering
   the same thing.
4. **What has not been tried yet** — approaches considered and skipped, so a
   later session does not mistake them for approaches already ruled out.
5. **Current state of files** — a table with columns `File | Status | Notes`.
   `Status` is exactly one of **Complete**, **In progress**, **Broken**, or
   **Not started**.
6. **Decisions made** — each with its reason, so it can be revisited rather
   than silently inherited.
7. **Blockers and open questions.**
8. **Exact next step** — one concrete action, specific enough to start on
   without re-deriving anything.
9. **Environment and setup notes** — anything non-obvious about how to run
   things.

Two rules govern what goes in them:

- **Write every section, always.** Put `N/A` or `nothing yet` where a section
  is genuinely empty. A skipped section is indistinguishable from an
  overlooked one, and an honest empty section is information — it tells the
  next session that nothing was blocked, or that nothing failed, rather than
  leaving it to wonder whether anyone looked.
- **Evidence or it is a guess.** A claim under "what worked" that has no
  command output, test name or file behind it is a guess, and is written as
  one ("believed to work — not verified"). Confident prose about unverified
  behaviour is the failure this section exists to prevent.

Write what only this conversation knows. Do not restate what is already on
disk in `TASKS.md`, a feature document or a context file — link to it instead.

---

POINTER FORM

The header block, a `Resume from:` line, and one sentence. The whole file:

```markdown
# Session: 2026-08-24 14:32

Work: document .claude/domain/product-design.md
Running: /product-design
Resume from: .claude/domain/design-process.md

Read that file. It holds the state; this one only says where it is.
```

No narrative, no file table, no decisions, no next step. Anything more would
be a second account of state the artifact already owns, and two accounts of
the same state that can disagree is worse than one.

---

SUPERSESSION DELETE

If **this conversation itself resumed from a session file**, write the new
snapshot first, then delete the file it resumed from. That file is superseded
— its state now lives in the newer one — and two snapshots of the same work
must never coexist in the directory.

- Take the path from the conversation. `/session-resume` states which file it
  loaded, explicitly, in its briefing.
- **Delete nothing when you cannot tell.** No searching the directory for a
  likely candidate, no deleting by date, no deleting the second-newest file on
  a hunch. An unresumed session file is never auto-deleted.
- Delete only after the new file is written. Never before, and never instead.
- Report the deletion on its own line, beside the path written.

---

COMMIT AND PUSH (skipped under `--no-commit`)

If COMMIT is false, do nothing here and run no git command.

Otherwise (the default), after the file is written and any SUPERSESSION DELETE
is done, follow the commit-and-push protocol — four steps, in this order:

1. **Pull at start.** Already run before anything was written, per ARGUMENT
   PARSING.
2. **Commit.** Stage by explicit path exactly the new session file
   (`git add -- <new-path>`) — plus, when SUPERSESSION DELETE removed a file,
   that file's deletion, in its own command:
   `git rm --cached --quiet --ignore-unmatch -- <superseded-path>`. It stages
   the deletion when git was tracking the file and does nothing when it was
   not — a handoff written by an earlier `--no-commit` save, say — so this
   command never needs to know which, and an untracked superseded path can
   never abort staging of the new file. Make
   one commit: `git commit -m "Save session <slug>"`. The new snapshot and the
   removal of the one it replaces are one unit of work, so they ride in one
   commit.
3. **Pre-push re-sync.** Unless NO_PUSH is true, `git pull` again. A conflict:
   abort the merge, keep the local commit, do not push, and report that it
   needs a manual sync and push.
4. **Push.** Unless NO_PUSH is true, `git push`. On failure, report the exact
   output and stop — never retry, never force-push.

On a non-git VCS (a `## VCS` section in `CLAUDE.md`), only the commit step
runs. On a commit failure (a pre-commit hook, say), surface the exact output
and stop — do not retry, amend or skip hooks. The session file stays written
either way.

---

REPORTING

On success, report exactly this much:

```
Wrote .claude/sessions/2026-08-24-1430-ecc-import-architecture.md (full form)
Deleted .claude/sessions/2026-08-23-0915-ecc-import-architecture.md (superseded)
Committed a1b2c3d — Save session ecc-import-architecture
```

The deletion line appears only when SUPERSESSION DELETE actually removed a
file. The last line carries the commit hash (`git rev-parse --short HEAD`),
with `(not pushed)` appended under `--no-push`. Under `--no-commit` it is
instead one line — `Nothing committed — the session file is uncommitted.` —
and is not repeated or expanded on.

---

DO NOT:
- Stage with `git add -A`, `git add .` or `git add -u`, stage anything but the
  new session file and the superseded file's deletion, commit twice, amend,
  skip hooks, force-push, retry a failed push, branch, or tag.
- Run any git command under `--no-commit`.
- Touch `.gitignore`, or write anything at all outside `.claude/sessions/`.
- Update a previous session file in place, append to one, or reuse its
  filename. Every save is a new file.
- Delete a session file other than the one this conversation demonstrably
  resumed from, or delete that one before the new file is written.
- Skip a section of the full form because it would be empty. Write `N/A`.
- Write a claim under "what worked" without the evidence that backs it, or
  present an inference as a verified result.
- Invent a `Work:` value to avoid `none`, or write more than one.
- Add a row to the known-artifact table for anything that is not a
  project-scoped state document carrying a resume marker.
- Write both forms, or add narrative to the pointer form.
- Write to `TASKS.md`, `FEATURES.md`, `PLAN.md`, a feature document, or
  anything under `.claude/context/`, or copy their contents into a section
  instead of linking to them.
- Run any shell command other than the single clock read and the git
  commands of the commit-and-push protocol.
- Start, finish, or continue the work being handed off. Writing the file is
  where this command ends.
