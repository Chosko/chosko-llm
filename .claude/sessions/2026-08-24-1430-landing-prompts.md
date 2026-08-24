# Landing prompts — ECC import work

Copy-paste these into fresh sessions, **in this order**. Each is self-contained:
it names the document to read and carries any decision that exists nowhere on
disk. Prompts 1–4 touch `skills/task-implement/SKILL.md` and must not be
reordered. Prompts 5–7 are independent of everything and of each other.

Companion handoff: `2026-08-24-1430-ecc-import-architecture.md` beside this file.

---

## [x] 0. Optional — commit the architecture first

The five feature docs, the `FEATURES.md` entries and the `.claude/domain/INDEX.md`
rows are currently uncommitted. Land them before authoring tasks so the task
bodies reference committed documents.

```
Commit the uncommitted architecture work: the five new feature documents under
.claude/domain/features/ (session-continuity, task-peer-review,
task-implement-launcher, shared-phase-engine, repo-local-audits), the five [NEW]
entries appended to .claude/FEATURES.md, and the five rows appended to
.claude/domain/INDEX.md. Do NOT bump root VERSION — nothing shipped; no file
under commands/, skills/, claude-md/, statusline/, hooks/, scripts/ or bin/
changed. VERSION bumps when a user receives something different, and design
documents for unbuilt features are not that. The bump comes with the first task
that actually changes a feature.
```

**Done — committed on branch `feature/ecc-import-architecture`, 2026-08-24.**

---

## [x] 1. Delete the dead dual-LLM lane

**This has no feature document.** All its evidence is here and in the council
transcript, so the prompt carries it.

```
/task-add Delete the dual-LLM local-model implementation lane from chosko-llm.

Evidence it is dead, verified 2026-08-24: across the entire git history of this
repo there are 109 `Target:` lines in .claude/tasks/ — 108 `claude`, 1
`claude+human`, and 0 targeting local/qwen/aider. Across the three downstream
projects that use these conventions (factotum 55 tasks, job-hunter-cli 48,
IsThisFreedom 3) there are another 165 `Target:` lines, again 0 local. That is
~274 task authorings across 4 repositories in 110 days with the lane never
invoked once.

Scope of the deletion, roughly 1,400 lines: scripts/cmd-task-impl.sh,
scripts/lib-task-external.sh, the external-LLM sections of
skills/task-implement/SKILL.md, the `.claude/external/` scaffolding emitted by
/task-setup, and the `chosko-llm task-impl` subcommand and its help text.

Two things must NOT be deleted: the `Target:` field itself, which stays with its
live values `claude` / `claude+human` / `human`, and any handling of those
values. Only the local-model path goes.

Before deleting, enumerate job-hunter-cli's 8 files that reference
.claude/external/ and its hand-written score-with-local.sh — that script is
author-written, not scaffolding, and is the one genuine coupling. Confirm it is
independent of this lane before proceeding. `.claude/external/` is present in
all three downstream projects but is inert scaffolding that nothing consumes.

Also update CLAUDE.md, docs/authoring-guide.md and .claude/context/ wherever
they describe the dual-LLM author/implementer split, and remove
.claude/context/cmd-task-impl.md.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those.
```

**Done — task 118 authored, commit `267c59f`, 2026-08-24.** Decisions taken
while authoring: the whole enrich apparatus goes too (`/task-enrich`,
`/task-add --enrich`, `Target: local`, enriched-body schema); `/task-setup`
keeps emitting `run-affected-tests.sh` / `run-full-tests.sh` (job-hunter-cli
uses them as its real test dispatcher) but drops the two aider prompt files;
`scripts/check-task-parity.sh` is deleted; root `VERSION` goes to `1.0.0`.
Task 118 deliberately leaves `.claude/domain/features/shared-phase-engine.md`
untouched — see the note under prompt 4.

---

## [ ] 2. Batch launcher

```
/task-add feature=task-implement-launcher

Read .claude/domain/features/task-implement-launcher.md first. Sequencing: the
dual-LLM lane deletion must already be done — it removes material from the same
file. Do not start until that is landed.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those.
```

---

## [ ] 3. Peer review

```
/task-add feature=task-peer-review

Read .claude/domain/features/task-peer-review.md first. Sequencing: the
dual-LLM deletion and task-implement-launcher must already be landed; all three
edit skills/task-implement/SKILL.md.

Two things in that document are binding and easy to lose, so make sure they land
in task bodies rather than staying only in the design doc:

1. Under --review, /task-iterate must NOT commit. It leaves the corrected tree
   for /task-implement's existing Step 7, so a task still produces exactly one
   commit. Standalone /task-iterate DOES commit and push. This is a deliberate
   departure from the obvious symmetric design and the reason is the
   one-commit-per-task contract.

2. A spawned subagent returns ASYNCHRONOUSLY — the spawn call yields an id
   immediately and the result arrives later as a separate notification, not as
   the tool call's return value. This was verified by direct probe on
   2026-08-24. The implementor's body must wait for its reviewer's result and
   must not reach Step 7 before it arrives; a body assuming a synchronous return
   will commit unreviewed work. Subagent nesting to depth 3
   (launcher -> implementor -> reviewer) was confirmed to work, so batch
   --review is in scope.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those.
```

