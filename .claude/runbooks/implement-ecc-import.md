# Runbook: implement-ecc-import

Created: 2026-08-24 · Source: manual · Model: opus
Sequencing: strictly ordered 1→32, one task per step. version-changelog (1–4) lands first so every later VERSION bump writes its CHANGELOG entry; the dual-LLM deletion (5) precedes everything that edits skills/task-implement/SKILL.md; session-continuity (6–8) and repo-local-audits (9–12) are independent of the rest and go next; then the launcher → peer-review → shared-phase-engine chain (13–25) in dependency order because all three features edit skills/task-implement/SKILL.md; 139 (26) needs the post-engine task-add; runbook-suite (27–32) needs `requires:` from 125.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [x] 1. Backfill CHANGELOG.md and land the versioning rule (task 146)

Depends on: none

Context: none

```prompt
/task-implement 146
```

Done: 2026-08-25 — commit 9477b1f (pushed). CHANGELOG.md created with 105 sections (0.1.0…0.62.2), rule + converse added to CLAUDE.md § Versioning and docs/authoring-guide.md; VERSION 0.62.1→0.62.2. Decisions: 0.53.0 dated 2026-08-07 (ee926e2) carrying 13e01c3 content; 0.52.1 claims shared claude-council commits; 0.59.0 records merge in one bullet; pure-backlog commits yield no bullets. No reference to scripts/check-changelog.sh anywhere yet (deliberately deferred to task 147). Premises held; nuance: 13e01c3 is on master first-parent, roadmap work is the side branch.

## [x] 2. Add the check-changelog.sh guard (task 147)

Depends on: 1

Context:
- 2026-08-25 (from step 1): CLAUDE.md § Versioning and the CHANGELOG.md preamble deliberately do not yet mention `scripts/check-changelog.sh`; task 147 should add that reference when it creates the guard. CHANGELOG.md has 105 sections, top section `0.62.2` = VERSION; strictly descending semver, no sub-headings, no shas.

```prompt
/task-implement 147
```
Done: 2026-08-25 — commit 47de381 (pushed). scripts/check-changelog.sh added (four invariants, numeric semver compare, silent on success, not a subcommand); authoring guide gained #### The guard under ### The changelog rule; CLAUDE.md § Versioning names the script (out-of-Files edit, on step 1's fact); VERSION 0.62.2→0.62.3. Premises: scripts/check-task-parity.sh is already red on this branch (unknown status tags [PLANNED]/[NEW]/[ITERATED] on the prompt side) independent of this task; running bin/chosko-llm trips the daily auto-upgrade hook (harmless, leaves gitignored .auto-upgrade-state). Orchestrator follow-up (user request, commit after 47de381): CHANGELOG.md preamble cut to one line, domain doc § 1 and authoring-guide section schema amended, VERSION 0.62.3→0.62.4.

## [x] 3. Print what changed on upgrade (task 148)

Depends on: 2

Context:
- 2026-08-25 (from steps 1–2): VERSION is now 0.62.4; CHANGELOG.md top section is `0.62.4` and its preamble is a single line (everything above the first `## ` is still preamble and never printed). scripts/check-changelog.sh exists — run it after the bump. Running bin/chosko-llm in the working repo trips the daily auto-upgrade hook (harmless).

```prompt
/task-implement 148
```
Done: 2026-08-25 — commit 2b28518 (pushed). lib.sh gained raw_version, src_changelog_path, print_changelog_range <old> <new> (return 0 = printed, 1 = nothing printed; single buffered awk pass; internal exit codes 10/11/12; cyan accent); resolve_version refactored onto raw_version; cmd-upgrade.sh prints the range after git pull and dumps git log --oneline only when the printer returns non-zero. VERSION 0.62.4→0.63.0. Premise correction: resolve_version is no longer byte-for-byte identical in one degenerate case — an empty/whitespace-only VERSION file now yields "unknown (sha)" instead of " (sha)"; accepted as the more correct answer. Verified against a throwaway clone in the scratchpad, never the real ~/.chosko-llm.

## [x] 4. Documentation for version-changelog (task 149)

Depends on: 3

Context:
- 2026-08-25 (orchestrator): .claude/domain/features/version-changelog.md § 1 was deliberately amended after the task body was written — the CHANGELOG.md preamble is one line, rules live in CLAUDE.md and the authoring guide. The body's "feature document is deliberately NOT changed" refers to task 149's own scope; do not revert that amendment. CLAUDE.md § Versioning already names scripts/check-changelog.sh (step 2).
- 2026-08-25 (from step 3): VERSION is now 0.63.0. lib.sh helpers landed as raw_version, src_changelog_path (in the src_*_path family) and print_changelog_range under a `# ---------- changelog ----------` section; the printer writes to stderr, returns 0 when it printed and 1 otherwise; cmd-upgrade.sh suppresses the git log dump exactly when the printer returned 0. Accent colour is cyan.

