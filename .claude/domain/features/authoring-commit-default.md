# Authoring commit default — the four pipeline design skills commit by default

`/architect`, `/product-design`, `/product-roadmap` and `/production-plan`
stop leaving their output in the working tree and start committing and
pushing it, the way `/task-add` and `/task-implement` already do. `--commit`
becomes unnecessary; `--no-commit` becomes the way to hold the output back
for review. Nothing else about the four changes: same phases, same gates,
same write sets, same commit-and-push protocol.

## Purpose

The pipeline's authoring stages were designed around a reviewer's pause —
[`product-design.md` § Design decisions](../product-design.md) records
"authoring commands that leave their output uncommitted unless `--commit` is
passed" as the product's own rule, one of the gates that keep the director
in the reviewer's seat.

For these four the pause stopped paying. A design document, a roadmap, a
plan and a feature document are all *written and then read again by the next
session*, usually on another machine or in another terminal, which is the
one place an uncommitted working tree helps nobody. The director's review
already happens where it matters — inside the run, at each skill's own
approval gate, before a line is written — so the second pause at the end
re-asks a question already answered, and the usual answer is `--commit`
typed after the fact.

The four commit-by-default; the remaining authoring commands do not. That
asymmetry is the feature, not a defect of it: the scaffolding commands
(`/task-setup`, `/domain-setup`, `/project-setup`, `/unity-mcp-setup`), the
context-layer builders (`/context-build`, `/context-convert`), the
refactorers (`/refactor-codebase`, `/refactor-tests`) and `/runbook-create`
all produce output whose first read is a human's eyes on the diff, and they
keep the old default deliberately.

## Scope and non-goals

**In scope**

- The commit default of exactly four skills: `/architect` (including its
  `amend` form run as `/architect`), `/product-design`, `/product-roadmap`,
  `/production-plan`.
- The `--no-commit` flag on each, with `--commit` retained as an accepted
  no-op and the existing mutual-exclusion error preserved.
- Pull-at-start, which is tied to the commit decision and therefore becomes
  unconditional on a default run.
- The two forwarding tables that record these skills' defaults on behalf of
  a caller: `/pipeline-patch` and `/pipeline-revise`.
- Every sentence in the shipped bodies, the docs, the domain layer and the
  context layer that asserts the old default — including the
  `product-design.md` design-decision bullet that records it as policy.

**Non-goals**

- **The other nine authoring commands.** `/task-setup`, `/domain-setup`,
  `/project-setup`, `/unity-mcp-setup`, `/context-build`,
  `/context-convert`, `/refactor-codebase`, `/refactor-tests` and
  `/runbook-create` keep the old default. This is settled, not deferred: the
  authoring group in
  [`docs/authoring-guide.md`](../../../docs/authoring-guide.md) shrinks to
  those nine and goes on existing.
- **Collapsing the four commit blocks onto one authority.** Each of the four
  carries its own near-identical ARGUMENT PARSING / pull-at-start /
  `COMMIT AND PUSH` apparatus, and each keeps it. Routing them through
  `task-engine`'s `references/commit.md`, or a new `pipeline-engine`
  reference, was weighed and declined for now — the duplication is visible
  but the coupling it would create (a design-pipeline skill requiring the
  task engine) is not obviously cheaper. Also settled, not open; revisit
  when a third change has to touch all four blocks at once.
- **Any change to what the four write.** Write sets, `WRITTEN` membership,
  staging rules and the explicit-paths-never-a-catch-all rule are all
  untouched.
- **Any change to the commit-and-push protocol itself.** Pull at start,
  commit, re-sync, push stays exactly as
  [`docs/authoring-guide.md`](../../../docs/authoring-guide.md) defines it.
- **`--push` as a new flag, or any change to `--no-push`.** `--no-push`
  keeps its meaning and keeps mattering only when something is being
  committed.

## Architecture

Built on the repository's own stack per
[`technical-direction.md`](../technical-direction.md): markdown feature
bodies interpreted by Claude Code, POSIX bash for the CLI. No code executes
this change — it is a change to what four prompt bodies instruct, and to the
documents that describe them. See
[`.claude/context/features.md`](../../context/features.md) for where each
body lives.

### The inverted boolean, four times

Every one of the four already resolves a single `COMMIT` boolean in an
`ARGUMENT PARSING` block, consults it once in PHASE 0 for pull-at-start, and
consults it again in a closing `COMMIT AND PUSH` section. The change is to
that boolean's default and to the flag that moves it, in the shape
`skills/task-engine/references/commit.md` § *The flags* already defines for
the auto-committing group:

- `COMMIT` is true unless `--no-commit` was passed.
- `--no-commit` implies `NO_PUSH` — nothing is committed, so nothing is
  there to push.
- `--commit` remains accepted and is a silent no-op, exactly as it is for
  `/task-add` today, so existing runbook steps, documented invocations and
  the two forwarding tables keep working through the transition.
- `--commit` together with `--no-commit` still stops the run with
  `--commit and --no-commit cannot be combined. Pick one.`

Three consequences propagate mechanically from the inversion, and each is a
sentence in a shipped body rather than a mechanism:

1. **Pull-at-start becomes unconditional** on a run without `--no-commit`.
   This matches `/task-add`, which already pulls on every run, and it is
   deliberate that a conflict stops the run before any work is done rather
   than after.
2. **The closing report's "nothing was committed" reminder** inverts: it
   fires under `--no-commit` instead of under the absence of `--commit`.
3. **The `DO NOT` git bullet** in each body inverts from "run no git command
   unless `--commit` was passed" to "run no git command when `--no-commit`
   was passed". The rest of that bullet — stage only explicit `WRITTEN`
   paths, never a catch-all, never force-push, never `--no-verify` — is
   untouched and still binds.

