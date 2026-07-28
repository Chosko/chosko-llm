# Task workflow

This document is the source of truth for the task backlog schema and the
dual-path implementation model. Read it when touching any `task-*` command
or skill, when changing the body schema, or when wiring an external
implementer.

## Roles

- **Author** — Claude Code, via `/task-add`. Plans the task conversationally,
  captures decisions, identifies files, writes the body. Has full repo access.
- **Claude implementer** — Claude Code, via `/task-implement`. The default
  path. Reads the thin body, navigates context/domain files as needed, and
  implements end-to-end.
- **Local LLM implementer** — a less-powerful local model (e.g.
  qwen2.5-coder:14b via Ollama + aider). Optional path. Needs a richer,
  self-contained body to work without external reads. Use `/task-enrich` to
  prepare a thin task for this path.
- **Human implementer** — the user, acting in an external tool an agent
  cannot drive (a game-engine editor such as Unity, a cloud console,
  physical hardware). Claude guides and verifies; the user performs the
  manual steps.

## Target field

Every task body and every TASKS.md summary block carries a `Target:` field:

| Value | Meaning |
| --- | --- |
| `claude` | Thin body. Claude implements, fetching context at implementation time. **Default.** |
| `local` | Enriched body. Self-contained; intended for a local LLM via aider. |
| `claude+human` | Claude implements, but the body declares manual-intervention checkpoints where Claude pauses, walks the user through a step in an external tool, and verifies the outcome before continuing. |
| `human` | The task is executed entirely by the user. `/task-implement` becomes a guided walkthrough: Claude guides and verifies each step but makes no production edits; it still owns the bookkeeping (status flips, the commit). |

`target: claude` bodies are authored lean. `target: local` bodies are
produced by `/task-enrich` from an existing thin body. `claude+human` and
`human` are set by `/task-add` at authoring time when the work involves
steps an agent cannot execute; both REQUIRE a `## Manual interventions`
section in the body (and vice versa — a body with that section must carry
one of these two targets). `/task-enrich` refuses human-involving targets:
a headless local LLM cannot pause for a human.

## Manual interventions section

Optional body section, present exactly when `Target:` is `claude+human` or
`human`. Placed between `## Decisions` and `## Hints`. It opens with a
`⚠ REQUIRES MANUAL INTERVENTION` warning line, followed by numbered
checkpoints. Each checkpoint is anchored to a trigger point ("After X: …"),
describes the manual step in the external tool, and ends with a verifiable
outcome Claude can check itself (a file that must exist, a compile/test
result). The mechanism is generic — Unity is the motivating example, but
any human-in-the-loop environment fits.

```
## Manual interventions

⚠ REQUIRES MANUAL INTERVENTION — pause implementation at these points and
walk the user through them; wait for their confirmation and verify the
outcome before continuing:

1. After <trigger>: <manual step in the external tool>. Verify <checkable
   outcome — e.g. the generated file exists and the project compiles>.
2. After <trigger>: <…>. Verify <…>.
```

At implementation time, verification is independent: Claude checks the
claimed outcome itself (file existence, compile/test result — whatever is
checkable from the filesystem or CLI) rather than trusting the user's
confirmation. On failure it reports exactly what is missing and re-guides;
it never proceeds past an unverified checkpoint unless the user explicitly
overrides.

## Thin body schema (`target: claude`)

```
# Task <N> — <Title>

Target: claude

## Goal
<One paragraph: what and why.>

## Acceptance criteria
- <Verifiable outcome.>
- <…>

## Decisions
<Only present when non-obvious choices were made during authoring — by the
user or by Claude. Each bullet: the choice + a brief why. Omit the section
entirely when no contested calls were made; its absence is meaningful.>
- <Choice — why.>

## Manual interventions
<Only present when Target is claude+human or human. ⚠ warning line +
numbered checkpoints; see "Manual interventions section" above.>

## Hints
<Required. Always present. List the file paths the implementer should
touch, including test files, documentation, and any collateral files
(e.g. install scripts, context-layer files, cross-referenced commands).
Write "none" explicitly only if genuinely nothing collateral exists.>
- <path/to/file>
- <…>
```

**Required sections:** Goal, Acceptance criteria, Hints.
**Conditional sections:** Decisions (present only when non-obvious choices
exist); Manual interventions (present exactly when the target is
`claude+human` or `human`).
No snippets, no required-reading lists, no conventions blocks, no definition
of done — Claude fetches what it needs from the project's context layer at
implementation time.

## Enriched body schema (`target: local`)

An enriched body is a thin body with two additional sections appended.
Goal, Acceptance criteria, Decisions, and Hints are unchanged.

```
## Context bundle
<Selective excerpts of relevant code, patterns, and constraints the local LLM
needs. Include only what is necessary; a bloated bundle causes the very context
overflow it is meant to prevent.>

## Implementation steps
<Step-by-step guidance concrete enough to follow without any external reads.
Each step that relies on a pattern must have that pattern present in the
Context bundle above.>
```

