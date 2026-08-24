# Session: 2026-08-24 14:30

Work: none — cross-feature architecture session, five features authored
Running: /claude-council, then free-form architecture

Handoff for landing the ECC-import work as tasks. Everything below is either
already on disk or must be carried into a task body, because it exists nowhere
else.

## What we are building

Five features architected in this session, all indexed in `.claude/FEATURES.md`
as `[NEW]` with `Source: prompt` and `Tasks: none`:

| Feature | Doc |
|---|---|
| `session-continuity` | `.claude/domain/features/session-continuity.md` |
| `task-peer-review` | `.claude/domain/features/task-peer-review.md` |
| `task-implement-launcher` | `.claude/domain/features/task-implement-launcher.md` |
| `shared-phase-engine` | `.claude/domain/features/shared-phase-engine.md` |
| `repo-local-audits` | `.claude/domain/features/repo-local-audits.md` |

Plus one deletion that is not a feature and needs its own task: the dual-LLM
local-model lane.

## What worked (with evidence)

- An LLM Council run reached high confidence on rejecting wholesale ECC
  adoption. Report and transcript are in the repo root:
  `council-report-20260824-095720Z-q16686f3a.html` and
  `council-transcript-20260824-095720Z-q16686f3a.md`. Run logged in the council
  journal as sha `16686f3a`, outcome recorded.
- ECC surveyed directly via the GitHub API, ~30 files read at source. Verified:
  ECC ships **no** `FEATURES.md` / `PLAN.md` / `TASKS.md` schema and nothing
  equivalent to `.claude/context/` or `.claude/domain/` (grepped across its full
  4,751-path tree).
- The dual-LLM lane is confirmed dead: 109 `Target:` lines in this repo
  (108 `claude`, 1 `claude+human`, 0 local) plus 165 across factotum,
  job-hunter-cli and IsThisFreedom (0 local). ~274 authorings, 4 repos,
  110 days, never invoked.
- `.claude/external/` is present in all three downstream projects but inert —
  scaffolding `/task-setup` emits and nothing consumes.

## What did NOT work (and why)

- The council's "freeze chosko-llm feature work" recommendation was **rejected
  by the user and correctly so**: job-hunter-cli repeatedly requires chosko-llm
  features to be created or updated, so tooling work here is demand-driven, not
  self-referential. Do not let a future session resurrect the freeze idea from
  the council report — the outcome note in the journal records why it failed.
- Bash heredocs (`<< 'EOF'`) into the Bash tool were mangled twice in this
  session ("unexpected EOF while looking for matching `'`"). Use the Write and
  Edit tools for file content, per the global CLAUDE.md rule.

## What has NOT been tried yet

- No tasks authored. `/task-add` has not been run for any of the five features.
- No implementation of anything.
- `/production-plan` has not been run, so these five are not in any milestone.

## Current state of files

| File | Status | Notes |
|---|---|---|
| `.claude/domain/features/*.md` (5 new) | Complete | Uncommitted |
| `.claude/FEATURES.md` | Complete | 5 `[NEW]` entries appended; uncommitted |
| `.claude/domain/INDEX.md` | Complete | 5 rows appended; uncommitted |
| `council-*.html` / `council-*.md` | Complete | Untracked in repo root; move or delete |
| `skills/task-implement/SKILL.md` | Not started | Target of 3 separate changes |
| `scripts/cmd-task-impl.sh` | Not started | Dead-lane deletion target |

## Decisions made

- **Option (b) scoped hard**, not (a), (c) or (d). Import from ECC at leaf level
  only; never its loader, marketplace, hooks or always-loaded rule packs.
- **`--review`, not `--pr`** — the flag produces no PR in the uncommitted flow.
- **`--rounds N`, default 1.** At N=1 a plain single pass, no gating. From N≥2
  the severity gate (loop only while BLOCKING findings remain) and the round
  bound both apply.
- **Sticky rejections**: a finding rejected in round *k* may not be re-raised in
  *k+1*, only escalated with new evidence. This matters more than the counter.
- **Under `--review`, `/task-iterate` does not commit** — it hands the corrected
  tree to `/task-implement` Step 7 so a task still produces exactly one commit.
  Standalone `/task-iterate` does commit and push. This deliberately departs
  from the user's initial "commits either way"; the reason is the
  one-commit-per-task contract.
- **Session files are per-project**, `.claude/sessions/`, markdown not `.tmp`,
  and the save command detects a skill's resume artifact rather than skills
  declaring one.
- Discarded after review: config-gc, rules-distill (as a skill), inherit-legacy-
  style, update-codemaps, intent-driven-development, spec-miner, harness-audit,
  delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and all
  dimension-reviewer agents except `code-reviewer`. Do not re-propose these.
- `code-explorer` was discarded specifically because `.claude/context/` already
  is the maintained version of what it computes on the fly.
- The opus/sonnet/haiku model split per agent is interesting but deferred.

## Blockers and open questions

- **Subagent nesting depth** — batch mode with `--review` means launcher →
  implementor → reviewer. Being probed at the end of this session; see the
  answer recorded in the task body for `task-peer-review`.
- `.claude/PLAN.md` does not exist though `/production-plan` shipped, and
  `FEATURES.md` still shows four `[PLANNED]` features (product-roadmap,
  slice-aware-architecture, production-plan, plan-readout) whose tasks 106–115
  are all `[DONE]`. Reconciliation is `/production-plan`'s job, deliberately not
  done here.

## Exact next step

Run the `/task-add` prompts in `landing-prompts.md` beside this file, in the
order given.

## Environment and setup notes

- ECC read via `curl` against `https://raw.githubusercontent.com/affaan-m/ECC/main`
  and the GitHub contents API. No clone — the repo is ~47 MB.
- `jq` is on PATH at the WinGet location, needed by the council journal scripts.