```prompt
/task-implement 149
```
Done: 2026-08-25 — commits 58192e4 (task 149) and e79f583 (feature version-changelog marked [DONE] in FEATURES.md, user-approved), both pushed. README (upgrade readout, versioning rule + guard pointer, repo-layout rows), docs/cli-help.txt, .claude/context/shared-lib.md (new Version and Changelog readout sections), .claude/context/cmd-upgrade.md, .claude/context/INDEX.md (CHANGELOG.md canonical doc, Last updated 2026-08-25). VERSION 0.63.0→0.63.1. Premises: README line hints off by a few lines; shared-lib.md had no existing version section (created one). Feature version-changelog fully shipped.

## [x] 5. Delete the dead dual-LLM lane (task 118)

Depends on: 4

Context:
- 2026-08-25 (from step 2): scripts/check-task-parity.sh is already red on this branch before any deletion — it reports [PLANNED], [NEW], [ITERATED] as unknown status tags on the prompt side. Not a regression to fix; relevant only if the task expects a green baseline.
- 2026-08-25 (from step 4): VERSION is now 0.63.1; every VERSION bump from here on writes its CHANGELOG.md section and runs scripts/check-changelog.sh. Subagents so far have used the repo's trailer-free commit style. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator step marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 118
```
Done: 2026-08-25 — commit dc4f951 (pushed). 36 files, +156/−1681. Deleted scripts/cmd-task-impl.sh, scripts/lib-task-external.sh, scripts/check-task-parity.sh, commands/task-enrich.md, .claude/context/cmd-task-impl.md, .claude/context/lib-task-external.md, .claude/external/{implement,tests}-prompt.md; task-impl subcommand removed from bin/chosko-llm, help, cli-help.txt; /task-add --enrich and enriched-body schema gone; Target: keeps exactly claude / claude+human / human; /task-setup reduced to TASKS.md + tasks/ + two wrappers (# CHOSKO_TASK_IMPL_STUB kept). VERSION 0.63.1→1.0.0; frontmatter: task-add 2.0.0, task-setup 2.0.0, task-implement 1.0.0 (skills/task-implement/SKILL.md), patch bumps on domain-setup, project-setup, unity-mcp-setup, architect. Extra decisions: design-process.md and technical-direction.md CI-guard examples repointed at check-changelog.sh; context INDEX Conventions marker now says eleven files. Premises: body said VERSION 0.62.0→1.0.0, actual start 0.63.1; skills/task-implement/body-schemas.md has no frontmatter (bump went on SKILL.md).

## [x] 6. Add the /session-save command (task 132)

Depends on: 5

Context:
- 2026-08-25 (from step 5): VERSION is now 1.0.0; skills/task-implement/SKILL.md is at 1.0.0, commands/task-add.md and task-setup at 2.0.0. The dual-LLM lane is gone (no cmd-task-impl.sh, lib-task-external.sh, check-task-parity.sh, task-enrich, --enrich, Target: local). Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 132
```
Done: 2026-08-25 — commit 722c4fd (pushed). commands/session-save.md at 0.1.0: writes .claude/sessions/YYYY-MM-DD-HHMM-<slug>.md, shared header (Work:/Running:), full form (nine sections) and pointer form (Resume from:), known-artifact table with the single /product-design → .claude/domain/design-process.md row (task body removed the /task-implement row; body is authority over the feature document), supersession delete, no commit/push, exactly one shell call (clock read for HHMM). VERSION 1.0.0→1.1.0. Premises held.

## [x] 7. Add the /session-resume command (task 133)

Depends on: 6

