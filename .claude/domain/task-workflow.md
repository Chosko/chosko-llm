# Task workflow

Source of truth for task backlog schema and implementation model. Read when touching any `task-*` command/skill or changing body schema.

## Roles

- **Author** — Claude Code, via `/task-add`. Plans task conversationally, captures decisions, identifies files, writes body. Full repo access.
- **Claude implementer** — Claude Code, via `/task-implement`. Default path. Reads thin body, navigates context/domain files as needed, implements end-to-end.
- **Human implementer** — user, acting in external tool agent can't drive (game-engine editor like Unity, cloud console, physical hardware). Claude guides + verifies; user does manual steps.

## Target field

Every task body + TASKS.md summary block carries `Target:` field:

| Value | Meaning |
| --- | --- |
| `claude` | Thin body. Claude implements, fetches context at implementation time. **Default.** |
| `claude+human` | Claude implements, but body declares manual-intervention checkpoints — Claude pauses, walks user through step in external tool, verifies outcome before continuing. |
| `human` | Task executed entirely by user. `/task-implement` becomes guided walkthrough: Claude guides + verifies each step, makes no production edits; still owns bookkeeping (status flips, commit). |

`target: claude` bodies authored lean. `claude+human` and `human` set by `/task-add` at authoring time when work involves steps agent can't execute; both REQUIRE `## Manual interventions` section in body (and vice versa — body with that section must carry one of these two targets).

## Manual interventions section

Optional body section, present exactly when `Target:` is `claude+human` or `human`. Placed between `## Decisions` and `## Hints`. Opens with `⚠ REQUIRES MANUAL INTERVENTION` warning line, followed by numbered checkpoints. Each checkpoint anchored to trigger point ("After X: …"), describes manual step in external tool, ends with verifiable outcome Claude can check itself (file that must exist, compile/test result). Mechanism generic — Unity motivating example, but any human-in-the-loop environment fits.

```
## Manual interventions

⚠ REQUIRES MANUAL INTERVENTION — pause implementation at these points and
walk the user through them; wait for their confirmation and verify the
outcome before continuing:

1. After <trigger>: <manual step in the external tool>. Verify <checkable
   outcome — e.g. the generated file exists and the project compiles>.
2. After <trigger>: <…>. Verify <…>.
```

At implementation time, verification independent: Claude checks claimed outcome itself (file existence, compile/test result — whatever checkable from filesystem or CLI) rather than trusting user's confirmation. On failure reports exactly what's missing, re-guides; never proceeds past unverified checkpoint unless user explicitly overrides.

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
**Conditional sections:** Decisions (present only when non-obvious choices exist); Manual interventions (present exactly when target is `claude+human` or `human`).
No snippets, no required-reading lists, no conventions blocks, no definition of done — Claude fetches what needed from project's context layer at implementation time.

## Short-form body schema (`--short`)

`/task-add --short` for trivial, low-ambiguity tasks where normal deep PHASE 1 investigation (reading CLAUDE.md, `.claude/context/`, `.claude/domain/` files for grounding) costs more tokens than task itself. Trades pre-implementation grounding for insertion-time efficiency: `/task-implement` resolves details at execution time instead.

```
# Task <N> — <Title>

Target: claude

## Goal
<1–3 sentences: what and why. No more.>

## Decisions
<Only present when a genuine non-obvious call was made during the (now
minimal) authoring pass, exactly as in the thin schema. Usually absent.>
```

`## Acceptance criteria` and `## Hints` omitted entirely — not left as placeholders — since authoring without deep investigation would likely produce content wrong or vacuous. PHASE 1.5 (split check) skipped entirely under `--short`, same as `--no-split`: task specific enough for `--short` is by definition not bundle of independent deliverables. PHASE 2 not skipped wholesale though — still asks about ambiguity inherent to user's own description; just doesn't ask about ambiguity that would only have surfaced through investigation `--short` skips.

`--short` mutually exclusive with `feature=<slug>` — it implies exactly the deep investigation `--short` exists to skip. Composes normally with `--no-commit` and `--no-push`.

## TASKS.md summary block format

```
## <N>. <Title>

Status: [MISSING]
Target: claude
Files: <comma-separated list>
Preconditions: <comma-separated task numbers, or "none">
Feature: <slug>          # optional — feature-derived tasks only
```

`Target:` in summary block mirrors body file's `Target:` field. Only field (besides `Files:`) intentionally duplicated between index and body, so backlog view shows implementer intent without opening body files.

`Status:`, `Preconditions:`, `Feature:` deliberately absent from body: describe how task fits into backlog, not what needs to be built.

