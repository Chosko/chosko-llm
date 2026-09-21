# Changelog

User-facing changes per root `VERSION`, highest version first. Rules and schema: `docs/authoring-guide.md` § Versioning.

## 1.66.4 — 2026-09-21

- **`/runbook-create`'s body is consolidated:** the same rules, stated once each. The runbook-argument errors, the name-collision rule and the already-taken target path are cited from the runbook schema and the body-migration reference instead of restated, the two backfill paragraphs are one, the `[RUNNING]`-never-migrated rule is stated once at the migration check, and the DO NOT list is gone — every bullet in it negated a sentence the body already carried, and the two rules that lived only there (never a branch or a tag; no git command under `--no-commit` bar the migration move) are now in PHASE 6. One stale statement is corrected: a nested runbook is refused for the orchestration it duplicates, not for the depth it costs, which is the reason `/runbook-run` already gives. Nothing about how the command behaves changed.

## 1.66.3 — 2026-09-21

- **`/task-implement`'s body is consolidated:** the same rules, stated once each. GOAL now points at the sections that own the failure, feature-completion and follow-up rules instead of restating them, the DOC_ONLY determination is stated where it is made rather than three times, the dirty-tree and body-read rules are left to the `task-engine` files that own them, and the DO NOT list keeps only the three prohibitions neither the body nor a file it cites already states. One stale statement is corrected: a delegated agent's return contract is six fields, so PRE-FLIGHT now cites the contract rather than naming a count that had drifted. Nothing about how the skill behaves changed.

## 1.66.2 — 2026-09-21

- **`/runbook-run`'s body is consolidated:** the same rules, stated once each. The five reference files are now one table saying when each is read, the `[~]`-is-never-committed rule is stated in COMMIT CADENCE and cited from the three places that repeated it, the `Done:` line's form and exclusions are cited from the runbook schema instead of restated, and the DO NOT list keeps only the two prohibitions the body does not already state. One disagreement inside the body is resolved: a nested runbook is refused for the orchestration it duplicates, not for the depth it costs, and that is the reason the refusal now gives. Nothing about how the skill behaves changed.

## 1.66.1 — 2026-09-21

- **`/task-add`'s body is consolidated:** the same rules, stated once each. The historical asides about what the free-form path used to do are gone, `--short`'s effects are stated in the phases they apply to rather than repeated in the argument note, the one-approval-gate rule is stated once, and the DO NOT list keeps only the three prohibitions the body does not already state. Nothing about how the command behaves changed.

## 1.66.0 — 2026-09-21

- **`/runbook-run`'s closing report has the two groups:** *Needs you* first — the feature completion candidates with their flip question, a failed step and its reason, a step left `[~]` to resume, the steps left outside the range or never started; then *For the record*, one line per step in the shape `<step n> — <outcome, commit sha and diffstat> — <what changed; decision or wrong premise flagged; questions relayed and their answers>`. Same at completion, at a `--to` / `--only` / `--steps` bound and at a failure halt; an empty group prints `none`.
- **Needs you items are numbered in every closing report** — `/runbook-run`'s, `/task-implement`'s and `/task-review`'s — so you answer by number. The numbering restarts at 1 in each report and a single item is still numbered.

## 1.65.2 — 2026-09-21

- **`/task-add`'s approval plan is a digest:** per task it shows the heading, `Target:`, the goal, the decisions when there are any, and `## Manual interventions` in full when the task needs you at the keyboard — plus one `Order:` line on a split and the `Placement:` line under `--before` / `--after`. The summary block's fields, the acceptance criteria and the hints are still authored in full and written to the files, and the report after the write names the ids, both paths and the counter advance.

## 1.65.1 — 2026-09-21

- **`/pipeline-revise` covers a roadmap item end to end:** the amend branch names a milestone's lines among what it applies to, walks from a milestone through its `Covers:` slices, and the merged sequence runs the roadmap step ahead of the feature documents.
- **A design-change question always waits:** a task amend whose draft adds a point diverging from a document another command owns is a GATED step in `/pipeline-revise`, and the task amend arm asks the question at its own gate whatever draft was passed in — an agreement is written only on an explicit answer.
- **`/doc-consolidate` requires the discipline installed:** on a project whose `CLAUDE.md` carries no `claude-md:editing-discipline` section it stops with the install command instead of running with no rules.
- Stale counts corrected: delegated agents return six fields, eleven features carry `disable-model-invocation`.

## 1.65.0 — 2026-09-21

- **`/pipeline-revise` takes a change set:** `/pipeline-revise "<change set>"` accepts free-form text describing several changes, or a pasted numbered list in `/follow-ups`' shape, with the old `<anchor> "<change>"` form still accepted for one item and a milestone nameable as an anchor. Each item is classified and walked; the items merge into one owner sequence — several sections of one feature document are one `/architect amend`, several documents one multi-slug run, every roadmap, plan or design edit one arm run — ordered upstream first. Every decision an owner's arm makes by a closed rule over its reads is made at plan time and shown on its step, tagged `headless`; a `/task-add` step is tagged `GATED` with one `Will ask:` line and sorts last. One plan gate, which always waits: `go`, `all but N`, `N as runbook step`, `N after M`, `stop`, and any edit re-renders the plan. What execution surfaces beyond the plan goes to one closing follow-up gate in the same shape, never written on its own. One commit at the end holds the whole revision, deferred-step runbooks included.
- **`/pipeline-patch` is retired.** Its single-owner case is a one-item change set, and everything that pointed at it — the lint catalogue's fix commands, `pipeline-suggest`'s routing, `/task-add`'s `--single` write-back line, the engine and reference bodies — now names `/pipeline-revise`. A machine that still has the command installed keeps a copy `chosko-llm` no longer ships; remove it with `chosko-llm rm command:pipeline-patch`.

## 1.64.0 — 2026-09-21

- **`/task-implement`'s closing report has two groups:** *Needs you* first, every item waiting on a decision at whatever length it needs; then *For the record*, one line per item in the fixed shape `<what deviated> — <why> — <resolved by whom>` — a criterion overshot and accepted by the reviewer, a wrong premise in a body, a consequential edit outside the task's files. Nothing in the second group is a question. `/task-review`'s report closes the same way.
- **Consequential edits are in scope:** a passage that an approved change made stale is updated by the implementer in whatever file owns it, in the task's commit, and reported in one line — never asked about, never left as a follow-up, never knowingly wrong. New meaning in an owned document stays untouched and is named as a precise follow-up (`/architect amend feature=<slug> "…"`).
- **`/task-review` flags an untraceable documentation edit:** an edit that introduces a decision the task never approved — not a criterion, not an agreed design change in its Decisions, not a consequential edit — is an `IMPORTANT` finding naming the sentence. Ownership guards decisions, never consistency; this check-after is what replaces asking before.

## 1.63.0 — 2026-09-21