---

## [ ] 4. Shared phase engine

**Carries a stale-document fix.** Task 118 (prompt 1) deletes `/task-enrich`
and `scripts/check-task-parity.sh`, but
`.claude/domain/features/shared-phase-engine.md` still names `task-enrich` in
its migration order and `check-task-parity.sh` among its validation ideas.
Task 118 left that document alone because it is `/architect`-owned; this
prompt must fix it before the tasks are derived from it.

```
/task-add feature=shared-phase-engine

Read .claude/domain/features/shared-phase-engine.md first. Sequencing: this
goes LAST of the four that touch skills/task-implement/SKILL.md. Landing it
before the other three rebases a large restructure onto a file that moved twice.

The feature document is stale in two places and must be corrected BEFORE the
task bodies are derived from it, so no task inherits the stale references:
task 118 deletes /task-enrich (commands/task-enrich.md) and
scripts/check-task-parity.sh. Remove task-enrich from the migration order in
that document (the surviving consumers are task-list, task-clean, task-add and
task-implement) and drop check-task-parity.sh from its validation notes. Keep
the rest of the document as-is.

Make sure the migration order in that document survives into separate tasks —
it is designed so each step is independently verifiable:

  a. The `requires:` frontmatter field plus the cmd-add / cmd-rm changes, with
     no feature using it yet. Inert alone, independently testable.
  b. Create skills/task-engine/ with reference files extracted VERBATIM from
     current bodies — no rewording during extraction, so any behaviour change
     shows up as a visible diff rather than hiding in a paraphrase.
  c. Migrate task-list first — smallest and read-only, so a regression is
     obvious and harmless.
  d. Then task-enrich, task-clean, task-add, and task-implement last.

Two facts already verified, so no task needs to re-derive them: parse_frontmatter
in scripts/lib.sh splits on the first colon generically, so `requires:
skill:task-engine` parses with zero changes to lib.sh; and cmd-add installs a
skill with `cp -R` of the whole folder, which is why the engine must live in a
skill and not a command.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those.
```

---

## [ ] 5. Session continuity

```
/task-add feature=session-continuity

Read .claude/domain/features/session-continuity.md first. Independent of the
task-* work — can be done at any point.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those. Note that the two
files in .claude/sessions/ are themselves hand-written examples of the layout
this feature specifies; treat them as the reference shape, not as generated
output.
```

---

## [ ] 6. Repo-local audits

**Carries the `CLAUDE.md` rule change that would otherwise be lost.**

```
/task-add feature=repo-local-audits

Read .claude/domain/features/repo-local-audits.md first. Independent of
everything else.

One task in this set must be a CLAUDE.md change, and it is the easiest thing
here to lose: this repo's rule is "bump root VERSION on every shipped change",
but the two skills in this feature live in .claude/skills/, are unversioned, and
ship to nobody. Changes to them must NOT bump root VERSION — bumping for a file
no user receives corrupts the meaning of the version install.sh reports.

Add a line to CLAUDE.md's Versioning section recording that exception, naming
.claude/skills/ as the repo-local unshipped location. Without it the next
session will bump VERSION for these files, because the existing rule says to.

Background, if you need it: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
holds the decision log for this whole body of work, including the ECC features
already assessed and discarded — do not re-propose those.
```

---

## [ ] 7. Reconcile the stale planning layer

Not part of the ECC work — a pre-existing inconsistency found while verifying
council claims. Worth landing before `/production-plan` runs against these five
new features.

```
Reconcile this project's own planning layer, which has drifted:

- .claude/FEATURES.md marks four features [PLANNED] — product-roadmap,
  slice-aware-architecture, production-plan, plan-readout — but their tasks
  (106 through 115) are all [DONE] in .claude/TASKS.md. The statuses were never
  flipped when the work finished.
- .claude/PLAN.md does not exist at all, even though the /production-plan skill
  has shipped and this repo dogfoods its own pipeline.

Work out the correct statuses from TASKS.md, flip them, and decide whether
PLAN.md should now be generated for this repo. Five new [NEW] features were
added on 2026-08-24 (session-continuity, task-peer-review,
task-implement-launcher, shared-phase-engine, repo-local-audits) and will need
placing in a milestone if you do generate it.

Background on those five, if you need it:
.claude/sessions/2026-08-24-1430-ecc-import-architecture.md and the feature
documents under .claude/domain/features/.
```

---

## Things that must not be re-proposed

A future session reading the council report in the repo root will find a
recommendation to **freeze chosko-llm feature work**. That recommendation was
rejected, correctly: job-hunter-cli repeatedly requires chosko-llm features to
be created or updated, so tooling work here is demand-driven rather than
self-referential. The council journal entry for sha `16686f3a` records this as
the run's outcome.

Also already assessed and discarded, with reasons, in the session handoff file:
config-gc, rules-distill as a shipped skill, inherit-legacy-style,
update-codemaps, intent-driven-development, spec-miner, harness-audit,
delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and every
ECC dimension-reviewer agent except `code-reviewer`.
