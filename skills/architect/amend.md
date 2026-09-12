# `/architect amend` — one targeted change to one feature document

Read this when ARGUMENT PARSING recognised the `amend feature=<slug>
"<change>"` form, once PHASE 0's domain-layer gate has passed. It carries the
whole arm: a consumer that has read only this file — `/architect` itself, or
a pipeline revision surface reading it by path — can execute it end to end
without opening `SKILL.md`. Where a rule already lives in another file in
this folder, this file cites it by path and restates nothing it owns.

The arm skips PHASE 1 (clarify) and PHASE 2 (architect) entirely: the change
is described, not designed. It edits the sections the change names, runs a
**precision** iterate guard in place of `./iterating.md`'s blanket one, asks
one question at one gate, and writes. It writes no progress marker: an
amendment is one gate long and has nothing to resume.

---

## Inputs

- `<slug>` — from `feature=<slug>`: the feature to amend, an existing
  `.claude/FEATURES.md` slug.
- `<change>` — the quoted text after it: what to change, naming the
  section(s) of the feature document it lands in.
- `--commit`, `--no-commit`, `--no-push` — unchanged in meaning; see
  *Committing* below.

It reads these, and nothing beyond them:

1. `.claude/FEATURES.md` — the entry for `<slug>`: its `Status:`, `Doc:`,
   `Source:` and `Tasks:` lines.
2. The `Doc:` document.
3. `.claude/TASKS.md` — the summary block of each id on `Tasks:`.
4. `.claude/tasks/<N>.md` — only for a task the guard cannot classify from
   its summary block (step 3), and only that task's body.
5. `.claude/domain/product-design.md` — only when the change belongs
   upstream (step 2).

Not the roadmap, not `technical-direction.md`, not the context layer, not
source: nothing is being designed.

## 1. Resolve the feature

- `.claude/FEATURES.md` is absent, or has no entry for `<slug>` → stop,
  listing the slugs that do exist (or saying there are none), and write
  nothing. Never guess at a near match.
- `Doc:` names a file that does not exist → stop and say so. The entry and
  its document disagree, which is a full `/architect <slug>` run's to repair,
  not an amendment's.

## 2. Scope the change

Pin the change to the `##` sections of the document it edits — the sections
`./feature-doc-template.md` defines, as this document actually carries them.
A section counts as named when the change names it, or quotes or names a
passage that lives in it.

- **A change that names no section and points at no passage the arm can
  locate is refused**, with a pointer to the full skill:

  > This change can't be scoped to named sections of `<Doc: path>`. Name the
  > sections it touches, or re-architect the feature with `/architect <slug>`.

  An amendment is surgical by construction; a change that spans the design is
  a re-architecture, and the full skill is one prompt away.
- Draft the edit to the pinned sections only, in the document's own register
  and at its mid-to-high level. `./feature-doc-template.md`'s two
  prohibitions and its update-in-place rule apply unchanged. Every section
  not pinned stays exactly as it is.
- **Upstream.** When the change moves a high-level decision that
  `product-design.md` records — the entry's `Source:` names a
  `product-design.md` section, and that section says otherwise — draft the
  matching high-level edit there too. The technical detail stays in the
  feature document.

## 3. The precision guard

**A `[NEW]` feature takes no guard at all** — it has no tasks. Go to step 4
with an empty touched set.

Otherwise collect the tasks exactly as `./iterating.md` § 1 does: the ids on
`Tasks:`, each looked up in `.claude/TASKS.md`, with an id that resolves to
nothing tolerated exactly as it is tolerated there — ignored, never an error.
`[DONE]` and `[SKIP]` tasks are never classified and never touched.

**Classify every other resolved task as touched or untouched** by the change:

- **From its summary block alone** — its title and its `Files:` line, set
  against the sections step 2 pinned. A task is *touched* when what its title
  says it delivers, or what its `Files:` build, is governed by a changed
  section; *untouched* when neither is.
- **Open its body only when the summary block cannot decide** —
  `.claude/tasks/<N>.md`, for that task alone. A task whose body still cannot
  decide is classified *touched*: staling a task that survives costs one
  reconciliation, while leaving one that does not survive costs a wrong
  implementation.
- A task already `[STALE]` is classified like any other; staling it again is
  a no-op.

Then, before the gate:

- **A touched `[IN PROGRESS]` task refuses the amendment.** Stop the run and
  write nothing:

  > Can't amend `<slug>`: task <N> — "<title>" is `[IN PROGRESS]`, and this
  > change touches it. An implementation is underway against the current
  > design. Finish that task, or reset its status, then re-run.

  This is `./iterating.md` § 2's refusal narrowed to the touched set, and its
  **no override** holds unchanged — not on the user's insistence, not with a
  flag.