- **New `/doc-consolidate`:** rewrites a rules document — a command or skill body, a feature document, a context file, a `CLAUDE.md` — or every document under a folder, under `claude-md:editing-discipline`, keeping every rule it stated. It shows a per-section ledger of only what it drops or merges (a superseded sentence beside its replacement, historical sentences under a count, duplicates with the surviving copy's location), gates per section or once per file, and then has a fresh-context verifier that sees only the old and new text list every rule the rewrite lost; the run ends only when that list is restored or accepted. On a folder it resolves a rule stated in several files to one owner cited from the rest. Meaning-preserving, never a style compressor; frontmatter, body headers and schema sections stay in place; line counts are reported as an observation, never a target. Uncommitted by default, `--commit` to commit and push.

## 1.62.0 — 2026-09-21

- **Three owners gain a direct amend arm:** `/product-roadmap amend "<change>"` edits named milestone lines (`Goal:`, `Exit criteria:`, `Rationale:`, `Covers:`, the `Strategy:` paragraph, `Not now`) behind one before → after gate and refuses a change it cannot pin; `/production-plan amend "<change>"` reconciles `PLAN.md` for the features, edges or milestones the change names and nothing else, with the cycle and later-milestone refusals intact; `/product-design amend "<change>"` reaches the finished design's amend arm directly, without the resume menu, and compresses `design-process.md` as before.
- **Every arm is headless-capable:** a revision surface that drafted the edit at plan time passes it in, and the arm writes without a second gate when its own draft matches, showing the difference as its gate when it does not. `/pipeline-revise` routes its design, roadmap and plan steps through these arms.

## 1.61.0 — 2026-09-21

- **`/architect amend` takes several features at once:** `amend feature=<slug>,<slug>,... "<change>"` scopes the change and runs the precision guard per feature, renders one gate with a section per feature, drafts the `product-design.md` upstream edit once, drops a feature whose touched task is `[IN PROGRESS]` while the rest proceed, and makes one commit.
- **A body read now classifies:** a task whose summary block could not decide its touched status, and whose body then did, is a clear case like any other; the arm asks only when the body still cannot decide, when the scope call is borderline, or when the findings point different ways.
- **No second gate under `/pipeline-revise`:** when the classification carried from the revise gate disagrees with the arm's own findings, the stricter one applies — not editorial over editorial — with no prompt, and the closing line names the deviation. The confirmation form is gone.

## 1.60.0 — 2026-09-21

- **`/task-add` asks about the design, not about file permissions:** the Grant / Reference / Drop question is gone. For a drafted task that names a document another pipeline command owns, the command now lists where the task *settles* something the document leaves open (for the record, unasked) and where it *diverges* from what the document states, and asks once, inside the approval gate, whether you agree to that design change. Agreement covers every passage stating the old design and is recorded dated in the body; disagreement sends the task back to drafting questions. A document is never kept wrong on purpose.
- **The read-only marker is gone:** `— read-only reference, do not edit` is no longer written, and `/task-implement` and the task amend arm no longer key on it. An implementer edits an owned document for the agreed design change and for nothing else, and stops to say so when it meets a further design decision.

## 1.59.0 — 2026-09-21

- **New `claude-md:editing-discipline`:** nine rules for editing a rules document — a CLAUDE.md, a command or skill body, a feature document, a context file. Supersede the old sentence instead of appending beside it, keep history out of the body, state the rule rather than the decision, one rule in one place cited everywhere else, clearer wording over more adjectives, no DO NOT bullet that negates a sentence the body already carries, rewrite the section rather than the sentence, merge overlapping sentences before finishing, and carry a change's consequences into every passage it makes stale whoever owns the file. Install it with `chosko-llm add claude-md:editing-discipline` (or `--local` for one project).
- **`/task-review` reports stratification:** in a diff that edits a rules document, history in the body, a duplicate statement, or an old sentence left beside its replacement is now an `IMPORTANT` finding citing the lines. A diff's size is never a finding.

## 1.58.6 — 2026-09-21

- **A run nobody is watching no longer asks whether to flip a feature to `[DONE]`:** under `/task-implement --agents` a delegated agent, and under `/runbook-run` a step's subagent, now name any feature whose tasks are all `[DONE]`/`[SKIP]` in their report instead of proposing the flip themselves. Previously the agent treated its one task as the whole run and reached the proposal, and a runbook step's subagent relayed it as a `QUESTIONS FOR USER` block that blocked the run mid-step.
- **The outermost run proposes instead:** the `--agents` launcher asks at the end of the batch exactly as it always did, and `/runbook-run`'s closing report — at completion, at a `--to` / `--only` / `--steps` bound and at a failure halt alike — now ends with a `Feature completion candidates:` block and one question, asked once before the `/follow-ups` call and printed not at all when there are no candidates. The orchestrator still never writes `FEATURES.md`.

## 1.58.5 — 2026-09-21

- **A relay child now gets a fixed contract of its own:** `/runbook-run`'s subagent contract carries a second pasted block, `RELAY CHILD RULES`, sent verbatim ahead of `OPERATING RULES` to every child the spawn relay spawns. It tells the child to write its full report to the result file, check that file exists and is non-empty, keep the report out of its returned turn, and end with the literal `DONE` plus one line. Previously those obligations were prose the orchestrator re-worded per spawn, and children were observed returning the report in the turn with no file written, or writing the file but omitting `DONE`.
- **The orchestrator checks the result file exists before replying to the caller:** on a `DONE` child, an absent or empty result file re-prompts that same child once with a fixed line, and a second miss fails the step with the missing path named in the `Done:` line. The re-prompt is not a relay round and does not count against the eight-round cap, and an existence check is still not opening the file.

## 1.58.4 — 2026-09-21

- **`/runbook-run` is quiet between steps:** it now prints one line per step at that step's end — `Step 4 done (abc1234). Starting step 5.`, or the failure line — and no longer narrates spawning, waiting, classifying a result, writing the `Done:` line or committing. Relayed `QUESTIONS FOR USER` blocks and the spawn relay's lines still come through verbatim, so a run that needs an answer still asks for it at once. The same holds under `--inline`.
- **The closing report is now the record of the run:** short but exhaustive, one entry per step — outcome, commit sha and diffstat, what changed in one line, any decision or wrong premise the agent flagged, and any question relayed with its answer — followed by whatever remains outside the range. It reads that way at completion, at a `--to` / `--only` / `--steps` bound and at a failure halt alike, and is built from the `Done:` lines and step reports already in hand: the orchestrator opens no file it did not open before.

## 1.58.3 — 2026-09-20

- **`chosko-llm help` describes what `show` prints since 1.58.0:** the `show <feature>` entry now says the command prints the body's leading `#` header — the `# /name` / `# Usage:` block that carries the flags — and that `--content` prints the full body in its place. The command itself is unchanged; only its help text had lagged.

## 1.58.2 — 2026-09-20

- **The remaining eighteen descriptions rewritten to the description contract** (`runbook-create`, `runbook-list`, `runbook-describe`, `runbook-clean`, `runbook-prune`, `runbook-run`, `session-save`, `session-resume`, `context-build`, `context-update`, `context-convert`, `refactor-codebase`, `refactor-tests`, `project-setup`, `unity-mcp-setup`, `unity-mcp-skill`, `claude-council`, `runbook-suggest`): each now says what the feature does and when to use it in at most 60 words; `claude-council` and `runbook-suggest` keep their trigger phrases first and their "Not for" list last. `runbook-run`'s description drops from 4,384 characters to 253, and every one of its flags now lives in its `#` header.
- Every flag, refusal, read-only contract and commit default a description no longer carries sits in that body's leading `#` header, which `chosko-llm show` prints and which loads only when the feature is invoked. Behaviour is unchanged.
- **Seven one-shot wizards and housekeeping commands carry `disable-model-invocation: true`** — `/project-setup`, `/unity-mcp-setup`, `/task-setup`, `/runbook-prune`, `/runbook-clean`, `/refactor-codebase`, `/refactor-tests`. None is useful to suggest unprompted, each is reachable by typing its name, and their descriptions leave the model's context entirely.
- **`unity-mcp-skill` carries a `paths:` filter** (`Assets/**`, `ProjectSettings/**`, `Packages/**`), so it loads only in a Unity project.
- The rendered skill list — the `- name: description` lines Claude Code injects at session start, summed over every command and skill — drops from 45,105 characters at v1.57.4 (25,566 after 1.58.1) to 13,035 on disk, of which the model receives 9,977: the ten hidden features' lines are never rendered.
- This repo's own local install under `.claude/commands/` and `.claude/skills/` is refreshed from the working tree for every feature it already held, so sessions on this repo see the 1.58.1 and 1.58.2 descriptions.

## 1.58.1 — 2026-09-20

- **Twenty pipeline-core descriptions rewritten to the description contract** (`task-add`, `task-list`, `task-setup`, `task-clean`, `task-implement`, `task-review`, `task-iterate`, `follow-ups`, `production-status`, `pipeline-check`, `pipeline-patch`, `pipeline-revise`, `pipeline-suggest`, `domain-setup`, `product-design`, `product-roadmap`, `architect`, `production-plan`, `task-engine`, `pipeline-engine`): each now says what the feature does and when to use it in at most 60 words, `pipeline-suggest` keeps its trigger phrases first and its "Not for" list last. Together they drop from ~22,000 to ~6,000 characters of system-prompt text per session.
- Every flag, refusal, read-only contract and commit default a description no longer carries now sits in that body's leading `#` header, which `chosko-llm show` prints and which loads only when the feature is invoked. Behaviour is unchanged.
- Each stage feature names its place in the pipeline in exactly one clause ("stage 3 of the pipeline: turns a design section into feature documents; its output is /task-add's input"); the "sits between X and Y" prose that six descriptions repeated is gone.
- **`task-engine`, `pipeline-engine` and `/domain-setup` carry `disable-model-invocation: true`.** The two reference libraries are read by path and never invoked, and the scaffold is always started by hand, so their descriptions leave the model's context entirely; all three stay listed and typeable. `task-review` and `task-iterate` stay model-invocable, since `/task-implement --review` spawns them by name.

## 1.58.0 — 2026-09-20

- **`chosko-llm show`** prints the body's leading `#` header — the `# /name` / `# Usage:` block that carries a feature's flags and contracts — under the description in every view; `--content` still prints the full body instead, and a body with no header prints nothing extra.
- **`/runbook-clean`** no longer carries a literal ` --- ` in its description, which Claude Code truncated the description at — the model saw 145 of its 1,111 characters.
- **`task-engine`, `pipeline-engine`, `claude-council`, `unity-mcp-skill`** open with a `#` header like every other shipped body — a two-line "read by path; not invoked" note for the two reference libraries.

## 1.57.4 — 2026-09-20

- `scripts/check-home-paths.sh` now catches every spelling of an install home, not only the three literals it was written against. `$CLAUDE_HOME/skills/…`, `${CLAUDE_HOME}/…`, `${HOME}/.claude/…` and `"$HOME"/.claude/…` all passed it silently before; the bare `$CLAUDE_HOME` form is the one an author is most likely to write.
- The citation form is stated as depth rather than by role: count directories from the citing file up to the install home, then down. A supporting file at a skill's root takes `../<other>/…`, the same as its `SKILL.md`; only a file under `references/` takes `../../<other>/…`. Seven shipped files already did this; the four-form table said otherwise.
- `routing.md`'s Amend column names each owner's amend file by a path relative to that table, so a revision surface following the column resolves it.
- The three `bash` blocks in `claude-council` each set `SKILL_DIR` themselves. Shell variables do not survive between blocks, so Steps 2 and 10 previously ran with it unset and the journal entry was never written.

## 1.57.3 — 2026-09-20

- Trimmed the prose in the bodies 1.57.2 touched: the two `council-gate.md` copies, `probes.md` and `pipeline-engine`'s `SKILL.md` now state the rule without narrating how it was arrived at. Behaviour is unchanged; the four bodies are 24 lines shorter than before 1.57.2, and a shipped body's prose is loaded into every run that reads it.

## 1.57.2 — 2026-09-20

- **Fixed two defects in 1.57.1, both of the kind that fail silently.** The probe took the `routing.md` row list from whichever install home it found first while counting features across both, so a stale copy in one home dropped a feature out of the count, out of `missing:` and out of the denominator at once — the verdict line read as complete while omitting it. Row names are now unioned across both homes.
- The claude-council gate in `/architect` and `/product-design` **asks for the skill by name** rather than by any path. A relative path found the council only when it was installed into the same home as the gate's own skill; an absolute one picked a scope and missed the other. Both failures were invisible, because the gate is built to say nothing when the council is absent — so a wrong "absent" looked exactly like a right one and the user never learned their installed skill was skipped. A name has no scope to get wrong. This is the rule `/follow-ups` already followed.
- Because of that, `scripts/check-home-paths.sh` has no exemption mechanism at all. Nothing needs one: asking whether an optional feature is installed is a question you answer with a name.
- `installed=` reports `unknown` when neither home holds a routing table, rather than `0/0` — which read as "nothing to install". `CLAUDE_HOME` relocates the user scope and no longer suppresses the project scope; the probe's feature test is `-f` again, not `-e`; and a change of working directory now invalidates a cached verdict, since `installed=` and `council=` answer for the directory they ran in.

## 1.57.1 — 2026-09-20

- **The pipeline probe now answers for both install scopes.** `installed=` and `council=` derived a single install home and always landed on `~/.claude`, so on a project that ran `chosko-llm add --local` every pipeline feature was reported missing — from a shell standing one directory above the install that held them. In this repo the old probe printed `installed=0/0`; it now prints the features it actually finds. An explicit `CLAUDE_HOME` still wins and is then the only home checked.
- The claude-council detection gate in `/architect` and `/product-design` asks for the skill **by name** rather than by a path, for the same reason. It previously looked only beside itself, so a council installed globally next to a `--local` skill read as absent — and this gate is built to no-op silently when the council is absent, which made a wrong answer invisible.
- `scripts/check-home-paths.sh` has no exemptions: asking whether an optional feature is *installed* is answered with a name, so no shipped body needs an absolute path for it.

## 1.57.0 — 2026-09-19

- **Every shipped body now cites another shipped file by a path relative to itself**, replacing all 134 absolute-home citations across 37 commands and skills. The old form — `${CLAUDE_HOME:-$HOME/.claude}/skills/<name>/…` — never resolved for a `--local` install: `chosko-llm add --local` repoints `CLAUDE_HOME` to `$PWD/.claude` for the duration of the install, but the executing agent expands the variable itself at read time and always lands on the global home. A project that installed the `task-*`, `runbook-*` or `pipeline-*` suites locally was therefore reading a different copy of every reference file, or none at all — and it failed silently, because a missing file is a legitimate skip.
- The form follows from depth — count directories up to the install home, then down: `./<file>.md` within one skill, `../<other>/…` from a file at a skill's root, `../../<other>/…` from a file under a skill's `references/`, and `../skills/<other>/…` from a command. They are correct by construction in both scopes — `--local` repoints the whole home and `cmd-add` installs `requires:` dependencies into that same home, so citing body and cited file are always siblings under one root.
- The `CLAUDE_HOME` override is unchanged: it still governs where `install.sh` and every `scripts/cmd-*.sh` verb writes. Only shipped bodies stopped trying to re-derive it at read time. The install-path notes in `task-engine`, `runbook-run`, `pipeline-engine` and the vendored `claude-council` now say so.
- The vendored `claude-council` skill's three `bash` invocations now go through a `SKILL_DIR` its install-path note defines, because those lines run from the project root and so cannot use a path relative to the skill body. Its journal and scripts are unchanged.
- Every affected command and skill takes a patch `version:` bump, so `chosko-llm update --all` actually delivers this fix to an existing install rather than reporting it already up-to-date.
- **New authoring-time guard, `scripts/check-home-paths.sh`.** Silent on success, non-zero naming each body that cites another shipped file by an absolute install home. Repo-local like `check-changelog.sh` and `check-routing.sh` — not a feature, installed nowhere, run by hand; `CLAUDE.md` § Versioning says when.

## 1.56.3 — 2026-09-19

- Fixed a scope bug in 1.56.2: the `--agents` hand-off prompt told the delegated agent to read `${CLAUDE_HOME:-$HOME/.claude}/commands/follow-ups.md`, a path that only ever resolves to the **global** install. `chosko-llm add --local` repoints `CLAUDE_HOME` to `$PWD/.claude` at install time, so a project that installed `/follow-ups` locally would have had every delegated agent find nothing there and report no follow-ups — silently, since a missing file is a legitimate skip.
- The agent is now given the command's **name and never a path**, which resolves in either scope, and the reason is recorded beside it so the path does not come back. `/task-implement`'s DO NOT list names the command's own body, rather than a repo path, as the single authority for what counts as a follow-up.

## 1.56.2 — 2026-09-19

- Under `--agents`, a delegated agent now **reads `/follow-ups`' rules rather than invoking the command** to populate the fifth return field. It opens `commands/follow-ups.md` at its installed path and applies what is there to its own session, keeping at most three items. The rules stay stated once, in that file, exactly as in 1.56.1 — only the mechanism changed.
- Two things this buys. The rule that `/follow-ups` fires **once per run, never per task** is whole again: nothing invokes the command but the run's own closing call, so 1.56.1's carve-out in the DO NOT list is gone and the bullet is a flat prohibition once more. And the field now degrades where an invocation would not — a user who removed the command by hand leaves the agent with nothing to read, and it skips the field silently, the same rule the closing call already follows. A missing optional input never fails a task.

## 1.56.1 — 2026-09-19

- The `--agents` return contract's fifth field is now **`/follow-ups`' output** rather than a bespoke format. Each delegated agent runs the command on its own session — which for a delegated agent is exactly the one task — and returns its list, capped at three items. 1.56.0 had restated the command's reading rule, its exclusion rule and its item format inside the contract; those are now stated once, in `commands/follow-ups.md`, and cited from the contract. A second copy is a copy that would drift.
- Only two bounds remain the channel's own, and they are named as such: the cap of three, which protects the parent's context rather than redefining a follow-up, and omission when the list is empty. The `--review` carve-out also got shorter — no rule is needed to keep findings out of the field, because the command's own exclusion rule already does.
- `/task-implement`'s DO NOT list now draws the line explicitly: a delegated agent running `/follow-ups` on its own session is **not** the run's closing call, which is still once per run in the parent, after the closing report. It produces one of that call's inputs, in a session the parent never sees, and emits nothing to the user. A second bullet forbids restating what counts as a follow-up anywhere in the skill.

## 1.56.0 — 2026-09-19

- **/task-implement --agents**: the per-agent return contract gains a fifth, optional field — **at most three one-line follow-ups**. Each agent may now report what its task left *unrecorded on disk* and would otherwise lose with its context, written the way `/follow-ups` writes an item: a slash command plus a short "to …" where one fits. This is what makes the run's closing `/follow-ups` call worth anything in a delegated run; before it, the four fields carried no narrative and an agent's "this left something behind" died with the agent.
- The field is deliberately narrow, and empty on almost every task. The same exclusion rule `/follow-ups` states applies: work already tracked on disk is not a follow-up, so a task the agent created, a commit it made and a status it flipped are all excluded. Three bounds keep it from becoming the narrative channel the other four fields refuse to be — one line each, at most three, and omitted entirely when there are none. A fifty-task run still leaves the parent holding fifty short rows.
- The parent records the lines, folds them into the closing list attributed to the task they came from, and does nothing else with them: it never acts on one mid-run, never re-words one into a judgement it cannot support, and never verifies one — it did not open the task. A follow-up line is never a reason to halt a run.
- `--review` is unchanged: a finding is still never a follow-up and no report, triage table or rejection ledger travels up. The one thing from a review loop that legitimately reaches the new field is a deferral `/task-iterate` noted should become a task, where none was authored — an unwritten task, not a finding.

## 1.55.2 — 2026-09-19

- **/task-implement**'s frontmatter `description:` is folded onto one physical line. It had grown across ten lines, and the CLI's frontmatter parser keeps only the first — so `chosko-llm show task-implement` had been silently truncating the description at the feature-completion clause, hiding the delegation, `--review`, review-budget and closing-call paragraphs from anyone reading it there. No wording changed; only the line breaks are gone.

## 1.55.1 — 2026-09-19

- **/task-implement**'s closing-call section no longer implies that a `--agents` run's follow-up list draws much from the agents. The four-field return contract carries no narrative, so an agent's own "this left something behind" never reaches the parent; the section now says that plainly and points at the launcher's own conversation — the delegation split, tasks skipped for unmet preconditions, failure lines, declined feature slugs — as the substantive half. The return contract is unchanged.
- **/runbook-run**'s closing-call section attributed a sentence to its own reads-and-writes contract that is not in it. Corrected to the real one: reading a step's result opens no file and happens at step 7 anyway, so the "reads three files" contract and the spawn relay's never-read-a-relay-file rule are both untouched.

## 1.55.0 — 2026-09-19

- **/runbook-run** and **/task-implement** now end every run with one **/follow-ups** call, after the run's own closing report and after the last commit. A run no longer ends leaving unrecorded work visible only in the transcript.
- It fires **once per run, never per step and never per task**, and at every point a run stops — not only at completion. For `/runbook-run` that is a `--to` / `--only` / `--steps` bound, a user-requested stop after a step (even with no bound to it) and a failure halt, as well as the runbook finishing. For `/task-implement` it is the end of the run whatever it resolved to (`<N>...`, `all`, `next`), a user-requested stop between tasks and a failure halt — and it comes *after* the feature-completion proposal, which can itself leave a slug `[PLANNED]`.
- In `/runbook-run`'s default spawned mode the orchestrator's reading covers the step subagents' result reports as well as its own conversation — already in hand from the step it just classified, so it opens no file and the "reads three files" contract is untouched. `--inline` is unchanged. Under `/task-implement --agents` the parent likewise reads the per-agent returns it already collects, and the return contract is unchanged.
- The call adds no commit, flips no status and runs after the index `Status:` and the final commit are already written, so it never dirties a tree a run just cleaned. Both skills declare `requires: command:follow-ups` and skip the call silently when the command is not installed — an absent optional closing step is not a run failure.

## 1.54.0 — 2026-09-19

- New command **/follow-ups** — reads the current conversation and lists what would be lost if it ended now: actions proposed but never executed, outcomes never recorded on disk, decisions taken in conversation and written down nowhere. It answers with exactly `No follow-ups left` or with a numbered list, and an empty list is a guarantee — the session can be quit without information or operation loss.
- Each item is written as a slash command plus a short "to …" explanation wherever a command fits, so a follow-up is executable rather than merely noted. The numbering is the handle: replying "execute 1 and 2" is ordinary conversation, not something the command implements.
- Work already tracked on disk is never a follow-up — a runbook that already holds the remaining steps leads the next session to them by itself. A task created in the conversation but not yet appended to the running runbook is one, because nothing on disk connects it to the work in flight.
- Read-only and argument-free: it opens no project file, writes nothing, commits nothing, and invokes no other command.

## 1.53.2 — 2026-09-17

- **/runbook-describe**'s header-line paragraph no longer reads as though `Created:`/`Source:`/`Model:` were the only header fields the command ever prints. It is now scoped to that one line and points at the `Archive:` line below it, so an executing agent that stops reading at that paragraph is not left with a rule the next paragraph contradicts.

## 1.53.1 — 2026-09-17

- **/runbook-describe** now surfaces a pruned runbook's archived step ids. It extracts the body header's `Archive:` line and prints it as one `Archived: 1, 2, 3   (pruned; counted as done)` line directly under the `Created:`/`Source:`/`Model:` line — above the step list, so the list is never read as the whole runbook — and counts every archived id as done and as present in its closing by-marker count, which is what makes that count agree again with the progress figure in the heading line above it. A surviving `deps:` naming an archived id is still printed verbatim and never annotated.
- A runbook that has never been pruned renders exactly as before, line for line: `Archive:` is absent on most runbooks, so the line and the count change are a no-op there. A body pruned to nothing renders its heading, header, `Archived:` line and count rather than an empty step list. `Last step number:` is deliberately not printed — it is bookkeeping for `/runbook-create --append`, not an answer to what a runbook's steps are.
- Still one targeted extraction pass over one body, still read-only: deriving the count from the body's steps and its `Archive:` line is derivation, not reconciliation, and an index `Steps:` count that disagrees is reported in prose and never corrected.

## 1.53.0 — 2026-09-17

- New command **/runbook-prune `<id|name|id-name>`** — removes every `[x]` step from one runbook's body, heading through prompt block, so a long-running runbook stops carrying finished prompts through the re-read `/runbook-run` does at the start of every step. `[ ]`, `[~]` and `[!]` are never touched; a struck step is `[x]` and is pruned like any other. It plans and confirms first, then commits and pushes by default (`--no-commit` / `--no-push` opt out), staging exactly the body and `.claude/RUNBOOKS.md`.
- The removed ids go on a new body-header **`Archive:`** line, and **an id on that line counts as `[x]`**. A surviving `Depends on:` naming a pruned step therefore still resolves — `/runbook-run` resolves it from the header — and the index's `Steps:` count keeps counting archived ids toward both halves, so a runbook pruned to nothing reads `7/7` rather than `0/0`. The line is a bare id list: no digest section, no retained `Done:` lines.
- A prune never moves `Last step number:`, which is what makes pruning the highest-numbered step safe. On a body written before that counter existed, the prune backfills it — to the highest id present, counting the steps about to go — as its first write, so a prune can never lower the next append's id.
- Refuses a `[RUNNING]` runbook and a body holding a `[~]` step; every other status may be pruned, `[FAILED]` included. A runbook with no `[x]` steps says so and stops without asking.

## 1.52.0 — 2026-09-17

- A runbook body's header now carries a **`Last step number:`** counter — the highest step id ever assigned in that runbook, monotonic, never derived with `max()`. It is the same rule `TASKS.md`'s `Last task number:` and the index's `Last runbook number:` already follow, and it is what keeps step ids stable once a step can be removed: a derived counter would hand a removed step's id to the next step written and silently repoint every `Depends on:`, `Failed at: step <n>` and `Context:` bullet recorded before then.
- **/runbook-create** writes that counter on a new runbook and takes each appended step's id from it, advancing it in the same write, instead of numbering from the highest existing step id.
- A body written before the field is legal and is backfilled in place, set to the highest step id present, by the first command that writes it and needs the value. No sweep and no migration.

## 1.51.0 — 2026-09-16

- **/architect amend** no longer asks whether a change is editorial when its own evidence settles it. A task touched on its title or `Files:` line, or added scope it can name, is classified not editorial; no touched task, no added scope and no contract text changed is classified editorial. The gate shows one `Classified:` line with that evidence and writes without waiting for a reply. It still asks — with a recommended answer — when a task's body had to be read, the scope call is borderline, or the findings disagree. **/pipeline-patch** inherits this through the arm it runs.
- **/pipeline-revise** classifies inserts, deletes and reorders as not editorial without asking, and an amend too whenever an edge, a `Files:` line or the scope changes, or all three editorial conditions hold. Its gate waits for a reply only when a borderline amend's editorial question or the here-versus-runbook choice is open; otherwise it shows the plan and runs it. Its report line now names the classification instead of a letter.
- When **/pipeline-revise** runs an `/architect amend` step, that step applies the carried classification without a prompt when its own findings agree, and asks for confirmation only when they differ.

## 1.50.1 — 2026-09-15

- **/session-save** no longer fails to commit when the session file it supersedes was never tracked — a handoff from before 1.49.0, or from a `--no-commit` save. It stages that deletion with `git rm --cached --ignore-unmatch`, which does nothing for an untracked file, instead of a `git add` that aborted staging of the new handoff too.
- **/pipeline-revise** now commits a completed revision in which a step was dropped as moot. Its commit step used to require that every step ran, contradicting its own COMMITTING rules, which withhold the commit only when a sequence stops part-way.

## 1.50.0 — 2026-09-15

- **/pipeline-patch** and **/pipeline-revise** now commit and push by default, and own the commit: every owner step runs uncommitted, and one commit at the end holds the whole patch or revision — never one commit per owner step. The subject is the arm's closing report line for a patch, and the `Revised <anchor> — …` report line for a revision. Pass `--no-commit` to leave the changes uncommitted, or `--no-push` to commit without pushing; `--commit` is still accepted and changes nothing.
- Both pull once at the start of the run, after the anchor resolves, since the owner steps no longer pull themselves.
- A **/pipeline-revise** sequence that stops part-way — an owner refuses, or its gate is answered stop — commits nothing and lists every path written so far, so every commit holds a complete revision. Handing the plan to `/runbook-create` (answer C) commits the new runbook as the revision's one commit.

## 1.49.0 — 2026-09-15

- **/session-save** now commits and pushes the handoff it wrote by default, as `Save session <slug>`. A handoff usually crosses machines, where an untracked file helps nobody. When the save supersedes a tracked session file, that file's deletion rides in the same commit. Pass `--no-commit` to leave the handoff uncommitted, or `--no-push` to commit without pushing; `--commit` is accepted and changes nothing.
- **/session-resume** is unchanged — it still writes, deletes and commits nothing.

## 1.48.0 — 2026-09-15

- **/runbook-create** now commits and pushes the runbook it wrote by default, like `/runbook-run` and `/runbook-clean`. A runbook is read by the next session, often on another machine, and its review already happens at the plan gate. Pass `--no-commit` to leave it uncommitted; `--commit` is still accepted and changes nothing, so existing invocations keep working.
- **/pipeline-patch** and **/pipeline-revise** forward `--no-commit` to `/runbook-create` when the run was not given `--commit`, so a revision run still commits nothing unasked.

## 1.47.3 — 2026-09-15

- **/pipeline-revise** no longer walks up from a successor whose dropped dependency edge is immediately replaced by one carrying the same spec. `delete.md`'s upward continuation, added in 1.47.1, keyed on the edge being dropped when it should have keyed on the work actually being withdrawn — so a reorder, which is a drop plus an insert, proposed an `/architect amend` step for every successor's feature document even though nothing stopped being delivered. The guard now sits on the general rule, matching the one `amend.md` already had, and `reorder.md` still needs no text of its own.

## 1.47.2 — 2026-09-15

- **/task-add** now says which rule wins when the ownership gate's **Drop** answer lands on a feature-derived task's own feature document. PHASE 4's feature case requires that pointer in every new body, and 1.47.0 closed that contradiction only for the case where no reconciliation points could be named; where points could be named, Drop and the PHASE 4 requirement still gave opposite instructions on the same path. The user's Drop answer decides, the body is written without the pointer, and the unreconciled points are recorded as that outcome already requires.

## 1.47.1 — 2026-09-15

- **/pipeline-revise** now says in each branch whether its impact walk continues from the tasks it reaches forward, instead of leaving it implicit. `amend.md` continues from every successor whose basis changes — up to that successor's own feature document, then forward again — and `delete.md` does the same from every successor whose edge is dropped, each node visited once. `insert.md` states that it does not: a task that only gains a wait edge still delivers what it did. `reorder.md` inherits both and needs no rule of its own.
- A feature document reached that way is named from index lines and shown at the gate as an `/architect amend` step, so an under-scoped plan is caught at the gate rather than by the task arm refusing partway through. It is named, never opened — the branch's body scope is unchanged, and whether the document really needs a change stays `/architect amend`'s call.

## 1.47.0 — 2026-09-15

- **/task-add** now offers three answers at its ownership gate instead of two: **Grant**, **Reference** and **Drop**. A Reference keeps an owned document in a task's Hints under one literal marker (`— read-only reference, do not edit`), authorises no edit, and never joins the task's `Files:` line — so a pointer the implementer only needs to read survives instead of being deleted whenever the design document is already correct.
- A feature-derived task's own feature document, the documentation task's included, is now written as a Reference without asking. `/task-add`'s PHASE 4 already required that pointer on every new body of a feature run, so the rule decides it rather than the user; the two no longer contradict each other.
- A marked Reference carried unchanged into a rewritten body — a reconciliation, or an amendment — counts as already decided and is not asked about again, so a restored pointer is no longer stripped by the next reconciliation. Turning one into an edit target, or adding a new owned path, is still a new question.
- **/task-implement** treats a Hint carrying that marker as read-only: it reads the document for context and leaves it alone, and stops to say so if the implementation turns out to need it changed.
- Every detected file still leaves the gate with a decision recorded, silence is still never a grant, and PHASE 4 still refuses a task whose detected file is neither granted, referenced nor removed.

## 1.46.6 — 2026-09-15

- **This repo's own `remote-session-protocol` hook** is now committed as executable, so a fresh clone's `PreToolUse[AskUserQuestion]` hook actually runs instead of failing with permission denied. Installed copies were already executable and are unaffected.

## 1.46.5 — 2026-09-15

- **/runbook-run --inline** no longer stalls on a step's `/task-implement` dirty-tree prompt when the only dirty files are the runbook and its index: the session answers `proceed` itself (never `include`) and says so in one line. Anything else dirty still brings the prompt to you.

## 1.46.4 — 2026-09-15

- **/runbook-run** now answers the cloud sandbox's Stop hook with `stop hook ignored on runbook WIP` instead of `stop hook refused`, so the transcript says the block was deliberately ignored and why. When it applies, and the one forced turn it costs, are unchanged.

## 1.46.3 — 2026-09-15

- **/runbook-run** keeps the part of a spawned prompt it writes itself minimal: the preamble names only the navigation instruction, the runbook and the step, and never restates a task body, feature document, context file or backlog the step will read for itself.
- The orchestrator no longer opens a step's task body or named documents to compose the prompt. The prompt block, the operating rules and `Context:` bullets are unchanged.

## 1.46.2 — 2026-09-15

- A runbook's `Sequencing:` header line is now optional and one line: only *why* the order is what it is, where list position and `Depends on:` can't show it.
- **/runbook-create --append** and step amendments no longer extend it; a dated fact about an inserted or struck step goes in that step's `Context:`. Existing longer lines are left as they are.

## 1.46.1 — 2026-09-15

- **/runbook-run** now writes a terse `Done:` line by default: `Done: <date>, commit <sha> (<N> files, +X/-Y).` A decision or wrong premise is added only when a later reader would be misled without it; review tallies, touched files, restated prompts and resumption narrative stay off the line.
- A step's agent now reports the diffstat beside the sha, so the orchestrator writes the line without running git. Existing `Done:` lines are not rewritten.

## 1.46.0 — 2026-09-15

- **/pipeline-revise** now marks a recommended answer at its editorial question, taken from the tier the plan already shows: an editorial tier recommends A, a local or structural one recommends B. One evidence line names the touched artifacts. You still have to reply, and silence still stops.
- The amend branch can now judge a change editorial (wording only, nothing downstream changing meaning, both answers running the same sequence), so that tier is reachable. Inserts, deletes and reorders are never editorial and recommend B.
- The answer carried into an `/architect amend` step is still your reply, never the recommendation.

## 1.45.0 — 2026-09-15

- **/architect amend** now marks a recommended answer at its editorial question, worked out from what the gate already shows: no touched task and no added scope recommends editorial, anything else recommends not editorial. One evidence line names the touched task ids or the added scope. You still have to reply, and silence still stops.
- Under **/pipeline-revise** your carried answer stays the marked one; the arm's own recommendation shows as one extra line only when it differs.

## 1.44.1 — 2026-09-14

- **/architect amend** under **/pipeline-revise**: the confirmation now says your revise-gate answer was given for the whole plan, and asks you to judge this document's edit on its own, so a structural plan doesn't nudge you into staling tasks for a wording-only document edit.

## 1.44.0 — 2026-09-14

- **/pipeline-revise** no longer asks the editorial question twice. Your answer at its gate carries into the `/architect amend` step, whose gate still shows the full change, touched tasks and outcome but asks you to confirm that answer (or switch, or stop) instead of repeating the question.
- Standalone **/architect amend** and **/pipeline-patch** still ask the full question every time.

## 1.43.0 — 2026-09-14

- **/pipeline-revise** amend branch: when `/architect amend` stales a task or moves the feature to `[ITERATED]`, the plan now runs one `/task-add feature=<slug>` reconciliation instead of amending each staled task. Reconciliation rewrites those tasks, clears `[STALE]`, drafts tasks for the added scope and returns the feature to `[PLANNED]`. Before, the same tasks were rewritten twice behind two sets of gates, and you still had to reconcile afterwards. The gate shows both forms.
- Facts in your change that the feature document doesn't hold (which files to touch, decisions spanning tasks) are listed at the gate, passed to reconciliation as its annotation, and named as things to check at `/task-add`'s gate.
- A change that also names something under a different anchor (a task of another feature) is scoped to the anchor, and the rest is reported as a separate run. The closing report drops the "Reconcile with /task-add" follow-up once reconciliation has run as a step.

## 1.42.2 — 2026-09-14

- **/runbook-run** and **/runbook-create --append** rename an older `<name>.md` body with a plain move and stage nothing until their own commit, which names the old path, the new path and `.claude/RUNBOOKS.md` together. Before, the rename was staged at once, so a step's own commit (or your next unrelated one) could carry it away from the `File:` rewrite.

## 1.42.1 — 2026-09-14

- **/runbook-clean** and **/runbook-describe** take a runbook as its id, its name, or `<id>-<name>`, and open or delete the body wherever its `.claude/RUNBOOKS.md` block's `File:` line points, so older `<name>.md` bodies still work. Neither renames a body.
- **/pipeline-patch** and **/pipeline-revise** accept the same three forms in their `runbook=` anchor.

## 1.42.0 — 2026-09-14

- **/runbook-create** writes a new runbook's body as `<id>-<name>.md`, and its plan shows that path. It refuses a new name whose first segment is all digits (`2026-migration`), suggesting one alternative, so `3-some-name` can never mean two runbooks.
- `--append` takes the runbook as its id, its name, or `<id>-<name>`. An older `<name>.md` body is renamed to the new form when you append to it (never while it is running), and with `--commit` the rename goes into the append's own commit.

## 1.41.0 — 2026-09-14

- **Runbook bodies** are now named `<id>-<name>.md` (`3-runbook-slug.md`), so the id you type is the one you see in `.claude/runbooks/`. Every body is opened at the path its `.claude/RUNBOOKS.md` block's `File:` line holds, so older `<name>.md` bodies keep working.
- **/runbook-run** takes the runbook as its id, its name, or `<id>-<name>`. If the two halves don't match, it reports the runbook the id really belongs to instead of guessing. An older body is renamed to the new form the first time a run starts on it (never while it is running), and the rename goes into that run's first step commit.

## 1.40.0 — 2026-09-14

- **/runbook-run** takes `--inline`: this session carries out each selected step itself instead of starting a fresh subagent per step. That saves the cost of orienting and spawning an agent for short runs of small, related steps. Selection, markers, `Done:` lines, the index, fact propagation and the per-step commits are unchanged, and nothing records which mode ran, so a runbook can be resumed in either mode.
- It composes with `--from`, `--to`, `--only`, `--steps N`, `--no-commit` and `--no-push`. It is refused beside `--relay-spawns` or `--model`, and the header `Model:` is not applied. Under it, steps share one context: the step's brief and the written records win over memory, questions are asked directly, and a child a step wants is spawned one level down, never done inline.

## 1.39.0 — 2026-09-14

- **/runbook-run** takes `--steps N`: run at most N steps in this run, then stop — no need to look up which step id is N steps ahead. Only steps actually executed count, so already-done steps never use up the budget. It composes with `--from` (`--from 4 --steps 2`), is refused beside `--to` or `--only`, and needs a positive integer.
- Reaching the count stops the run like a `--to` bound: the runbook goes back to `[PENDING]` unless every step is done, and `Depends on:` is never weakened.

## 1.38.1 — 2026-09-14

- **/runbook-describe** prints a compact summary instead of a deep read: one header line (created, source, model), one line per step with its dependencies and `needs:` only when they apply, and at most one short `done:` line per finished or failed step, with wrong premises shown as a count. `Sequencing:`, `Companion:`, `Context:` notes and the re-propose count are no longer printed.
- It now pulls only the lines it prints from the runbook's body instead of reading the whole file, and never opens the task bodies a `Done:` line mentions, so its cost stays close to the size of its output. It no longer guesses a `Needs:` value for a step that has none.

## 1.38.0 — 2026-09-13

- **/runbook-run** answers the cloud sandbox's Stop hook with the fixed literal `stop hook refused` instead of re-explaining itself. That hook won't let a turn end on a dirty tree, and an in-flight step is dirty by design — the `[~]` heading and the index's `[RUNNING]` are the resume signal and must stay uncommitted — so the block landed at every step start and every relayed question, each time costing a few hundred tokens and a `git status` to re-derive an answer that never changes.
- The rule applies only when the two bookkeeping files the run just wrote are the only dirty ones; anything else in the tree is handled normally, so a genuinely forgotten commit still gets thought about. No tool call, no explanation, and the turn ends there.

## 1.37.0 — 2026-09-12

- **/pipeline-revise** forwards `--no-commit` to `/product-design` and `/production-plan` when the run was not given `--commit`, matching the defaults those two took in 1.36.0. Without it a revision run would have committed when the user did not ask. `/runbook-create --append` still commits nothing by default and is forwarded `--commit` as before.
- **/pipeline-patch** and **/pipeline-revise** both label the forwarding table's first column as the revision command's own default, so no row reads as a claim about an owner's default.

## 1.36.0 — 2026-09-12

- **/product-design**, **/product-roadmap** and **/production-plan** commit and push what they wrote by default, the same flip `/architect` took in 1.35.0. Pass `--no-commit` to write everything and run no git command; `--no-push` commits without pushing. `--commit` is still accepted and is now a silent no-op. The pull-at-start now runs on every run that is not `--no-commit`.
- **/product-design** now commits `.claude/domain/design-process.md`, so a resumed design process carries across machines and terminals instead of living in one working tree.

## 1.35.0 — 2026-09-12

- **/architect** commits and pushes what it wrote by default. Pass `--no-commit` to write everything and run no git command; `--no-push` commits without pushing. `--commit` is still accepted and is now a silent no-op, so existing invocations keep working. The pull-at-start now runs on every run that is not `--no-commit`.

## 1.34.1 — 2026-09-11

- **/production-status** counts a feature's task IDs that are no longer in `TASKS.md` as `archived: N` in its task rollup (`[archived]` under `--task-ids`) instead of dropping them, so a fully archived `[PLANNED]` feature no longer reads as having no tasks. It still opens nothing under `.claude/tasks/`.
- **/task-implement** stops on a task number that is not in `TASKS.md` and names `.claude/tasks/archive/<N>.md` as where its body would be; an archived task is never implemented again.
- **/task-add** `feature=<slug>` keeps archived task IDs on the feature's `Tasks:` line when it rewrites it.
- **/task-review** and **/task-iterate** never pick a file under `.claude/tasks/archive/` when guessing which task a diff belongs to.
- **/architect** iterate guard explains ids absent from `TASKS.md` as archived tasks; its behaviour is unchanged.

## 1.34.0 — 2026-09-11

- **pipeline-suggest** (new skill) answers a free-form request to build, change, fix, remove or sequence work with one line naming the pipeline command that fits it — `/architect`, `/task-add`, `/pipeline-patch`, `/pipeline-revise` and the rest — then stops. Claude Code selects it from its description; it asks nothing, writes nothing, only checks whether `.claude/FEATURES.md` or `.claude/TASKS.md` exists, and says nothing on a project with neither.
- **pipeline-engine** the routing table gains a row for `pipeline-suggest`.

## 1.33.0 — 2026-09-11

- **/pipeline-revise** (new skill) changes, inserts into, removes from or reorders already-planned work — a feature document, a task or a runbook step — by walking the change's impact from an anchor and running each owner's own amend step in order.
- **/pipeline-revise** proposes an editorial, local or structural plan behind one gate that always asks whether the change is editorial, and re-runs `/pipeline-check` on the anchor before and after.
- **/pipeline-revise** runs three or fewer owner steps in the session and offers to hand four or more to `/runbook-create`; removal is `[SKIP]` or a struck step, never a deletion.
- **/pipeline-patch** (new command) applies a change that touches exactly one feature document, task or runbook step through that owner's amend arm and re-checks it, reading only the indexes; anything structural is refused in one line naming `/pipeline-revise`.
- **pipeline-engine** the routing table gains rows for `/pipeline-patch` and `/pipeline-revise`.

## 1.32.0 — 2026-09-11

- **/architect** gains `amend feature=<slug> "<change>"`: a targeted change to the named sections of one feature document, behind one gate, without the clarify or architecture phases. Only the tasks the change touches are marked `[STALE]`, only a touched `[IN PROGRESS]` task refuses it, and you are asked every time whether the change is editorial — an editorial change stales nothing and leaves the feature's status alone.
- **task-engine** gains `references/amend.md`, the rules for changing one existing task: which body sections and summary fields may change, dropping a `Preconditions:` edge with its reason recorded, deleting a live task as `[SKIP]`, and attaching an orphan task to a feature. It refuses an `[IN PROGRESS]`, `[DONE]` or `[SKIP]` task, and sends a change to what the feature promises to `/architect amend`.
- **runbook-run** gains `references/step-amend.md`, the rules for changing one pending step: strike it (`[x]` with `Done: struck — <reason>`, never deleted or renumbered), insert a step through `/runbook-create --append --before` / `--after`, or add dated facts to its `Context:`. A wrong prompt is struck and a corrected step inserted; a running runbook takes changes only after its current step.
- **pipeline-engine** the routing table records where each owner's amend entry is — `/architect`, the task suite, the runbook suite and `/product-design` — and that `/production-plan` and `/product-roadmap` need none.

## 1.31.0 — 2026-09-11

- **/pipeline-check** (new command) reports structural drift across `FEATURES.md`, `TASKS.md`, `PLAN.md` and `RUNBOOKS.md`: an unknown feature slug, a precondition never assigned or pointing at a `[SKIP]` task, a precondition cycle, an `[ITERATED]` feature, a `[STALE]` task, a feature missing from the plan or a plan line naming an unknown one, a finished runbook still `[PENDING]`, and a `[PLANNED]` feature whose work has all resolved. Each finding carries an `ERROR` or `WARNING` severity and the one command that fixes it; a clean project prints one line.
- **/pipeline-check** `feature=<slug>` scopes the report to one feature and the tasks and plan lines that name it. The command is read-only, never refuses over a missing index, and never reports an archived task as drift.
- **pipeline-engine** (new skill, installed with `/pipeline-check`) is the shared reference for the pipeline as a whole: the one-line project probe, how the indexes point at each other, a routing table of what every pipeline feature consumes, produces and owns, and the drift catalogue. It is never invoked directly.
- **scripts/check-routing.sh** (repo-local) checks that every routing-table row names a shipped feature and that every feature reading the engine has a row.

## 1.30.0 — 2026-09-11

- **/task-clean** is now a skill (`skill:task-clean`) rather than a command; `chosko-llm add` / `update` of the skill retires an installed command copy.
- **/task-clean** archives instead of deleting: each pruned body moves to `.claude/tasks/archive/<N>.md` under a frozen header recording its summary block, and a prune no longer touches `.claude/FEATURES.md`, so a feature keeps every task id it generated. Its commit now reads `task-clean: archive tasks …`.
- **/task-clean** gains `--backfill`, which recovers from git history the bodies earlier runs deleted, archives them the same way, and puts each id back on its feature's `Tasks:` line.
- **task-engine** `resolution.md` gains the archive rule: an id referenced but absent from `TASKS.md` is archived and terminal, and nothing reads the archive unless you name a task and ask for it.

## 1.29.0 — 2026-09-11

- **/runbook-create** `--append` gains `--before <step>` / `--after <step>`: the new steps are written at that position in the runbook instead of at the foot, and still take the next unused step id. No existing step is edited, moved or renumbered.
- **runbook schema** a step's number is a stable id, not its position: order is list position, and a body may carry step ids out of numeric order after an insert.
- **/runbook-run** `--from`, `--to` and `--only` still name steps by id, and now cut the list at those steps' positions, so a range is always the stretch of steps the run walks.

## 1.28.0 — 2026-09-11

- **/task-implement** `next` and `all` now honour `Preconditions:`: a task is picked only once every task it names is `[DONE]` or `[SKIP]`, and `all` orders its list so nothing starts ahead of what it waits on. A task named by number is never blocked.
- **/task-implement** an `all` run names by id every task it left blocked, a precondition cycle included, and between tasks skips with one line a task whose preconditions no longer hold.
- **/production-status** the Next column's `/task-implement <N>` is the first task in backlog order whose preconditions are satisfied, not the lowest-numbered open one; a feature whose open tasks all wait on something reads `waits on task <id>`.
- **/task-add** gains `--before <N>` / `--after <N>`: the new task is written at that position in `TASKS.md` and the matching `Preconditions:` edge is written with it. No existing id is renumbered.
- **/task-add** gains `feature=<slug> --single`, attaching one task to a `[PLANNED]` feature without re-planning it and saying that the feature document was not updated; on a project with `FEATURES.md`, a free-form run asks at its approval gate whether the task belongs to a feature.

## 1.27.0 — 2026-09-03

- **/runbook-run** gains `--to N`, stopping the run after step N. It composes with `--from`, so `--from X --to Y` runs that range of steps inclusive.
- **/runbook-run** `--only N` is now exactly `--from N --to N` — one selection model rather than three, with the shorthand kept for the common case.
- **/runbook-run** a run that stops at its `--to` bound leaves the runbook `[PENDING]`, never `[DONE]`, and reports which steps remain outside the range.
- **/runbook-run** neither bound weakens a `Depends on:`; naming `--only` beside a bound, or a `--to` below a `--from`, is an error that runs nothing.

## 1.26.0 — 2026-09-02

- **/runbook-run** gains a spawn relay for environments where a subagent cannot spawn a subagent, such as cloud sessions: a step's agent asks with `SPAWN REQUEST` and the orchestrator spawns the child at its own level, so nothing has to nest.
- **/runbook-run** forwards the child's prompt and result by path and never opens either file, keeping the child's output out of the orchestrator's context; `--relay-spawns` forces the mode where the environment is already known to be flat.
- **runbook subagent contract** tells a step's agent to route a child through the relay rather than doing its work inline or dropping it silently.
- **/runbook-create** gains a tenth prompt-quality rule preferring two steps to one that would need a nested spawn.

## 1.25.0 — 2026-09-02

- **/runbook-describe** a new command printing one runbook in depth — header, status, and every step with its marker, dependencies, `Done:` line and whether it needs a person.
- **runbook steps** gain an optional `Needs:` line (`agent` / `agent+human` / `human`, absent meaning `agent`), authored by `/runbook-create` and called out at its confirmation gate.
- **/runbook-describe** prints an authored `Needs:` as written, and for a step lacking one may infer from the prompt block — always labelled `(inferred)`, never written back.

## 1.24.0 — 2026-09-02

- **runbooks** every runbook now carries a numeric id beside its name; `.claude/RUNBOOKS.md` gains a `Last runbook number:` counter, exactly as the task backlog has.
- **/runbook-run, /runbook-create --append, /runbook-clean** take that id anywhere they take a name — a bare all-digits argument is an id, anything else a name.
- **/runbook-list** prints the id and the runbook's one-line title as new columns, still without ever opening a body.
- **runbook index** an index written before ids is backfilled in place by the first command that writes it; ids are never renumbered and a pruned one is never reused.

## 1.23.3 — 2026-08-28

- **macOS** the CLI now runs on the stock bash 3.2: associative arrays and `mapfile` — which broke `update`, `add`, `show` and `ls` with `declare: -A: invalid option` — are replaced with portable equivalents, and the em dash `ls` prints for an empty cell no longer trips bash 3.2's variable parsing.

## 1.23.2 — 2026-08-25

- **chosko-llm changelog** the readout is repainted in the palette `ls` and `show` already use: versions green, subjects cyan, `code` spans yellow, the bullet marker dim.
- **chosko-llm upgrade** shares that palette, since both go through the one renderer.

## 1.23.1 — 2026-08-25

- **chosko-llm upgrade** reloads its helpers after the pull, so a change to the changelog renderer takes effect in the very upgrade that ships it instead of the next one.

## 1.23.0 — 2026-08-25

- **chosko-llm changelog** every entry is now one terse line opening with a bold subject naming what changed.
- **chosko-llm upgrade** renders that bold subject in colour, and strips the `**` markers when colour is off.
- **CHANGELOG.md** the whole history is rewritten in the new style; versions, dates and ordering are untouched.

## 1.22.5 — 2026-08-25

- **chosko-llm ls** about 27× faster — 5.4 s down to 0.2 s on ~34 features, from 217 processes to 3, with byte-identical output.
- **chosko-llm show / update** faster too: the `superseded` and `migration pending` probes read an index built once instead of rescanning the clone.

## 1.22.4 — 2026-08-25

- **/production-status** renders its feature section as a fixed five-column table instead of improvising a shape per run.

## 1.22.3 — 2026-08-25

- **/task-implement, /task-review** instruction fixes: the review-budget authority is listed where it is used, and the reviewer's reading list defers to the read budget.

## 1.22.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.22.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.22.0 — 2026-08-25

- **/task-review** honours the read budget its caller sends, and reports a cap that actually binds.
- **/task-review** invokes no test command in any mode — a green suite is an input its caller hands it.
- **chosko-llm add skill:task-review** installs `task-engine` first, now that the skill declares it.

## 1.21.0 — 2026-08-25

- **/task-implement --review** gains `--review-model` and `--review-effort`, both defaulting to `auto` and resolved per task from that task's own diff.
- **/task-implement --review** now spawns a Sonnet reviewer on an ordinary task instead of inheriting the implementer's model; `--review-model same` restores the old behaviour.

## 1.20.0 — 2026-08-25

- **skill:task-engine** gains `references/review-budget.md`, the single authority for the review cost controls its consumers wire up next.

## 1.19.3 — 2026-08-25

- **/architect** no longer leaves a cleaned feature stuck at `[DONE]`: the iterate guard keys its status flip on the feature's status, not its task list.

## 1.19.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.19.1 — 2026-08-25

- **chosko-llm ls** is fast again — each row parses any given file at most once, undoing the 30% the `REQUIRES` column cost.

## 1.19.0 — 2026-08-25

- **/production-status** replaces its readiness column with a **Next** column naming the concrete action each feature needs.
- **/production-status** stops claiming `no tasks yet` on a feature whose finished tasks were pruned.

## 1.18.0 — 2026-08-25

- **chosko-llm ls** gains a `REQUIRES` column, so a feature's dependencies read straight off the listing.

## 1.17.0 — 2026-08-25

- **chosko-llm ls** prints one table ordered by feature name instead of five kind-grouped blocks.

## 1.16.0 — 2026-08-25

- **claude-md:git-commit-style** new artifact — a global commit-message shape, with the trailers behind a checkable size test.
- **/task-implement** commit-message body is now optional and capped at 2–3 lines.

## 1.15.0 — 2026-08-25

- **chosko-llm changelog** new subcommand — opens `CHANGELOG.md`, or prints from a version, date or duration with `--since`.
- **chosko-llm upgrade / --version** point at it with a TTY-gated tip.

## 1.14.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.14.0 — 2026-08-25

- **skill:runbook-suggest** new skill — proposes capturing a conversation's follow-up actions as a runbook before the session closes.

## 1.13.0 — 2026-08-25

- **/runbook-clean** new command — deletes each `[DONE]` runbook's body and index block, behind a confirmation gate.

## 1.12.0 — 2026-08-25

- **/runbook-list** new command — one line per runbook: status, name, steps done over total, creation date and source.

## 1.11.0 — 2026-08-25

- **/runbook-create** new command — writes a runbook out of the conversation that produced it, new or `--append`.

## 1.10.0 — 2026-08-25

- **skill:runbook-run** new skill — walks a runbook top to bottom, one subagent per step, committing after each.

## 1.9.0 — 2026-08-25

- **/task-add** asks for pre-authorisation before drafting a task that must edit a document another command owns, instead of only warning.

## 1.8.5 — 2026-08-25

- **skill:task-engine** drops a stale note about a migration that had already landed; no rule changed.

## 1.8.4 — 2026-08-25

- **/task-implement** consumes `task-engine` for the rules the `task-*` suite shares, and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.3 — 2026-08-25

- **/task-add** consumes `task-engine` and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.2 — 2026-08-25

- **/task-clean** consumes `task-engine` and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.1 — 2026-08-25

- **/task-list** is the first feature to consume `task-engine`; its output is unchanged.

## 1.8.0 — 2026-08-25

- **skill:task-engine** new skill — a reference library holding one authority per rule the `task-*` features share. Nothing consumes it yet.

## 1.7.0 — 2026-08-25

- **requires:** new optional frontmatter key naming the features a feature reads a file out of.
- **chosko-llm add** installs a feature's requirements first; **rm** refuses to break an installed dependent without `--force`.

## 1.6.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.6.0 — 2026-08-25

- **/task-implement** gains `--review` and `--rounds N` — a task is reviewed by a fresh context and corrected before its single commit.

## 1.5.0 — 2026-08-25

- **skill:task-iterate** new skill — triages `/task-review`'s findings, applies what survives and records why the rest did not.

## 1.4.0 — 2026-08-25

- **skill:task-review** new skill — audits a diff against the acceptance criteria of the task that produced it, and writes nothing.

## 1.3.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.3.0 — 2026-08-25

- **/task-implement** batch parent becomes a launcher: it hands each agent a fixed-size prompt and never opens a delegated task's body. Observable behaviour unchanged.

## 1.2.3 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.0 — 2026-08-25

- **/session-resume** new command — loads one handoff out of `.claude/sessions/`, briefs the conversation, then stops.

## 1.1.0 — 2026-08-25

- **/session-save** new command — writes a per-project handoff capturing what a conversation knows and nothing else does.

## 1.0.0 — 2026-08-25

- **chosko-llm task-impl** removed (breaking) — the local-model lane (aider + Ollama) is gone and the subcommand now exits 2.
- **/task-enrich** is no longer shipped, and `/task-add --enrich` with it; `Target:` keeps `claude`, `claude+human` and `human`.
- **/task-setup** creates the backlog and the two test-dispatch wrappers only, no longer the aider prompt templates.

## 0.63.1 — 2026-08-25

- **chosko-llm help** notes that `upgrade` prints what changed for the versions just pulled.

## 0.63.0 — 2026-08-25

- **chosko-llm upgrade** prints the `CHANGELOG.md` sections for exactly the versions just pulled, instead of a raw commit list.

## 0.62.4 — 2026-08-25

- **No user-facing change** in this release.

## 0.62.3 — 2026-08-25

- **scripts/check-changelog.sh** new authoring-time guard — fails when the top `CHANGELOG.md` section does not match `VERSION`.

## 0.62.2 — 2026-08-25

- **CHANGELOG.md** added at the repo root, backfilled from `0.1.0` onward.

## 0.62.1 — 2026-08-24

- **No user-facing change** in this release.

## 0.62.0 — 2026-08-24

- **skill:claude-council** new skill — pressure-test a decision with five thinking-lens advisors and a dual-chairman synthesis.
- **/task-list** fenced-output instruction trimmed to one reading.

## 0.61.1 — 2026-08-22

- **/task-list** numbered output no longer gets renumbered by the markdown renderer.

## 0.61.0 — 2026-08-16

- **/product-design** replaces `design-process.md` when a run ends instead of appending, so the file stops growing a run at a time.
- **/production-status** no longer treats a `[DONE]` feature as still ready to start.

## 0.60.0 — 2026-08-13

- **FEATURES.md** accepts `[DONE]` as a feature status, so a finished feature has somewhere to land.

## 0.59.0 — 2026-08-11

- **hook** new feature kind — a `.sh` Claude Code runs on a hook event, installed into the repo it governs.
- **chosko-llm update** re-prompts for hook wiring when an update moves a hook's `event:` or `matcher:`.
- **chosko-llm export** includes the `.claude` shell scripts.

## 0.58.2 — 2026-08-09

- **repo scripts** the six that are executed are tracked with the executable bit set.

## 0.58.1 — 2026-08-09

- **/product-roadmap** fixes a steer question whose two options could be read the same way.

## 0.58.0 — 2026-08-08

- **/product-roadmap** asks who proposes the milestone order, and records the strategic premise behind the order it produces.

## 0.57.2 — 2026-08-08

- **/product-roadmap** the product pipeline's stages are renumbered end to end now that it sits in them.

## 0.57.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.57.0 — 2026-08-08

- **/task-list** groups tasks under their milestone in plan order, and flags a task whose feature is blocked.

## 0.56.0 — 2026-08-08

- **/production-status** new command — the active milestone, the ready set, the blocked features and one recommendation.

## 0.55.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.55.0 — 2026-08-08

- **/production-plan** new skill — writes `.claude/PLAN.md`: ordered features per milestone, plus cycle and ordering validation.

## 0.54.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.54.0 — 2026-08-07

- **/architect** resolves a roadmap scope slice instead of a whole design section on projects that have a roadmap.

## 0.53.2 — 2026-08-07

- **/architect** moves its input resolution into an on-demand reference file, so a project with no roadmap reads none of it.

## 0.53.1 — 2026-08-07

- **No user-facing change** in this release.

## 0.53.0 — 2026-08-07

- **/product-roadmap** new skill — milestones with goals, exit criteria and the scope slices that decide what each takes.
- **claude-md:remote-session-protocol** new artifact, installable into a repo's `CLAUDE.md`.

## 0.52.1 — 2026-08-07

- **/task-add** documentation-task ownership gate becomes a warning instead of a refusal.
- **/architect, /product-design** gain an optional `claude-council` decision gate.

## 0.52.0 — 2026-08-06

- **chosko-llm add / update** accept several feature names in one call.

## 0.51.1 — 2026-08-06

- **chosko-llm ls / show** give `superseded` and `migration pending` distinct status colours.

## 0.51.0 — 2026-08-06

- **chosko-llm ls / show** surface a feature whose kind changed and is waiting to be migrated.

## 0.50.0 — 2026-08-06

- **--local / --global** on `ls`, `add`, `rm`, `update` and `show` — install features into a single repo instead of `~/.claude/`.

## 0.49.2 — 2026-08-06

- **scripts/lib.sh** owns install-scope resolution, ahead of the subcommands that use it.

## 0.49.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.49.0 — 2026-08-05

- **/context-convert** new skill — converts a context layer between the flat and nested layouts, reporting the move plan first.

## 0.48.0 — 2026-08-05

- **/context-update** handles nested layers, and takes `unit=<names>` to scope a run to specific units.

## 0.47.0 — 2026-08-05

- **/context-build** `nested` builds a router index plus per-unit leaves instead of one flat index.

## 0.46.0 — 2026-08-05

- **/context-build, /context-update** become skills, and stamp a `Layout:` marker on the index.

## 0.45.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.45.0 — 2026-08-05

- **chosko-llm update** migrates a feature that changed kind instead of leaving two copies installed.

## 0.44.2 — 2026-08-05

- **No user-facing change** in this release.

## 0.44.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.44.0 — 2026-08-05

- **/architect** writes a resume marker, so an interrupted design session can be picked up where it stopped.

## 0.43.3 — 2026-08-05

- **shipped features** oversized `description:` fields trimmed to the length the authoring guide specifies.

## 0.43.2 — 2026-08-05

- **authoring commands** vestigial `--no-commit` checks removed from the ones that never committed anything anyway.

## 0.43.1 — 2026-08-05

- **chosko-llm task-impl** refuses a task with a missing `Target:`, not only one whose target is not `claude`.

## 0.43.0 — 2026-08-05

- **chosko-llm task-impl** hard-refuses any task whose `Target:` is not `claude` — an unattended run cannot pause for a human.

## 0.42.2 — 2026-08-05

- **skill:unity-mcp-skill** dead reference links removed.

## 0.42.1 — 2026-08-05

- **/task-setup** fixes the external-LLM prompt templates, which still described the superseded task-body schema.

## 0.42.0 — 2026-08-05

- **/task-add --short** a lightweight body for trivial tasks, skipping the deep investigation pass that would cost more than the task.

## 0.41.0 — 2026-08-05

- **/task-implement** skips the test phases on a task that touches nothing but documentation.

## 0.40.0 — 2026-08-05

- **/task-implement** offers one fresh subagent per task on a multi-task run; `--agents` / `--no-agents` pre-answer the question.

## 0.39.0 — 2026-07-28

- **/task-add feature=<slug>** appends a final documentation-update task to every feature it plans.

## 0.38.0 — 2026-07-28

- **/task-implement** strict-TDD sequence simplified to the steps it actually runs.

## 0.37.0 — 2026-07-28

- **/product-design** sweeps the conversation at the end of a phase for design detail that never made it into the document.

## 0.36.0 — 2026-07-28

- **/task-implement** pushes once per task, right after that task's own commit, instead of deferring to the end of the run.

## 0.35.0 — 2026-07-28

- **/unity-mcp-setup** pushes what it commits; `--no-push` skips the push.

## 0.34.0 — 2026-07-28

- **/project-setup** pushes what it commits; `--no-push` skips the push.

## 0.33.0 — 2026-07-28

- **/domain-setup, /product-design, /architect** push what they commit; `--no-push` skips the push.

## 0.32.0 — 2026-07-28

- **/refactor-codebase, /refactor-tests** push what they commit; `--no-push` skips the push.

## 0.31.0 — 2026-07-28

- **/context-build, /context-update** push what they commit; `--no-push` skips the push.

## 0.30.0 — 2026-07-28

- **/task-add, /task-clean, /task-setup, /task-enrich** push what they commit; `--no-push` skips the push.

## 0.29.0 — 2026-07-28

- **committing features** all follow one commit-and-push protocol — pull, commit, re-sync, push — instead of each carrying its own.

## 0.28.0 — 2026-07-28

- **chosko-llm export** records the exported repo's version and creation date in the manifest.

## 0.27.1 — 2026-07-28

- **chosko-llm export** prints a file-count and line-count report when it finishes.

## 0.27.0 — 2026-07-28

- **statusline** new feature kind, and the `session-statusline` status bar that ships through it.

## 0.26.0 — 2026-07-27

- **/task-implement -y** and the `skip-tests-unattended` policy marker suppress the per-task confirmation on projects with no test suite.

## 0.25.0 — 2026-07-27

- **/architect** adopts `technical-direction.md` as the project's established stack instead of re-deciding it per feature.

## 0.24.0 — 2026-07-27

- **/product-design** gains a technical-direction phase, and writes `technical-direction.md`.

## 0.23.2 — 2026-07-27

- **chosko-llm export** excludes the task backlog, and separates each file clearly in the Markdown output.

## 0.23.1 — 2026-07-27

- **chosko-llm export** fixes an invalid `local` declaration in the open-in-file-manager helper.

## 0.23.0 — 2026-07-27

- **chosko-llm export** opens the output folder when it finishes.

## 0.22.0 — 2026-07-27

- **chosko-llm export** new subcommand — package a repo's Claude config as a Markdown file or a zip.

## 0.21.1 — 2026-07-27

- **No user-facing change** in this release.

## 0.21.0 — 2026-07-27

- **/task-clean** prunes the task IDs it removes from `FEATURES.md` too, so the feature index stops pointing at tasks that are gone.

## 0.20.0 — 2026-07-27

- **/task-add feature=<slug>** plans tasks from a feature document, and reconciles them when the design changes.

## 0.19.0 — 2026-07-27

- **/architect** new skill — turns a design section into a low-level feature document.

## 0.18.0 — 2026-07-27

- **/product-design** new skill — the guided design pass and the documents it produces.

## 0.17.0 — 2026-07-27

- **/project-setup** runs `/domain-setup` as part of first-time initialization.

## 0.16.0 — 2026-07-27

- **/domain-setup** new command — scaffolds the domain knowledge layer and the `FEATURES.md` index.

## 0.15.0 — 2026-07-27

- **TASKS.md** the backlog schema gains the `[STALE]` status and the `Feature:` origin link.

## 0.14.2 — 2026-07-27

- **No user-facing change** in this release.

## 0.14.1 — 2026-07-27

- **No user-facing change** in this release.

## 0.14.0 — 2026-07-21

- **skill:unity-mcp-skill** new skill — drives the Unity Editor through MCP.

## 0.13.2 — 2026-07-21

- **/task-implement** Unity MCP checkpoint question offers explicit automatic and manual options instead of an ambiguous opt-out.

## 0.13.1 — 2026-07-17

- **chosko-llm channel** fixes `--list` showing a bogus `origin` entry.

## 0.13.0 — 2026-07-17

- **chosko-llm channel** new subcommand — point the managed clone at a branch to test unmerged work.

## 0.12.0 — 2026-07-17

- **/project-setup** offers to run `/unity-mcp-setup` on Unity projects.

## 0.11.0 — 2026-07-17

- **/task-implement** drives a task's manual checkpoints through Unity MCP when the project and the session both support it.

## 0.10.0 — 2026-07-17

- **/unity-mcp-setup** new command — makes a Unity project ready for MCP-assisted task implementation.

## 0.9.0 — 2026-07-10

- **/project-setup** injects a Tasks-implementation section into `CLAUDE.md` on Unity projects, covering dirty-tree noise and the testing policy.

## 0.8.2 — 2026-07-10

- **/task-implement** states that a checkpoint explanation ends the turn, so the user actually sees it before being asked.

## 0.8.1 — 2026-07-10

- **/task-implement** human-in-the-loop checkpoint wording polished.

## 0.8.0 — 2026-07-09

- **plugin manifest** the repo ships a Claude Code plugin manifest and marketplace entry.

## 0.7.3 — 2026-07-09

- **committing commands** the non-git VCS rule is stated once and referenced, instead of repeated in every one of them.

## 0.7.2 — 2026-07-09

- **shipped commands** redundant TOOL DISCIPLINE blocks removed.

## 0.7.1 — 2026-07-09

- **scripts/check-task-parity.sh** new repo guard keeping the `/task-implement` prompt and `cmd-task-impl.sh` in step.

## 0.7.0 — 2026-07-09

- **/task-implement** becomes a skill, so its supporting files load only when the branch that needs them applies.

## 0.6.4 — 2026-07-09

- **/task-implement** its duplicated test-runner tables carry "mirrored copy" markers, so an edit to one is visibly an edit to both.

## 0.6.3 — 2026-07-09

- **chosko-llm task-impl** fixes running the affected tests twice per task.

## 0.6.2 — 2026-07-09

- **smoke-test suite** removed, along with the docs that referenced it.

## 0.6.1 — 2026-07-08

- **/task-implement** explains a manual step before asking the human to confirm it.

## 0.6.0 — 2026-07-08

- **/task-implement** honours `Testing policy for /task-implement: skip-tests` in a project's `CLAUDE.md`, so a run stops asking about the missing suite.

## 0.5.1 — 2026-07-08

- **/task-implement** dirty-tree prompt splits "proceed" into committing the existing changes first or leaving them uncommitted.

## 0.5.0 — 2026-07-08

- **/task-implement** human-in-the-loop targets `claude+human` and `human`, with a `Manual interventions` body section that pauses the run at each checkpoint.

## 0.4.1 — 2026-07-08

- **/context-update** the Plastic SCM `## VCS` snippet maps `git log`, so incremental mode works on a non-git project.

## 0.4.0 — 2026-07-01

- **/task-add** proposes splitting a description into several tasks when it bundles independent deliverables.

## 0.3.1 — 2026-07-01

- **install.sh** fixes the `curl | bash` install failing on an unset `BASH_SOURCE`.

## 0.3.0 — 2026-06-05

- **chosko-llm --version** prints the repo-level version.

## 0.2.0 — 2026-06-05

- **chosko-llm show** new subcommand — inspect one feature's versions, status, description and body.
- **chosko-llm ls** gains a STATUS column, and prints actionable suggestions after the table.
- **chosko-llm add --all** installs every uninstalled feature; `update --all` skips what is up to date or locally ahead.
- **chosko-llm uninstall** is reachable through the proxy.
- **chosko-llm upgrade** gains daily auto-upgrade, toggled with `--enable-auto` / `--disable-auto`.
- **install.sh** one-liner `curl | bash` install, plus a `chosko-llm.cmd` entry point for cmd and PowerShell.
- **semantic colour** across the CLI, colour-coded feature kinds, and `NO_COLOR` honoured.
- **TASKS.md** the backlog splits into a lightweight index plus per-task body files, with the thin body schema and the `Target:` field.
- **/task-add, /task-list, /task-clean, /task-implement, /task-enrich** new task commands.
- **/refactor-codebase, /refactor-tests, /context-build, /context-update, /project-setup** new workflow commands.
- **chosko-llm task-impl** runs the external-LLM (aider + Ollama) task sequence, with `--model`, `--retries` and `--map-tokens`.
- **commit control** authoring commands leave their output uncommitted and take `--commit`; auto-committing commands take `--no-commit`.
- **/task-implement** prompts on a dirty working tree instead of aborting.

## 0.1.0 — 2026-05-06

- **chosko-llm** initial release — `ls`, `add`, `rm`, `update`, `upgrade` and `help`, `install.sh` / `uninstall.sh`, and copy-not-symlink installs into `~/.claude/`.
