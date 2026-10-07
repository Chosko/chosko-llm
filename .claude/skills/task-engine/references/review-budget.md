# Review cost controls

Authority for: the `--review-model` / `--review-effort` values and their two
reserved words, the deterministic `auto` tier table behind their defaults, the
read budget that backs the effort axis, what is counted and what is never
counted, and the reporting rules that keep both auditable.

Extracted verbatim from feature `task-peer-review`'s *Review cost controls*
section, which authored every table below. The protocol has two consumers —
`/task-implement`, which resolves the pair and passes it, and `/task-review`,
which honours it — so it is stated once, here, and neither consumer restates
it. The feature citation is for a reader working on the `chosko-llm` repo —
never open that path at run time: the domain layer is not installed, and
everything below stands on its own.

---

## The flags

Two flags on `/task-implement`, each taking a name or one of two reserved
words:

```
--review-model  <name> | same | auto        default auto
--review-effort shallow | standard | deep | same | auto    default auto
```

- Both require `--review`; without it, stop the run in the shape `--rounds`
  already uses.

### The reserved words

`same` means *the implementer's*:

- **on model** — omit `model:` from the Agent call, so the child inherits
  the parent.
- **on effort** — omit the budget block from the spawn prompt entirely, so
  the reviewer reads unbounded.

`auto` resolves deterministically, per the tier table below.

### Model names are not validated locally

Pass model names **verbatim** to the Agent tool. Keep no local allow-list: a
hardcoded list would refuse a model that works, which is a worse failure than
the tool's own rejection of a typo. `/runbook-run --model` already behaves
this way.

## `auto` is deterministic, not a judgement

Resolve it from four signals the implementer already holds when the loop
starts, costing no extra read:

- lines changed and files changed, from the round's own diff;
- the count of acceptance-criteria bullets, from the task body read in Step 1;
- whether the diff touches any non-`.md` file — the executable-surface test
  that separates a prompt edit from a code change.

First matching row wins:

| Tier | Fires when | model | budget |
| --- | --- | --- | --- |
| heavy | executable **and** (>= 400 lines, or >= 8 files, or >= 12 criteria) | `opus` | `deep` |
| light | not executable **and** < 150 lines **and** <= 3 files | `sonnet` | `shallow` |
| standard | everything else | `sonnet` | `standard` |

- `auto` never selects `haiku`: per-criterion verdicts are judgement work.
  `haiku` remains valid when named explicitly.
- Resolve **per task, not per run** — each task's own diff decides: the
  parent passes two strings through and each implementor measures its own
  work.

## The budget is a table of permissions, not an adjective

Two classes of read, treated differently:

- The **navigation layer is never counted and is permitted in full at every
  tier**: `CLAUDE.md` and its chain, `.claude/context/INDEX.md` and the rows
  for the files in the diff, the task body, and the feature document named by
  the task's `Feature:` line. Metering them would push a capped reviewer past
  the index and into source, which is the expensive path.
- **Source and test files beyond the diff are counted** — distinct files, not
  reads; re-opening a counted file is free.

| | shallow | standard | deep |
| --- | --- | --- | --- |
| Navigation layer | full, uncounted | full, uncounted | full, uncounted |
| Source/test files beyond the diff | 0 | 15 | unbounded |
| Whole-file reads | no — hunks plus 40 lines of context | yes | yes |
| Callers and imports of changed symbols | no | direct only | transitive |
| Tests covering the diff | only those in the diff | yes | yes |
| Per-criterion verdicts | from the diff alone; the rest `unverifiable` | full | full |
| Test command | never | never | never |

- shallow sits at zero, and the consequence is load-bearing: **a reviewer
  forbidden to read callers answers "no" to Pre-Report Gate question 3, which
  the gate already says demotes the finding one severity or drops it.** A
  cheap review therefore becomes more *conservative*, never more
  confident-and-wrong, and no finding gets cheaper to assert by spending less
  to check it.
- **No tier ever permits a test command** — not `shallow`, not `deep`, not
  `same`. This is part of `/task-review`'s read-only contract, not a budget
  setting: the reviewer invokes no test command under any budget, any testing
  policy, and either invocation path. Reading test *files* as source is a
  different thing, governed by the table above.

## A cap that binds must be reported

15 is set not to bind on an ordinary task. When a cap actually binds:

- stop investigating;
- report the remaining criteria under the gate as usual;
- say in one line that the cap bound.

## The resolved pair is reported

Report the resolved pair once per task alongside the round summary, so
`auto` is auditable:

```
Review: sonnet / standard (auto — 210 lines, 4 files, code)
```

---

## Per-consumer notes

- **`/task-implement`** — the producer. Its `review-rounds.md` reads this file
  to resolve `--review-model` / `--review-effort` and pass the result: the
  Agent call carries `model:` unless the model resolved to `same`, in which
  case it is omitted and the child inherits; the spawn prompt carries the
  budget block unless the effort resolved to `same`, in which case it is
  omitted entirely. Resolution runs per task, from that task's own round diff.
  In batch mode the launcher passes the two strings through and measures
  nothing.
- **`/task-review`** — the consumer. It honours the budget block it was handed
  and reports a cap that bound. Its own gates are unchanged: the budget caps
  reads, never admissibility, and no finding is admissible that a tier's own
  limits prevented it from checking — the Pre-Report Gate resolves that. A
  **manually invoked** `/task-review` receives no budget block and has no
  cost-control flags: it runs in the user's own session, on the model they
  chose, and reads unbounded.
- **`/task-iterate`** — no cost controls apply. It runs in the session that
  holds the tree, never as a subagent, so there is no spawn to parameterise.
