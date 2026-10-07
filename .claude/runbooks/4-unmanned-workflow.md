# Runbook: unmanned-workflow

Created: 2026-10-06 · Source: conversation (unmanned-workflow design) · Model: opus
Last step number: 21
Sequencing: All design and task authoring precedes all implementation; the rewrite runs last so its review compares against final behaviour.

## [x] 1. Merge master (with tasks 278–280 landed) into unmanned

Depends on: none

Context: none

```prompt
Work on branch `unmanned` of this repo (chosko-llm). It is an experimental branch cut from master; the user tests it as a deployed channel (`chosko-llm channel unmanned`).

Precondition: tasks 278, 279 and 280 must already be implemented on master. Run `git fetch origin master` and check `.claude/TASKS.md` as it is on `origin/master` (`git show origin/master:.claude/TASKS.md`): all three must be `[DONE]`. If any is not, stop and report which ones are missing — do not implement them here (this runbook lives on `unmanned`; running them here would land them on the wrong branch).

Then merge `origin/master` into `unmanned` with a merge commit (never rebase), resolve any conflict keeping both sides' intent, run `./scripts/check-changelog.sh`, `./scripts/check-home-paths.sh` and `./scripts/check-routing.sh`, and push `unmanned`.
```

Done: 2026-10-06, commit `eff9f9f` (25 files, +121/-110).

## [x] 2. Architect the interaction policy (A–D)

Depends on: 1

Needs: agent+human

Context: none

```prompt
/architect interaction-policy — a shared, opt-in interaction policy for every interactive chosko-llm feature: gates, output and questions.

This repo is tooling, not a product: it uses only `.claude/FEATURES.md` + `.claude/TASKS.md` (no PLAN.md, no roadmap). Ground the feature doc in the existing code. Everything below was settled with the user and exists nowhere on disk; carry it into the feature document.

Home and mechanism
- A new non-invocable skill `skills/interaction-engine/` holds these rules once (one rule, one place). Every interactive feature declares `requires: skill:interaction-engine` and cites it by relative path instead of restating it. It is NOT put inside pipeline-engine (rejected: pipeline-engine and task-engine each cover only part of the features).
- Policy line in a project's CLAUDE.md: `Interaction policy: attended|unattended`. Default is `attended` (absent line = attended), so existing projects are unaffected — the whole thing is opt-in.
- Every interactive skill and command accepts `--attended` / `--unattended` to override for one run.
- Precedence: flag > the runbook's own `Execution policy:` header (runbook-run only) > the CLAUDE.md line > attended. task-implement's existing `--unattended` and runbook-run's `--attended/--unattended` fold into this one rule.
- `Testing policy for /task-implement: …` (incl. `skip-tests-unattended`) stays independent of the interaction policy.

Gates under `unattended`
- Three classes:
  1. Confirmation-only gates pass on their own and print a short summary of what was written, naming the commit (git revert is the undo; each auto-passed write is its own commit). These are: task-add "Approve and write?", runbook-create's gate, every amend gate (architect, product-design, product-roadmap, production-plan, task-engine amend), pipeline-revise when it has no open questions, production-plan's main gate only when reconciliation found nothing, task-implement's feature DONE-flip proposal and its skip-tests "Proceed?", the context-build / context-update / context-convert STOPs, refactor-codebase / refactor-tests plan gates except HIGH-risk items, project-setup's final "Approve and run?", session-save's pointer prompt.
  2. Design-heavy gates always wait for the user even under unattended: product-design and architect, where the user confirms a conversational round. Any gate not listed in class 1 keeps waiting (e.g. product-roadmap's main gate).
  3. Destructive gates always wait under every policy: task-clean (incl. backfill), runbook-prune, runbook-clean, product-design discard, task-setup overwrite, any remote branch deletion.
- runbook-run's rule "never skip a gate the step's skill defines because it already knows the answer" (SKILL.md and references/inline-contract.md) gives way to class 1 under unattended.
- Real decisions are PARKED whenever the feature has a parking mechanism (tasks, runbook steps, objective runs). Where none exists, the run stops and ends its message with the question. The agent never picks an option on the user's behalf — no "trivial question" exception.

Output (applies to gate summaries and closing reports only, not read-only listings)
- No verbatim artifact previews at gates: no full drafts, no before → after diffs. Replace them with a concise plain-language summary: what changes, why, what it affects. The user can reply "show" to see the full draft. This covers pipeline-revise, every amend gate, runbook-run and task-implement question relays ("full draft verbatim and unabridged" rules go), task-add's manual-interventions block.
- Soft rule: about 8 lines for a gate summary, about 10 for a closing report. Break it only when really needed. SHAs, diffstats, file paths dropped unless they matter.
- pipeline-revise gate becomes: one verdict line, one plain sentence per change, then the questions. Owner-step table and headless/GATED tokens leave the chat; lint shows failures only; after an edit only the changed line is re-shown.
- Reply shortcuts (`all but N`, `P1: Q1a`, …) keep working but aren't printed every time; at most a one-line hint.

Questions
- A message that asks ends with the question(s). Nothing after them: no drafts, legends, grammar lists. Context goes above.
- Plain language first, IDs last in parentheses. Say exactly what wasn't done and why; spend words on meaning, not on task numbers, slugs or section anchors the user doesn't have in context. Example — bad: "task 42's acceptance criterion not met, update password-auth § Session to match?"; good: "The login task was supposed to log users out after 30 idle minutes, but the code only ends sessions when the browser closes, because the session library has no idle timer. Should I change the design to accept that, or keep the 30-minute rule and add a task for it? (task 42, password-auth)".
- Templates to rewrite to this rule: task-implement's feature-completion proposal, task-engine stale-task prompt, parked-question lines (task-engine and runbook-run parking), pipeline-check finding lines (message first; its "do not reword the template" rule changes), architect amend evidence lines, the one-line "Amended …" reports.
- A run collects its questions and asks them together when it stops.

Also in scope: this repo's own CLAUDE.md, the context layer and domain layer must describe the new policy. Out of scope until the experiment ships: README.md, docs/reference.md and other user-facing docs.
```

