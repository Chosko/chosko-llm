# Branch: reorder — an entry moves

Read this when `./SKILL.md`'s CLASSIFY chose reorder. Together with
`./SKILL.md` it is the whole branch, and `./delete.md` and `./insert.md`
carry the mechanics: a reorder is a skip-and-insert, so this file composes
those two, cites them by path, and adds only its boundary, its tier and its
reason wording. It writes nothing itself.

---

## Applies when

An existing task or runbook step is to run at a different position in its
sequence.

**A change to `Preconditions:` that does not move an entry is an amend, not a
reorder**, and routes to `./amend.md`. That boundary is what keeps
`./SKILL.md`'s classification unambiguous: without it, "make task 45 wait on
task 42" has two plausible branches.

## Impact walk

`./delete.md`'s, for the entry leaving its position, then `./insert.md`'s,
for the replacement at the new one.

## Owner sequence

- **A task** — `[SKIP]` the entry in place, with a reason naming the reorder
  (`reordered — replaced by task <K>, <before|after> task <M>`), per
  `./delete.md`; then insert a replacement carrying its spec at the new
  position, per `./insert.md`. Ids are never renumbered and no block moves:
  ids are stable and order is appearance order, per
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *Index file format* — so a move is a new id at the new place.
- **A runbook step** — the same shape: strike it, with a reason naming the
  reorder, per `./delete.md`; then a positional insert at the new place, per
  `./insert.md`.

## Tier

Fixed, not judged: every reorder is **structural**, because it changes an
order or an edge by definition. The editorial question is still asked, per
`./SKILL.md`; under A the gate shows the same sequence as under B, with that
reason, since no step of a reorder can be dropped as wording.

## Verification

`./delete.md`'s and `./insert.md`'s, both.

## Outcomes

Theirs — `[SKIP]` or a struck step on the old entry, a new task or pending
step at the new position. None of its own.

## Never

- Write anything itself.
- Renumber an id, move a block or a step, or rewrite a `Depends on:`.
- Restate a rule `./delete.md` or `./insert.md` owns.
