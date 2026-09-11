# Task workflow

Source of truth for task backlog schema and implementation model. Read when touching any `task-*` command/skill or changing body schema.

## One authority per rule (`task-engine`)

Everything below this section is a *rule* — schema, vocabulary, protocol —
and every rule has exactly one home. That home is `skills/task-engine/`, a
shipped skill that is a reference library and not a command: no arguments,
no behaviour, nothing to invoke. Eight files under `references/`, one
authority each:

| File | Owns |
| --- | --- |
| `resolution.md` | `.claude/TASKS.md` parsing, body-file location, the task archive (`.claude/tasks/archive/<N>.md`, the frozen-header form, and the archived-and-terminal rule every id reader cites), the `all` / `next` / explicit-list selectors and the eligibility clause the batch two honour, the `/task-setup`-has-run gate. |
| `status.md` | Status vocabulary, which values are terminal, which implementable, legal transitions. |
| `targets.md` | `Target:` values, the `## Manual interventions` pairing rule, the delegation guard. |
| `stale.md` | `[STALE]`: who writes it, who clears it, the implement-anyway/stop protocol, reconciliation classification. |
| `tree.md` | The dirty-tree prompt protocol and the Step-7 fold. |
| `commit.md` | Pull-at-start, commit and push per task, `--no-commit` / `--no-push` gating. |
| `review-budget.md` | Review cost controls: the `--review-model` / `--review-effort` values, the deterministic `auto` tier table, the read budget behind the effort axis. |
| `amend.md` | Changing one existing task in place: the two checks before writing (not `[IN PROGRESS]`; no change to what its feature promises, else route to `/architect amend`), which body sections and summary-block fields may change, a dropped `Preconditions:` edge named in `## Decisions`, deleting a live task as `[SKIP]`, adding `Feature:` to an orphan, one gate, a closed write set. |

A consumer cites the file by path and then **states only its own
deviations** — `/task-clean`'s prune set is `status.md`'s terminal statuses
plus its own refusal to prune `[STALE]`; `/task-list`'s markers are its own,
the vocabulary they key off is not. That is the whole discipline: if a
statement is true of two `task-*` features, it belongs in the engine, and a
consumer restating it has created a second copy to forget.

Five features consume it: `/task-add`, `/task-list`, `/task-clean`,
`/task-implement`, and `/task-review` — the last for two things only:
`review-budget.md`, when a `--review` spawn hands it a budget block, and
`resolution.md` § *The archive*, which keeps its weakest task-resolution
fallback out of `.claude/tasks/archive/`. `/task-iterate` does not — it
operates on diffs and findings, not on the backlog's schema, and states its
one-line archive exclusion inline. `/architect` and `/production-status` name
§ *The archive* as the rule's home without consuming the engine: neither
declares `requires: skill:task-engine`, and each states inline the one
consequence it needs — an id absent from `TASKS.md` is terminal.

