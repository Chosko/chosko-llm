# Context index

Layout: flat

Last updated: 2026-10-07

Nav layer for `chosko-llm`. How to read it: `../../CLAUDE.md` § Navigation.

Canonical project docs live outside this folder, stay authoritative:
- `../../CLAUDE.md` — hard rules, authoring entry-point.
- `../../README.md` — user-facing overview.
- `../../docs/reference.md` — complete feature + CLI reference the README links into.
- `../../docs/authoring-guide.md` — frontmatter/versioning truth.
- `../../docs/cli-help.txt` — CLI help text shipped to users.
- `../../CHANGELOG.md` — user-facing changes per root `VERSION`, newest first;
  read by `chosko-llm upgrade` to print what a pull changed.

## Files

| File | Covers |
| --- | --- |
| [cli-entry.md](./cli-entry.md) | Bootstrap (`install.sh`/`uninstall.sh`), `bin/chosko-llm` proxy dispatch subcommands, daily auto-upgrade hook. |
| [shared-lib.md](./shared-lib.md) | `scripts/lib.sh` core — logging, colors, version, auto-upgrade state, the assign-vs-print helper convention; hub for the rest of `lib.sh`. Sourced by every subcommand. |
| [shared-lib-scope.md](./shared-lib-scope.md) | `scripts/lib.sh` scope and path resolution — `--local` / `--global` scope, the kinds each scope supports, the claude-md target, every source, installed and export path helper. |
| [shared-lib-frontmatter.md](./shared-lib-frontmatter.md) | `scripts/lib.sh` frontmatter parsing and source validation — the `_FM_AWK` scanner, the readers built on it, `require_versioned_source`. |
| [shared-lib-kinds.md](./shared-lib-kinds.md) | `scripts/lib.sh` feature-kind helpers — claude-md sections, statusline and hook prompts, kind resolution (`resolve_feature`); hub for the `replaces:` and `requires:` helpers. |
| [shared-lib-migration.md](./shared-lib-migration.md) | `scripts/lib.sh` kind migration (`replaces:`) — removing the stale artifact when a feature changes kind, the `replaces:` index `ls`, `show` and `update --all` probe, `split_kind_spec`. |
| [shared-lib-requires.md](./shared-lib-requires.md) | `scripts/lib.sh` dependencies (`requires:`) — splitting, trimming and validating a feature's `requires:` value for `cmd-add`, `cmd-rm` and `cmd-ls`. |
| [shared-lib-changelog.md](./shared-lib-changelog.md) | `scripts/lib.sh` changelog readout — `CHANGELOG.md` parser contract, shared section renderer, `upgrade` range printer, `changelog --since` classification and selection. |
| [cmd-ls.md](./cmd-ls.md) | `scripts/cmd-ls.sh` — list features w/ installed/latest versions and a REQUIRES column, one name-ordered table; `--installed` / `--available` filters; kind-migration statuses; TTY footer hints; hub for its rendering internals. |
| [cmd-ls-render.md](./cmd-ls-render.md) | `scripts/cmd-ls.sh` rendering — `list_all`'s three passes and name-ordered emit, the fork budget, the one batched frontmatter read, the in-memory CLAUDE.md scan. |
| [cmd-show.md](./cmd-show.md) | `scripts/cmd-show.sh` — inspect one feature (versions, status, description, the body's leading `#` header that carries the flags, body/diff); handle local-only. |
| [cmd-add.md](./cmd-add.md) | `scripts/cmd-add.sh` — install feature (command/skill/claude-md/statusline/hook, or `--all`) into `$CLAUDE_HOME`; refuse if already installed; install anything the source declares in `requires:` first; hub for per-name isolation. |
| [cmd-add-isolation.md](./cmd-add-isolation.md) | `scripts/cmd-add.sh` per-name isolation — the `add_one` subshell that keeps one failing name from stopping a multi-name install. |
| [cmd-rm.md](./cmd-rm.md) | `scripts/cmd-rm.sh` — uninstall feature (command/skill/claude-md/statusline/hook) from `$CLAUDE_HOME`; dependents guard + `--force`. |
| [cmd-update.md](./cmd-update.md) | `scripts/cmd-update.sh` — re-copy feature (or version-aware `--all`); install if missing. |
| [cmd-upgrade.md](./cmd-upgrade.md) | `scripts/cmd-upgrade.sh` — `git pull` managed clone, refresh proxy; `--enable-auto`/`--disable-auto` toggle. |
| [cmd-changelog.md](./cmd-changelog.md) | `scripts/cmd-changelog.sh` — read-only view onto the clone's `CHANGELOG.md`; no-arg opens it in an editor, `--since <version\|date\|duration>` prints a range to stdout, `--print` forces unpaged plain output. |
| [cmd-channel.md](./cmd-channel.md) | `scripts/cmd-channel.sh` — point managed clone at branch ('channel') to test unmerged work; no-arg show current, `--list` show available, `<branch>` switch + refresh proxy. |
| [cmd-export.md](./cmd-export.md) | `scripts/cmd-export.sh` — package repo's Claude config into Markdown file or zip via `select_export_files`; output dir from `export_dir_path`. |
| [cmd-help.md](./cmd-help.md) | `scripts/cmd-help.sh` — print `docs/cli-help.txt` or fallback help. |
| [features.md](./features.md) | Shipped-artifact kinds under `commands/`, `skills/`, `claude-md/`, `statusline/`, `hooks/`, incl. the hook-only `event:` / `matcher:` keys; why this repo's `.claude/skills/` is not a kind; hub for the frontmatter contract, the three feature families and every other shipped feature. |
| [feature-contract.md](./feature-contract.md) | The per-feature contract — frontmatter block incl. optional `replaces:` / `requires:`; the `description` contract (short what+when, flags in the body `#` header) and the loading-control keys `disable-model-invocation:` / `paths:` with the eleven hidden features that carry the first; supporting-file conventions and the home-path guard (`scripts/check-home-paths.sh`); cross-refs to authoring guide. |
| [setup-commands.md](./setup-commands.md) | Project-initialization commands — `project-setup`, `domain-setup`. |
| [context-skills.md](./context-skills.md) | The navigation-context skills — `context-build`, `context-update`, `context-convert`. |
| [session-handoff.md](./session-handoff.md) | The session-handoff pair — `session-save`, `session-resume`. |
| [refactor-doc-consolidate.md](./refactor-doc-consolidate.md) | Behaviour-preserving rewrite tools — `refactor-codebase`, `refactor-tests`, `doc-consolidate`. |
| [claude-md-hook-statusline.md](./claude-md-hook-statusline.md) | The shipped claude-md artifacts (`tool-usage-policy`, `editing-discipline`, `git-commit-style`), the `remote-session-protocol` hook and the `session-statusline` statusline. |
| [task-suite.md](./task-suite.md) | The `task-*` suite's family-wide contract and domain pointers; hub for `task-setup`, `task-add`, `task-list`, `task-clean`, `task-implement`, `task-review`, `task-iterate` and `task-engine`. |
| [task-backlog.md](./task-backlog.md) | Backlog maintenance — `task-setup`, `task-clean`, `task-list`. |
| [interaction-engine.md](./interaction-engine.md) | `interaction-engine`, the non-invocable reference engine for the interaction policy every interactive feature reads — `policy.md` (attended/unattended, flags, precedence), `gates.md` (the three gate classes), `messages.md` (output and question rules). |
| [task-engine.md](./task-engine.md) | `task-engine`, the non-invocable reference engine the `task-*` suite reads, and its `references/` files. |
| [task-add.md](./task-add.md) | `task-add`, the backlog's authoring command. |
| [task-implement.md](./task-implement.md) | `task-implement` — common path, supporting files, unattended parking, body reading, human-in-the-loop tasks, testing policy, `[STALE]` handling, `Preconditions:`. |
| [task-implement-delegation.md](./task-implement-delegation.md) | `task-implement` — delegated runs (`--agents`), per-task commits, the feature-completion proposal, the closing report. |
| [task-implement-review.md](./task-implement-review.md) | `task-implement --review` — the review/iterate loop, its flags, the reviewer spawn. |
| [task-review-iterate.md](./task-review-iterate.md) | The review pair — `task-review`, `task-iterate`. |
| [runbook-suite.md](./runbook-suite.md) | The runbook suite's family-wide contract and domain pointers; hub for `runbook-run`, `runbook-create`, `runbook-list`, `runbook-describe`, `runbook-clean`, `runbook-prune`, `runbook-suggest`, `follow-ups` and `follow-ups-resolve`. |
| [runbook-run.md](./runbook-run.md) | `runbook-run` — the runbook store, the skill's reference files and dependencies. |
| [runbook-run-loop.md](./runbook-run-loop.md) | `runbook-run` — execution policy, parked-question handles, runbook ids, the step loop and its result cases, the end branch, the spawn relay, resolve. |
| [runbook-run-contracts.md](./runbook-run-contracts.md) | `runbook-run` — chat contract, closing report, commit convention, Stop-hook reply, hard contracts, range bounds, depth budget. |
| [runbook-create.md](./runbook-create.md) | `runbook-create`, the runbook author. |
| [runbook-readers.md](./runbook-readers.md) | The runbook read side — `runbook-list`, `runbook-describe`. |
| [runbook-pruners.md](./runbook-pruners.md) | The runbook pruners — `runbook-clean`, `runbook-prune`. |
| [follow-ups.md](./follow-ups.md) | `runbook-suggest`, one of the two artifacts nobody invokes; `follow-ups` and `follow-ups-resolve`. |
| [pipeline.md](./pipeline.md) | The product pipeline's family-wide contract; `pipeline-engine`, the non-invocable reference engine, and the routing guard; `pipeline-suggest`, the other artifact nobody invokes; hub for the stage, reader and revision files. |
| [product-design.md](./product-design.md) | Stage 1, `product-design`, and the vendored `claude-council` its council gate delegates to. |
| [pipeline-planning.md](./pipeline-planning.md) | The two planning stages — `product-roadmap`, `production-plan`. |
| [architect.md](./architect.md) | Stage 3, `architect`. |
| [pipeline-readers.md](./pipeline-readers.md) | The pipeline's read-only reporters — `production-status`, `pipeline-check`. |
| [pipeline-revise.md](./pipeline-revise.md) | `pipeline-revise`, the one revision surface — its change-set argument, its four branch files, classification, impact walk, lint bracket. |
| [pipeline-revise-plan.md](./pipeline-revise-plan.md) | `pipeline-revise` — merge and order, plan-time decisions, tiers, the one gate and its reply grammar, actuation and the branch owner sequences, the closing follow-up gate, failure contract, commit. |

## Domain

Product and rules knowledge — what the product is, why it is built this way — lives in its own layer and is indexed there, not here: [../domain/INDEX.md](../domain/INDEX.md).

## Conventions

- `Layout: flat` under the title declares this layer's shape: one index, every context file beside it — about fifty files, each family grouped behind a hub file that lists the rest of the family in its § Overview. Read the marker, never infer the layout. Restructuring is `/context-convert`'s job, not a hand edit.
- Source references use repo-root-relative paths + fully qualified names, e.g. `scripts/lib.sh::resolve_feature`.
- Cross-references to sibling context files use relative links (`./other.md`).
- Cross-references to canonical docs use `../../`-prefixed paths.
