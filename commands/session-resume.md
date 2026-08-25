---
name: session-resume
version: 0.1.0
type: command
description: Brief this session from a handoff file under .claude/sessions/ — the newest one, the newest from a given date, or a path you name — then stop. Reports what was being built, what must not be retried and the exact next step, flags a file older than 14 days as stale before briefing, names any path the file references that no longer resolves, and hands over the deletion of the file it resumed from. Read-only: writes nothing, deletes nothing, and never starts the work it just described.
---

# /session-resume
# Global command: load one handoff file written by `/session-save` and brief
# the current conversation from it. Single pass — no phases, no conversation,
# no supporting files.
# Usage: /session-resume
#        /session-resume <YYYY-MM-DD>
#        /session-resume <path>
# Examples: /session-resume
#           /session-resume 2026-08-24
#           /session-resume .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

GOAL
Resolve one file out of `.claude/sessions/`, brief this session from it, and
stop. The briefing carries the three things a new conversation would otherwise
repeat or lose: what was being built, what must not be retried, and the exact
next step.

This command **reads** a handoff — it does not act on one. Its value is
entirely in the stopping. A resume command that starts working is the failure
mode that makes handoff tooling untrustworthy: the user asked to be told where
things stood, not to have the next step taken for them while they were reading.

$ARGUMENTS

---

ARGUMENT PARSING

`$ARGUMENTS` has exactly three recognized forms:

| Argument | Behaviour |
|---|---|
| *(none)* | the newest candidate file in `.claude/sessions/` |
| `YYYY-MM-DD` | the newest candidate from that date |
| a path | read that file directly |

An argument is a **path** when it contains `/` or `\`, or ends in `.md`. It is
a **date** when it matches `YYYY-MM-DD` exactly.

**There is no task-number selector.** A bare number is not a recognized
argument. Say so in one line and carry on with the newest candidate — like
`/session-save`, this command never refuses over its own arguments. Anything
else unrecognized is handled the same way.

---

FINDING THE FILE

List `.claude/sessions/` with the file-listing tool. Do **not** run `ls`,
`find`, `git`, or any other shell command to do it.

**Only a file carrying a `Work:` line is a candidate.** `.claude/sessions/`
may hold companion documents that are not handoffs — a hand-written notes
file, a scratch plan someone dropped beside the real thing — and a file with
no `Work:` line would otherwise be selected as "the newest file" and briefed
from as though it were a handoff. The `Work:` line is mandatory in both forms
`/session-save` writes, which makes it the cheapest reliable discriminator.

A non-candidate is **skipped silently**. It is not an error, not a warning,
and not worth a line of output — the directory is allowed to hold other
things.

**Ties break deterministically.** Two files can share the identical
`YYYY-MM-DD-HHMM` prefix, so "newest" is ambiguous on the prefix alone. Sort
candidates on the **full filename**, descending, and take the first. Then
**name the file that was picked**, on the first line of the output, before
anything else:

```
Resuming from .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
```

Naming it is what makes the tie-break correctable: if it picked the wrong one,
the user re-runs with an explicit path.

A **path given explicitly is read as given**, with no candidacy check. The
user named the file; that settles it. If it has no `Work:` line, brief from
whatever it does carry and say so in one line.

Two situations stop the command, reported plainly:

- No `.claude/sessions/` directory — say the project has no session store and
  point at `/session-save`. Do **not** create the directory.
- The directory exists but holds no candidate, or none from the requested
  date — say so, and for the date form name the dates that do have candidates.
  Do not fall back to a different date.

**Never invent a briefing.** With no file there is nothing to report, and a
plausible-sounding summary of a session that was never saved is worse than the
plain admission that nothing was.

---

FOLLOWING A POINTER

A **pointer-form** file carries a `Resume from:` line and one sentence. It
holds no state itself, so briefing from it alone would report nothing:

```markdown
# Session: 2026-08-24 14:32

Work: document .claude/domain/product-design.md
Running: /product-design
Resume from: .claude/domain/design-process.md
```

Read the artifact named by `Resume from:` and brief from **that**, using the
session file only for its header block.

If that path no longer resolves, say so on its own line and brief from what
the pointer file itself carries — its `Work:` and `Running:` lines and nothing
more. That is a thin briefing, and saying it is thin is the honest report.

The file this command resumed from is the **session file**, never the
artifact. The artifact belongs to the skill that maintains it and is never
named for deletion.

---

BEFORE THE BRIEFING

Both of these run **before** the briefing, not after. A warning that arrives
after the reader has already absorbed the briefing has arrived too late.

**1. Staleness — 14 days.** Compare the file's date prefix against today. If
it is more than 14 days old, flag it:

```
This handoff is 23 days old. Treat its file state and next step as claims
about a repository that has since moved.
```

Take today's date from the session context. If the context carries none, a
single clock read (`date`) is the only shell command this command may run —
never `git`, never `ls`, never `grep`. Staleness is a **flag, never a
refusal**: brief the file anyway. For a file that is never resumed this flag
is the only pruning signal that will ever fire.

**2. Paths that no longer resolve.** The `Current state of files` table names
files; so may `Work:`, `Resume from:` and the prose. Check them, and name each
one that is gone:

```
Paths this handoff names that no longer exist:
  scripts/cmd-impl.sh
  .claude/tasks/118.md
