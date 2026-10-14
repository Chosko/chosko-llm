# Features: runbook-run

## Overview

Covers `skills/runbook-run/` — the runbook asset kind's store and the
skill's reference files and dependencies. The rest of its bullet:
[runbook-run-loop.md](./runbook-run-loop.md) and
[runbook-run-contracts.md](./runbook-run-contracts.md). The family hub:
[runbook-suite.md](./runbook-suite.md).

- `skills/runbook-run/` — orchestrator of the runbook asset kind
  (`.claude/runbooks/<id>-<name>.md` bodies at the path each index block's
  `File:` holds + `.claude/RUNBOOKS.md` index; body is
  source of truth, index's `Status:`/`Steps:` derived and rebuildable from it —
  the id and its counter are the one exception, assigned rather than derived).
  **Skill not command** because `cmd-add` copies a skill folder with `cp -R`
  while a command is one file carrying nothing: it hosts `references/
  runbook-schema.md` (store, body schema, the FIVE step markers
  `[ ]`/`[~]`/`[x]`/`[!]`/`[P]` — `[P]` parked: a `Context:` bullet
  `- <date> parked: <question>` carries the question verbatim, options
  included, never an approval-gate draft; not done in `Steps:`, committed
  like `[x]`/`[!]`, never beside `[~]`, not a skip, cleared to `[ ]` with
  `- <date> unparked with answer: <text>` — the four statuses
  `[PENDING]`/`[RUNNING]`/`[FAILED]`/`[DONE]` (a runbook waiting on a `[P]`
  step is `[PENDING]`), the optional header `Execution policy:
  attended|unattended` (absent = `attended`; any other value an argument
  error at run time), the optional header `Parallelism: <N|max>` directly
  after it (an integer of 2 or more, or `max`; absent = 1; authored by
  `/runbook-create` only when asked for a parallel runbook, never rewritten
  by a run, overridden for one run by `/runbook-run --parallel`; any other
  value an argument error at run time; mutually exclusive with `Sequencing:`,
  whose constraint the graph does not carry) — under a parallelism above one
  `Depends on:` is the ONLY ordering constraint and list position is priority
  among the steps selectable at the same moment, and `[~]` MAY be committed
  (a landed step's commit carries it for the steps still in flight), the
  resume signal being `[RUNNING]` plus a `wt/runbook-<id>-step-<n>` worktree
  on this machine rather than an uncommitted `[~]` — the index
  `Parked: steps <ids>` line present only while
  a step is `[P]` — `Failed at:`'s rule applied again — the optional
  per-step `Needs:` field, index block + its `Last runbook number:` counter and
  per-runbook **id**, plus two header fields of the body's own: the
  `Last step number:` step counter — highest id ever assigned, only ever
  increases, never `max()`, next unused id = value + 1 — and the optional
  `Archive:` id list `/runbook-prune` writes, whose ids **count as `[x]`**
  everywhere a marker is read, keeping a surviving `Depends on:` resolvable and
  the `Steps:` count unchanged by a prune; a body with no `Last step number:`
  line is backfilled in place — to the highest id present, counting steps about
  to be removed — by whichever of `/runbook-create --append` and
  `/runbook-prune` writes it first)
  and `references/subagent-contract.md` (two fenced blocks: OPERATING RULES,
  pasted verbatim into every spawned prompt, and RELAY CHILD RULES, pasted
  verbatim ahead of it into a relay child's prompt only — six placeholders,
  `<RUNBOOK>`, `<N>`, `<FILE>` (the body's `File:` path, for the never-edit
  rule; relay file names stay built from `<RUNBOOK>`/`<N>`) and `<WORKTREE>`
  (the absolute directory the step works in — its
  `.claude/worktrees/runbook-<id>-step-<n>` worktree under a parallelism
  above one, the base tree's own path on a sequential run — carrying two
  fixed rules: every path touched is under it, and the remote is the
  orchestrator's, so an invoked skill commits as usual but skips its pull,
  re-sync and push of the base as under `--no-push` with no flag typed —
  its own `park/task-<N>` the one branch it still pushes when it parks, per
  `task-engine`'s `parking.md` — and before
  `DONE` the agent rebases its branch onto the base tip per `task-engine`'s
  `worktree.md` § *The agent integrates*, a no-op on the base itself), plus
  `<PROMPT>`/`<RESULT>` on the child block alone,
  and it carries the `SPAWN REQUEST` rule; OPERATING RULES make the literal
  `DONE` line mandatory — a finished turn without it is a hard failure however
  complete the work, and work that made no commit omits the sha and diffstat;
  RELAY CHILD RULES carry a precedence line: `<RESULT>` is the child's return
  channel, overriding any instruction in `<PROMPT>` or a skill it invokes to
  reply in the turn or write nothing to disk), both cited by the other three
  by a `./references/<f>.md` path relative to the citing body;
  `/objective-run` cites `subagent-contract.md` (its worker and checker
  briefs) and `parking.md` (its parked questions) as
  `../runbook-run/references/<f>.md`.
  `references/inline-contract.md` holds the fixed inline rule set that replaces the OPERATING RULES under
  `--inline`, read only when that flag is passed. Both contracts carry, as
  fixed text, one unconditional rule — a step command's dirty-tree prompt
  listing only the runbook and the index is answered `proceed` (never
  `include`) by the step's agent or the inline session, one line said — and
  two rules conditional on the preamble's `unattended` sentence: leave the
  tree clean of your own changes before ending with a question (work a skill
  parked on a branch is not yours) and say so; and a `Context:` bullet
  `unparked with answer:` answers the invoked skill's question, never relayed
  back. `references/parking.md`, read once per run on two triggers only
  (policy resolved to `unattended` in step 1; step 3 selecting or blocked by
  a `[P]` step), holds the fifth result row, the end branch, unparking, the
  pre-ask, mid-run answers, the rejections and the attended handling of a
  `[P]` step — bookkeeping in the two files only, never a task body, branch
  or diff. `references/parallel.md`, read once in step 1 only when the
  parallelism resolves above one (with `task-engine`'s `worktree.md`, which
  it names), amends steps 2–8, the result cases, the resume signal, the
  commit cadence and the closing report for that run — the body carries the
  flag, the resolution, the three argument errors and one pointer line; the
  loop it describes is in [runbook-run-loop.md](./runbook-run-loop.md).
  `references/parallel-authoring.md` is `/runbook-create`'s, read only for a
  parallel runbook. `references/step-amend.md` (amending one pending step: strike it as `[x]` with a `Done:` line opening
  `struck — <reason>` and no commit sha, never deleted or renumbered; insert
  through `/runbook-create --append --before`/`--after`; add dated `Context:`
  facts; the prompt block immutable, so a wrong prompt is struck and a
  corrected step inserted; a `[RUNNING]` runbook accepting changes only after
  its current step), is never read by this body — whatever amends a step
  (`pipeline-revise`) reads it by path, and reads and writes
  the body at `File:`. `references/body-migration.md` (the lazy rename
  of a legacy `<name>.md` body: plain `mv` to `<id>-<name>.md` then rewrite
  `File:`, nothing staged until the writing command's one commit, which names
  old path, new path and the index explicitly — never `git mv`, whose staged
  rename a step's own commit would carry off; never while
  `[RUNNING]`; a taken target path stops, never overwritten; non-git VCS
  mapping), is read ONLY by `/runbook-run` and `/runbook-create --append`, and
  only after the schema's one-sentence check finds a `File:` file name not
  beginning `<id>-`. No sweep, no migration script. It IS the dependency
  the rest of the runbook suite and `/objective-run` declare — and declares
  three itself, `requires: command:follow-ups, skill:follow-ups-resolve,
  skill:task-engine` (the second for the mid-run follow-up protocol and the
  post-report execution of approved items; the third for one file alone,
  `../task-engine/references/worktree.md`, the worktree protocol, which joins
  the "reads three files" contract as a read made only by a run whose
  parallelism is above one — [task-engine.md](./task-engine.md)): its
  CLOSING THE RUN section applies the first
  command's rules — body read by name, never invoked — as the *Follow-ups*
  group of the closing report, once per run (completion, a `--to`/`--only`/
  `--steps` bound, the end branch, a user-requested stop after a step, or a
  failure halt), after the final commit, adding no commit; with the command
  absent the group holds the run's own items only, silently; in the default
  spawned mode that
  reading covers the step subagents' result reports — already in hand from
  step 7, so no file is opened and neither the "reads three files" contract
  nor the spawn relay's never-read-a-relay-file rule is touched.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run-loop.md](./runbook-run-loop.md) — execution policy, handles,
  ids, the step loop, parking and the spawn relay.
- [runbook-run-contracts.md](./runbook-run-contracts.md) — chat contract,
  closing report, commit convention, Stop-hook reply and hard contracts.
- [pipeline-dashboard.md](./pipeline-dashboard.md) — the opt-in dashboard: the
  ARGUMENTS row for `--dashboard` / `--no-dashboard` is the one line naming
  it, and the one place its state and chat line sit outside the two-files and
  quiet-between-steps contracts.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