Context:
- 2026-08-25 (from step 6): VERSION is now 1.1.0. commands/session-save.md (0.1.0) landed with: shared header block (`# Session: …`, `Work:` four-value table with `none` first-class, `Running:`), full form = optional preamble + nine sections in the feature document's order, pointer form = header + `Resume from:` + one sentence; known-artifact table has ONE row (/product-design → .claude/domain/design-process.md) per task 132's Decisions; the command makes exactly one shell call (clock read). Read that file for the exact header shape /session-resume must parse. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 133
```
Done: 2026-08-25 — commit 890c3ef (pushed). commands/session-resume.md at 0.1.0: three argument forms (none / YYYY-MM-DD / path), candidacy by Work: line, pointer form followed via Resume from:, 14-day staleness flag, fixed-shape briefing ending with the deletion handover sentence, read-only (at most one clock read). VERSION 1.1.0→1.2.0. Decisions: CHANGELOG.md edited though not in Files: (rule landed after the body); unrecognized argument falls back to newest candidate, explicit missing path stops. Disclosure: the agent amended an unpushed commit (eb4af56) to fix a mangled subject line — no hook skipped, no force push. Note: ./bin/chosko-llm ls --available reads the managed clone unless CHOSKO_LLM_HOME points at the working tree.

## [x] 8. Documentation for session-continuity (task 134)

Depends on: 7

Context:
- 2026-08-25 (from steps 6–7): VERSION is now 1.2.0. commands/session-save.md and commands/session-resume.md both at 0.1.0. Known-artifact table has ONE row (/product-design → .claude/domain/design-process.md) per task 132's Decisions — the feature document lists two; the body is authority. /session-resume takes no task-number selector; deletion handover is a closing sentence naming the resumed file. Verify with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available (without the override it reads the managed clone). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 134
```
Done: 2026-08-25 — commits b5476b1 (task 134) and 2d6e3c7 (feature session-continuity [DONE], pre-approved), both pushed. README gained "Hand off a conversation — /session-save and /session-resume"; .claude/context/features.md gained two shipped entries; authoring guide cross-reference; feature document reconciled (seven authorized items + <date|path> signature; Open questions: none outstanding). VERSION 1.2.0→1.2.1. Premises held; CHANGELOG.md edited as collateral of the bump (not in Files:).

## [x] 9. Record the .claude/skills/ exemption in CLAUDE.md (task 135)

Depends on: 8

Context:
- 2026-08-25 (from steps 1–8): VERSION is now 1.2.1; every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:). CLAUDE.md § Versioning already carries the changelog rule and its converse (a change that does not bump VERSION gets no entry — repo-local .claude/ artifacts never bump VERSION); the exemption task 135 records must sit consistently beside that bullet. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 135
```
Done: 2026-08-25 — commit 66adc0b (pushed). CLAUDE.md § Versioning gained the narrow .claude/skills/ exemption bullet (repo-local dev tooling: no version: frontmatter, invisible to CLI verbs, never bumps VERSION; the rest of .claude/ — context, domain, backlog — bumps as usual). VERSION 1.2.1→1.2.2. Premise correction: the section had four bullets, not three (changelog bullet landed at step 1); its converse clause was surgically reworded to "artifacts exempt from the bump (next bullet) never get one" so it no longer contradicts the exemption. No .claude/skills/ created yet.

## [x] 10. Add the repo-local /context-budget audit skill (task 136)

Depends on: 9

Context:
- 2026-08-25 (from step 9): VERSION is now 1.2.2. CLAUDE.md § Versioning has the .claude/skills/ exemption: a change confined to .claude/skills/ does NOT bump VERSION and gets no CHANGELOG entry; anything else in .claude/ or the repo still bumps. Repo-local skills carry no version: frontmatter and no CLI verb sees them. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 136
```
Done: 2026-08-25 — commit f7f436b (pushed). .claude/skills/context-budget/SKILL.md created (first repo-local skill; frontmatter name/type/description, no version:), no VERSION bump, no CHANGELOG entry, per the exemption. Decisions: estimated saving = (lines − threshold) × (est. tokens ÷ lines); inventory find carries -size +0c (empty .gitkeep files divide by zero); description: extraction accumulates multi-line YAML plain scalars. Premises: line figures in the body are stale (task-setup now 351 lines, unflagged; production-plan/product-design/product-roadmap/architect now flag; task-add 834, task-implement SKILL 697); first-line-only description count undercounts.

## [x] 11. Add the repo-local /rule-overlap audit skill (task 137)

Depends on: 10

