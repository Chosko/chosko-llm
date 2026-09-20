---
name: follow-ups
version: 0.1.1
type: command
description: List what this conversation would lose if it ended now — actions proposed but never executed, outcomes never recorded on disk, decisions written down nowhere — as a numbered list, or exactly `No follow-ups left`. Use it before a session ends, or when a run stopped early.
---

# /follow-ups
# Global command: read this conversation and list what it would lose if it
# ended now. Read-only — no file is opened, nothing is written, nothing is
# invoked. Takes no arguments. The answer is `No follow-ups left` or a
# numbered list, each item a slash command plus a short "to …" explanation
# wherever a command fits. Work already tracked on disk is never a
# follow-up. The numbering is the handle: the user may reply by number, and
# acting on a number is ordinary conversation, not something this command
# implements.
# Usage: /follow-ups

GOAL
Answer one question: **if this conversation ended right now, what would be
lost?** An empty answer is a guarantee, not a shrug — it says the session
can be quit with no information and no operation left behind.

WHAT COUNTS
Read the conversation, and nothing else. Three kinds of thing are
follow-ups:

- an **action proposed but never executed** — something this session said
  it would do, or offered to do, and did not;
- an **outcome never recorded on disk** — something that happened here and
  left no trace in a file, an index or a commit;
- a **decision or fact taken in conversation and written down nowhere** —
  it exists only in the transcript, and the transcript is what is about to
  go away.

WHAT DOES NOT
Work already tracked on disk is not a follow-up. `/runbook-run X to
continue the implementation` is not one: the runbook already holds those
steps, and the next session finds them by reading it. But a task created in
this conversation and not yet appended to the running runbook **is** one —
nothing on disk connects it to the work in flight, so it can slip out of
the implementation pipeline unnoticed. The test is not "is it written
down"; it is "does what is written down lead a later session to it".

THE OUTPUT
Exactly one of:

- the single line `No follow-ups left`; or
- a numbered list, one follow-up per item.

Nothing else — no preamble, no summary of the conversation, no closing
offer.

Write each item as a slash command plus a short "to …" explanation wherever
a command fits the follow-up:

```
1. /task-add feature=password-auth to reconcile tasks 12 and 14, which went
   stale after the amendment
2. /runbook-create --append to put task 31 into the runbook this session is
   running
```

A free-form item is legal where no command fits. Prefer the command form
whenever one does.

THE NUMBERING IS THE HANDLE
The numbers are there so the user can reply by number — "execute 1 and 2
now", "insert 3 as the next step in this runbook". Acting on a number is
ordinary conversation, handled the way any other request is; this command
does not implement it, and does not offer to.

STOP THERE
Print the line or the list, and stop. Take no argument. Open no project
file — not `.claude/TASKS.md`, not a runbook, not the index. Write nothing,
commit nothing, and invoke no other command.
