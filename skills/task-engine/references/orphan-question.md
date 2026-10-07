# The orphan question

Authority for: when a free-form task is offered to a planned feature, how the
question is rendered, and what each answer does.

Extracted verbatim from `/task-add`'s `THE ORPHAN QUESTION`.

---

## When it is asked

Asked only on a free-form run — one not planned from a feature — and only when
`.claude/FEATURES.md` exists; on a project without that file the question is
not asked and nothing is said about it.

## The question

Just before the run's closing approval prompt, render:

> These features are planned and could take this task:
>
>   <title> (`<slug-a>`)
>   <title> (`<slug-b>`)
>
> Does the task belong to one of them — name it — or stay on its own (the
> default)?

listing every `[PLANNED]` entry in `.claude/FEATURES.md`, in index order —
the only status an attached task leaves true. When no entry is `[PLANNED]`
there is nothing to attach to, and the question is not asked.

## The answers

- **A slug** attaches the task to that feature: read the entry's `Doc:` as
  the primary context, revise the draft against it (the `Feature:` line, the
  Goal naming the feature, the document under Hints), and re-present the plan
  at the same gate. The question is asked on every free-form run, a split
  included; on a split plan every part is attached the same way.
- **none** — or an approval that does not address the question — writes
  the task as a free-form task, with no `Feature:` line.

---

## Per-consumer notes

- **`/task-add`** — asks it only when FEATURE is unset and SHORT is false: it
  is not asked under `--short`, because its only non-`none` answer is the
  `--single` path, which `--short` cannot take. It renders it in PHASE 3, just
  before **"Approve and write?"**. A slug takes the `--single` path for that
  feature — the entry's `Doc:` read as PHASE 1b's primary context — and from
  then on SINGLE-TASK ATTACHMENT applies in full, the write-back line included;
  on a split plan the write-back line names every attached ID.