Done: 2026-10-06, commit `4dd2316` (4 files, +353/-1). Decision: output and question rules apply under both policies; only gate classes depend on the policy.

## [x] 3. Architect all remaining features in one sitting

Depends on: 2

Needs: agent+human

Context: none

```prompt
/architect unity-mcp-removal setup-sync session-readers quick-implement orchestrate-mode objective-run

Read `.claude/domain/features/interaction-policy.md` (written by the previous step) first: every feature here follows it (gates, parking, concise output, question-last, plain language). This repo uses only FEATURES.md + TASKS.md (no PLAN.md, no roadmap). Everything below was settled with the user and exists nowhere on disk; carry it into the feature documents.

1. unity-mcp-removal
- Delete `skills/unity-mcp-skill/` and `commands/unity-mcp-setup.md` (superseded by Unity's official MCP), the `Unity MCP for /task-implement:` CLAUDE.md marker and its consumers, and `skills/task-implement/unity-mcp-checkpoints.md`.
- Relocate the generic parts of unity-mcp-checkpoints.md into task-implement's human-in-the-loop instructions, written without naming any particular MCP: automatic vs manual choice, check the Console after a compile, wait out a domain reload, verify the outcome instead of trusting "looks done".
- Keep: project-setup's Unity detection (ProjectSettings/ProjectVersion.txt), the test-suite question, the Unity dirty-tree noise template, the Plastic SCM VCS mapping, targets.md's Unity worked example.
- No removal mechanism exists for installed copies: the CHANGELOG entry tells users to run `chosko-llm rm` for both and delete the old CLAUDE.md marker and `.claude/context/mcp-tools.md` from their projects.
- Update every reference: project-setup, task-implement, task-engine targets.md, context and domain files, the repo-local `.claude/skills/rule-overlap` and `context-budget`.

2. setup-sync (project-setup and siblings drifted from the features they set up)
- Fix: ask the testing policy on every project (not only Unity) and offer all three values (`skip-tests`, `full-tdd`, `skip-tests-unattended`) — task-setup's no-test-suite option must write the marker; offer the new `Interaction policy` line; add `git mv`, `git rm`, `git show`, `git branch` rows to the `## VCS` mapping template; add `Target:` to task-setup's index format; add the optional ` (<milestone-slug>)` to domain-setup's `Source:` line; offer the claude-md sections (doc-consolidate hard-stops without `editing-discipline`; also `git-commit-style`, `tool-usage-policy`) and the `remote-session-protocol` hook; warn that a `## VCS` section disables `--unattended`; suggest pipeline next steps (/product-design, /architect) in project-setup's final report; fix task-setup's dead "LOCATING THE TEST RUNNER" citation (now RESOLVING THE TEST RUNNER); remove project-setup's "it was a command before v0.46.0" history line; cite installed paths, not repo paths, for task-add.
- Recurrence guard: a new frontmatter key `project-policy:` on any feature that reads a per-project fact (CLAUDE.md line + allowed values, a claude-md section, a VCS op), and a guard `scripts/check-setup.sh` modelled on `check-routing.sh` (silent on success, non-zero naming each violation) that fails when a declared fact is not offered by its setup owner, a vcs op has no `## VCS` row, or a hook/claude-md feature is missing from setup's offer. The CLI frontmatter parser must tolerate the new key. Register the guard in CLAUDE.md beside the other guards.
- Replace the schema copies in task-setup (index and body format) and domain-setup (FEATURES entry) with citations of their owners.