Context:
- 2026-08-25 (from step 10): VERSION is still 1.2.2 (repo-local skills bump nothing). .claude/skills/context-budget/SKILL.md exists — follow its frontmatter shape (name, type, description; no version:, with the one-line reason) and its register. Inventory tip from that skill: `find` needs `-size +0c` because skills/.gitkeep and skills/claude-council/journal/.gitkeep are empty; description: fields are multi-line YAML plain scalars, so accumulate continuation lines. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 137
```
Done: 2026-08-25 — commit 0c6a5d9 (pushed). .claude/skills/rule-overlap/SKILL.md created (no version:, no VERSION bump, no CHANGELOG entry). Deterministic grep/awk collection of headings + normative lines over commands/*.md, skills/**/*.md, claude-md/*.md; model judges sameness; threshold three or more features (features counted, not occurrences); disagreement ranked first; vendored skills, hooks/, statusline/, docs/, scripts/, bin/, .claude/ excluded; read-only. Verified: surfaces "Never retry, never force-push" at task-add.md:784, task-clean.md:270, task-implement/SKILL.md:532. Premises held.

## [x] 12. Documentation for repo-local-audits (task 138)

Depends on: 11

Context:
- 2026-08-25 (from steps 9–11): VERSION is 1.2.2 (task 135 bumped it; 136 and 137 bumped nothing per the exemption). Both repo-local skills exist: .claude/skills/context-budget/SKILL.md and .claude/skills/rule-overlap/SKILL.md, frontmatter name/type/description only. CLAUDE.md § Versioning holds the exemption bullet and a reworded converse clause ("artifacts exempt from the bump (next bullet) never get one"). Task 138's own doc changes DO bump VERSION (README, authoring guide, context/domain layers are not under .claude/skills/). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 138
```
Done: 2026-08-25 — commits 7e6ecb7 (task 138) and 4ffab0e (feature repo-local-audits [DONE], pre-approved), both pushed. README (exemption sentence, .claude/skills/ layout row), authoring guide (§ Versioning exemption, new "Repo-local skills are not features" section after § Vendored skills, frontmatter-schema preamble scoped to shipped features; § The changelog rule converse reworded to match CLAUDE.md), .claude/context/features.md overview note, feature document reconciled. VERSION 1.2.2→1.2.3. Premise: Files: omitted CHANGELOG.md (rule postdates the body). Verified cmd-export.sh does carry .claude/skills/.

## [x] 13. Turn /task-implement's batch parent into a launcher (task 119)

Depends on: 12

Context:
- 2026-08-25 (from step 5): skills/task-implement/SKILL.md is at 1.0.0 after task 118 removed the Target: local warning and the dual-LLM lane; skills/task-implement/body-schemas.md carries no frontmatter (the SKILL.md version covers the folder). check-task-parity.sh no longer exists.
- 2026-08-25 (from steps 6–12): VERSION is now 1.2.3. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:). Repo-local skills under .claude/skills/ (context-budget, rule-overlap) exist and are exempt from the bump. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 119
```
Done: 2026-08-25 — commit 03a1c2e (pushed). skills/task-implement/delegated-runs.md: launcher shape, "What the parent never reads" (parent opens no task body for a delegated task; claude+human / human / requested-[STALE] exception kept), fixed four-part agent prompt frame (task number + repo path, resolved flags, read-it-yourself instruction, return contract of exactly four values). SKILL.md: PRE-FLIGHT step 2/2b, PER-TASK preamble, DO NOT prohibition, description clause; skill 1.0.0→1.1.0. VERSION 1.2.3→1.3.0. Premise: body predicted VERSION 1.0.0→1.1.0; actual 1.2.3→1.3.0.

## [x] 14. Documentation for task-implement-launcher (task 120)

Depends on: 13

Context:
- 2026-08-25 (from step 13): VERSION is now 1.3.0; skills/task-implement/SKILL.md is 1.1.0. The launcher prompt frame carries the repo's absolute path in addition to the task number (deliberate, O(1) in batch size); the return contract is exactly four values. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 120
```
Done: 2026-08-25 — commits 4d2c8e5 (task 120) and db2e456 (feature task-implement-launcher [DONE], pre-approved), both pushed. .claude/context/features.md task-implement entry carries the launcher contract ("seven supporting files" corrected); .claude/domain/task-workflow.md "Delegated runs" updated; feature document's two authorised reconciliations applied, two open-question bullets resolved (grep reliability, next resolution path); the dirty-tree open question was left as-is though shipped behaviour settles it. .claude/context/INDEX.md not edited (Last updated already 2026-08-25). VERSION 1.3.0→1.3.1. Premises held.

## [x] 15. Add the /task-review skill (task 121)

Depends on: 14

