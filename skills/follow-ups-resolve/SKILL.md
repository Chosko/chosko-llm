---
name: follow-ups-resolve
version: 0.2.0
type: skill
description: 'Act on a user reply to a numbered Follow-ups list: rewrite the list from the feedback until the user approves it, then execute it, delegating items to subagents. Trigger whenever the user answers such a list by number or as a whole — "do 1 and 3", "flip all eligible features to [DONE]", "ask me about 2 now", "fix it in place", "I will handle 4 myself, remove it" — whatever produced it: /follow-ups, a /runbook-run or /task-implement closing report, or any numbered list in that shape. Not for: a reply by the P<n> handle of a parked question, which answers that question; a new request unrelated to the list; producing a list, which is the job of /follow-ups.'
requires: command:follow-ups
---

# /follow-ups-resolve
# Global skill: act on the user's reply to a numbered Follow-ups list. Not
# invoked by name — selected from the description above. Keeps one working
# list, rewrites it from the user's feedback until it is approved, then runs
# it: delegates items to subagents, relays their genuine questions, and brings
# every new follow-up back for approval. Beside a running /runbook-run it
# resolves and approves but defers execution to the run's end. Commits nothing
# of its own — each item commits the way the command it runs does.

THE WORKING LIST
One list per conversation. It starts as the Follow-ups list the user replied
to, and every later reply rewrites it — never a second list beside it. Its
items are written the way `/follow-ups` § THE OUTPUT writes them.

The numbering is the reply handle: the list is numbered from 1 each time it
is printed, as one sequence, and a reply's numbers refer to the latest
printing.

Its output is the `Follow-ups` heading and the numbered items. Once any item
is approved, the items split into two sections under that heading —
**Approved** first, then **Awaiting approval** — the numbering running on
across both. An executed item leaves the list, its outcome reported in one
line; a list with no items left is the line `No follow-ups left`.

RESOLVE
The user's feedback rewrites the list: items that share an action are merged
into one, items the user takes on are removed, a question the user asks to be
asked is put now and its answer rewrites the item it belongs to, and a new
instruction becomes a new item. Print the rewritten list and wait. It is
re-presented after every reply until the user approves it.

Nothing executes before approval. A reply that says to execute named items
as printed — "do 1 and 3", "go" for the whole list — approves them; a reply
that changes an item approves nothing, and the rewritten item waits. Silence
is not approval.

EXECUTE
An approved item runs. This session orchestrates: it delegates each item to
a subagent, independent items in parallel and dependent ones in order, and
may do small work itself — a one-line fix in place. Each delegated prompt is
self-contained: the item, the decisions from this conversation it rests on,
and the gate rule below.

GATES
Every delegated prompt tells the subagent to auto-confirm an approval gate
that asks nothing but approval ("Approve and write?") and to surface, as it
usually would, any gate carrying a genuine question. The user's approval of
an item counts as the approval its gate asks for only while the gate's draft
stays inside that item: a draft that diverges from the design the item
states, or leaves a question open, is surfaced, and goes to the user.

The orchestrator never answers a gate raised to it — auto-mode policy may
refuse an agent answering on the user's behalf. It relays the gate to the
user verbatim, and the reply goes back to the subagent that raised it.

NEW FOLLOW-UPS
A follow-up that arises during execution — named in a subagent's report, or
met by this session — goes to the user for approval, then joins the list. It
waits under **Awaiting approval** like any other item and never runs on its
own.

TASKS LAND IN A RUNBOOK
When the project has runbooks (`.claude/RUNBOOKS.md` exists), every task a
follow-up creates brings a companion item proposing the runbook and the
position it belongs at — `/runbook-create --append <runbook> --after <step>`
to put task <N> where its work falls. That item is part of the list like any
other: it is approved or rewritten, then executed. A task outside a runbook
drifts out of the implementation pipeline (`/follow-ups` § WHAT DOES NOT).

DURING A RUNBOOK RUN
While a `/runbook-run` is in flight, the user may resolve and approve items
under the rules above, but **nothing executes until the run ends** — not even
with the whole list approved. The list is printed on demand only:
`/follow-ups` invoked mid-run prints what has been collected so far, Approved
first, then Awaiting approval, and a reply that rewrites or approves items is
acknowledged in one line, never by re-printing the list. A follow-up that
arises mid-run is printed once, when it arises, as the one line `Follow-up:
<item>`, and joins the list under **Awaiting approval**. An approval moves the
items it names into **Approved**, merged with an item already there where they
share an action. A reply by a parked step's `P<n>` handle answers that step
and is never an approval here.

At the run's end the closing report's Follow-ups group carries the list — the
items still awaiting approval appear there, once, not in a second list after
it. After the report the approved items start executing, without waiting for
another reply, except an item whose precondition is an item still awaiting
approval: it waits until that one is approved and done.