3. session-readers
- New commands `/session-list` and `/session-describe`, modelled on runbook-list / runbook-describe. No session index exists; read header lines only (grep), never dump bodies.
- session-list: one line per handoff — date/time, slug, what it was about (`Work:`), first sentence of the next step; marks pointer-form files.
- session-describe: a short plain description of what the session is about, where it stopped, the very next step(s) and objectives, open blockers, and the orchestrate-mode area handoffs if any. Not a wall of text.
- Every session command that refers to a specific session (session-resume, session-describe) accepts a file path, a date, or a slug, like runbook-describe's argument resolution.

4. quick-implement (`/quick-implement`)
- A task-add-like spec conversation, then it implements right away instead of writing a backlog task. No TASKS.md entry.
- Drift check during the spec phase, with or without a feature doc: search the project's documentation with search commands (grep for the identifiers, files and terms the spec touches) to pinpoint the exact files and sections affected, then read only those parts. Drift with documented design is mentioned, never blocking.
- One gate before implementing, following the interaction policy.
- Implements with task-implement's sequence: dirty-tree check, testing policy, tests first, commit and push. `--review` / `--rounds` are opt-in, as in task-implement. One spec = one commit; if the spec is too big for one change it suggests /task-add instead of splitting.
- Never flips FEATURES.md statuses (the docs catch-up follow-up owns that).
- The spec is committed with the change under `.claude/specs/<date>-<slug>.md` and deleted, in the same commit, by the follow-up that brings documentation up to date; /pipeline-check reports leftover specs.
- Final report: which docs now lag the code, and proposed follow-ups — architect amendments or `/pipeline-revise --catch-up` (a new editorial catch-up mode that amends docs to match landed code). Breaks to design or already-implemented code are handled at follow-up time.
- Plumbing: move the checks inlined in task-add (design-change check, reconciliation, orphan question) and task-implement (testing policy resolution, tests-first sequence, closing report) into task-engine references so both features cite one copy; task-review and task-iterate gain a `spec=<path>` argument (today they need a task and would otherwise fall back to the most recently modified task); pipeline-revise gains the `--catch-up` mode; add a routing row (scripts/check-routing.sh).