Context:
- 2026-08-25 (from steps 13–14): VERSION is now 1.3.1; skills/task-implement/SKILL.md is 1.1.0 with seven supporting files, including delegated-runs.md (launcher shape: fixed four-part prompt frame, four-value return contract). Features version-changelog, session-continuity, repo-local-audits and task-implement-launcher are [DONE]. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 121
```
Done: 2026-08-25 — commit c75baa4 (pushed). skills/task-review/SKILL.md (0.1.0) + remote-diffs.md: task=/base= args, local mode inline, four-signal task resolution, four review gates (80% confidence floor, Pre-Report Gate, BLOCKING-requires-proof, zero-findings valid), three severity tiers, R<round>-<n> finding schema, per-criterion + overall verdicts, spawned-vs-manual output (opt-in .claude/reviews/<task>-R<round>.md), sticky rejections, read-only, no fan-out, no PR creation; SHELLING OUT constraint (read-only git/gh only). VERSION 1.3.1→1.4.0. Premise: body predicted 1.1.0→1.2.0.

## [x] 16. Add the /task-iterate skill (task 122)

Depends on: 15

Context:
- 2026-08-25 (from step 15): VERSION is now 1.4.0. skills/task-review/SKILL.md (0.1.0) landed with the R<round>-<n> finding schema, three severity tiers (unmet criterion always BLOCKING), per-criterion and overall verdicts, and the opt-in review file at .claude/reviews/<task>-R<round>.md — read it for the exact shapes /task-iterate must consume. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:); the body's predicted VERSION numbers are stale, follow the rule not the numbers. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 122
```
Done: 2026-08-25 — commit b48056a (pushed). skills/task-iterate/SKILL.md (0.1.0, no supporting file): mandatory fix/defer/reject triage table before the first edit, three input forms, three finding sources (caller output / .claude/reviews/<task>-R<n>.md highest round / PR threads), PR-mode replies, caller-dependent commit asymmetry, three-part return (triage summary, sticky rejection ledger, unresolved-BLOCKING yes/no). Flags: task=, base=, --no-commit, --no-push only. VERSION 1.4.0→1.5.0 (body predicted 1.2.0→1.3.0).

## [x] 17. Add the --review / --rounds loop to /task-implement (task 123)

Depends on: 16

Context:
- 2026-08-25 (from steps 13–16): VERSION is now 1.5.0; skills/task-implement/SKILL.md is 1.1.0 (launcher from task 119: fixed four-part prompt frame in delegated-runs.md, four-value return contract). skills/task-review (0.1.0: R<round>-<n> findings, three tiers, per-criterion + overall verdicts, opt-in .claude/reviews/<task>-R<round>.md) and skills/task-iterate (0.1.0: fix/defer/reject triage, three-part return with explicit unresolved-BLOCKING yes/no, flags task= base= --no-commit --no-push, caller asserts never infers) exist — read both for the exact contracts the --review loop drives. Depth note from the runbook-suite design: /task-implement --review spawning implementor then reviewer under an orchestrator is past verified nesting depth; state it, do not block on it. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh; the body's predicted VERSION numbers are stale, follow the rule. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 123
```
Done: 2026-08-25 — commit a4cb5d8 (pushed). New skills/task-implement/review-rounds.md (read only with --review: availability gate for task-review + task-iterate, placement after Step 5 / before Step 6 on the uncommitted tree, six-part reviewer spawn prompt, async-return rule, iterate in-session with mandatory do-not-commit assertion, N=1 vs N≥2 loop control, BLOCKING-only continuation, sticky rejections, cap-hit handling). SKILL.md 1.1.0→1.2.0 (--review / --rounds N parsing with two error messages, new section between Steps 5 and 6, Step 7 one-commit clause, five DO NOT bullets). delegated-runs.md: REVIEW/ROUNDS in the resolved-flag list + "Review rounds inside a delegated task" section (parent's four-field return unchanged). VERSION 1.5.0→1.6.0 (body predicted 1.3.0→1.4.0). Depth: launcher→implementor→reviewer verified; under an orchestrator it is one deeper, unprobed, no fallback added.

## [x] 18. Documentation for task-peer-review (task 124)

Depends on: 17

Context:
- 2026-08-25 (from steps 15–17): VERSION is now 1.6.0. Shipped: skills/task-review (0.1.0, SKILL.md + remote-diffs.md), skills/task-iterate (0.1.0, no supporting file), skills/task-implement 1.2.0 with EIGHT supporting files now (review-rounds.md added). --rounds requires --review; error strings are `--rounds requires --review.` and `--rounds needs a positive integer.`. Review file is opt-in at .claude/reviews/<task>-R<round>.md. Verify listings with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh; the body's predicted VERSION numbers are stale. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 124
```
Done: 2026-08-25 — commits 9f921bf (task 124) and ee98445 (feature task-peer-review [DONE], pre-approved), both pushed. README (/task-review, /task-iterate bullets; --review [--rounds N]; one-commit-per-task invariant), authoring guide commit groups, .claude/context/features.md (two new entries, task-implement entry with eight supporting files), .claude/domain/task-workflow.md new "## Review loop" section, feature document's four authorised reconciliations. VERSION 1.6.0→1.6.1. .claude/context/INDEX.md untouched (Last updated already current). Premises held.

