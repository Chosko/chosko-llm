# The closing report

Authority for: the report a run that implements work ends with — its two
groups and their order, the one-line shape of *For the record*, the one
numbered *Follow-ups* list and what feeds it, the empty-group form, and the
numbering as the reply handle.

Extracted verbatim from `/task-implement`'s `THE CLOSING REPORT`. When the
report is given and where the `/follow-ups` command's rules are applied are
each consumer's own (`/task-implement`'s CLOSING THE RUN).

---

## The two groups

Every run ends with one closing report — at completion, at a failure halt
and at a stop the user asked for alike — in two groups, in this order, each
under its heading. Its length and what it names follow
`../../interaction-engine/references/messages.md` § *Output*; every question
in it follows § *Questions*:

- **For the record** — one line per item, in exactly this shape:
  `<what deviated> — <why> — <resolved by whom>`. A criterion overshot, a
  wrong premise or cross-reference in the specification, a consequential
  edit outside the declared files, a deliberate departure from the
  specification, the `--no-commit` reminder that nothing was committed. No
  item in this group runs past one line, and none is a question.
- **Follow-ups** — one numbered list, `1.`, `2.`, …, each item as long as it
  needs to be, holding two kinds of item under the one numbering. The run's
  own items: an unresolved `BLOCKING` finding, work left unfinished and why,
  a follow-up naming an owner's command with its anchor and passages. And the
  items the `/follow-ups` command's rules yield when applied to the run's
  reading — the command's body read by name and applied, never invoked. Two
  items naming the same action are one item, in the command form where
  either had it.

An empty group prints its heading and `none`. Two lines in the first
group's shape:

```
Task 245 asked ~25 net lines across two files — the mandated block needed 19 — +31, reviewer approved.
Body Hints named ./test-runner.md for the policy marker — the marker's rule is testing-policy.md step 0 — edit cites the right one, reviewer confirmed.
```

## The numbering is the reply handle

It starts at 1 in every report, carries no meaning beyond the handle, and a
report with a single item still numbers it. A reply by number — "execute 1
and 2 now" — is acted on by the `follow-ups-resolve` skill when it is
available, and otherwise handled as any other request is.

---

## Per-consumer notes

- **`/task-implement`** — the specification is the task body and the
  declared files its `Files:`. *For the record* also carries one line in
  another shape, the review pair (its `review-rounds.md` § *Reporting the
  resolved pair*). Its own *Follow-ups* items add a task left
  `[IN PROGRESS]` and why, a precondition that no longer held, a slug
  declined at the FEATURE COMPLETION proposal, a parking branch whose delete
  failed, and a task parked this run or skipped for want of an answer — its
  `Question:` verbatim and multi-line under its `P<n>` handle in place of an
  item number, options included. A parked task keeps its `P<n>` handle, the
  one it held this run or the next unused one, and a reply by it is that
  task's answer, recorded exactly as a reply mid-run is (BETWEEN TASKS step
  2a), and the next run unparks the task. Order at the end of a run: the
  FEATURE COMPLETION proposal first, then this report, the run's last act
  (CLOSING THE RUN). Under `--agents`, the parent renders the report from the
  per-agent returns it holds: each agent's sixth field is its *For the
  record* lines, attributed to its task, its fifth field feeds the
  *Follow-ups* group attributed the same way, and each `[PARKED]` return is a
  *Follow-ups* item with the question the return carried (its
  `delegated-runs.md`).
