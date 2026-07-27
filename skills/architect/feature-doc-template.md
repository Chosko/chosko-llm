# Feature document and FEATURES.md entry schemas

Read this in PHASE 3, every run. It carries both things PHASE 3 writes: the
feature document, and the index entry that points at it.

---

## `.claude/domain/features/<slug>.md`

One document per low-level feature. Sections in this order.

```markdown
# <Feature name>

<One paragraph: what this feature is, in terms a reader who knows the
product but not the code would recognize.>

## Purpose

<What problem this solves and for whom. One or two paragraphs. If the
feature came from product-design.md, this is the technical restatement of
its high-level description — link the section rather than restating it at
length.>

## Scope and non-goals

<What is in and, more importantly, what is deliberately out. Non-goals are
the section future readers actually need: without them, every later session
re-litigates whether this feature should also do X.>

## Architecture

<The components this feature needs and what each is responsible for. One
subsection or bullet per component: its responsibility in a sentence, and
how it relates to the others. Mid-to-high level — a component is a
meaningful unit of responsibility, not a class.>

<Where an existing part of the system is extended rather than added to,
name it and say how. Reference the context layer
(`.claude/context/<file>.md`) rather than describing the existing code from
scratch.>

## Data and state

<What is stored, where it lives, and what its shape is at the level of
fields and relationships — not migrations or schemas-as-DDL. What is
in-memory versus persisted, what is derived, and what the source of truth
is for each piece.>

## Interfaces and contracts

<The boundaries: what this feature exposes to the rest of the system and
what it expects from it. Signatures in prose or as declarations are fine;
implementations are not. Include the failure contract — what happens when
an input is invalid or a dependency is unavailable.>

## Dependencies

<Other features this one depends on, by slug, and what it needs from each.
Also external dependencies (libraries, services) with a one-line reason for
each — an unexplained dependency is the hardest thing to remove later.>

## Open questions

<What could not be resolved at architecture time, and what each blocks.
Write these down rather than guessing: an open question in this section is
a normal state, and a guess presented as a decision is not.>

<Omit the section entirely only when there are genuinely none — its
absence should mean something.>
```

Two things this document must not contain, however tempting:

- **Code.** Not implementations, not snippets that "show the shape". The
  moment code lands here it becomes the spec, and it is written against a
  codebase that will have moved by planning time.
- **File-by-file plans.** No "edit `src/foo.ts`, add `bar()`". `/task-add`
  produces that against the code as it then stands, which is the only time
  it can be correct.

If the feature is being re-architected, update this document in place. Keep
its slug and its heading; rewrite the sections whose design changed. Do not
create a second document, and do not append a changelog — the design is the
current truth, and the history lives in VCS.

---

## `.claude/FEATURES.md` entry

Appended for a new feature, updated in place for an existing one:

```
---

## <slug> — <one-line title>

Status: [NEW]
Doc: .claude/domain/features/<slug>.md
Source: product-design.md § <section>
Tasks: none

---
```

| Field | Written by | Notes |
| --- | --- | --- |
| `<slug>` | `/architect` | Stable kebab-case identifier. Never renamed, never reused. |
| `Status:` | `/architect` | `[NEW]` / `[ITERATED]` here. `[PLANNED]` is `/task-add`'s. |
| `Doc:` | `/architect` | Path to the feature document. |
| `Source:` | `/architect` | `product-design.md § <section>`, or the literal `prompt` when architected with no design documents. |
| `Tasks:` | **`/task-add`** | Write `none` only when creating a brand-new entry. On an existing entry, leave the line untouched. |

There is no `Last feature number` counter and no numeric IDs — slugs are the
identifiers, so there is nothing to count.

### The `Tasks:` rule, restated

`FEATURES.md` is the one artifact in the pipeline with two writers. The split
is **by line**, which is what makes it safe: `/architect` never writes
`Tasks:`, `/task-add` never writes `Doc:` or `Source:`. Overwriting `Tasks:`
here would destroy the only link from a feature to the tasks generated from
it — the link reconciliation depends on.

### Status transitions this skill may write

| From | To | When |
| --- | --- | --- |
| (none) | `[NEW]` | First write of a new feature. |
| `[NEW]` | `[NEW]` | Re-architecting a feature that was never planned. |
| `[PLANNED]` | `[ITERATED]` | Re-architecting a feature whose tasks exist (PHASE 0b). |
| `[ITERATED]` | `[ITERATED]` | Re-architecting again before re-planning. |

Illegal, and not to be written under any circumstances:

- **`[PLANNED]` → `[NEW]`.** Tasks were generated from this feature. Even if
  every one is later pruned, the feature stays `[PLANNED]`.
- **`[NEW]` → `[ITERATED]`.** `[ITERATED]` means the backlog drifted from the
  design; with no tasks downstream there is nothing to drift from.

---

## Slug naming

- Kebab-case, derived from the feature name: "Session handling" →
  `session-handling`.
- Specific enough to stay unambiguous as the product grows — `auth` is a bad
  slug in a product that will later have API keys and OAuth; `password-auth`
  is a good one.
- Never renamed. If the name turns out wrong, the title line can change; the
  slug cannot. A renamed slug orphans every task's `Feature:` line pointing
  at it.