## [x] 19. Add the `requires:` frontmatter field (task 125)

Depends on: 18

Context:
- 2026-08-25 (from steps 1–18): VERSION is now 1.6.1. Features [DONE] so far: version-changelog, session-continuity, repo-local-audits, task-implement-launcher, task-peer-review. Frontmatter fields currently parsed by lib.sh's parse_frontmatter are gated on a key allowlist (a finding from the hand-run that preceded this runbook) — verify the allowlist before assuming `requires:` will be emitted. Repo-local .claude/skills/ (context-budget, rule-overlap) carry no version: and must stay invisible to CLI verbs. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh; the body's predicted VERSION numbers are stale, follow the rule. Verify listings with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 125
```
Done: 2026-08-25 — commit 7a74267 (pushed). lib.sh: `requires` added to parse_frontmatter's allowlist; new requires_specs <file> (comma-split, validated via parse_replaces_spec, dies on malformed — call via command substitution, not process substitution; whitespace around commas AND around the kind colon squeezed). cmd-add.sh: install_requires resolves one level deep via add_one recursion, pre-copy validations hoisted ahead of the per-kind case; --all untouched. cmd-rm.sh: --force plus dependents scan that refuses removal naming every dependent (self-reference excluded). Authoring guide requires: section, cli-help.txt. VERSION 1.6.1→1.7.0. No shipped feature declares requires: yet. Confirmed: feature document's "parse_frontmatter needs no change" claim is wrong (allowlist at lib.sh:191) — task 131 reconciles it.

## [x] 20. Create the task-engine skill by verbatim extraction (task 126)

Depends on: 19

Context:
- 2026-08-25 (from steps 13–19): VERSION is now 1.7.0. skills/task-implement/SKILL.md is 1.2.0 with eight supporting files (delegated-runs.md carries the launcher; review-rounds.md the --review loop). `requires:` frontmatter is live: a comma-separated list of kind-prefixed specs (command:<n>, skill:<n>, …), resolved one level deep by cmd-add, guarded by cmd-rm's dependents scan; the shared-phase-engine feature document's claim that parse_frontmatter needed no change was wrong (task 131 reconciles it). Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh; the body's predicted VERSION numbers are stale, follow the rule. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 126
```
Done: 2026-08-25 — commit b15c297 (pushed). skills/task-engine/SKILL.md (0.1.0, no requires:, not user-invocable) + references/{resolution,status,targets,stale,tree,commit}.md, each opening with its extraction sources and closing with Per-consumer notes. VERSION 1.7.0→1.8.0. Decisions: commit.md keeps the literal citation "docs/authoring-guide.md's commit-and-push protocol" (verbatim from current bodies, with a note it is a citation not a runtime read; four push steps inline); commit.md already carries task 123's --review clause as a /task-implement-only note; targets.md lists three values and records commands/task-list.md:170's dead `local` residue for task 127 to fix. Environment: the INSTALLED ~/.claude copy of /task-implement is 0.18.0 (pre-118, still mentions Target: local) — subagents execute that stale copy; all extraction was done from repo sources.

## [x] 21. Migrate /task-list onto the task-engine (task 127)

Depends on: 20