5. orchestrate-mode (`/orchestrate-mode`, `/orchestrate-mode <notes>`, `/orchestrate-mode --off`) — imported from the user's workflow on another repo, generalised
- Conversation-scoped mode; confirm on/off in one line; a context summary carries "orchestrator mode: on". While on, every request for a code, asset or scene change is a batch, whatever its size; questions are answered inline from context files and earlier reports and spawn nothing; other commands run as usual (see Option 3 below).
- Orchestrator reads only CLAUDE.md, `.claude/context/INDEX.md` and the context files of the areas a request touches — no source files, no domain feature files, no agent transcripts, no session files. It never edits code, never drives an editor or other single-instance tool, never reads a transcript. It asks the user only when two readings of a note lead to different code.
- Split by file ownership: areas own disjoint files or named regions of a shared file (functions or #region), found from the context files; two notes needing the same region are one area in sequence; an ambiguous note goes to the user while the other areas launch.
- Handoff file per area at `.claude/sessions/<session-file-stem>/agent-<area>.md` (under `.claude/sessions/pending/` before the first /session-save, moved into the session folder once it exists). Read first, rewritten at the end of each task (supersede, no history), under ~120 lines, written for a zero-context reader: files and functions, constants and values, rules the owner set, rejected-by-owner list (always kept, never retried), the verification recipe that works, pitfalls. A retiring agent writes its handoff first; a missing or stale handoff is rebuilt from the owned code.
- Brief, in this order: read CLAUDE.md; the handoff path to read and rewrite; the owner's note verbatim; constraints from earlier owner decisions; what is off limits (other areas' files/regions, the single-instance tool unless this agent owns it); shared-file discipline (small exact-string Edits only, never Write over an existing file, never sed a whole file, on a failed Edit re-read and retry, stay inside the owned region); the project's own quick check; the report shape (a few lines: what changed, constants old → new, files and functions, anything guessed). The orchestrator relays the report's substance, never the transcript.
- Launch: independent areas in one message (parallel); shared-region areas serialised; at most one single-instance-tool owner per batch. The project-specific recipe for driving such a tool lives in the project, not in the command.
- After the batch: one quick check by the orchestrator, then a short report (soft rule) — outcome first, one bullet per area, decisions needed flagged. When iterations converge, ask once whether to iterate or check in.
- Check-in: one commit per area, one at a time, at the end (only the orchestrator stages and commits; parallel agents never touch git's index). A shared file rides with the area that changed it most. Then /session-save and move the handoffs into the session folder. Checking in on the user's word is a confirmation gate, so under unattended it passes on its own.
- Agent models: opus by default, fable only for genuinely hard work (brief says why); `--model` overrides.
- Failures table and NEVER list from the import stay (compile failure stops the batch; serialise same-region agents; refuse and surface permission requests an agent was denied; etc.).
- Removed from the import: all Unity/Neon Siege/FieldRenderer specifics, `compile-check.sh` (no script), any VCS discussion beyond "one commit per area", any /proto-sync reference (not replaced; follow-ups catch doc updates).
- Option 3 boundary with other commands: areas apply only to free-form requests and quick-implement's implementation step. Pipeline commands keep their own delegation; the mode switches it on by default (task-implement uses --agents even for one task; runbook-run unchanged). Conversations (task-add, architect, pipeline-revise, quick-implement's spec) run in one fresh subagent and the orchestrator relays its questions. Each command keeps its commit rule; quick-implement under the mode still makes one commit (areas don't commit separately). The "is the mode on?" check lives once in the interaction-engine.
- session-save and session-resume learn about handoff subfolders (save moves pending/ handoffs; resume and session-describe list the areas).

6. objective-run (`/objective-run "<objective>" [--max-time 2h] [--max-rounds N]`)
- First turns the objective into checkable success criteria (the only gate; passes on its own if the objective is already clear).
- Progress log at `.claude/objectives/<id>.md`, committed every round; resumable.
- Each round: a fresh worker subagent does one piece of work and commits; a fresh checker subagent marks each criterion met / not met with evidence.
- Stops when all criteria are met, when --max-time has passed (checked with `date` between rounds; a started round finishes), or after N rounds with no progress. Questions are parked.
- The log has a "Docs to update" section filled as changes land; the final report proposes them as follow-ups: architect amendments or editorial `/pipeline-revise --catch-up`.
- Under orchestrate-mode it does not split rounds into areas (it already delegates each round).
- Reuses runbook-run's subagent contract, parking, and the review-round loop shape.
```

Done: 2026-10-06, commits `769f344`, `b4df3f8` (10 files, +1135/-25). Also applied the editorial amend of interaction-policy flagged by the review of step 2.

## [x] 4. Task the interaction policy

Depends on: 2

Needs: agent+human

Context: none

```prompt
/task-add feature=interaction-policy
```

Done: 2026-10-06, commit `20db180` (9 files, +411/-3). Tasks 281–287; task 287 may edit five architect-owned feature docs, by the user-approved exception recorded in its Decisions.

## [x] 5. Rewrite pilot: measure cost on 4 files (scratch, no commit)

Depends on: 1

Needs: agent+human

Context:
- 2026-10-06 (orchestrator): this is a cloud session, so a step agent cannot spawn subagents and every child goes through the spawn relay (cap 8 per step). Batch by role: one relay child per role per round covering all four files (rewriter → reviewer → fixer → reviewer …), at most 3 rounds, so at most 6 relay rounds. A child cannot see its own token usage; the orchestrator records each relayed child's tokens and adds the totals to this step's Done: line — report everything else.

```prompt
A cost pilot for a later lossless rewrite of every shipped body (commands/, skills/*/SKILL.md, skills/*/*.md, skills/*/references/*.md, claude-md/ — about 102 files, ~196k words) into an imperative, bullet-style, protocol-first form. This step only measures; it writes nothing to the repo and commits nothing.

Measure cost from the token counts each subagent you spawn reports (sum them per file and in total); do not ask the user for /usage.

Files: commands/session-save.md, commands/session-resume.md, commands/runbook-list.md, commands/runbook-describe.md. Work in a scratch directory outside the repo.

Process per file, each role a fresh subagent:
1. Rewriter: imperative bullets, protocol and workflow first; frontmatter byte-identical; literal templates, commands and output strings verbatim; headings cited from other files kept exactly (grep for them first); relative paths unchanged; rationale dropped only when it doesn't change how a rule applies; a NEVER/DO NOT item that only restates the body is folded into the body and the list deleted. Writes the rewrite plus an inventory of every atomic instruction in the original mapped to its place in the rewrite.
2. Reviewer: independent (must not read the inventory), walks the original line by line, flags LOST / CHANGED / ADDED as BLOCKING and style as ADVISORY.
3. If BLOCKING findings: a fresh fixer, then a fresh reviewer. Minimum 1 round, maximum 3; stop at the first round with no BLOCKING finding.
4. Mechanical checks: frontmatter identical, cited headings present, fenced code blocks byte-identical.

A feasibility study in the design conversation found: session-save went 2487 → 1830 words in 2 rounds (each round caught something the previous one missed — subtle meaning shifts such as "X and Y" turned into a comma list, and a ban narrowed when a DO NOT list was folded); task-engine's parking.md gained only 5% (already dense). Expect dense files to gain little.

Report, and put in your Done: line: files done, words before → after per file, rounds per file, blocking findings per round, total subagent tokens spent, and the extrapolated cost for the remaining ~100 files. Do not re-litigate whether to rewrite; that is the next step's decision.
```

Done: 2026-10-06, no commit — measurement only. 4 files 8121 → 6635 words (−18%), 1 round each, 0 blocking findings; relay children 227,854 tokens (~57k per file). Extrapolated to the remaining ~100 files: ~5.3M tokens at 1 round, ~10.5M at 2, ~15.8M at 3; plan on 2 (a spelled-out implicit rule was rated advisory, a stricter reviewer would add a round).

## [x] 6. Decide whether to run the full rewrite

Depends on: 5

Needs: human

Context: none

```prompt
Show the user the pilot result recorded in step 5's Done: line (word reduction per file, rounds, tokens spent, extrapolated cost for the remaining ~100 files) in a few plain lines, then ask one question: run the full imperative rewrite at the end of this runbook (go), or skip it (no-go)? Record the answer verbatim in this step's report so step 20 can read it. Change no files.
```

Done: 2026-10-07, no commit — user answered: "Go" (run the full rewrite at step 20).

## [x] 9. Task the Unity MCP removal

Depends on: 3

Context: none

```prompt
/task-add feature=unity-mcp-removal
```

Done: 2026-10-07, commit `722395f` (5 files, +231/-3). Tasks 288–290; 289 also refreshes the tracked --local copies; 290 also edits docs/authoring-guide.md (authoring reference, not user-facing).

## [x] 10. Task setup sync

Depends on: 3

Context: none

```prompt
/task-add feature=setup-sync
```

Done: 2026-10-07, commit `8a90125` (6 files, +253/-3). Tasks 291–294; /task-setup's no-test-suite option asks skip-tests vs skip-tests-unattended.

## [x] 12. Task the session readers

Depends on: 3

Context: none

```prompt
/task-add feature=session-readers
```

Done: 2026-10-07, commit `dc96119` (6 files, +239/-3). Tasks 295–298.

## [x] 14. Task quick-implement

Depends on: 3

Context: none

```prompt
/task-add feature=quick-implement
```

Done: 2026-10-07, commit `f28f508` (9 files, +412/-3). Tasks 299–305; 300 also moves test-runner.md, no-test-suite.md and the testing-policy project-policy: declaration into task-engine (marker text unchanged).

## [x] 16. Task orchestrate-mode

Depends on: 3

Context: none

```prompt
/task-add feature=orchestrate-mode
```

Done: 2026-10-07, commit `49eb078` (6 files, +275/-3). Tasks 306–309; pipeline-suggest stays silent while the mode is on.

## [ ] 18. Task objective-run

Depends on: 3

Context: none

```prompt
/task-add feature=objective-run
```

## [ ] 7. Implement the interaction policy

Depends on: 4

Context: none

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `interaction-policy`, in backlog order, as one invocation: /task-implement <ids> --review --unattended
```

## [ ] 11. Implement the Unity removal, then setup sync

Depends on: 7, 9, 10

Context:
- 2026-10-06 (from step 3): this repo also keeps `--local` installed copies under `.claude/skills/` and `.claude/commands/` (incl. `task-implement/unity-mcp-checkpoints.md`); the removal must refresh those copies, not only the sources.
- 2026-10-06 (from step 3): under setup-sync the testing-policy line's `project-policy:` declaration goes on `/task-implement` (quick-implement's plumbing later moves the rule to `task-engine`).

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `unity-mcp-removal`, then every one whose `Feature:` line is `setup-sync`, in that order (setup-sync edits project-setup's Unity branch after the removal), as one invocation: /task-implement <ids> --review --unattended
```

## [ ] 13. Implement the session readers

Depends on: 7, 12

Context: none

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `session-readers`, in backlog order, as one invocation: /task-implement <ids> --review --unattended
```

## [ ] 15. Implement quick-implement

Depends on: 7, 14

Context: none

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `quick-implement`, in backlog order, as one invocation: /task-implement <ids> --review --unattended
```

## [ ] 17. Implement orchestrate-mode

Depends on: 13, 15, 16

Context: none

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `orchestrate-mode`, in backlog order, as one invocation: /task-implement <ids> --review --unattended

This goes after session-readers and quick-implement: orchestrate-mode extends session-save/resume/describe for handoff subfolders and delegates quick-implement's implementation step.
```

## [ ] 19. Implement objective-run

Depends on: 15, 18

Context: none

```prompt
Run /task-implement on every [MISSING] task in .claude/TASKS.md whose `Feature:` line is `objective-run`, in backlog order, as one invocation: /task-implement <ids> --review --unattended

This goes after quick-implement: objective-run's docs follow-ups use `/pipeline-revise --catch-up`, which quick-implement's tasks add.
```

## [ ] 20. Full imperative rewrite (only if step 6 said go)

Depends on: 6, 19

Context:
- 2026-10-07 (from step 6): the user answered "Go". Budget from step 5's pilot: plan on 2 rounds (~10.5M tokens); in the cloud each child goes through the spawn relay, so batch children by role per feature to stay under the relay cap of 8.

```prompt
Read step 6's report in this runbook (its Done: line / Context). If the user said no-go, report "skipped: no-go at step 6" and change nothing.

If go: the user approved, at step 6, running this as a multi-agent workflow (they explicitly opted into multi-agent orchestration for this rewrite). Rewrite every shipped body — commands/*.md, skills/*/SKILL.md, skills/*/*.md, skills/*/references/*.md, claude-md/*.md — into an imperative, bullet-style, protocol-first form with no instruction or constraint lost. Out of scope: README.md, docs/, .claude/context/, .claude/domain/, this repo's CLAUDE.md, repo-local .claude/skills/.

Process, one fresh agent per feature (a feature's files together), with the same rules and rounds step 5 used: rewriter (writes rewrite + instruction inventory) → independent reviewer that does not read the inventory (LOST / CHANGED / ADDED = BLOCKING) → fresh fixer → fresh reviewer; minimum 1 round, maximum 3; stop at the first round with no BLOCKING finding. Mechanical checks per file: frontmatter identical except the version bump, headings cited from other files present, fenced code blocks byte-identical, `./scripts/check-home-paths.sh` and `./scripts/check-routing.sh` pass. A file with no real gain keeps its original text.

Each feature lands as its own commit with a patch bump of its `version:` frontmatter; then one root VERSION patch bump with a CHANGELOG section ("Rewrite shipped bodies in imperative form; no behaviour change"); `./scripts/check-changelog.sh` passes. Record per-feature word counts before → after and rounds in your report.
```

## [ ] 21. Final consistency sweep

Depends on: 20

Context: none

```prompt
Run /pipeline-check and fix any finding it reports for the features this runbook added or changed (interaction-policy, unity-mcp-removal, setup-sync, session-readers, quick-implement, orchestrate-mode, objective-run). Then run /context-update. Then run `./scripts/check-changelog.sh`, `./scripts/check-home-paths.sh`, `./scripts/check-routing.sh` and `./scripts/check-setup.sh`; all must be silent. Report in a few lines what was fixed, if anything.
```

## Do not re-propose

- Unattended as the default behaviour — rejected: the interaction policy is opt-in, `attended` is the default so existing projects are unaffected.
- Putting the shared rules inside pipeline-engine — rejected: they live in a new `interaction-engine` skill.
- Auto-picking the recommended option for a real decision, even a "trivial" one — rejected: park whenever the feature can park; otherwise stop with the question last.
- Strict line limits on output — rejected: ~8 lines is a soft rule, broken only when really needed.
- A Stop hook (`objective-guard`) enforcing objective-run's time cap — rejected.
- `--for` as objective-run's time flag — rejected: it is `--max-time`.
- A compile-check / fast-check script for orchestrate-mode — rejected: no script; the project's own quick check is used.
- VCS discussion (git vs other VCS) in orchestrate-mode's check-in — rejected: only "one commit per area, one at a time, at the end".
- Any /proto-sync reference or doc-sync replacement in orchestrate-mode — rejected: follow-ups catch doc updates.
- Moving the Unity editor recipe into unity-mcp-skill, or keeping unity-mcp-skill / unity-mcp-setup — rejected: both are deleted (superseded by Unity's official MCP).
- Other names for quick-implement (/task-direct, /task-express, /task-now, /build, /fasttrack, /implement) — rejected: it is `/quick-implement`.
- Merging quick-implement and orchestrate-mode, or running every pipeline command through areas (Options 1 and 2) — rejected: Option 3, the mode changes only how work runs.
- Running the imperative rewrite before the behaviour changes, or mixing it into behaviour commits — rejected: it runs last, as separate commits, so the lossless review compares against fixed text.
- Editing README.md, docs/reference.md or other user-facing docs during the experiment — rejected: they are rewritten when everything ships.
- A prerelease version scheme on `unmanned` — rejected: follow CLAUDE.md's normal VERSION + CHANGELOG rule per change.
- Generating PLAN.md, product-roadmap.md or milestones for this repo — rejected: it is tooling and uses only FEATURES.md + TASKS.md.