- **An untouched `[IN PROGRESS]` task does not refuse.** It is listed at the
  gate as untouched and left alone. That is the precision the blanket guard
  lacks.

## 4. The gate

The arm's one and only gate. One message, carrying:

1. **The change** — each section to be edited, with the drafted edit (before
   → after, or the new text), plus the `product-design.md` edit when step 2
   drafted one.
2. **The touched set** — each touched task's id, status and title, and
   whether its summary block or its body decided it. Untouched live tasks
   follow, one line each, so a classification can be overruled.
3. **The proposed outcome** under each answer below: which tasks go
   `[STALE]`, and what the feature's `Status:` becomes.
4. **The question.** It is asked on every amendment, a `[NEW]` feature's
   included, and is never inferred, classified or pre-answered by the arm:

> Is this change editorial — wording only, with nothing any task builds
> changing?
>
> A. **Editorial** — edit the document; no task is staled and `Status:`
>    stays `<status>`.
> B. **Not editorial** — edit the document, mark <ids | no tasks> `[STALE]`,
>    and `Status:` becomes `<outcome>`.
> C. **Stop** — write nothing.

The user may overrule a classification, or the scope call below, in the same
answer; re-render the outcome and ask again. A reclassification that makes an
`[IN PROGRESS]` task touched triggers step 3's refusal unchanged: stop, and
write nothing. Wait for an explicit answer. Silence, an unclear reply or EOF
is C.

### The status outcome

The arm chooses among the transitions `./feature-doc-template.md`
§ *Status transitions this skill may write* already allows. It adds none,
and that section's illegal list binds here too.

- **Editorial (A)** — no task is staled, and `Status:` stays as it was.
- **Not editorial (B)** — `[STALE]` is written on the touched tasks, and on
  those only. The feature goes to `[ITERATED]` — from `[PLANNED]` or
  `[DONE]`; an `[ITERATED]` feature stays `[ITERATED]` — when any task was
  staled, **or** when the change adds scope no existing task covers: a
  component, a contract or a promise that no live task's title or `Files:`
  answers to. The arm makes that scope call and shows it at the gate as part
  of the proposed outcome; it is not a second question. Otherwise `Status:`
  stays as it was.
- A `[NEW]` feature stays `[NEW]` under either answer.

A non-editorial change to a `[DONE]` feature therefore reaches `[ITERATED]`
whenever it adds scope: its completed tasks are never touched, and the new
work is new tasks.

## 5. Write

On A or B, write exactly the following, adding each path written to
`WRITTEN`:

| Path | What is written |
| --- | --- |
| The `Doc:` document | The sections step 2 pinned, as approved at the gate. |
| `.claude/domain/product-design.md` | The upstream edit — only when step 2 drafted one. |
| `.claude/TASKS.md` | `Status: [STALE]` on each touched task — B only. `Status:` lines only, as `./iterating.md` § 4.1 writes them. |
| `.claude/FEATURES.md` | The entry's `Status:` line — only when the outcome changes it. |

That set is closed. Never `Doc:`, `Source:` or `Tasks:`; never
`.claude/domain/INDEX.md`, which already registers the document; never a
task body, not even one step 3 opened; never a progress marker.

## 6. Report

One closing line:

```
Amended <slug>: <section>, <section>[; product-design.md § <section>] — <editorial | stale: <ids> | stale: none> — <old status> → <new status>.
```

When any task was staled, follow it with
`Reconcile with /task-add feature=<slug>.` — a stale task the user is not
told about is the failure the guard exists to prevent. When `WRITTEN` is
non-empty and the run committed nothing, end with an explicit reminder that
nothing was committed.

## Committing

Under `/architect amend`, `SKILL.md`'s COMMIT AND PUSH applies to `WRITTEN`
unchanged: `--commit`, `--no-commit` and `--no-push` mean what they mean on
every other run,
and PHASE 0 ran the pull-at-start before dispatching here. A consumer that
executes this file by path commits under its own rules; the write set in
step 5 is what it stages.

---

## Never

- Run PHASE 1 or PHASE 2, or ask anything but the gate's one question.
- Infer whether a change is editorial, or skip the question because the
  answer looks obvious.
- Stale an untouched task, or refuse on an untouched `[IN PROGRESS]` one.
- Override a touched `[IN PROGRESS]` refusal.
- Classify, stale or otherwise touch a `[DONE]` or `[SKIP]` task.
- Accept a change the arm cannot scope to named sections.
- Write anything outside step 5's table.
