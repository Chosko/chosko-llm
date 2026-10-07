# The design-change check

Authority for: which paths another pipeline command owns, how a drafted
task's points against an owned document are enumerated as *settles* or
*diverges*, the question a diverging point raises, what agreement writes into
the drafted body, what disagreement does, and the hard rules.

Extracted verbatim from `/task-add`'s `DESIGN-CHANGE CHECK`. Its phase labels
(`PHASE 2`, `PHASE 3`, `PHASE 4`) are that command's own and are kept in its
note below.

---

## What it applies to

Applies to **every task the run drafts** — the documentation task, a single
free-form task, each part of a split, and any existing body rewritten during
reconciliation. What it catches is a task whose implementation would change a
design the user has not seen changed: the user agrees to the design change at
the gate, or the task is redrawn. A document is never kept wrong on purpose,
and a path is never marked read-only.

## Detection

These paths are owned by another command in this pipeline. This table is the
sole source of ownership — do not try to derive it from a project's domain
layer, which most projects do not carry:

| Path | Owner |
| --- | --- |
| `.claude/domain/features/*.md` | `/architect` |
| `.claude/domain/product-design.md`, `technical-direction.md`, `business-model.md` | `/product-design` |
| `.claude/domain/product-roadmap.md` | `/product-roadmap` |
| `.claude/PLAN.md` | `/production-plan` |

`.claude/FEATURES.md` and `.claude/TASKS.md` are **excluded**: they are split by
line rather than by file, and `/task-add` is itself one of their writers.

Run the check against both the drafted `## Hints` and the summary block's
`Files:` line, for every task drafted in the run. A path matching a row above
is a *detected file*.

## Enumeration

For each detected file, list the points at which the task's implementation
touches what the document says — numbered, one line or two each, each naming
the passage it lands on. "Review this document for drift" is not a point.
Every point is one of two kinds:

- **settles** — the document leaves the matter open (an open question, an
  unstated detail, a choice the design defers to implementation) and the task
  decides it. No conflict with the design.
- **diverges** — the document states one thing and the task will do another.
  A design change.

A detected file with no points is a path in `## Hints` like any other.

## The question

Asked only when at least one point diverges, at the run's gate — one block
per task, every detected file's diverging points together, settling points
listed beneath for the record:

> The task to <title, in plain words>, as drafted, would change the design:
>
>   1. <what the design says now, what the task would do instead, and why>
>      (`<path>` § <section>)
>   2. …
>
> It also settles, without conflict: <the point> (`<path>` § <section>).
>
> Agree to these design changes? (task <N>)

A task whose points all settle asks nothing; its settled points still go into
the body below.

## Agreement

The design change is agreed as a whole, not passage by passage: the
implementer updates every passage of the document that states the old
design, the enumerated ones included, and introduces no meaning beyond the
agreed change. The path stays in `## Hints` and joins `Files:`. Write it into
the drafted body before it is written — `## Acceptance criteria`:

> - `<path>` states the agreed design change — <the change in one line> — in
>   every passage that stated the old one, and settles <the settled points>.
>   Nothing else in the document changes.

and `## Decisions`:

> - **Design change agreed (user decision, `<YYYY-MM-DD>`):** <one line per
>   diverging point>. Settled here: <one line per settling point>. `<path>` is
>   normally `<owner>`'s; this task updates it for exactly this and for nothing
>   else. A further design decision met at implementation time is not
>   covered: leave that passage untouched and name it under *Follow-ups* as a
>   precise follow-up.

`<YYYY-MM-DD>` is the date of the run. A task with settling points only
records them the same way, without the user-decision marker.

## Disagreement

The task, not the document, is wrong: it is heading somewhere the user does
not want. Return to the questions with the diverging points as the open
questions, redraft, and re-present the plan at the same gate.

## Hard rules

- A diverging point is never written as agreed without an explicit answer.
  Silence is not agreement, and neither is an approval that does not address
  the question: re-ask and wait rather than assume.
- The run never writes a task with an unanswered diverging point. If it would,
  stop the run and report — write nothing.
- **Agreement does not make the drafting command a writer.** It never edits
  an owned document itself; the agreement authorises the *implementer of the
  task it drafts*, at implementation time. One writer per artifact holds for
  the pipeline commands.
- A body rewritten — reconciliation (`./reconciliation.md`), or an amendment
  under `./amend.md` — re-runs the check only on the points the rewrite adds;
  an agreement already recorded in `## Decisions` stands.

---

## Per-consumer notes

- **`/task-add`** — the drafting command. The question is rendered at
  PHASE 3, before **"Approve and write?"**, inside the run's single gate;
  disagreement returns to PHASE 2; the agreed body is written by PHASE 4,
  which never writes a task with an unanswered diverging point; `<YYYY-MM-DD>`
  is the date of the `/task-add` run.
