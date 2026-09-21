# `/architect amend` — targeted changes to one or more feature documents

Read this when ARGUMENT PARSING recognised the `amend feature=<slug>[,<slug>...]
"<change>"` form, once PHASE 0's domain-layer gate has passed. It carries the
whole arm: a consumer that has read only this file — `/architect` itself, or
a pipeline revision surface reading it by path — can execute it end to end
without opening `SKILL.md`. Where a rule already lives in another file in
this folder, this file cites it by path and restates nothing it owns.

The arm skips PHASE 1 (clarify) and PHASE 2 (architect) entirely: the change
is described, not designed. It edits the sections the change names in each
named document, runs a **precision** iterate guard per feature in place of
`./iterating.md`'s blanket one, settles one question per feature at one gate —
on its own when the evidence is clear, asking only when it is not — and
writes. It writes no progress marker: an amendment is one gate long and has
nothing to resume.

---

## Inputs

- `<slugs>` — from `feature=<slug>[,<slug>...]`: one or more features to
  amend, each an existing `.claude/FEATURES.md` slug, comma-separated with no
  spaces.
- `<change>` — the quoted text after it: what to change, naming the
  section(s) of each feature document it lands in. One change, applied to
  every named feature; a change that reads differently per feature names the
  feature beside the part that is its own.
- `--commit`, `--no-commit`, `--no-push` — unchanged in meaning; see
  *Committing* below.

It reads these, and nothing beyond them:

1. `.claude/FEATURES.md` — the entry for each slug: its `Status:`, `Doc:`,
   `Source:` and `Tasks:` lines.
2. Each `Doc:` document.
3. `.claude/TASKS.md` — the summary block of each id on each `Tasks:` line.
4. `.claude/tasks/<N>.md` — only for a task the guard cannot classify from
   its summary block (step 3), and only that task's body.
5. `.claude/domain/product-design.md` — only when the change belongs
   upstream (step 2).

Not the roadmap, not `technical-direction.md`, not the context layer, not
source: nothing is being designed.

Steps 1–3 run per feature, in the order the slugs were given; step 4 is one
gate for all of them; steps 5 and 6 write and report per feature.

## 1. Resolve the features

- `.claude/FEATURES.md` is absent, or has no entry for a slug → stop the
  whole run, listing the slugs that do exist (or saying there are none), and
  write nothing. Never guess at a near match, and never proceed with the
  slugs that did resolve: the run is one change, and a slug the user typed
  wrong is a change they have not yet described.
- A `Doc:` names a file that does not exist → stop the whole run and say so,
  writing nothing. The entry and its document disagree, which is a full
  `/architect <slug>` run's to repair, not an amendment's.

## 2. Scope the change, per feature

Pin the change to the `##` sections of the document it edits — the sections
`./feature-doc-template.md` defines, as this document actually carries them.
A section counts as named when the change names it, or quotes or names a
passage that lives in it.

- **A change that names no section and points at no passage the arm can
  locate in a document is refused for that document**, with a pointer to the
  full skill:

  > This change can't be scoped to named sections of `<Doc: path>`. Name the
  > sections it touches, or re-architect the feature with `/architect <slug>`.

  On a single-feature run that ends the run. On a multi-feature run the
  feature is dropped with that line and the rest proceeds. An amendment is
  surgical by construction; a change that spans the design is a
  re-architecture, and the full skill is one prompt away.
- Draft the edit to the pinned sections only, in the document's own register
  and at its mid-to-high level. `./feature-doc-template.md`'s two
  prohibitions and its update-in-place rule apply unchanged. Every section
  not pinned stays exactly as it is.
- **Upstream.** When the change moves a high-level decision that
  `product-design.md` records — an entry's `Source:` names a
  `product-design.md` section, and that section says otherwise — draft the
  matching high-level edit there too, **once for the run**: several features
  sharing one source section share one upstream edit. The technical detail
  stays in the feature documents.

## 3. The precision guard, per feature

**A `[NEW]` feature takes no guard at all** — it has no tasks. Its touched
set is empty.

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
  `.claude/tasks/<N>.md`, for that task alone. A body that decides is a
  decision like any other, recorded as *touched on body* or *untouched on
  body*. A task whose body still cannot decide is classified *touched* and
  recorded as *undecided*: staling a task that survives costs one
  reconciliation, while leaving one that does not survive costs a wrong
  implementation.
- A task already `[STALE]` is classified like any other; staling it again is
  a no-op.

Then, before the gate:

