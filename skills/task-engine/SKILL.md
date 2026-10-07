---
name: task-engine
version: 0.8.4
type: skill
description: Reference library for the task-* features — one authority per rule they share, under references/; read by path by the task-* commands and skills and by the pipeline revision surface, never invoked.
disable-model-invocation: true
project-policy: line:Testing policy for /task-implement=skip-tests|full-tdd|skip-tests-unattended, vcs:add, vcs:commit, vcs:status, vcs:rev-parse, vcs:log, vcs:mv, vcs:show, vcs:branch
---

# task-engine
# Reference library, read by path by /task-add, /task-list, /task-clean,
# /task-implement, /task-review and /pipeline-revise; not invoked.

> **Not directly invocable.** This skill exists so that the rules the
> `task-*` features share have exactly one home. It has no command, no
> arguments and no behaviour of its own. Nothing invokes `/task-engine`;
> nothing should suggest it. `/task-add`, `/task-list`, `/task-clean`,
> `/task-implement` and `/task-review` cite the files below by path while they
> run, the pipeline revision surface `/pipeline-revise` reads
> `references/amend.md` by path, and those files are the only content here.

> **Install path assumption:** this skill installs beside the features that
> read it — `chosko-llm add skill:task-engine` writes it under the same home
> those features are installed into, whichever home that is. So a feature
> names a file here by a path **relative to its own body**, never by an
> absolute home path, counting directories up to the install home and back
> down: `../task-engine/references/<file>.md` from a file at another skill's
> root, `../../task-engine/references/<file>.md` from a file under another
> skill's `references/`, `../skills/task-engine/references/<file>.md` from a
> command, and `./<file>.md` between two files in this skill.
>
> That is scope-proof by construction. `CLAUDE_HOME` still governs where
> `install.sh` and the `scripts/cmd-*.sh` verbs *write* — including
> `--local`, which repoints the whole home to `$PWD/.claude` — but a shipped
> body cannot re-derive it at run time, because the executing agent expands
> `${CLAUDE_HOME:-$HOME/.claude}` itself and always lands on the global home.
> Citing body and cited file are always siblings under one root, so a
> relative path is correct in either scope with no probing and no fallback.

---

## The map

| Reference file | Owns |
| -------------- | ---- |
| `references/resolution.md` | Where the backlog lives, the `.claude/TASKS.md` summary-block schema, the not-initialised stop, when a per-task body file may be opened, the task archive (its location, the archived-file form and the archived-and-terminal rule), the `all` / `next` / explicit-list selectors, and the eligibility clause — implementable status plus satisfied `Preconditions:` — that the batch selectors honour. |
| `references/status.md` | The nine status tags and what each means, which are terminal, which are implementable, how a status filter is accepted, and the legal transitions. |
| `references/targets.md` | The three `Target:` values, the `## Manual interventions` pairing rule, what each target means at implementation time, and the delegation guard. |
| `references/stale.md` | What `[STALE]` means, who sets and clears it, how the originating feature is found, and how each feature treats a stale task. |
| `references/tree.md` | The dirty-tree prompt protocol and the folding rules that follow from it. |
| `references/commit.md` | Commit and push gating: `--no-commit` / `--no-push`, pull-at-start, what may be staged, one commit per unit of work, and commit/push failure handling. |
| `references/review-budget.md` | Review cost controls: the `--review-model` / `--review-effort` values and their `same` / `auto` reserved words, the deterministic `auto` tier table, the read budget behind the effort axis, what is counted and what never is, and the cap-bound and resolved-pair reports. |
| `references/design-change.md` | The design-change check: the owner table of paths another pipeline command owns, the *settles* / *diverges* enumeration of a drafted task's points, the question a diverging point raises, what agreement writes into the drafted body, what disagreement does, and the hard rules. |
| `references/reconciliation.md` | Applying reconciliation on a re-planning run: classify every task the feature generated, present each call with a one-line reason, and apply the approved plan and nothing beyond it. |
| `references/orphan-question.md` | The orphan question: when a free-form task is offered to a `[PLANNED]` feature, how the question is rendered, and what each answer does. |
| `references/amend.md` | Changing one existing task: the two checks before writing (not `[IN PROGRESS]`, and no change to what its feature promises), which body sections and summary-block fields may change, rewriting a `Preconditions:` edge, deleting a live task as `[SKIP]`, adding `Feature:` to an orphan, the single gate (a `confirmation` gate under the interaction policy), the closed write set and the closing report line. |
| `references/testing-policy.md` | The `Testing policy for /task-implement:` marker and its three values, and how a run establishes how the project's tests run — marker, project convention, inference, the no-test-suite branch — and which tests count as affected. |
| `references/test-runner.md` | The test-runner inference heuristics, read only when neither a marker nor a project convention names the test command. Mirrored in `/task-setup`'s TEST RUNNER INFERENCE. |
| `references/no-test-suite.md` | No-test-suite mode: the scaffold-or-skip question, and skip-tests mode with its `confirmation`-class "Proceed?" prompt. |
| `references/tests-first.md` | The tests-first sequence, Steps 2–5: update the tests, implement within the declared files, run the affected tests, run the full suite, and when a failing test stops the work. |
| `references/closing-report.md` | The closing report: its *For the record* and *Follow-ups* groups and their shapes, the empty-group form, and the numbering as the reply handle. |
| `references/parking.md` | Task parking under the `unattended` policy: the one event that parks, which prompts take their default instead — two of them `confirmation` gates that pass on their own — the `## Parking handoff` section, the `park/task-<N>` branch, the park sequence, the unpark transaction, the answerer rule and the two refusals. Read by `/task-implement` only when UNATTENDED is true or a resolved task is `[PARKED]`; never on an attended run that meets no parked task. |

Each file is the **single authority** for its rule. A consuming feature cites
the file and states only what it does differently.

---

## How to read a reference file

Every reference file but two was extracted **verbatim** from the feature
bodies that previously each carried their own copy of the rule. The
exceptions are `references/amend.md` and `references/parking.md`, authored
in the engine: no feature ever carried a copy of either, and each says so
itself. Where those copies said
the same thing in different words, the file carries the fuller statement
unchanged and records the other copies' material divergences as explicit
per-consumer notes. So a file reads as:

- the shared rule, in the words one of the consumers already used, and
- a `Per-consumer notes` section naming which feature departs from it and how.

A note attributed to a feature applies to that feature only. Wording that
names a phase or step (`PHASE 5`, `Step 7`, `WORKFLOW step 3`) is the
originating feature's own label and is kept as it stood.

**This `SKILL.md` carries no rule text.** It exists because `chosko-llm`
installs a skill folder, and a folder needs a versioned `SKILL.md` to be
installable at all. Every rule lives in a reference file; adding rule text
here would recreate the duplication the engine exists to remove.