## Status vocabulary

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`, `[DONE]`, `[SKIP]`, `[STALE]`.

`[DONE]` and `[SKIP]` only terminal statuses — only two `/task-clean` prunes by default. Vocabulary lives in the prompt layer alone; no shell script encodes it.

## `Feature:` — origin link

Optional summary-block line carrying slug of feature document task generated from. Written only by `/task-add feature=<slug>`; absent entirely on free-form tasks (never `Feature: none`), so presence distinguishes the two. Lives in index not body, same reason `Status:` and `Preconditions:` do: backlog metadata, not implementation contract.

Reconciliation depends on it — without line, re-planning run can't tell which existing tasks belong to feature being re-planned. `/task-implement` mostly treats it as informational, with one exception: it's what the `[DONE]` feature-completion proposal (below) uses to find every task belonging to a slug.

`/task-list` does more with it when project has `.claude/PLAN.md`: resolves slug through plan's milestone `Features:` lists to find task's milestone, groups backlog under milestone headings **in plan order**, and appends `⚠ blocked by <slug>` when task's feature is blocked (same readiness rule `/production-status` uses — feature blocked when some dependency edge pointing at it originates from feature not `[DONE]` and not `[PLANNED]` w/ all tasks `[DONE]`/`[SKIP]`; unresolvable edge slug ignored, not treated as blocker). Task w/ no `Feature:` line, or one naming slug no milestone lists (incl. `Unscheduled` slugs), groups under trailing `Unplanned` heading. Marker order fixed and stated in command body: `⚠ <target>`, `[<slug>]`, `(deps: N, M)`, `⚠ stale`, `⚠ blocked by <slug>`. Status filter applies before grouping, so it works within groups.

**No `PLAN.md` → none of that happens**, and command says nothing about it: output byte-for-byte what it always was, silent no-op not a warning. Most projects using `/task-list` have no roadmap. See [product-workflow.md § The read stage](./product-workflow.md#the-read-stage-production-status).

## `[STALE]` — drift marker

`[STALE]` means feature document task generated from has been re-architected since task written, so spec may no longer match design. `/architect` sets it; `/task-add feature=<slug>` reconciliation clears it (updating body in place, flipping back to `[MISSING]`, or marking task `[SKIP]` and drafting replacement).

- **Not terminal.** Live work awaiting reconciliation, not abandoned work. `/task-clean` never prunes it.
- **Never set by `/task-add` at authoring time.** New task has no design drift to record.
- **Never picked up silently.** `/task-implement` warns — naming feature, saying design changed — lets user implement anyway or stop; `all` and `next` skip stale tasks rather than deciding for user. Only a human can judge whether superseded design still applies, so the choice is always put to them.

See [`./product-workflow.md`](./product-workflow.md) for feature side of this contract: `FEATURES.md` schema, feature status machine, iterate guard that writes `[STALE]`, reconciliation protocol resolving it.

## Feature-derived tasks (`/task-add feature=<slug>`)

`/task-add` has two input modes. Free-form mode takes prose description, unchanged by any of this. Feature mode takes `feature=<slug>`, resolves through `.claude/FEATURES.md`, plans from low-level feature document `/architect` wrote — treating that document as primary context source, way `/task-implement` treats task body. Free-form text alongside slug narrows scope; doesn't replace document. Both modes compose with `--no-split`, `--no-commit`.

`/task-add`, `/task-clean`, `/task-setup --commit` all follow commit-and-push protocol in [docs/authoring-guide.md](../../docs/authoring-guide.md) rather than plain `git commit` — pull at start, commit, re-sync, push, all skippable via `--no-push` (or implied by `--no-commit`/no `--commit`). See that doc for algorithm; not re-derived here.

Since feature document describes unit of *design*, split check inverts: distinct components and independently deliverable slices of its architecture normally each become task, one task for whole feature is exception.

Feature-derived tasks differ from free-form ones three ways: summary block carries `Feature: <slug>`, body's `## Goal` names originating feature with its document path under `## Hints`, run updates feature's `FEATURES.md` entry — `Tasks:` and `Status: [PLANNED]`, never `Doc:` or `Source:`.

### Reconciliation

Feature whose `Tasks:` line is non-`none` has been planned before, so re-planning run reconciles instead of appending. Every existing task classified, classification presented under PHASE 3's existing single approval gate:

| Situation | Action |
| --- | --- |
| Still valid under new design | Left untouched. |
| Needs minor change, and is `[STALE]` or `[MISSING]` | Body updated in place; `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` with reason; replacement drafted. |
| `[DONE]` | Never modified, skipped, or reopened. |

