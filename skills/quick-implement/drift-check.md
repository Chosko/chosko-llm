# The drift check

Read by `/quick-implement` during the spec conversation, once the spec's goal,
criteria and hints are drafted. It finds where the project's documentation
already says something about what the spec changes, and whether the spec
agrees with it.

---

## What is searched

The project's documentation, wherever it exists:

- the domain layer — `.claude/domain/`, feature documents included;
- the context layer — `.claude/context/`;
- `CLAUDE.md`;
- `README.md`.

A layer the project does not carry is skipped silently. With
`feature=<slug>`, that feature's document is already read in full as context;
it is searched like the rest, and its hits are classified like any other.

## How it searches

1. **Collect the terms.** From the drafted spec: the identifiers it names
   (functions, types, flags, commands, config keys), the files it will touch,
   and the domain terms its goal and criteria use.
2. **Search, do not read.** Run search commands (Grep, or `grep -rn`) for
   those terms over the layers above. Read no document whole on the strength
   of its name.
3. **Pinpoint.** For each hit, find the enclosing section — the nearest
   heading above the matching line — and read only that section.
4. **Discard noise.** A hit whose section does not describe behaviour the
   spec changes (a passing mention, an example on another subject) is not a
   hit.

## How each hit is classified

With the design-change check's two kinds, `../task-engine/references/design-change.md`
§ *Enumeration*:

- **settles** — the section leaves the matter open and the spec decides it;
- **diverges** — the section states one thing and the spec does another.

The check applies to every documentation layer searched, not only to the
paths that check's owner table lists; for an owned path the owner is named at
the gate, since its follow-up is that owner's amend.

## What it does with them

- **Divergences are listed at the gate and never block.** The run does not
  refuse, redraw or stop because the spec disagrees with a document. The
  gate names each one in plain words; the user may change the spec there.
- Every hit, of either kind, goes into the spec's `## Drift` section
  (`./spec.md`).
- The closing report turns them into follow-ups: `/architect amend` for a
  diverging point in a feature document, `/pipeline-revise --catch-up <spec>`
  for the rest.

The check never edits a document. Bringing the documentation up to date is
the follow-up's job, after the code has landed.