- **A touched `[IN PROGRESS]` task drops the feature from the run.** One
  line, and nothing of that feature is written:

  > Can't amend `<slug>`: task <N> — "<title>" is `[IN PROGRESS]`, and this
  > change touches it. An implementation is underway against the current
  > design. Finish that task, or reset its status, then re-run.

  On a single-feature run that ends the run with nothing written. On a
  multi-feature run the other features proceed. This is `./iterating.md`
  § 2's refusal narrowed to the touched set, and its **no override** holds
  unchanged — not on the user's insistence, not with a flag.
- **An untouched `[IN PROGRESS]` task does not refuse.** It is listed at the
  gate as untouched and left alone. That is the precision the blanket guard
  lacks.

A run every feature of which was dropped, in step 2 or here, stops before the
gate with nothing written.

## 4. The gate

The arm's one and only gate. One message, one section per feature that
reached it, each carrying:

1. **The change** — each section to be edited, with the drafted edit (before
   → after, or the new text).
2. **The touched set** — each touched task's id, status and title, and what
   decided it: *summary block*, *body*, or *undecided*. Untouched live tasks
   follow, one line each, so a classification can be overruled.
3. **The proposed outcome**: which tasks go `[STALE]`, and what the
   feature's `Status:` becomes — under the classification applied on a clear
   case, under each answer when the question is asked.
4. **The classification** — a `Classified:` line on a clear case, the
   question on an ambiguous one, by the rule below.

The `product-design.md` edit, when step 2 drafted one, is rendered once,
above the feature sections. A feature dropped in step 2 or 3 is named in one
line above them too, so the gate shows the whole run.

### Clear or ambiguous, per feature

Whether the change is editorial for a feature is settled by a closed rule
over findings items 1–3 already render — the touched set and what decided
each status in it, the drafted edit, and the scope call (§ *The status
outcome*). "Clear" means a mechanical signal, never the arm's confidence. Test
in this order; the first that matches wins:

1. **Ambiguous** — any one of:
   - a live task is *undecided* — its body was read and still could not
     decide;
   - the scope call is borderline — the change may add scope, but no
     component, contract or promise it adds can be named;
   - the findings point different ways — no task is touched and no scope is
     added, yet contract or interface text in an edited section changes.
2. **Clear not editorial** — a task is touched on its summary block or on its
   body, or the added scope is a nameable component, contract or promise.
3. **Clear editorial** — the touched set is empty, no scope is added, and no
   contract or interface text in the edited sections changes.

A `[NEW]` feature has no tasks, so its touched set is empty; the scope call
and the edited text classify it like any other.

### A clear case

No question. After items 1–3, one line:

```
Classified: <editorial | not editorial> — <evidence>
```

The evidence cites only what items 1–3 render, never an adjective:
`touched on summary block: <ids>`, `touched on body: <ids>` and/or
`scope added: <named scope item> (§ <edited section>)` for not editorial;
`no task touched, no scope added, no contract text changed` for editorial.

### An ambiguous case

The question, with one marked letter — the recommendation:

> Is this change editorial for `<slug>` — wording only, with nothing any
> task builds changing?
>
> <evidence line>
>
> A. **Editorial** — edit the document; no task is staled and `Status:`
>    stays `<status>`.
> B. **Not editorial** — edit the document, mark <ids | no tasks> `[STALE]`,
>    and `Status:` becomes `<outcome>`.
> C. **Stop** — write nothing for this feature.

**The recommendation is derived, never judged.** It is a closed rule over two
findings the gate already renders — the touched set (item 2) and the scope
call (item 3, § *The status outcome*) — and adds no inference of its own:

- touched set empty **and** no scope added → mark **A**;
- otherwise → mark **B**.

The evidence line above the letters states which findings decided it, citing
only what items 2–3 already render — a task id, an edited section, or the
named scope item — never an adjective:

- A marked: `Recommended: A — no task touched, no scope added; A and B write
  the identical set here.` A is marked only on that pair of findings, and on
  it A and B do write the identical set — no task to stale, no `Status:`
  change — so the line says so. Both letters are still offered, so the
  classification can be overruled.
- B marked: `Recommended: B — touched: <ids>` and/or `scope added: <named
  scope item> (§ <edited section>)`.

The marked letter is a recommendation, not an answer: the reply still has to
name a letter, and nothing is written on it alone.

### Waiting, on a multi-feature run