Context:
- 2026-08-25 (from step 20): VERSION is now 1.8.0. skills/task-engine/ exists (0.1.0): SKILL.md is a reference-file map only; rules live in references/resolution.md, status.md, targets.md, stale.md, tree.md, commit.md, each with a Per-consumer notes section. targets.md records that commands/task-list.md:170 still says "Targets `claude` and `local` get no marker" — dead post-118 residue to remove during this migration. `requires: skill:task-engine` is the field to declare (task 125 made it live). Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh; the body's predicted VERSION numbers are stale. Verify listings with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 127
```
Done: 2026-08-25 — commit 8cef4a1 (pushed). commands/task-list.md 0.5.2→0.6.0 with requires: skill:task-engine; LOCATING THE BACKLOG and STATUS TAGS replaced by references to ${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md and status.md (PLAN.md probe kept as /task-list's own; status is a display filter); a third summary-block-parse copy in WORKFLOW step 1 also removed; dead `local` target removed. Output verified byte-identical before/after; cmd-add installs task-engine first. VERSION 1.8.0→1.8.1. Premises: body lands at 229 lines not <150 (the rest is /task-list-unique, protected verbatim); commit message says 227 (off by two, not amended); skills/task-engine/references/targets.md now carries a stale /task-list note ("awaiting its migration") — untouched, to be folded into a later engine edit.

## [x] 22. Migrate /task-clean onto the task-engine (task 128)

Depends on: 21

Context:
- 2026-08-25 (from steps 20–21): VERSION is now 1.8.1. skills/task-engine/ (0.1.0) references: resolution.md, status.md, targets.md, stale.md, tree.md, commit.md. /task-list migrated (0.6.0, requires: skill:task-engine, citation form ${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md). Known stale text: references/targets.md's /task-list per-consumer note still says the `local` mention is "dead text awaiting its migration" — task 127 removed it; if this task edits targets.md's notes anyway, correct that line (and bump task-engine's version: as the skill's own rule requires); if not, leave it for task 130/131. Line-count targets in the bodies are targets, not criteria — the criterion is zero copies of engine-owned rules. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. Verify with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 128
```
Done: 2026-08-25 — commit a33470b (pushed). commands/task-clean.md 0.7.0→0.8.0 with requires: skill:task-engine, 296→228 lines; cites resolution.md, status.md, stale.md, commit.md (not tree.md/targets.md — no dirty-tree protocol, no delegation). commit.md's /task-clean per-consumer note proved complete — task 126's extraction needed no fix. Dry-run plan identical before/after (44 removals, 10 Preconditions rewrites, 10 Tasks: rewrites). VERSION 1.8.1→1.8.2. Premises: 228 lines not <150 (plan template + PHASE 2 protected verbatim); Files: omitted CHANGELOG.md.

## [x] 23. Migrate /task-add onto the task-engine (task 129)

Depends on: 22