`Target:` is updated to `local` when the body is enriched.

## TASKS.md summary block format

```
## <N>. <Title>

Status: [MISSING]
Target: claude
Files: <comma-separated list>
Preconditions: <comma-separated task numbers, or "none">
Feature: <slug>          # optional — feature-derived tasks only
```

`Target:` in the summary block mirrors the body file's `Target:` field. It is
the only field (besides `Files:`) intentionally duplicated between the index
and the body, so the backlog view shows implementer intent without opening
body files.

`Status:`, `Preconditions:`, and `Feature:` are deliberately absent from the
body: they describe how the task fits into the backlog, not what needs to be
built.

## Status vocabulary

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`,
`[DONE]`, `[SKIP]`, `[STALE]`.

`[DONE]` and `[SKIP]` are the only terminal statuses — the only two
`/task-clean` prunes by default. The vocabulary is mirrored in shell:
`scripts/check-task-parity.sh` holds the canonical list and
`scripts/cmd-task-impl.sh` holds the orchestrator's implementable-status
allowlist. A change here that does not land in both fails the parity guard.

## `Feature:` — the origin link

An optional summary-block line carrying the slug of the feature document a
task was generated from. Written only by `/task-add feature=<slug>`; absent
entirely on free-form tasks (never `Feature: none`), so its presence is what
distinguishes the two. It lives in the index rather than the body for the
same reason `Status:` and `Preconditions:` do: it is backlog metadata, not
part of the implementation contract.

Reconciliation depends on it — without the line, a re-planning run cannot
tell which existing tasks belong to the feature being re-planned. Readers of
the backlog (`/task-list`, `/task-implement`) treat it as informational.

## `[STALE]` — the drift marker

`[STALE]` means the feature document this task was generated from has been
re-architected since the task was written, so the spec may no longer match
the design. `/architect` sets it; `/task-add feature=<slug>` reconciliation
clears it (updating the body in place and flipping back to `[MISSING]`, or
marking the task `[SKIP]` and drafting a replacement).

- **Not terminal.** Live work awaiting reconciliation, not abandoned work.
  `/task-clean` never prunes it.
- **Never set by `/task-add` at authoring time.** A new task has no design
  drift to record.
- **Refused unattended, allowed interactively.** `chosko-llm task-impl`
  refuses a `[STALE]` task outright, naming the feature and pointing at
  `/task-add feature=<slug>`. `/task-implement` warns — naming the feature
  and saying the design changed — and lets the user implement anyway or
  stop; `all` and `next` skip stale tasks rather than deciding for the
  user. A human can judge whether a superseded design still applies; a
  headless local LLM cannot. The asymmetry is deliberate.

See [`./product-workflow.md`](./product-workflow.md) for the feature side of
this contract: the `FEATURES.md` schema, the feature status machine, the
iterate guard that writes `[STALE]`, and the reconciliation protocol that
resolves it.

## Feature-derived tasks (`/task-add feature=<slug>`)

`/task-add` has two input modes. The free-form mode takes a prose
description and is unchanged by any of this. The feature mode takes
`feature=<slug>`, resolves it through `.claude/FEATURES.md`, and plans from
the low-level feature document `/architect` wrote — treating that document as
the primary context source, the way `/task-implement` treats a task body.
Free-form text alongside the slug narrows scope; it does not replace the
document. Both modes compose with `--enrich`, `--no-split`, and
`--no-commit`.

`/task-add`, `/task-clean`, `/task-setup --commit`, and
`/task-enrich --commit` all follow the commit-and-push protocol in
[docs/authoring-guide.md](../../docs/authoring-guide.md) rather than a plain
`git commit` — pull at start, commit, re-sync, push, all skippable via
`--no-push` (or implied by `--no-commit`/no `--commit`). See that doc for
the algorithm; it is not re-derived here.

Because a feature document describes a unit of *design*, the split check
inverts: distinct components and independently deliverable slices of its
architecture normally each become a task, and one task for a whole feature is
the exception.

Feature-derived tasks differ from free-form ones in three ways: their summary
block carries `Feature: <slug>`, their body's `## Goal` names the originating
feature with its document path under `## Hints`, and the run updates the
feature's `FEATURES.md` entry — `Tasks:` and `Status: [PLANNED]`, never
`Doc:` or `Source:`.

### Reconciliation

A feature whose `Tasks:` line is non-`none` has been planned before, so a
re-planning run reconciles instead of appending. Every existing task is
classified, and the classification is presented under PHASE 3's existing
single approval gate:

| Situation | Action |
| --- | --- |
| Still valid under the new design | Left untouched. |
| Needs minor change, and is `[STALE]` or `[MISSING]` | Body updated in place; a `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` with a reason; a replacement is drafted. |
| `[DONE]` | Never modified, skipped, or reopened. |

