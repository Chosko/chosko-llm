# The spec file

Read by `/quick-implement` at the gate, when it drafts the spec, and again
when it writes it.

---

## Where it lives

`.claude/specs/<YYYY-MM-DD>-<slug>.md`. `<YYYY-MM-DD>` is the date of the
run; `<slug>` is the spec's title in kebab-case — lowercase, words joined by
`-`, punctuation dropped. When a file of that name already exists, the new one
takes a `-2` suffix (`-3`, … on a further collision); an existing spec is never
overwritten. Create `.claude/specs/` when it is absent.

## Its body

The task body schema, plus one section:

```
# <Title>

## Goal
<what the change does and why, in a few sentences>

## Acceptance criteria
- <one checkable statement per bullet>

## Decisions              ← omit when there are no non-obvious choices
- <a choice made in the conversation, and its one-line reason>

## Hints
- <file or document> (<what to look at there>)

## Drift
- `<path>` § <section> — settles: <the point the spec decides>
- `<path>` § <section> — diverges: <what the document says, what the change does instead>
```

`## Drift` lists every hit the drift check classified (`./drift-check.md`),
one bullet each, with its kind. A check that found nothing writes `none`.
It is the record a later `/pipeline-revise --catch-up` works from, so a hit is
never dropped from it for being minor.

The spec carries no `Status:`, no `Target:`, no task id and no `Feature:`
line: it is not a backlog entry. When the run was anchored with
`feature=<slug>`, the feature document goes under `## Hints`.

## Its lifecycle

1. **Drafted** during the spec conversation, and summarised at the gate.
   Nothing is on disk before the gate is approved or passes on its own.
2. **Written** right after the gate, before implementation starts, so the
   review pair can audit against it (`spec=<path>`).
3. **Staged in the implementation commit**, beside the change it describes —
   one commit holds both.
4. **Deleted only by `/pipeline-revise --catch-up <spec>`**, in the commit
   that brings the documentation up to date. Nothing else deletes it:
   `/quick-implement` never does, and a spec still present is the signal that
   the catch-up has not run.

A run that stops before the gate, or at it, writes no spec.
