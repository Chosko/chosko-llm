# The routing table

Authority for: what each pipeline feature consumes, what it produces, which
artifact lines it owns, what must hold before it runs, and the shape of its
arguments.

**The contract, in one line: this table is the ownership authority the
revision suite reads, and a consumer states only its deviations from a row.**

Authored here, with every row verified against the shipped body of the
feature it describes — never against a design document. A row a shipped body
does not support is not written.

---

## Columns

- **Feature** — the feature's name, backquoted, with a leading `/` when it is
  invoked as a slash command. The name only: whether it ships as a command or
  a skill is not recorded, so a feature that changes kind changes no row.
- **Consumes** — the project artifacts it reads.
- **Produces** — what a run writes, creates or removes, including any write it
  makes to a line another row owns, marked as such.
- **Owns** — the lines a change is routed to this feature for. **By line, not
  by file**, wherever a file has more than one writer, and on a `Status:` line
  with several writers by the value or transition written. No two rows claim
  the same line, or the same value on it. A file named whole is owned whole.
- **Preconditions** — what must hold before it runs, and where it points when
  that does not hold.
- **Argument shape** — its arguments and flags.
- **Amend** — the owner's own entry point for amending what it owns, when it
  has one; `—` when it has none. A revision surface routes an amendment
  through this column.

## Agreement with `/task-add`

`/task-add`'s OWNERSHIP PRE-AUTHORISATION table is the sole source of
ownership for its pre-authorisation check, and names four owned paths. This
table agrees with it on each: `.claude/domain/features/*.md` is
`/architect`'s; `product-design.md`, `technical-direction.md` and
`business-model.md` are `/product-design`'s; `product-roadmap.md` is
`/product-roadmap`'s; `.claude/PLAN.md` is `/production-plan`'s. The two
tables have different jobs — this one routes a change to its owner, that one
gates an implementer's edit rights — and should they ever disagree, this one
is fixed. That table is not this file's to change.

## Row shape