The gate waits for a reply only when at least one feature is ambiguous. One
reply answers every asked feature: a letter per feature (`a: A, c: B`), or
one letter for all of them (`B`). An asked feature the reply leaves unnamed
is C — the marked letter is a recommendation there as everywhere, and
nothing is written on it alone. Clear features never wait: with no feature
asked, the gate renders its `Classified:` lines and goes straight to step 5.

### A classification carried from `/pipeline-revise`

When this arm runs as an owner step of `/pipeline-revise`, that skill's gate
has already settled the editorial question for the same change — by the
user's reply, or by its own classification when nothing there was open. That
classification is carried in and set, per feature, against the letter this
arm's own findings mark under the recommendation rule above:

- **They agree** — apply it with no prompt. After items 1–3, one line —
  `Classified: <editorial | not editorial> — carried from the revise gate; this edit's own findings agree: <evidence>`.
- **They disagree** — **the stricter classification applies**: *not
  editorial* over *editorial*, whichever side carried it. No prompt. After
  items 1–3, one line —
  `Classified: not editorial — carried: <carried>; applied: not editorial — <evidence>`
  — and the closing line in step 6 states the deviation. Staling a task that
  survives costs one reconciliation; not staling one that does not survive
  costs a wrong implementation.

The carried classification replaces the clear-or-ambiguous rule: an
ambiguous case under it is resolved by the same comparison, the arm's own
marked letter standing for its findings. Only `/pipeline-revise` carries a
classification. Standalone `/architect amend` applies the clear-or-ambiguous
rule above.

### Replies

Whenever the arm asks, the user may overrule a touched/untouched call, or
the scope call below, in the same answer, for any feature; re-render the
outcome and re-apply the rules above to the new findings, writing without
another prompt when every feature is now clear, and asking again otherwise.
A reclassification that makes an `[IN PROGRESS]` task touched drops that
feature exactly as step 3 does. Wait for an explicit answer. Silence, an
unclear reply or EOF is C for every asked feature. No flag pre-answers the
question.

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

For every feature classified A or B — answered, applied by a clear case, or
applied from a carried classification — write exactly the following, adding
each path written to `WRITTEN`:

| Path | What is written |
| --- | --- |
| Each `Doc:` document | The sections step 2 pinned, as approved at the gate. |
| `.claude/domain/product-design.md` | The upstream edit — only when step 2 drafted one; once. |
| `.claude/TASKS.md` | `Status: [STALE]` on each touched task — B only. `Status:` lines only, as `./iterating.md` § 4.1 writes them. |
| `.claude/FEATURES.md` | Each entry's `Status:` line — only when the outcome changes it. |

That set is closed. Never `Doc:`, `Source:` or `Tasks:`; never
`.claude/domain/INDEX.md`, which already registers the document; never a
task body, not even one step 3 opened; never a progress marker. A feature
answered C, or dropped, gets no write.

## 6. Report

One closing line per feature:

```
Amended <slug>: <section>, <section>[; product-design.md § <section>] — <editorial | stale: <ids> | stale: none>[ — carried <carried>, applied not editorial] — <old status> → <new status>.
```

A dropped feature reports the line step 2 or 3 gave it. When any task was
staled, follow the lines with `Reconcile with /task-add feature=<slug>.` for
each such feature — a stale task the user is not told about is the failure
the guard exists to prevent. When `WRITTEN` is non-empty and the run
committed nothing, end with an explicit reminder that nothing was committed.

## Committing

Under `/architect amend`, `SKILL.md`'s COMMIT AND PUSH applies to `WRITTEN`
unchanged, one commit for the whole run: `--commit`, `--no-commit` and
`--no-push` mean what they mean on every other run, and PHASE 0 ran the
pull-at-start before dispatching here. A consumer that executes this file by
path commits under its own rules; the write set in step 5 is what it stages.

---

## Never

- Run PHASE 1 or PHASE 2, or ask anything but the gate's per-feature
  question.
- Classify without asking on anything but § 4's clear case — never on an
  undecided body, a borderline scope call or findings that point different
  ways, and never because the answer merely looks obvious — or ask the
  question on a clear case, or on a case a carried classification settles.
  On an ambiguous case, treat the marked letter as the answer: it is shown
  for an explicit reply.
- Stale an untouched task, or refuse on an untouched `[IN PROGRESS]` one.
- Override a touched `[IN PROGRESS]` drop.
- Classify, stale or otherwise touch a `[DONE]` or `[SKIP]` task.
- Accept a change the arm cannot scope to named sections, or proceed past a
  slug that does not resolve.
- Write anything outside step 5's table, or anything for a feature answered
  C or dropped.
