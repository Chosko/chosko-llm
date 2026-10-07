# Session: 2026-10-07 10:02

Work: document .claude/runbooks/4-unmanned-workflow.md
Running: /runbook-run unmanned-workflow (paused before step 20, by the user)

Cloud session that designed the opt-in unmanned workflow, wrote runbook 4 on branch `unmanned`, and ran it through step 19. The runbook body holds per-step state (`Done:` lines, `Context:` bullets); this file holds what the runbook does not.

## What we are building

An experimental, opt-in "unmanned" workflow for chosko-llm on branch `unmanned` (channel: `chosko-llm channel unmanned`): a shared interaction policy (`attended|unattended`, gate classes, concise summaries, plain-language questions asked last), Unity MCP removal, setup-sync, `/session-list` + `/session-describe`, `/quick-implement`, `/orchestrate-mode`, `/objective-run`, then a lossless imperative rewrite of every shipped body. Decisions live in the runbook's step 2 and step 3 prompts, its `## Do not re-propose` section, and the feature docs under `.claude/domain/features/`.

## What worked (with evidence)

- Runbook steps 1–19 all `[x]`; index `.claude/RUNBOOKS.md` shows `Status: [PENDING]`, `Steps: 18/20` (commit `2233b22`).
- Tasks 281–311 implemented, each with one review round; seven features flipped to `[DONE]` in FEATURES.md (commit `d88b9cf`).
- Post-run follow-ups fixed: quick-implement review findings routed to owning areas under orchestrate mode (`d6bd2ef`), duplicate testing-policy question (`fb29001`), park-else-stop paragraphs collapsed to gates.md citations (`88bcbca`), docs/reference.md fourteen findings (`824c27e`), flaky `check-setup.sh` SIGPIPE (`7ce6ea8`, 30/30 clean runs). VERSION is 1.97.4.
- Tasks 278–280 landed on master (`ac1beaf`, `329077b`, `a6e70d0`) and were merged into `unmanned` (`eff9f9f`).
- Rewrite pilot (step 5): 4 files 8121 → 6635 words, 1 round each, 0 blocking; ~57k tokens per file; extrapolation ~10.5M tokens for the rest at 2 rounds. User answered "Go" at step 6.

## What did not work (and why)

- In this cloud session a subagent cannot spawn subagents, so every reviewer went through runbook-run's spawn relay, capped at 8 per step. It fit steps 7–19 (≤7 tasks each, `--rounds 1`), but step 20's rewrite (~45 features × several fresh agents) cannot fit. That is why the user paused before step 20 to resume on a PC where nesting works.
- A first attempt to edit the runbook failed because a parallel subagent had switched the shared working tree to master; never run tree-touching agents in parallel on one checkout.

## What has not been tried yet

- Steps 20 (full imperative rewrite) and 21 (final consistency sweep).
- Testing the new features as a deployed channel on a real project.

## Current state of files

| File | Status | Notes |
| --- | --- | --- |
| .claude/runbooks/4-unmanned-workflow.md | In progress | Steps 20–21 `[ ]`; their `Context:` bullets carry the go decision, budget and local-copy refresh |
| .claude/RUNBOOKS.md | In progress | `[PENDING]`, 18/20 |
| .claude/skills/, .claude/commands/ (tracked --local copies) | Broken | Behind the sources; step 21 refreshes them |

## Decisions made

- Step 20 runs on the PC, not in the cloud — relay cap (see above).
- The orchestrator auto-approved design questions and trivial gates from settled decisions, per the user's instruction; real decisions went to the user (only step 6 did).
- Commit-trailer misses on a few pushed commits are discarded (user decision); never rewrite pushed history for them.
- README.md and user-facing docs stay untouched until the experiment ships (docs/reference.md got only the count fix the user asked for).

## Blockers and open questions

- None blocking. Step 21's Context notes a known redundancy now fixed (`fb29001`); it may report nothing for it.

## Exact next step

On the PC, on branch `unmanned` after `git pull`: run `/runbook-run unmanned-workflow` (it resumes at step 20).

## Environment and setup notes

- This repo sets no `Interaction policy:` line, so runs are `attended` unless a flag is passed.
- No managed clone existed in the cloud container; `./bin/chosko-llm ls --available` worked with `CHOSKO_LLM_HOME` pointed at the repo.
- Guards to run after shipped-body edits: `check-changelog.sh`, `check-home-paths.sh`, `check-routing.sh`, `check-setup.sh`.
