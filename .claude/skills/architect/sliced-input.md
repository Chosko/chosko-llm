# Slice-aware input resolution — roadmap scope slices

Read this in PHASE 0 for a target the activation probe found a slice for. It
carries slice mode and nothing else: how a target resolves to one milestone's
share of a high-level feature, how several candidate slices are
disambiguated, how the slice's exclusions become the feature document's
non-goals, and the `Source:` value this mode produces.

Everything shared with the traditional mode stays where it is. The input
forms, the gate, the read-the-inputs list, stack detection, the
existing-entry check and the interrupted-session check are `SKILL.md`'s;
matching a target against `product-design.md` sections when no slice applies
is `./sectioned-input.md`'s. This file does not restate any of them.

## What a slice is

`/product-roadmap` writes `.claude/domain/product-roadmap.md`: milestones in
execution order, each headed `## <milestone-slug> — <title>` and each
carrying a `Covers:` list of scope slices in the form

```
Covers:
- product-design.md § Authentication — Email and password only. No
  third-party providers, no SSO, no reset-by-SMS.
```

A **scope slice** is one milestone's share of one high-level feature. Its
identity is the `(milestone, section)` pair — it has no identifier of its
own, and you must not invent one.

The roadmap is read-only here. `/architect` never writes it, and never reads
`.claude/PLAN.md` at all. A slice that turns out to be wrong is fixed by
re-running `/product-roadmap`, not by editing the document from this skill.

## Matching a target to a slice

Compare the target against the section name in each `Covers:` entry — the
text between `§` and the ` — ` that opens the scope statement.

1. **Exact match first**, case-insensitively and ignoring surrounding
   whitespace and trailing punctuation. `Authentication` matches
   `§ Authentication`.
2. **Then a forgiving prose match** — the target is contained in the section
   name or the section name in the target, or the two plainly name the same
   subject. A prose match is never silent: state in one line which slice you
   matched and to which milestone, and let the user correct you before the
   run continues.
3. **Never fuzzy-match past an exact one.** If any entry matches exactly,
   the prose candidates are discarded rather than added to the list.

Prose matching is chosen over a strict exact-heading rule because roadmap
sections are written by hand and get reworded, and a strict rule fails
closed — silently dropping the project into traditional mode, which is the
one outcome the user would not notice. The confirmation line is what pays
for the looseness.

## Resolution, in order

1. **Find every slice whose section matches the target**, across all
   milestones.
2. **One match → architect that slice.**
3. **Several matches, in different milestones → ask which one.** List each
   candidate with its milestone slug and its scope statement, and wait for an
   explicit answer. The user may name the milestone in the invocation
   (`/architect Authentication m1-mvp`) to skip the question; a named
   milestone that matches no candidate is an error to report, not a reason to
   guess.
4. **Take the slice's scope statement as a boundary.** The low-level features
   produced cover that slice and no more. The statement's exclusions become
   the feature document's **non-goals** — the template already has the
   section, so nothing about the document schema changes; only where its
   content comes from is new. Name the milestone in the non-goals text where
   the exclusion is a deferral rather than a rejection ("third-party
   providers — deferred to `m3-oauth`").
5. **Record the milestone in `Source:`** (below).

**The union of several slices is never architected**, and a milestone is
never guessed. Both would silently produce a low-level feature that straddles
milestones, which is exactly the crossing edge this mode exists to prevent.

## What this mode writes as `Source:`

The field gains an optional milestone parenthetical:

```
Source: product-design.md § Authentication (m1-mvp)
```

The parenthetical carries the milestone slug of the resolved slice and
nothing else. It is absent on traditional-mode features and on
`Source: prompt` features, so every existing entry stays valid and a reader
that ignores the suffix keeps working.

PHASE 3 writes the field; this mode only decides its value.
`./feature-doc-template.md` carries the full `FEATURES.md` entry schema and
the by-line ownership split — `/architect` remains the field's only writer.

## Failure contract

- **No roadmap, or a roadmap with no `Covers:` line** → traditional mode,
  **silently**. Not a warning: it is the normal state of most projects.
- **Roadmap present, target section unsliced** → traditional mode for that
  target, stated in one line so the choice is visible.
- **Target section sliced across several milestones, none named** → ask, per
  step 3. Never guess and never architect the union.
- **A slice whose section is absent from `product-design.md`** → architect it
  anyway and warn once, consistent with `/product-roadmap` warning rather
  than refusing on the same condition.
- **`--no-slices`** → this file is not read at all; every target takes the
  traditional path. On a project with no roadmap the flag is a silent no-op.
