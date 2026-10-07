---
name: session-describe
version: 0.1.0
type: command
description: Print a short plain description of one handoff under .claude/sessions/ — what it is about, where it stopped, its next step, what is still open and blocked, and its area handoffs — without loading it into the conversation. Use it to check a handoff before resuming it.
requires: command:session-resume, command:session-save
---

# /session-describe
# Global command: resolve one handoff by `/session-resume`'s resolution rule
# and print about ten plain lines describing it — what the session is about,
# where it stopped and its next step, the objectives still open, open
# blockers, and its orchestrate-mode area handoffs by name. Does not brief and
# does not stop to wait: the session stays on disk. Reads the header block and
# only the sections it summarises, never a whole file and never an area
# handoff's body. Read-only — writes, deletes, stages and commits nothing; runs
# no shell command.
# Usage: /session-describe [<path|date|slug>]
# Examples: /session-describe
#           /session-describe ecc-import-architecture
#           /session-describe 2026-08-24

GOAL
Answer "what is this handoff about, and where did it stop?" without loading
it. `/session-list` shows every handoff in one line each; this command gives
one handoff about ten lines; `/session-resume` loads it into the conversation
and waits for work. A reader who needs the evidence, the dead ends or the file
table opens the file or resumes it.

$ARGUMENTS

---

RESOLVING THE FILE

Apply the resolution rule in `/session-resume` to `$ARGUMENTS` — its forms,
candidacy, tie-break and stops, unchanged. Name the picked file on the first
output line:

```
Describing .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
```

The file forms, the header block and the section headings are
`/session-save`'s.

---

THE READ BUDGET

From the resolved file, only the lines this command summarises, by targeted
extraction — never a full Read:

- one Grep, with line numbers, for the header lines (`Work:`, `Running:`,
  `Resume from:`) and the `##` section headings, which locates each section;
- then, by line range, only the preamble and the sections summarised below:
  *What we are building*, *Blockers and open questions* and *Exact next step*.

*What worked*, *What did not work*, *What has not been tried yet*, *Decisions
made*, *Current state of files* and *Environment and setup notes* are not
read.

A **pointer-form** file is described from its header block and one line of
the artifact its `Resume from:` names: that artifact's resume marker — its
current-stage, phase or next-step line — found with one Grep. Nothing else of
the artifact is read.

Area handoffs are named from a listing of `.claude/sessions/<session-file-stem>/`
— the file-listing tool, `agent-<area>.md` filenames only. No area handoff's
body is read.

A file whose extracted lines do not fit `/session-save`'s forms — a section
missing, a header line absent — is described as found, with what is missing
named in one line. Never compensate by reading more.

---

THE DESCRIPTION

About ten lines after the first, in this order, each a summary in plain words
and never a quotation of a long section:

1. **About** — what the session is about, from the preamble, or the first
   sentence of *What we are building* when there is no preamble; with its
   `Work:` and `Running:` values.
2. **Stopped at / next** — where it stopped and the very next step or steps,
   from *Exact next step*.
3. **Still open** — the objectives *What we are building* sets that the next
   step shows are not yet done.
4. **Blocked** — open blockers and questions, from *Blockers and open
   questions*; `none` when it says so.
5. **Areas** — the area names, when a subfolder of the session's stem exists.
   Omitted otherwise.

A pointer-form file prints its `Work:` and `Running:` values, the artifact
path, and the artifact's resume-marker line, in place of lines 1–4.

```
Describing .claude/sessions/2026-08-26-0910-orchestrate-checkout.md
About:    rebuilding the checkout flow into three areas (task 141, /task-implement).
Next:     run the checkout area's verification recipe, then merge the payment area.
Open:     the refund path and the receipt email are not started.
Blocked:  none.
Areas:    checkout, payment, receipts.
```

---

DO NOT:
- Brief the session, load it into the conversation, or stop to wait for work.
  Print the description and end; resuming is `/session-resume`.
- Write, edit, create, delete, stage or commit any file, or run any shell
  command.
- Follow a `Work:` path, or read any file beyond the resolved handoff and a
  pointer's artifact line.
- Suggest whether to resume the session or what to do next. Describe it; the
  user decides.
