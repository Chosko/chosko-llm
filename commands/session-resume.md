---
name: session-resume
version: 0.3.1
type: command
description: Brief this session from a handoff file under .claude/sessions/ — the newest, the newest from a given date or with a given slug, or a path you name — reporting what was being built, what must not be retried and the next step, then stop. Use it when picking up work /session-save recorded.
---

# /session-resume
# Global command: load one handoff file written by `/session-save` and brief
# the current conversation from it. Single pass — no phases, no conversation,
# no supporting files. Read-only: writes nothing, deletes nothing, and never
# starts the work it just described. Flags a file older than 14 days as
# stale before briefing, names any path the file references that no longer
# resolves, and hands the deletion of the file it resumed from to the user.
# Usage: /session-resume
#        /session-resume <YYYY-MM-DD>
#        /session-resume <slug>
#        /session-resume <path>
# Examples: /session-resume
#           /session-resume 2026-08-24
#           /session-resume ecc-import-architecture
#           /session-resume .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

GOAL

- Resolve one file out of `.claude/sessions/`, brief this session from it, and
  stop.
- The briefing carries what a new conversation would otherwise repeat or lose:
  what was being built, what must not be retried, and the exact next step.
- **Read** the handoff; never act on it. The user asked to be told where
  things stood, not to have the next step taken for them.

$ARGUMENTS

---

THE RESOLUTION RULE

This section — ARGUMENT PARSING and FINDING THE FILE together — is the whole,
self-contained rule for turning an argument into one handoff file. Another
session command applies it by name, as "the resolution rule in
`/session-resume`", without restating it: such a command names the picked file
on its own first output line, in its own words; everything else here applies
to it unchanged.

ARGUMENT PARSING

Try the four recognized forms of `$ARGUMENTS` in this order:

| Argument | Behaviour |
|---|---|
| a path — contains `/` or `\`, or ends in `.md` | read that file directly, with no candidacy check |
| a date — matches `YYYY-MM-DD` exactly | the newest candidate from that date |
| a slug — anything else that is not purely numeric | the newest candidate whose filename's slug part equals it exactly |
| *(none)* | the newest candidate in `.claude/sessions/` |

- **Slug part:** what follows the `YYYY-MM-DD-HHMM-` prefix and precedes
  `.md`. `2026-08-24-1430-ecc-import-architecture.md` has the slug
  `ecc-import-architecture`.
- Match slugs exactly, on the filename alone.
- A slug that equals no candidate's slug part: name the nearest existing slugs
  — up to five, those sharing the longest prefix or the most words with it —
  and stop. No substring or fuzzy fallback, no fall-through to the newest
  candidate: guessing a file for a name the user typed would load the wrong
  session.
- **There is no task-number selector.** A bare number is not a slug (no slug
  `/session-save` generates is purely numeric) and not a recognized argument.
  Say so in one line and carry on with the newest candidate — like
  `/session-save`, do not refuse over a bare number.

FINDING THE FILE

1. List `.claude/sessions/` with the file-listing tool, and match dates and
   slugs against the filenames it returns. Do **not** run `ls`, `find`,
   `grep`, `git`, or any other shell command to do it.
2. **Only a top-level file carrying a `Work:` line is a candidate.** The
   directory may hold companion documents that are not handoffs (a
   hand-written notes file, a scratch plan) and subfolders (such as the area
   handoffs of an orchestrated session, and `pending/`). The `Work:` line is
   mandatory in both forms `/session-save` writes, so it is the discriminator.
3. **Skip a non-candidate silently** — a file with no `Work:` line, a
   subfolder, anything inside a subfolder. Not an error, not a warning, not a
   line of output.
4. **Break ties deterministically.** Files can share the identical
   `YYYY-MM-DD-HHMM` prefix, and several can carry the same slug. Sort the
   candidates on the **full filename**, descending, and take the first.
5. **Name the picked file** on the first line of the output, before anything
   else, so the user can correct a wrong pick by re-running with an explicit
   path:

```
Resuming from .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
```

- **Read an explicit path as given**, with no candidacy check. If it has no
  `Work:` line, brief from whatever it does carry and say so in one line.

Stop, reporting plainly, in four situations:

- No `.claude/sessions/` directory — say the project has no session store and
  point at `/session-save`. Do **not** create the directory.
- The directory exists but holds no candidate, or none from the requested
  date — say so, and for the date form name the dates that do have
  candidates. Do not fall back to a different date.
- A slug matches no candidate — name the nearest existing slugs, as above.
- An explicit path does not exist — say so. Do not fall back to the newest
  candidate.

**Never invent a briefing.** With no file, there is nothing to report; say
plainly that nothing was saved rather than give a plausible-sounding summary.

---

FOLLOWING A POINTER

A **pointer-form** file carries a `Resume from:` line and one sentence, and
holds no state itself:

```markdown
# Session: 2026-08-24 14:32

