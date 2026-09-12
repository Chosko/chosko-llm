# Traditional input resolution — `product-design.md` sections

Read this in PHASE 0. It carries the resolution mode that matches a target
against `product-design.md`'s high-level feature sections and against
existing `FEATURES.md` slugs, and the `Source:` value that mode produces.

Nothing else moves here: the gate, the read-the-inputs list, stack
detection, the existing-entry check and the interrupted-session check all
stay in `SKILL.md`, because they are shared by every resolution mode.

## The forms of the input

What ARGUMENT PARSING leaves after stripping the flags is the input,
resolved in PHASE 0. It is one of:

- **Empty** — read `product-design.md` and ask which feature(s) to
  architect.
- **One or more feature names** — matched against `product-design.md`'s
  high-level features and against existing `FEATURES.md` slugs.
- **A free-form description** — architect that, with no design documents
  required. This is the path on a project that has code but has never run
  `/product-design`.

## Resolving the target feature(s)

With no argument, list `product-design.md`'s high-level features and ask
which to architect. With names, match them; when a name matches nothing, say
so and ask rather than guessing. Confirm the resolved list back to the user
in one line before continuing.

## What this mode writes as `Source:`

`product-design.md § <section>`, or the literal `prompt` when architected
directly with no design documents.

PHASE 3 writes the field; this mode only decides its value.
`./feature-doc-template.md` carries the full `FEATURES.md` entry schema and
the by-line ownership split.