Update-in-place preferred whenever task's goal survives design change: nothing implemented yet, so rewriting body cheaper, keeps backlog free of dead `[SKIP]` entries. Which applies is judgment call about how much task remains — no mechanical rule.

Feature document itself read-only to `/task-add`.

## Split suggestion (`/task-add`)

Between PHASE 1 READ and PHASE 2 ASK, `/task-add` considers whether description would produce better units as multiple tasks — bundles independent deliverables, or single task would be too large. Suggestion, not gate: stays silent for work fine as one task. `--no-split` skips check entirely.

When user accepts proposed split, every part written in same run: sequential IDs, one `TASKS.md` summary block + one `.claude/tasks/<N>.md` body file per part, `Last task number` advanced by number of parts, all files committed together in single commit covering every task ID created. Part depending on earlier part gets that earlier part's ID auto-wired into `Preconditions:` line; part with no dependency gets `none`. Declining proposal — or `--no-split` — falls back to normal single-task flow.

## Body file header

`Target:` field lives on second line of body file, immediately after `# Task N — Title` heading, as plain `Key: value` line — no YAML frontmatter. Consistent with how `Status:` and `Files:` expressed in TASKS.md.

## Test-dispatch convention

`/task-setup` writes two thin wrapper scripts under `.claude/external/`:

- `run-affected-tests.sh` — run project's test runner against given files.
- `run-full-tests.sh` — run full suite.

They are the project's one stable pair of entry points for running tests, inferred from project files at `/task-setup` time. Nothing in the `task-*` suite invokes them — `/task-implement` resolves its own test command and never reads them — but a project wiring its own scripts, CI or CLAUDE.md to them has one place to change when the runner changes. A project with no test suite gets no-op stubs carrying the `# CHOSKO_TASK_IMPL_STUB` sentinel, which is what marks a wrapper as a stub when `/task-setup` runs again.

`/task-implement` follows commit-and-push protocol in [docs/authoring-guide.md](../../docs/authoring-guide.md) once per task, immediately after that task's commit — not deferred to end-of-run — mirroring "one commit per task" with "one push per task." `--no-push` skips pull-at-start and each task's re-sync/push while still committing every task as usual; `--no-commit` implies no push. See that doc for pull/commit/re-sync/push algorithm; not re-derived here.

## `/task-implement` discipline

`/task-implement` is Claude Code implementation path. Reads body file as primary context source, then navigates CLAUDE.md, `.claude/context/`, source files as needed — doesn't need exhaustive body to work well.

When body carries `Target: claude+human`, `/task-implement` announces checkpoints up front, then implements normally, pausing at each checkpoint to walk user through manual step and independently verify outcome before continuing (see "Manual interventions section").