`amend.md` is the one file no `task-*` feature reads. It was authored in the
engine, since no consumer ever carried a copy, and it is read by path by
whatever amends a single task — the pipeline revision surfaces,
`/pipeline-patch` and `/pipeline-revise` — which execute it but own none of
the lines it writes. See [§ Changing a planned task](#changing-a-planned-task-pipeline-patch-pipeline-revise).

**Why a skill and not a command.** `cmd-add` installs a skill by `cp -R` of
the whole folder, so supporting files ride along; a command is a single `.md`
file and can carry nothing. A reference library therefore has exactly one
shippable shape. The consumers read it at
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md` —
never `~/.claude`, never a `docs/` path, since neither survives installation.

**Why `requires:` had to exist first.** A body reading a file inside another
installed feature breaks when that feature is absent, and the failure surfaces
as an agent following a dangling path mid-run rather than as anything the CLI
said. All five consumers declare `requires: skill:task-engine`; `chosko-llm
add` installs the engine before the dependent, and `chosko-llm rm
skill:task-engine` refuses while any dependent is installed.

`requires:` is **flat, one level deep and non-transitive by design** — no
version ranges, no solver, no lockfile, no cycle detection. That is not a
first cut awaiting a real resolver: the moment a dependency needs one it has
outgrown this repo's no-state-file rules, and the correct response is to
restructure the dependency, not to build the solver.

The one thing `requires:` cannot express is an **optional** dependency — a
feature that must keep working when the other is absent. That is why the two
`council-gate.md` copies stay duplicated; see
[docs/authoring-guide.md](../../docs/authoring-guide.md) § "Keeping the two
`council-gate.md` copies in step".

Design rationale and the migration's actual outcome:
[`./features/shared-phase-engine.md`](./features/shared-phase-engine.md).

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

`--short` mutually exclusive with `feature=<slug>` (and so with `--single`) — it implies exactly the deep investigation `--short` exists to skip. Composes normally with `--no-commit` and `--no-push`.

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

## Backlog order and `Preconditions:`

Two things order backlog, and selectors read both: **appearance order** in `TASKS.md` is the priority, **`Preconditions:`** the hard constraint. The id carries no order — ids stable and only ever increase, so a task inserted mid-file carries a higher id than tasks below it. Read order from position, never from number.

`Preconditions:` is **load-bearing for `next` and `all`**, not informational. Task eligible only when its status is implementable **and** every id on its `Preconditions:` line resolves to a task `[DONE]` or `[SKIP]`; id resolving to no task ignored, never a blocker. `next` = first eligible task in appearance order. **`all` = `next` repeated** until nothing eligible — one rule, no second definition of eligibility, no graph algorithm — resolved once up front by simulating the repetition (each selected task treated `[DONE]` for the walks after), so a batch still gets one resolution report and one delegation count. Implementable tasks left unselected are named by id w/ what they wait on, a precondition cycle included; between tasks an `all` run re-checks upcoming task's `Preconditions:` against the `TASKS.md` re-read it already does, skipping w/ one line a task whose preconditions no longer hold. Task requested by number never blocked: naming it is choosing its moment. `/production-status`'s Next column picks `/task-implement <N>` by same rule. Clause lives once, in `task-engine`'s `resolution.md` § *Selectors*.

**`/task-add` can insert.** Appending at end still default. `--before <N>` writes new summary block immediately above task N's and appends new id to N's `Preconditions:` (the one sanctioned edit to another task's line); `--after <N>` writes it immediately below and puts N on new task's `Preconditions:`. Both halves always together — position for human reading top to bottom, edge for selectors; either alone leaves the two disagreeing. Flags mutually exclusive; unknown N stops. Insertion consumes next id exactly as append does, no existing id moves; moving an existing task is a revision, not an insertion (§ Changing a planned task). When run writes several tasks (split, feature run) flag places the first, rest follow it. A `Feature:`-tagged task landing among another feature's tasks is legal — reconciliation keys on `Feature:`, never position.

## Status vocabulary

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`, `[DONE]`, `[SKIP]`, `[STALE]`.

`[DONE]` and `[SKIP]` only terminal statuses — only two `/task-clean` archives by default. Vocabulary lives in the prompt layer alone; no shell script encodes it.

## `Feature:` — origin link

Optional summary-block line carrying slug of feature document task generated from. Written only by `/task-add feature=<slug>`; absent entirely on free-form tasks (never `Feature: none`), so presence distinguishes the two. Lives in index not body, same reason `Status:` and `Preconditions:` do: backlog metadata, not implementation contract.

Reconciliation depends on it — without line, re-planning run can't tell which existing tasks belong to feature being re-planned. `/task-implement` mostly treats it as informational, with one exception: it's what the `[DONE]` feature-completion proposal (below) uses to find every task belonging to a slug.

`/task-list` does more with it when project has `.claude/PLAN.md`: resolves slug through plan's milestone `Features:` lists to find task's milestone, groups backlog under milestone headings **in plan order**, and appends `⚠ blocked by <slug>` when task's feature is blocked (same readiness rule `/production-status` uses — feature blocked when some dependency edge pointing at it originates from feature not `[DONE]` and not `[PLANNED]` w/ all tasks `[DONE]`/`[SKIP]`; unresolvable edge slug ignored, not treated as blocker). Task w/ no `Feature:` line, or one naming slug no milestone lists (incl. `Unscheduled` slugs), groups under trailing `Unplanned` heading. Marker order fixed and stated in command body: `⚠ <target>`, `[<slug>]`, `(deps: N, M)`, `⚠ stale`, `⚠ blocked by <slug>`. Status filter applies before grouping, so it works within groups.

**No `PLAN.md` → none of that happens**, and command says nothing about it: output byte-for-byte what it always was, silent no-op not a warning. Most projects using `/task-list` have no roadmap. See [product-workflow.md § The read stage](./product-workflow.md#the-read-stage-production-status).

## `[STALE]` — drift marker

`[STALE]` means feature document task generated from has been re-architected since task written, so spec may no longer match design. `/architect` sets it; `/task-add feature=<slug>` reconciliation clears it (updating body in place, flipping back to `[MISSING]`, or marking task `[SKIP]` and drafting replacement).

- **Not terminal.** Live work awaiting reconciliation, not abandoned work. `/task-clean` never archives it by default.
- **Never set by `/task-add` at authoring time.** New task has no design drift to record.
- **Never picked up silently.** `/task-implement` warns — naming feature, saying design changed — lets user implement anyway or stop; `all` and `next` skip stale tasks rather than deciding for user. Only a human can judge whether superseded design still applies, so the choice is always put to them.

See [`./product-workflow.md`](./product-workflow.md) for feature side of this contract: `FEATURES.md` schema, feature status machine, iterate guard that writes `[STALE]`, reconciliation protocol resolving it.

## The archive (`/task-clean`)

Task leaving backlog is **archived, not deleted**. `/task-clean` removes summary block from `TASKS.md` and `git mv`s body to `.claude/tasks/archive/<N>.md` — a rename, so history follows the file — then writes frozen header under its title: `Archived:` date plus `Status:`, `Files:`, `Preconditions:`, `Feature:` (when present) as summary block had them at that moment. Nothing else derived or added; header never updated. Folder append-only, archiving run its only writer. Survivors' `Preconditions:` still drop archived ids — archived precondition is satisfied one, no reader should resolve into archive to know a task is ready. Non-terminal set named explicitly archives same way; frozen `Status:` records task pruned live. **Prune never opens `FEATURES.md`**: feature keeps every id it ever generated on `Tasks:`, so `Tasks: none` again means never planned.

**The rule** lives in `resolution.md` § *The archive*, cited by every id reader: id referenced anywhere but absent from `TASKS.md` is archived and terminal; no command probes the folder, opens an archived file, or reports on its contents, except when user names a task and asks to read it. Absence is whole signal — no reader checks file is there, so hand-deleted body and archived one look the same until someone asks to read it, and the missing file says so itself. Folder no command traverses costs session same as no folder. Readers state only deviations: `/task-implement <N>` on absent id stops naming the archive path, opens it only on explicit ask, never re-implements; `/task-add feature=<slug>` leaves absent ids unclassified and keeps them when rewriting `Tasks:`; `/task-review` / `/task-iterate` exclude archive from weakest task-resolution fallback; `/production-status` counts them `archived: N` in its rollup; `/architect`'s iterate guard unchanged. `/task-list`, `/task-setup`, session commands and CLI change nothing — no listing of the archive exists anywhere, by design.

**Why a skill.** `/task-clean` was a command; now `skills/task-clean/SKILL.md` w/ `replaces: command:task-clean`, so `add`/`update` retire the command copy. Migration exists for one reason: `--backfill`'s procedure sits in supporting file `backfill.md`, read only when flag present, and a command is one file that can carry nothing beside it — same reasoning that made `task-engine` a skill. `--backfill` recovers bodies earlier runs deleted: git history's deletions under `.claude/tasks/`, body from deleting commit's parent, header from that parent's `TASKS.md` block, `Archived:` dated to the deletion, and each id put back on its feature's `Tasks:` line — the one `FEATURES.md` write left in `/task-clean`, on that path only. Exclusive w/ status set, same plan-and-Apply gate, git only.

Design: [`./features/task-archive.md`](./features/task-archive.md).

## Changing a planned task (`/pipeline-patch`, `/pipeline-revise`)

Live task changed after planning goes through `task-engine`'s `references/amend.md` — one arm, one gate, closed write set — never hand-edited, never re-planned by `/task-add`. No `task-*` feature drives that arm; the two pipeline revision surfaces do, by path:

- **`/pipeline-patch task=<N> "<change>"`** — change touching this task alone (wording, Hints, `Files:`, `Target:`, an orphan's `Feature:`). Decided from `TASKS.md` and the other indexes, never the body; refused, naming `/pipeline-revise`, when a structural signal fires — an edge changing, a new task, a deletion another line points at, a move.
- **`/pipeline-revise`** — change reaching past this task. Sequences the arm among other owners' steps, upstream first, behind one gate: `/architect amend` before the task arm when the change moves what the feature promises (the arm's own second check routes such a change there anyway), successors' `Preconditions:` through the same arm, one step per task.

What the arm allows is `amend.md`'s, not restated here: refuses `[IN PROGRESS]`, `[DONE]`, `[SKIP]`; a change to what the feature promises goes to `/architect amend`; a dropped `Preconditions:` edge is named in the dependent's `## Decisions`. Neither surface writes a line itself — every line the arm writes is still `/task-add`'s, per `pipeline-engine`'s routing table. See [product-workflow.md § Revision](./product-workflow.md#revision-pipeline-patch-pipeline-revise).

**Removing a live task is `[SKIP]` with a reason, never deletion.** Arm writes `Status: [SKIP]` + dated reason in `## Decisions`; summary block and body stay. Successors' edges on it dropped through the same arm, each naming the deletion. Taking a task out of the backlog stays `/task-clean`'s explicit act over terminal statuses — and even that archives rather than deletes (§ The archive); `[SKIP]` is what makes a task eligible for it.

**Moving** a task is skip-and-insert (`/pipeline-revise`'s reorder branch): old task `[SKIP]` w/ `reordered — replaced by task <K>, <before|after> task <M>`, replacement inserted at the new place under a new id through `/task-add --before`/`--after`. Ids never renumbered, blocks never moved. **Inserting** is `/task-add feature=<slug> --single --before|--after <N>` (§ Backlog order), the scope written into the feature doc first by `/architect amend` when it's new. `[DONE]` tasks never touched by any of it — follow-up is a new task.

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

Feature document itself read-only to `/task-add`. May still be named in a drafted task's Hints — but only with dated, point-scoped grant user gave at PHASE 3 ownership gate (see [product-workflow.md](./product-workflow.md) § Documentation task), or not at all. Grant binds that task's *implementer*; never `/task-add`, which stays a non-writer of every owned document.

### Attaching one task (`--single`)

`/task-add feature=<slug> --single "<description>"` plans exactly one task against feature document (still PHASE 1b's primary context) and attaches it to a feature without re-planning it. **What it changes:** new block carries `Feature: <slug>`, body names the feature in Goal and its document under Hints, id appended to entry's `Tasks:` line. **What it does not change:** no reconciliation over feature's other tasks (not even read); feature's `Status:` stays `[PLANNED]` — the only status `--single` accepts, since one more planned task leaves design-to-backlog relationship unchanged (`[NEW]`/`[ITERATED]` still need a full planning run, `[DONE]` would claim done w/ a task open); no documentation task; no split; `Doc:`/`Source:` untouched as always. Mutually exclusive w/ `--short`, same reason `feature=` is.

Nor does it update feature document: report ends w/ one fixed line saying document was not updated and naming `/pipeline-patch feature=<slug>` as write-back, so drift announced when created rather than discovered later. `/task-add` stays non-writer of the document. One commit, under single-task (or split) message plus `FEATURES.md` — never `Plan feature`, since one attached task is not a planning pass.

**Orphan question.** On a project w/ `.claude/FEATURES.md`, free-form run (not `--short`) asks inside PHASE 3's existing gate — never a second one — whether task belongs to a feature, listing every `[PLANNED]` entry, none the default. Slug takes the `--single` path; none writes task exactly as before. No `FEATURES.md`, or no `[PLANNED]` entry → question not asked, free-form path unchanged.

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

`--review` / `--rounds N` propagate to each implementor as part of run's resolved flags, and **each implementor spawns its own reviewer** — launcher → implementor → reviewer, one level deeper than the launcher alone. Parent passes flags through and nothing else changes there: it still sees only the four returned fields (task number, terminal status, commit hash, one-line failure reason on failure), never a finding, never a triage verdict. Implementor's reviewer returns asynchronously like any other agent, so implementor must not commit before its own reviewer's result has arrived — a commit on the strength of a spawn call's return value is unreviewed work reported as reviewed.

Protocol details live in `skills/task-implement/delegated-runs.md`, read only when delegation active.

## Review loop (`/task-review` + `/task-iterate`)

Two skills, one division of labour: `/task-review` audits a diff against acceptance criteria of task that produced it and reports findings; `/task-iterate` triages those findings, applies what survives, records why rest did not. Neither does other's job — reviewer never edits, iterator never finds. Skill that both finds and fixes grades its own work.

Both take same three input forms — no argument (uncommitted tree), branch name (against repo's default branch, `base=<ref>` overrides), PR number or URL (through `gh`) — and both resolve task same way: `task=<n>`, then number in branch name, then PR title, then most recently modified `.claude/tasks/*.md`. Unresolvable task **stops** either skill; reviewing a diff against nothing in particular is what Claude Code's built-in `/code-review` already does, and checking against the task's criteria is this pair's only reason to exist beside it.

**Reviewer must be fresh context.** Under `/task-implement --review` the review runs as a subagent, and that's mechanism not detail: reviewer that watched code being written holds author's reasoning and rationalises what it finds. Iterate runs in main session instead, because its edits have to land in tree the run commits.

**Gates before a finding is written**: ≥80% confidence, four-question Pre-Report Gate (exact line, concrete failure mode, callers/imports/tests read, defensible severity), and proof for anything BLOCKING. Zero findings is valid, complete review — stated in skill body, because reviewer under implicit pressure to justify its invocation produces findings to justify it. Three severities only; unmet acceptance criterion always BLOCKING.

**Mandatory triage is auditable replacement for a silent judgement.** "Fix what's worth fixing" is normally decided in someone's head, leaving no record of what was dismissed. Every finding therefore gets exactly one written verdict — `fix`, `defer` (with follow-up task number, or line saying what that task would be), `reject` (with reason that could be argued with) — and whole table written **before** first edit. Triage decided while editing is triage rationalised by edit already made.

**Sticky rejections.** Finding rejected in round *k* travels into round *k+1* as binding context and may not be re-raised there — only escalated, on evidence earlier round did not have. Without this the loop ping-pongs between stubborn reviewer and compliant iterator, and no round counter substitutes for it: bound stops the argument, doesn't settle it. In PR mode the rejection replies left on open threads are same ledger.

**Severity gate and round bound.** `--rounds N` defaults to 1 (one review, one iterate, stop). N ≥ 2 continues only while `BLOCKING` findings remain unresolved, and stops at N regardless; `IMPORTANT` and `ADVISORY` reported in round that found them, never re-raised. Rounds after first re-review only hunks last iterate changed. Unresolved BLOCKING after last round stops whole run: tree left uncommitted, task left `[IN PROGRESS]`. That's why loop sits **before** Step 6, not between Steps 6 and 7 — flipping `[DONE]` first and halting after would leave backlog claiming work never accepted.

**Invariant: `/task-iterate` does not commit inside `/task-implement --review`.** Standalone it commits and pushes like every other auto-committing feature; inside a round it commits nothing and leaves corrected tree for that run's Step 7. So a reviewed task still produces **exactly one commit**. Were iterate to commit there, a task would land an implementation commit plus separate fix commit for corrections no human reviewed separately — two commits for one task, second describing the first. Asymmetry is deliberate and load-bearing; do not make the two paths agree. Mode is asserted by caller and **never inferred** — not from dirty tree, not from findings having been passed in, not from round number — because an inference that gets it wrong fails silently, a commit that should not exist looking exactly like one that should.

See [`./features/task-peer-review.md`](./features/task-peer-review.md) for feature design behind this.

## `[DONE]` feature-completion proposal

When a task carrying a `Feature: <slug>` line lands `[DONE]` in Step 6, and that leaves every task carrying the same `Feature: <slug>` at `[DONE]` or `[SKIP]`, the run records `<slug>` as a completion candidate — but proposes nothing yet. This holds whether the task ran in the parent conversation or in a delegated subagent; the parent already re-reads `TASKS.md` after each task (in-context or delegated), and that's where the check runs. That re-read is the index file, never a task body — it costs the launcher nothing and both the agent-verification step and this check depend on it.

A candidate is recorded only when the feature's current `FEATURES.md` `Status:` is `[PLANNED]`. A feature that's `[NEW]` or `[ITERATED]` has no business reaching `[DONE]` without `/architect` or `/task-add feature=<slug>` running first — the guard never fires for those, same as it never fires for a feature already `[DONE]`.

Proposals are batched to the end of the run, never asked per-task — a many-task run that finishes several features asks once, for all of them together, after the last requested task's Step 7 (or Step 6, under `--no-commit`). A single-task run reaches "end of run" immediately after that one task, which is what makes "propose when it's the last task of a feature" and "propose only at the end of a batch" the same rule.

On the user's approval — per slug, not all-or-nothing — `/task-implement` edits that entry's `Status:` line in `.claude/FEATURES.md` to `[DONE]` and, unless `--no-commit` was passed, stages the file and creates one commit covering every slug approved this run (even when several features completed in the same batch), separate from the per-task commits, then re-syncs and pushes per `docs/authoring-guide.md`'s commit-and-push protocol (skipped under `--no-push`). A declined or unnamed slug stays `[PLANNED]`; the run doesn't ask about it again.

This is the only write `/task-implement` makes to `FEATURES.md`, and the only status it's allowed to set there — see [product-workflow.md § `[DONE]` is proposed, never applied silently](./product-workflow.md#done-is-proposed-never-applied-silently). A human flipping a feature to `[DONE]` by hand, outside any run, is equally valid and never overwritten.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring, versioning, copy-not-symlink, no new deps).
- [`./product-workflow.md`](./product-workflow.md) — product pipeline upstream of this backlog: `FEATURES.md`, feature status machine, writers of `Feature:` and `[STALE]`.
- [`./features/task-peer-review.md`](./features/task-peer-review.md) — feature design behind the review loop: the three input forms, the gates, mandatory triage, sticky rejections, and the `--review` / `--rounds` integration.
- [`./features/shared-phase-engine.md`](./features/shared-phase-engine.md) — feature design behind `task-engine` and `requires:`: why the engine had to be a skill, what the CLI change is, the migration order, and what the extraction actually achieved.
- [`./features/pipeline-revision.md`](./features/pipeline-revision.md) — feature design behind `/pipeline-patch` and `/pipeline-revise`, the surfaces that drive `amend.md`.
- [`./features/task-archive.md`](./features/task-archive.md) — feature design behind the task archive: the archived-file form, the archived-and-terminal rule, `/task-clean` as a skill, and `--backfill`.
- [`../../docs/authoring-guide.md`](../../docs/authoring-guide.md) — the `requires:` frontmatter contract, and the council-gate exception that `requires:` cannot cover.
- [`../context/features.md`](../context/features.md) — shipped artifacts including every `task-*` command and skill, plus `skills/task-engine/`.
- `commands/task-setup.md`, `commands/task-add.md`, `skills/task-clean/SKILL.md` + `skills/task-clean/backfill.md`, `commands/task-list.md`, `skills/task-implement/SKILL.md`, `skills/task-engine/SKILL.md` + `skills/task-engine/references/*.md`, `skills/task-review/SKILL.md`, `skills/task-iterate/SKILL.md` — command and skill implementations.