```

Then brief without treating them as present. A briefing that reports "the
implementation is half-finished in `scripts/cmd-impl.sh`" about a file that
was deleted three commits ago sends the next session looking for something
that is not there.

---

THE BRIEFING

Fixed in shape. Three things, in this order, and nothing padded around them:

**1. What was being built.** From `Work:`, `Running:` and the file's *What we
are building* section. One short paragraph. `Work: none` is a first-class
value — report it as an anchorless session, not as missing information.

**2. What must not be retried.** From *What did not work (and why)*, *What has
not been tried yet*, and *Decisions made*. This is the highest-value part of
the briefing and the whole reason the file exists: without it the next session
repeats the same dead ends at full cost before discovering the same thing.
Keep the reasons attached — a decision without its reason gets silently
inherited instead of revisited, and an approach that was skipped is not an
approach that was ruled out.

**3. The exact next step.** From *Exact next step*, **verbatim**. Do not
paraphrase it, do not improve it, and do not split it into a plan.

Then the file's own *Current state of files* table if it has one, and its
blockers and environment notes if they carry anything. Everything else in the
file is on disk and stays there — the user can read it, and re-narrating it
costs tokens the handoff exists to save.

**End by naming the file and handing over the deletion:**

> You resumed from `.claude/sessions/2026-08-24-1430-ecc-import-architecture.md`.
> Delete that file when the `Work:` it describes is finished — deletion is part
> of finishing, not cleanup afterwards. A `/session-save` in this conversation
> removes it automatically as superseded; otherwise remove it at the final
> commit, or when the work is confirmed done.

That sentence is the only way this command participates in pruning. It
**deletes nothing itself**, and it is the resumed session that acts on it. It
also states the path explicitly so `/session-save`'s supersession delete can
take it from the conversation rather than guessing at the directory.

---

THEN STOP

After the briefing, **stop and wait.** Start no work, edit no file, create no
file, run no shell command, and take no step of the plan just described — not
even the first one, not even when it is obvious, not even when it is one line.

Say so plainly and end the turn:

```
Stopping here. Say what to pick up and I will start.
```

The user resumed a session to be told where it stood. Deciding on their behalf
that the next step should just be done is how a handoff tool becomes something
they stop invoking.

---

READ-ONLY THROUGHOUT

- Writes nothing, creates nothing, deletes nothing, stages nothing, commits
  nothing. There is no `--prune` and no `--commit`.
- Runs no shell command except the single clock read under BEFORE THE
  BRIEFING, and never `git`.
- Reads nothing under `.claude/tasks/`, and neither `.claude/FEATURES.md` nor
  `.claude/PLAN.md`, **unless the `Work:` line points there** — `Work: task
  118` makes `.claude/tasks/118.md` fair reading, and nothing else in the
  backlog becomes fair reading with it.
- Opens no context or domain file the handoff does not name.

---

FAILURE CONTRACT — degradation, never refusal

| Situation | Behaviour |
| --- | --- |
| No `.claude/sessions/` directory | Say so, point at `/session-save`, stop. Create nothing. |
| Directory holds no candidate | Say so and stop. Files with no `Work:` line were skipped silently and are not mentioned. |
| No candidate from the requested date | Say so, name the dates that do have candidates, stop. |
| An explicit path that does not exist | Say so and stop. Do not fall back to the newest candidate. |
| An explicit path with no `Work:` line | Brief from what it carries, say so in one line. |
| `Resume from:` names a path that is gone | Say so, brief from the pointer file's header alone, call the briefing thin. |
| A full-form file missing sections | Brief the sections it has, name the ones it lacks in one line. |
| File older than 14 days | Flag before the briefing, then brief normally. Never a refusal. |
| Paths in the file that no longer exist | Name each one before the briefing, then brief without them. |
| An unrecognized argument | Say so in one line, carry on with the newest candidate. |

---

DO NOT:
- Start, continue or finish the work being handed off — including its first
  step, its obvious step, or its one-line step.
- Edit, create or delete any file, including the session file itself. The
  deletion is handed to the resumed session as an instruction, never performed
  here.
- Run any shell command other than the single clock read, and never `git`,
  `ls`, `find` or `grep`.
- Invent a briefing when no file was found, or fill a missing section with a
  plausible guess.
- Select a file with no `Work:` line as "the newest", or report skipping one
  as an error.
- Pick between same-prefix candidates without naming which one was picked.
- Fall back to another date, or to the newest candidate, when an explicit path
  or date found nothing.
- Delete or name for deletion the artifact a pointer file points at. Only the
  session file is ever superseded.
- Put the staleness flag or the missing-path list after the briefing.
- Paraphrase the exact next step, or expand it into a plan.
- Read `.claude/tasks/`, `FEATURES.md` or `PLAN.md` when `Work:` does not
  point there, or re-narrate a document the handoff merely links to.