When body carries `Target: human`, per-task flow becomes guided walkthrough: Claude makes no production edits, guides user step by step with same verify loop, still handles bookkeeping (status flips, commit of user's changes). `all`/`next` runs warn when resolved list contains human-involving tasks — they can't run unattended.

In full test mode, Step 1 of per-task workflow also determines, silently and with no confirmation prompt, whether current task is documentation-only: every path in its `Files:` field is documentation artifact (`README.md`, `CHANGELOG.md`, `docs/**`, or comparable prose) and none is source file, script, test file, or command/skill specification (`commands/*.md`, `skills/**/*.md` — these are executable specifications, not prose, despite `.md` extension). Determination reuses `Files:` field from PRE-FLIGHT and body just read at Step 1 — no extra re-read. When `Files:` empty, ambiguous, or mixes documentation with any non-documentation path, task treated as normal code task; skill never guesses toward skipping tests. When task determined documentation-only, Steps 2 (write tests), 4 (run affected tests), 5 (run full suite) skipped for that task exactly as they already are in skip-tests / skip-tests-unattended mode. Orthogonal to that mode: when skip-tests mode already active, Steps 2/4/5 already skipped for every task, making documentation-only determination moot.

### Delegated runs

Run whose selector resolves to 2+ tasks offers to implement each task in fresh subagent. Motivation is context, not throughput: in single conversation, task 1's reading and diffs still loaded when task 3 starts, so later tasks get progressively less headroom. One agent per task gives each full window while parent keeps only run-level bookkeeping. `--agents` / `--no-agents` pre-answer the question; run of fewer than 2 tasks never asks it, unchanged.

On such run parent is **launcher**, not orchestrator. It resolves task list, evaluates delegation guard, hands each agent a prompt, records what comes back — nothing else. The three fields the guard needs (`Target:`, `Status:`, `Feature:`) all sit in each task's `TASKS.md` summary block, which PRE-FLIGHT already reads once for whole run, so **parent opens no `.claude/tasks/<N>.md` for a delegated task, on any path**. Hand-off prompt is fixed size — same frame every time with a different number in it: task number, repo's absolute path, run's resolved flags (open list, so a flag added later rides through without prompt growing), and instruction for agent to read body, CLAUDE.md and `.claude/context/` itself. What returns is exactly four values: task number, terminal status, commit hash (or that nothing was committed), one-line failure reason only when it failed.

Two things follow, and they are the point. Parent's context no longer grows with size of batch — fifty-task run leaves it holding fifty short rows instead of fifty task bodies it will never use again. And no special batch-agent path exists: delegated task executes the same flow a hand-typed `/task-implement <n>` does, so delegated flow and manual flow stop being two things that can drift apart. Handing an agent a pre-chewed summary would also pay for the `.claude/context/` layer twice, since that layer is already the precomputed answer to "what do I need to read".

Tasks parent keeps still have bodies read in Step 1, exactly as ordinary in-context run does. That path unchanged.

Agents **sequential, never parallel** — every task in run shares one working tree, one branch, one `.claude/TASKS.md`, so concurrency would race on status flips, staging, pushes. Parent blocks on each agent before spawning next, re-reads `TASKS.md` in between (agent wrote status), halts whole run on failure rather than continuing.

Delegation partial by design. `claude+human` and `human` tasks, and `[STALE]` tasks requested explicitly by number, stay in parent conversation: all three depend on question put to user — manual checkpoint's confirmation, or stale implement-anyway/stop choice — subagent can't hold that conversation. Mixed run states which tasks go where before starting. Each delegated agent still owns its task's status flips, its single commit, its single push, so one-commit / one-push-per-task invariant holds regardless of where task ran.

Protocol details live in `skills/task-implement/delegated-runs.md`, read only when delegation active.

## `[DONE]` feature-completion proposal

When a task carrying a `Feature: <slug>` line lands `[DONE]` in Step 6, and that leaves every task carrying the same `Feature: <slug>` at `[DONE]` or `[SKIP]`, the run records `<slug>` as a completion candidate — but proposes nothing yet. This holds whether the task ran in the parent conversation or in a delegated subagent; the parent already re-reads `TASKS.md` after each task (in-context or delegated), and that's where the check runs. That re-read is the index file, never a task body — it costs the launcher nothing and both the agent-verification step and this check depend on it.

A candidate is recorded only when the feature's current `FEATURES.md` `Status:` is `[PLANNED]`. A feature that's `[NEW]` or `[ITERATED]` has no business reaching `[DONE]` without `/architect` or `/task-add feature=<slug>` running first — the guard never fires for those, same as it never fires for a feature already `[DONE]`.

Proposals are batched to the end of the run, never asked per-task — a many-task run that finishes several features asks once, for all of them together, after the last requested task's Step 7 (or Step 6, under `--no-commit`). A single-task run reaches "end of run" immediately after that one task, which is what makes "propose when it's the last task of a feature" and "propose only at the end of a batch" the same rule.

On the user's approval — per slug, not all-or-nothing — `/task-implement` edits that entry's `Status:` line in `.claude/FEATURES.md` to `[DONE]` and, unless `--no-commit` was passed, stages the file and creates one commit covering every slug approved this run (even when several features completed in the same batch), separate from the per-task commits, then re-syncs and pushes per `docs/authoring-guide.md`'s commit-and-push protocol (skipped under `--no-push`). A declined or unnamed slug stays `[PLANNED]`; the run doesn't ask about it again.

This is the only write `/task-implement` makes to `FEATURES.md`, and the only status it's allowed to set there — see [product-workflow.md § `[DONE]` is proposed, never applied silently](./product-workflow.md#done-is-proposed-never-applied-silently). A human flipping a feature to `[DONE]` by hand, outside any run, is equally valid and never overwritten.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring, versioning, copy-not-symlink, no new deps).
- [`./product-workflow.md`](./product-workflow.md) — product pipeline upstream of this backlog: `FEATURES.md`, feature status machine, writers of `Feature:` and `[STALE]`.
- [`../context/features.md`](../context/features.md) — shipped artifacts including every `task-*` command and skill.
- `commands/task-setup.md`, `commands/task-add.md`, `commands/task-clean.md`, `commands/task-list.md`, `skills/task-implement/SKILL.md` — command and skill implementations.