A row is a line beginning `` | ` `` — a table row whose first cell is the
backquoted feature name, with an optional leading `/`. The header row, the
separator and every other line are not rows. `scripts/check-routing.sh` and
`probes.md`'s `installed` probe both read rows by exactly this shape, so a
formatting change here is a change to both.

A feature adds its own row in the change that ships it. `lint.md` names two
fix commands that have no row, `/pipeline-patch` and `/pipeline-revise`:
neither ships yet, and a row naming a feature the repository does not carry
fails the routing check.

---

## The table

| Feature | Consumes | Produces | Owns | Preconditions | Argument shape | Amend |
| --- | --- | --- | --- | --- | --- | --- |
| `/domain-setup` | Whether `.claude/domain/`, `.claude/domain/features/`, `.claude/domain/INDEX.md`, `.claude/FEATURES.md` and a `CLAUDE.md` domain pointer exist; the heading and opening paragraph of each existing `.claude/domain/**/*.md` | Each of those that is missing: the two directories, `.claude/domain/INDEX.md` with one row per existing document, `.claude/FEATURES.md` as the bare `# Features` title, the `CLAUDE.md` pointer (a minimal `CLAUDE.md` when there is none) | The creation of `.claude/domain/INDEX.md` and its rows for documents that predate it; the creation of `.claude/FEATURES.md` and its title line — no entry line; the `CLAUDE.md` domain-layer pointer | None; with everything present, it says so and writes nothing | `[--commit] [--no-push]` | — |
| `/product-design` | `.claude/domain/INDEX.md`; `.claude/domain/design-process.md`, its resume state; `product-design.md`, `technical-direction.md` and `business-model.md` on resume; `CLAUDE.md`, `README.md`, `.claude/context/`, source | `.claude/domain/design-process.md`, `product-design.md`, `technical-direction.md`, `business-model.md` (opt-in); their `.claude/domain/INDEX.md` rows | `product-design.md`, `technical-direction.md`, `business-model.md` and `design-process.md`, whole; their rows in `.claude/domain/INDEX.md` | `.claude/domain/` and its `INDEX.md` exist, else → `/domain-setup` | `[<free-form context>] [--commit] [--no-push]` | Re-run on a completed process: the resume menu's amend arm edits the three documents in place |
| `/product-roadmap` | `.claude/domain/INDEX.md`; `product-design.md` when present; `product-roadmap.md`, its resume state; `.claude/FEATURES.md`, read-only | `.claude/domain/product-roadmap.md`; its `.claude/domain/INDEX.md` row | `product-roadmap.md`, whole — milestones, `Goal:`, `Exit criteria:`, `Rationale:` and the `Covers:` slices; its row in `.claude/domain/INDEX.md` | `.claude/domain/` and its `INDEX.md` exist, else → `/domain-setup` | `[<free-form context>] [--commit] [--no-push]` | — |
| `/architect` | `.claude/domain/INDEX.md`; `product-design.md` and `technical-direction.md` when present; `.claude/FEATURES.md`; `product-roadmap.md` unless `--no-slices`; `.claude/TASKS.md`, for its iterate guard; `.claude/context/`, source — never `.claude/PLAN.md` | `.claude/domain/features/<slug>.md` and its progress marker (removed at the end); the `FEATURES.md` entry, with `Tasks: none` on a brand-new entry only (a line `/task-add` owns); `Status: [STALE]` on `TASKS.md` lines; `.claude/domain/INDEX.md` rows; clarifications written back into `product-design.md` (a document `/product-design` owns) | `.claude/domain/features/*.md`; the `FEATURES.md` entry heading, `Doc:`, `Source:` with its optional ` (<milestone-slug>)`, and `Status:` → `[NEW]` / `[ITERATED]`; `TASKS.md` `Status:` → `[STALE]`, on every non-`[DONE]` task of a re-architected feature; its rows in `.claude/domain/INDEX.md` | `.claude/domain/` and its `INDEX.md` exist, else → `/domain-setup`; refuses to re-architect a feature with an `[IN PROGRESS]` task, and asks when another is not `[DONE]` | `[<feature name> ... \| <free-form description>] [<milestone-slug>] [--no-slices] [--commit] [--no-push]` | — |
| `/production-plan` | `.claude/FEATURES.md` — slug, `Status:`, `Source:`, `Tasks:`; the `## Dependencies` section of each `Doc:` document; `product-roadmap.md` when present; `.claude/PLAN.md`; `.claude/TASKS.md`, to propose `[SHIPPED]` | `.claude/PLAN.md`, and nothing else | `.claude/PLAN.md`, whole — `Roadmap:`, `Last reconciled:`, each milestone's `Status:`, `Covers:` and `Features:`, `## Unscheduled`, `## Dependencies` | `.claude/FEATURES.md` with at least one feature, else → `/domain-setup`, `/architect`; refuses a dependency cycle or a dependency on a later milestone | `[<free-form context>] [--commit] [--no-push]` | — |
| `/task-add` | `.claude/TASKS.md`; `.claude/FEATURES.md`; the `Doc:` document of the feature it plans; on reconciliation, each listed task's block and `.claude/tasks/<N>.md`; `CLAUDE.md`, `.claude/context/`, `.claude/domain/`, source | New summary blocks and `.claude/tasks/<N>.md` bodies; reconciled statuses and bodies; `FEATURES.md` `Tasks:` and `Status:`; one commit | `TASKS.md` `Last task number:`, and each new block's heading, `Target:`, `Files:`, `Preconditions:` and `Feature:`; `Status:` → `[MISSING]` on create, and `[STALE]` → `[MISSING]` or → `[SKIP]` on reconciliation; the anchor task's `Preconditions:` under `--before`; `.claude/tasks/<N>.md`, created and rewritten in place; `FEATURES.md` `Tasks:` once the entry exists, and `Status:` → `[PLANNED]` | `.claude/TASKS.md` and `.claude/tasks/` exist, else → `/task-setup`; `feature=<slug>` needs `FEATURES.md`, a known slug and a resolvable `Doc:`; `--single` needs a `[PLANNED]` feature | `[--short] [--no-split] [--before <N> \| --after <N>] [--no-commit] [--no-push] <description>` · `feature=<slug> [--single] [--no-split] [--before <N> \| --after <N>] [--no-commit] [--no-push] [<text>]` | — |
| `/task-implement` | `.claude/TASKS.md`; `.claude/tasks/<N>.md`, for the current task only; `CLAUDE.md`, including the `Testing policy for /task-implement:` marker; `.claude/FEATURES.md`, for feature completion; `.claude/context/`, `.claude/domain/`, source; `git status` | Source and test changes; `TASKS.md` status flips; the `FEATURES.md` `Status:` flip; one commit per task, plus one for the approved flips | `TASKS.md` `Status:` → `[IN PROGRESS]`, `[DONE]`, `[PARTIAL]`; `FEATURES.md` `Status:` `[PLANNED]` → `[DONE]`, proposed once at the end of a run and written only on the user's confirmation | `.claude/TASKS.md` exists, else → `/task-setup`; the task's body exists; `--review` needs `task-review` and `task-iterate` | `<N>... \| all \| next [--no-commit \| --no-push] [-y] [--agents \| --no-agents] [--review [--rounds N] [--review-model <name>\|same\|auto] [--review-effort shallow\|standard\|deep\|same\|auto]]` | — |
| `/task-review` | The diff under review — the working tree, a branch, or a pull request through `gh`; `.claude/tasks/<n>.md`; the feature document its `Feature:` names; `CLAUDE.md`, `.claude/context/`, callers and tests | A findings report; `.claude/reviews/<task>-R<round>.md` only when a manual run asks for one; nothing on disk when spawned | `.claude/reviews/<task>-R<round>.md` | A non-empty diff; a task it can resolve, or `task=<n>`; `gh`, for a pull request | `[<branch> [base=<ref>] \| <pr-number\|pr-url>] [task=<n>]` | — |
| `/task-iterate` | Findings — from its caller, the latest `.claude/reviews/<task>-R<n>.md`, or pull-request comments; `.claude/tasks/<n>.md`; `CLAUDE.md`, `.claude/context/`, source | Source and test fixes; standalone, a commit and push — none inside a `/task-implement --review` round; pull-request thread replies | No line of any pipeline index | Findings to triage; a task it can resolve | `[<branch> [base=<ref>] \| <pr-number\|pr-url>] [task=<n>] [--no-commit] [--no-push]` | — |
| `/task-list` | `.claude/TASKS.md`; `.claude/PLAN.md` and `.claude/FEATURES.md` when a plan exists | A listing; writes nothing | Nothing | `.claude/TASKS.md` exists, else → `/task-setup` | `[<STATUS>]` | — |
| `/task-clean` | `.claude/TASKS.md`; whether `.claude/tasks/<N>.md` and `.claude/tasks/archive/<N>.md` exist, for each id it archives; under `--backfill`, git history and `.claude/FEATURES.md` | Removed summary blocks; bodies moved to `.claude/tasks/archive/<N>.md`; pruned ids dropped from survivors' `Preconditions:` (a line `/task-add` owns); under `--backfill` only, archived ids restored to `FEATURES.md` `Tasks:` (a line `/task-add` owns); one commit | The removal of `TASKS.md` summary blocks; `.claude/tasks/archive/` — each moved body and its frozen header | `.claude/TASKS.md` exists, else → `/task-setup`; `--backfill` needs git | `[<STATUS>...] [--no-commit \| --no-push]` · `--backfill [--no-commit \| --no-push]` | — |
| `/production-status` | `.claude/PLAN.md`, `.claude/FEATURES.md`, `.claude/TASKS.md`, `.claude/domain/product-roadmap.md`; `product-design.md`'s section headings | A report; writes nothing | Nothing | `.claude/PLAN.md` exists, else → `/production-plan` | `[milestone=<slug>] [--task-ids]` | — |
| `/runbook-create` | `.claude/RUNBOOKS.md`; the target body, under `--append`; the conversation's follow-up list | `.claude/runbooks/<name>.md` and `.claude/RUNBOOKS.md`, created on first use; ids assigned to an id-less index | The body header, `Sequencing:` and `Companion:`; each step's heading, `[ ]` marker, `Depends on:`, `Needs:`, `Context: none` and prompt block; `## Do not re-propose`; appended steps; `RUNBOOKS.md` `Last runbook number:`, each block's heading, `File:`, `Created:`, `Source:`, the `Steps:` total, and `Status:` → `[PENDING]` on create and `[DONE]` → `[PENDING]` on an append | None for a new runbook; `--append` needs a known runbook that is not `[RUNNING]` in another session; `--before` / `--after` need `--append` and a known step | `[<name> \| <description>] [--commit [--no-push]]` · `--append [<name\|id>] [--before <step> \| --after <step>] [--commit [--no-push]]` | — |
| `/runbook-run` | `.claude/RUNBOOKS.md`; `.claude/runbooks/<name>.md`, re-read at every step; `CLAUDE.md` | The body and the index, nothing else; one commit per step; ids assigned to an id-less index (lines `/runbook-create` owns) | Body markers `[~]`, `[x]` and `[!]`, `Done:` lines and dated `Context:` bullets; `RUNBOOKS.md` `Status:` → `[RUNNING]`, `[FAILED]`, `[DONE]`, and back to `[PENDING]` at a `--to` bound; the `Steps:` done count; `Failed at:` | A known runbook; not `[DONE]` without a range; not `[RUNNING]` unless resuming; every `Depends on:` met | `<name\|id> [--from N] [--to N] [--only N] [--model <m>] [--relay-spawns] [--no-commit \| --no-push]` | — |
| `/runbook-list` | `.claude/RUNBOOKS.md` only | A listing; writes nothing | Nothing | None; a missing or empty index prints one line | `[<STATUS>]` | — |
| `/runbook-describe` | `.claude/RUNBOOKS.md` and exactly one body | A description; writes nothing | Nothing | A known runbook | `<name\|id>` | — |
| `/runbook-clean` | `.claude/RUNBOOKS.md`, `File:` included; whether each body exists | Deleted bodies and a rewritten index; ids assigned to an id-less index (lines `/runbook-create` owns); one commit | The removal of a `[DONE]` runbook's index block and the deletion of its body | Every named runbook known and `[DONE]` | `[<name\|id> ...] [--no-commit] [--no-push]` | — |
| `runbook-suggest` | The conversation only | One or two lines pointing at `/runbook-create`; writes nothing | Nothing | A follow-up list of three or more actions, two or more with an ordering constraint, or any action resting on decisions recorded nowhere on disk | None — selected from its description, never invoked | — |
| `/pipeline-check` | The probe; the index lines of `.claude/FEATURES.md`, `.claude/TASKS.md`, `.claude/PLAN.md` and `.claude/RUNBOOKS.md` | A report; writes nothing | Nothing | At least one of those four indexes, else → `/task-setup`, `/domain-setup` | `[feature=<slug>]` | — |