### Supporting files that restate the default

The four skills are folders, and five supporting files inside them assert
the old default in prose. They are part of the same change, not follow-up:
`architect/amend.md`, `architect/iterating.md`, `architect/council-gate.md`,
`product-design/council-gate.md`, `product-design/resuming.md`.

### The two consumers

`/pipeline-patch` and `/pipeline-revise` each carry a *forwarding table*
whose rows are grouped by the owner's commit default — the one place in the
product where a command records another command's default on its behalf. A
default that changes without its forwarding row changing produces exactly
the failure the tables exist to prevent: a revision run committing when the
user did not ask.

`/product-design` and `/production-plan` move out of the "commits nothing by
default" row and into `/task-add`'s row — forward `--no-commit` when
`--commit` was absent, forward nothing when it was present. `/architect` is
reached by these two only through its amend arm, which is unaffected (below),
so it needs no row of its own.

### The by-path arm keeps no default

`architect/amend.md`, `task-engine/references/amend.md` and
`runbook-run/references/step-amend.md` are *arms executed by path*: the
executor stages and commits their closed write set, and the arm itself
asserts no default. That contract is what lets `/pipeline-patch` run an arm
without inheriting a command's habits.

The flip therefore reaches `/architect amend` **only when it runs as
`/architect`**. Loaded by path by `/pipeline-patch` or `/pipeline-revise`,
`architect/amend.md` behaves exactly as it does today. Any edit to
`amend.md` that gave it a default of its own would break the patcher's own
table, and is out of bounds.

### `council-gate.md`'s exclusion survives by rewording

Both `council-gate.md` files say the council's report and transcript are
"never staged by `--commit`". That sentence is about `WRITTEN` membership —
those two files are never in the staging list under any circumstances — and
it merely happened to name the flag that did the staging. It becomes "never
staged", which is what it always meant and is now also what it says.

### Documentation as part of the change, not after it

The old default is asserted in six places outside the shipped bodies:
`README.md`, `docs/reference.md`, `docs/authoring-guide.md` §
*Commit-and-push convention*, `.claude/domain/product-workflow.md` §
*Commit and push*, `.claude/context/features.md`, and
`.claude/domain/features/owner-amend-arms.md`. Per
[CLAUDE.md](../../../CLAUDE.md) § Versioning these are documentation: they
bump no `VERSION` and earn no `CHANGELOG` entry, while the four skill bodies
and the two consumers are product and bump as always.

One of the six is not a description but a decision:
`product-design.md` § Design decisions records the old default as product
policy. It is narrowed rather than deleted — the gate-keeps-the-director-in-
the-reviewer's-seat principle stands, and the sentence is corrected to say
which commands still express it that way.

## Data and state

No stored state, no schema, no file format. The only state involved is
`COMMIT` and `NO_PUSH`, resolved per run from `$ARGUMENTS` and held in the
run's own context. There is no settings key, no marker file and no
per-project override — a project that wants the old behaviour passes
`--no-commit`, exactly as it does for `/task-add` today.

One state file changes hands as a side effect: `/product-design` writes
`.claude/domain/design-process.md` as its resume state, and a
commit-by-default run now commits it. The resume state becomes shareable
across machines and terminals instead of living in one working tree. That is
a behaviour change nobody asked for, it reads as a gain, and it is recorded
here so a future reader does not have to rediscover why the file started
appearing in commits.

## Interfaces and contracts

**The flag surface**, identical on all four:

- `--no-commit` — write everything, run no git command, report what was
  written and remind the user nothing was committed.
- `--no-push` — commit as always, skip the pull-at-start / re-sync / push
  cycle. Meaningful only when something is being committed.
- `--commit` — accepted, no-op.
- `--commit --no-commit` — stops the run:
  `--commit and --no-commit cannot be combined. Pick one.`

**The forwarding contract.** `/pipeline-patch` and `/pipeline-revise` make
no commit of their own and must, for each owner step, forward whichever flag
produces *the user's stated intent* under that owner's default. The table is
the contract; a default change that does not reach it is a defect.

**Failure contract.** Unchanged from the commit-and-push protocol: a pull
conflict at start stops the run before any work; a commit rejected by a hook
surfaces the exact output, leaves files staged, and is never retried,
amended or forced past; a failed push leaves the commit local and tells the
user to sync manually. The run never force-pushes, branches, tags or passes
`--no-verify` / `--no-gpg-sign` / `--amend`.

**What a reader of a default run now sees:** a pull before the first
question, and a commit hash plus a push confirmation in the closing report
where there used to be a reminder that nothing was committed.

## Dependencies

- `pipeline-revision` — owns `/pipeline-patch` and `/pipeline-revise`, whose
  forwarding tables state these four defaults. Their rows change in this
  feature; nothing else of theirs does.
- `owner-amend-arms` — owns `architect/amend.md` and the by-path arm
  contract this feature must not disturb. Its own documentation names
  `/architect amend`'s flags and is updated here.
- `pipeline-engine` — owns the routing table. No row changes: this feature
  adds no command, removes none and re-kinds none, so
  `./scripts/check-routing.sh` has nothing new to check. It is still run,
  because the four bodies are edited.
- `version-changelog` — the four skills and the two consumers are product,
  so root `VERSION` moves and `CHANGELOG.md` gains a section;
  `./scripts/check-changelog.sh` must pass.

External dependencies: none. No new tooling, no new script, nothing added to
the POSIX-bash-only constraint.

## Open questions

None. The two questions this change raised — whether the remaining authoring
commands follow, and whether the four commit blocks should collapse onto one
authority — were both asked at architecture time and both answered no, and
are recorded under *Scope and non-goals* as decisions rather than left here
as pending work.