Work: document .claude/domain/product-design.md
Running: /product-design
Resume from: .claude/domain/design-process.md
```

- Read the artifact named by `Resume from:` and brief from **that**, using the
  session file only for its header block.
- If that path no longer resolves, say so on its own line and brief from what
  the pointer file itself carries — its `Work:` and `Running:` lines and
  nothing more — and say the briefing is thin.
- The file this command resumed from is the **session file**, never the
  artifact. The artifact belongs to the skill that maintains it; never name it
  for deletion.

---

BEFORE THE BRIEFING

Run both checks **before** the briefing, never after it.

**1. Staleness — 14 days.** Compare the file's date prefix against today. If
it is more than 14 days old, flag it:

```
This handoff is 23 days old. Treat its file state and next step as claims
about a repository that has since moved.
```

- Take today's date from the session context. If the context carries none, a
  single clock read (`date`) is the only shell command this command may run —
  never `git`, never `ls`, never `grep`.
- Staleness is a **flag, never a refusal**: brief the file anyway.

**2. Paths that no longer resolve.** Check the files the `Current state of
files` table names, and any named by `Work:`, `Resume from:` and the prose.
Name each one that is gone:

```
Paths this handoff names that no longer exist:
  scripts/cmd-impl.sh
  .claude/tasks/118.md
```

Then brief without treating them as present.

---

THE BRIEFING

Fixed in shape: three things, in this order, nothing padded around them.

**1. What was being built.** One short paragraph from `Work:`, `Running:` and
the file's *What we are building* section. `Work: none` is a first-class
value — report it as an anchorless session, not as missing information.

**2. What must not be retried.** From *What did not work (and why)*, *What
has not been tried yet*, and *Decisions made* — the highest-value part of the
briefing. Keep the reasons attached: a decision without its reason gets
silently inherited instead of revisited, and an approach that was skipped is
not an approach that was ruled out.

**3. The exact next step.** From *Exact next step*, **verbatim**. Do not
paraphrase it, do not improve it, and do not split it into a plan.

Then:

- The file's own *Current state of files* table if it has one, and its
  blockers and environment notes if they carry anything. Leave everything
  else in the file on disk — do not re-narrate it.
- A full-form file missing sections: brief the sections it has, name the ones
  it lacks in one line. Never fill a missing section with a plausible guess.

**Then the areas, when the file has a folder.** When `.claude/sessions/` holds
a folder named after the resolved file's stem (its filename without `.md`),
list it with the file-listing tool and name each `agent-<area>.md` in it by
area, with its path:

```
Area handoffs (give each area's next agent its file):
  ui       .claude/sessions/2026-08-24-1430-ecc-import-architecture/agent-ui.md
  storage  .claude/sessions/2026-08-24-1430-ecc-import-architecture/agent-storage.md
```

- Build the list from filenames alone; never read a handoff's body.
- Listing the areas does not turn orchestrate mode on.
- No folder, or no `agent-*.md` in it: say nothing about areas.

**End by naming the file and handing over the deletion:**

> You resumed from `.claude/sessions/2026-08-24-1430-ecc-import-architecture.md`.
> Delete that file when the `Work:` it describes is finished — deletion is part
> of finishing, not cleanup afterwards. A `/session-save` in this conversation
> removes it automatically as superseded; otherwise remove it at the final
> commit, or when the work is confirmed done.

- That sentence is the only way this command participates in pruning. It
  **deletes nothing itself**; the resumed session acts on it.
- State the path explicitly, so `/session-save`'s supersession delete can take
  it from the conversation rather than guessing at the directory.

---

THEN STOP

After the briefing, **stop and wait.** Start no work, edit no file, create no
file, run no shell command, and take no step of the plan just described — not
even the first one, not even when it is obvious, not even when it is one line.

Say so plainly and end the turn:

```
Stopping here. Say what to pick up and I will start.
```

---

READ-ONLY THROUGHOUT

- Write nothing, create nothing, delete nothing, stage nothing, commit
  nothing. There is no `--prune` and no `--commit`.
- Run no shell command except the single clock read under BEFORE THE
  BRIEFING, and never `git`.
- Read nothing under `.claude/tasks/`, and neither `.claude/FEATURES.md` nor
  `.claude/PLAN.md`, **unless the `Work:` line points there** — `Work: task
  118` makes `.claude/tasks/118.md` fair reading, and nothing else in the
  backlog becomes fair reading with it.
- Open no context or domain file the handoff does not name, and do not
  re-narrate a document the handoff merely links to.

---

FAILURE CONTRACT — degradation, never refusal, with one exception

Every situation below either degrades to the most useful report the files
allow or, when there is nothing to brief from, says so and stops. The one
exception is a slug that matches nothing: the command stops instead of
briefing from the newest file, because guessing a file for a name the user
typed loads the wrong session.

| Situation | Behaviour |
| --- | --- |
| No `.claude/sessions/` directory | Say so, point at `/session-save`, stop. Create nothing. |
| Directory holds no candidate | Say so and stop. Files with no `Work:` line were skipped silently and are not mentioned. |
| No candidate from the requested date | Say so, name the dates that do have candidates, stop. |
| An explicit path that does not exist | Say so and stop. Do not fall back to the newest candidate. |
| A slug with no exact match | Name the nearest existing slugs and stop. No substring or fuzzy match, no fall-back to the newest candidate. |
| An explicit path with no `Work:` line | Brief from what it carries, say so in one line. |
| `Resume from:` names a path that is gone | Say so, brief from the pointer file's header alone, call the briefing thin. |
| A full-form file missing sections | Brief the sections it has, name the ones it lacks in one line. |
| File older than 14 days | Flag before the briefing, then brief normally. Never a refusal. |
| Paths in the file that no longer exist | Name each one before the briefing, then brief without them. |
| A bare number | Say it is not a recognized argument in one line, carry on with the newest candidate. |