Context:
- 2026-08-25 (from steps 20–22): VERSION is now 1.8.2. /task-list (0.6.0) and /task-clean (0.8.0) are migrated, both with requires: skill:task-engine and citations in the form ${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md. Both landed at ~228 lines, not <150 — line counts are targets; the criterion is zero copies of engine-owned rules while consumer-unique content stays verbatim. commit.md's per-consumer notes have so far been complete for each consumer; check /task-add's note before restating anything. Known stale text in references/targets.md (/task-list note saying `local` is "awaiting its migration") — correct it only if this task edits the engine anyway, else leave for task 130/131. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. Verify with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 129
```
Done: 2026-08-25 — commit d123a45 (pushed). commands/task-add.md 2.0.0→2.1.0 with requires: skill:task-engine; cites resolution.md, status.md, targets.md, stale.md, commit.md (not tree.md). INDEX FILE FORMAT, manual-interventions authoring rules + Unity example, and RECONCILIATION's four-way table are cited not copied (they live verbatim in the engine, whose headers name /task-add as source). commit.md's /task-add note was complete. Every DO NOT bullet kept. VERSION 1.8.2→1.8.3. Premises: body is 731 lines not <400 (remaining content is /task-add-unique); the prescribed before/after throwaway /task-add run cannot execute unattended (Approve-and-write gate), replaced by phase-by-phase textual walk plus scratch-CLAUDE_HOME install check.

## [x] 24. Migrate /task-implement onto the task-engine (task 130)

Depends on: 23

Context:
- 2026-08-25 (from steps 13–23): VERSION is now 1.8.3. skills/task-implement/SKILL.md is 1.2.0 with eight supporting files (delegated-runs.md = launcher, review-rounds.md = --review loop, body-schemas.md has no frontmatter). /task-list 0.6.0, /task-clean 0.8.0, /task-add 2.1.0 are migrated: each declares requires: skill:task-engine and cites ${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md; consumer-unique content stays verbatim, engine-owned rules appear zero times; line-count targets were missed on every migration and treated as targets, not criteria. commit.md's per-consumer notes have been complete for every consumer so far and already carry the --review clause for /task-implement; tree.md exists for the dirty-tree protocol. Known stale text in references/targets.md (/task-list note saying `local` is "awaiting its migration") — task 127 removed it; correct that note if you edit the engine (bump task-engine's version: accordingly), otherwise flag it for task 131. Real before/after runs that hit approval gates cannot execute unattended — use a textual walk plus a scratch-CLAUDE_HOME install check. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 130
```
Done: 2026-08-25 — commit c8ed527 (pushed). skills/task-implement/SKILL.md 1.2.0→1.3.0 with requires: skill:task-engine, cites all six references, new "SHARED RULES (the task-engine)" section; skills/task-implement/dirty-tree.md DELETED (tree.md is its verbatim extraction) — seven supporting files remain; delegated-runs.md cites targets.md § The delegation guard; review-rounds.md points at commit.md and records why the --review availability gate is a runtime check, not requires:. VERSION 1.8.3→1.8.4. Scratch install verified: task-engine installed first; `chosko-llm rm skill:task-engine` refuses naming skill:task-implement. Premise: body is 709 lines not <350. Still open for task 131: references/targets.md's /task-list note ("awaiting its migration") is wrong since task 127.

## [x] 25. Documentation for shared-phase-engine (task 131)

Depends on: 24

Context:
- 2026-08-25 (from steps 19–24): VERSION is now 1.8.4. All four consumers are migrated: /task-list 0.6.0, /task-clean 0.8.0, /task-add 2.1.0, skills/task-implement 1.3.0 (now SEVEN supporting files — dirty-tree.md was deleted, tree.md replaced it). skills/task-engine is 0.1.0 with references/{resolution,status,targets,stale,tree,commit}.md. Two reconciliations the feature document needs beyond its own list: (1) the claim that parse_frontmatter needed no change is wrong — task 125 added `requires` to lib.sh's key allowlist; (2) every migration missed its line-count target (task-list 229, task-clean 228, task-add 731, task-implement 709) because consumer-unique content is protected verbatim — record targets as targets. Stale engine text to fix: references/targets.md's /task-list per-consumer note says the `local` mention is "dead text awaiting its migration" — task 127 removed it; correcting that note bumps task-engine's version: (patch). requires: is declared by all four consumers; cmd-rm refuses to remove task-engine while any dependent is installed. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 131
```
Done: 2026-08-25 — commits 47d7f6c (task 131) and 3c2d48e (feature shared-phase-engine [DONE], pre-approved), both pushed. README, authoring guide (council-gate rule qualified with skills/task-engine/ as the worked example; non-invocable reference-library skill shape), context layer (shared-lib.md, cmd-add.md, cmd-rm.md, features.md, INDEX.md), domain (task-workflow.md one-authority-per-rule section; feature document reconciled). skills/task-engine/references/targets.md stale /task-list note fixed, task-engine 0.1.0→0.1.1 (deliberate departure from the body's no-shipped-body criterion, on this runbook's instruction). VERSION 1.8.4→1.8.5. Premise corrections: parse_frontmatter allowlist has EIGHT keys (name, version, type, description, replaces, requires, event, matcher), not six; task-implement is 708 lines not 709; the open question about a non-invocable skill surfacing in skill selection was never observed — left open and marked explicitly unverified (task-engine has never been installed on this machine); features.md's task-implement entry corrected to seven supporting files.

## [ ] 26. Replace /task-add's ownership notice with a pre-authorisation gate (task 139)

Depends on: 25

Context:
- 2026-08-25 (from steps 19–25): VERSION is now 1.8.5. Feature shared-phase-engine is [DONE]: commands/task-add.md is 2.1.0 with requires: skill:task-engine, citing ${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/{resolution,status,targets,stale,commit}.md; engine-owned rules appear zero times in the body, consumer-unique content (draft templates, PHASE 3/4, feature mode) stays verbatim; the body is 731 lines. skills/task-engine is 0.1.1. Real before/after /task-add runs cannot execute unattended (Approve-and-write gate) — verify by textual walk. Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. Verify with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 139
```

## [ ] 27. Add the /runbook-run skill with its two references (task 140)

Depends on: 26

Context: none

```prompt
/task-implement 140
```

## [ ] 28. Add the /runbook-create command (task 141)

Depends on: 27

Context: none

```prompt
/task-implement 141
```

## [ ] 29. Add the /runbook-list command (task 142)

Depends on: 28

Context: none

```prompt
/task-implement 142
```

## [ ] 30. Add the /runbook-clean command (task 143)

Depends on: 29

Context: none

```prompt
/task-implement 143
```

## [ ] 31. Add the /runbook-suggest skill (task 144)

Depends on: 30

Context: none

```prompt
/task-implement 144
```

## [ ] 32. Documentation for runbook-suite (task 145)

Depends on: 31

Context: none

```prompt
/task-implement 145
```

## Do not re-propose

- Freezing chosko-llm feature work (a council recommendation, rejected: job-hunter-cli repeatedly requires chosko-llm features to be created or updated, so tooling work here is demand-driven).
- Any ECC feature assessed and discarded in the companion document: config-gc, rules-distill as a shipped skill, inherit-legacy-style, update-codemaps, intent-driven-development, spec-miner, harness-audit, delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and every ECC dimension-reviewer agent except `code-reviewer`.
- A PLAN.md, product roadmap or milestones for this repo (CLAUDE.md: it is tooling, not a product).
- Re-opening any decision recorded in a task body's Decisions section; the bodies are the authority.