Update-in-place is preferred whenever the task's goal survives the design
change: nothing has been implemented, so rewriting the body is cheaper and
keeps the backlog free of dead `[SKIP]` entries. Which applies is a judgment
call about how much of the task remains — there is no mechanical rule.

The feature document itself is read-only to `/task-add`.

## Split suggestion (`/task-add`)

Between PHASE 1 READ and PHASE 2 ASK, `/task-add` considers whether the
description would produce better units as multiple tasks — because it
bundles independent deliverables, or because a single task would be too
large. This is a suggestion, not a gate: it stays silent for work that's
fine as one task. `--no-split` skips the check entirely.

When the user accepts a proposed split, every part is written in the same
run: sequential IDs, one `TASKS.md` summary block and one
`.claude/tasks/<N>.md` body file per part, `Last task number` advanced by
the number of parts, and all files committed together in a single commit
covering every task ID created. A part that depends on an earlier part has
that earlier part's ID auto-wired into its `Preconditions:` line; a part
with no dependency gets `none`. Declining the proposal — or `--no-split` —
falls back to the normal single-task flow.

## Body file header

The `Target:` field lives on the second line of the body file, immediately
after the `# Task N — Title` heading, as a plain `Key: value` line — no YAML
frontmatter. This is consistent with how `Status:` and `Files:` are expressed
in TASKS.md.

## Static implement-procedure artifact

`/task-setup` writes the per-project external-LLM wiring under
`.claude/external/`:

- `implement-prompt.md` — the system-prompt fed to the local LLM via aider.
- `tests-prompt.md` — the system-prompt for the test-writing pass.
- `run-affected-tests.sh` — run the project's test runner against given files.
- `run-full-tests.sh` — run the full suite.

Standard aider invocation (one-shot, by hand):

```
aider --model ollama/qwen2.5-coder:14b \
      --read .claude/external/implement-prompt.md \
      --read .claude/tasks/<N>.md
```

Always run `/task-enrich <N>` before handing a task to the local LLM.

## Orchestrated path: `chosko-llm task-impl`

The orchestrator (`scripts/cmd-task-impl.sh`) runs an 8-step sequence driven
by aider against a single enriched task at a time:

```
Step 1.   flip TASKS.md Status: → [IN PROGRESS]
Step 2.   aider with tests-prompt.md          (skipped in skip-tests mode)
Step 3.   run-affected-tests.sh — expect FAIL (skipped in skip-tests mode)
Step 4.   aider with implement-prompt.md, retry up to N times on failure
          (N = $CHOSKO_TASK_IMPL_RETRIES, default 3)
Step 5.   run-affected-tests.sh — expect PASS (skipped in skip-tests mode)
Step 6.   run-full-tests.sh   — expect PASS  (skipped in skip-tests mode)
Step 7.   flip TASKS.md Status: → [DONE]
Step 8.   stage Files: ∪ TASKS.md, one commit
```

The orchestrator refuses on a dirty working tree, refuses if any of the four
artifacts under `.claude/external/` is missing, and refuses a `[STALE]` task
(`all` never selects one; an explicit ID halts the run). Statuses outside the
`[MISSING]` / `[STUBBED]` / `[INCORRECT]` / `[PARTIAL]` allowlist are skipped
with a warning.

## `/task-implement` discipline

`/task-implement` is the Claude Code implementation path. It reads the body
file as the primary context source, then navigates CLAUDE.md, `.claude/context/`,
and source files as needed — it does not need an exhaustive body to work well.

When the body carries `Target: local`, `/task-implement` emits a one-line
warning before proceeding:

> Note: this task was written for a local LLM (target: local) — implementing
> with Claude anyway.

No confirmation prompt is shown; implementation proceeds normally.

When the body carries `Target: claude+human`, `/task-implement` announces
the checkpoints up front, then implements normally, pausing at each
checkpoint to walk the user through the manual step and independently
verify the outcome before continuing (see "Manual interventions section").

When the body carries `Target: human`, the per-task flow becomes a guided
walkthrough: Claude makes no production edits, guides the user step by step
with the same verify loop, and still handles the bookkeeping (status flips,
the commit of the user's changes). `all`/`next` runs warn when the resolved
list contains human-involving tasks — they cannot run unattended.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring, versioning,
  copy-not-symlink, no new deps).
- [`./product-workflow.md`](./product-workflow.md) — the product pipeline
  upstream of this backlog: `FEATURES.md`, the feature status machine, and
  the writers of `Feature:` and `[STALE]`.
- [`../context/features.md`](../context/features.md) — shipped artifacts
  including every `task-*` command and the `task-enrich` skill.
- `commands/task-setup.md`, `commands/task-add.md`,
  `commands/task-clean.md`, `commands/task-list.md`,
  `commands/task-enrich.md`, `skills/task-implement/SKILL.md` — the
  command and skill implementations.
