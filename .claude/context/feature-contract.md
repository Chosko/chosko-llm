# Features: frontmatter and authoring contract

## Overview

Covers the contract every shipped feature follows, whatever its kind: the
frontmatter block, the `description` contract, the optional keys, and the
authoring patterns the CLI and the guards rely on. Feature kinds and the
inventory of shipped features: [features.md](./features.md).

## Public API (per-feature contract)

Every feature file requires complete frontmatter block:
```yaml
---
name: <kebab-case>          # MUST match filename / folder name
version: <semver>           # required; install refuses without it
type: command | skill | claude-md | statusline | hook
description: <one line>
replaces: command:<name>     # OPTIONAL, only on a kind change; see below
requires: skill:<name>       # OPTIONAL, any kind; comma-separated; see below
project-policy: vcs:<op>     # OPTIONAL, any kind; comma-separated; see below
event: PreToolUse            # hook kind ONLY; required there
matcher: AskUserQuestion     # hook kind ONLY; optional, narrows event to one tool
disable-model-invocation: true   # OPTIONAL loading-control key; see below
paths:                       # OPTIONAL, skills only; see below
  - "Assets/**"
---
```

**`description` is short by contract** — `../../docs/authoring-guide.md`
§ The `description` contract. Flags,
argument grammar, refusals, read-only contracts and commit/push defaults
live in the body's leading `#` header (`# /name`, summary, `# Usage:`,
`# Examples:`), which loads only on invocation and which `cmd-show` prints
under the description ([cmd-show.md](./cmd-show.md)). Every shipped body has
one; the two engines' is a two-line "read by path; not invoked" note.

**Loading-control keys** — three Claude Code frontmatter keys this repo may
use; `parse_frontmatter` ignores unknown keys, so they pass through
`add` / `update` untouched and are never a rejection path:
- `disable-model-invocation: true` (commands, skills) — description kept
  out of the model's context; only the user invokes it, by typing
  `/<name>`; stays listed and typeable. **Carried by eleven features:** the
  three reference libraries `skills/task-engine/`, `skills/pipeline-engine/`,
  `skills/interaction-engine/`, the authoring skill `skills/doc-consolidate/`,
  and seven wizards / housekeeping commands never worth suggesting
  unprompted — `commands/project-setup.md`, `commands/task-setup.md`,
  `commands/domain-setup.md`, `commands/refactor-codebase.md`, `commands/refactor-tests.md`,
  `commands/runbook-prune.md`, `commands/runbook-clean.md`. `task-review` /
  `task-iterate` deliberately NOT hidden — `/task-implement --review` spawns
  them by name.
- `user-invocable: false` (commands, skills) — hidden from the `/` menu;
  model-only. Carried by nothing.
- `paths:` (skills only) — loads only when files matching its globs are in
  play. Carried by nothing.

`replaces:` is an optional key from the kind-migration path: set it when
a feature changes kind (`commands/<n>.md` rewritten as `skills/<n>/SKILL.md`),
so the install verbs remove the superseded artifact instead of leaving two
definitions of one slash command — which verbs, and when:
[shared-lib-migration.md](./shared-lib-migration.md) § Public API › Kind migration. Live
examples: `skills/context-build/SKILL.md`, `skills/context-update/SKILL.md` and
`skills/task-clean/SKILL.md`.
Drop the key once the migration has propagated.

`requires:` is another optional key, valid on every kind: a comma-separated
list of kind-prefixed specs naming features whose files this one reads at run
time. Install and removal semantics: [shared-lib-requires.md](./shared-lib-requires.md) §
Public API › Dependencies (`requires:`); the `--force` override:
[cmd-rm.md](./cmd-rm.md) § Public API. Live examples: `commands/task-add.md`,
`commands/task-list.md`, `skills/task-clean/SKILL.md` and
`skills/task-implement/SKILL.md`, all declaring `requires: skill:task-engine`;
and `commands/pipeline-check.md`, declaring `requires: skill:pipeline-engine`.
`skills/pipeline-revise/SKILL.md` declares seven at once.
Unlike `replaces:`, it is permanent — the dependency does not "propagate" and
the key is dropped only when the reference is.

`project-policy:` is the third optional key, valid on every kind and carried
only by the feature that **states the rule** for a per-project fact: a
comma-separated list of `line:<marker>=<v1>|<v2>` (a `CLAUDE.md` line and its
values), `section:<claude-md feature>` and `vcs:<op>` (a git operation a
`## VCS` mapping must translate) specs. No CLI verb acts on it. Declared by
`skills/interaction-engine/` (the interaction-policy line),
`skills/task-implement/` (the testing-policy line), `skills/doc-consolidate/`
(`section:editing-discipline`), and for `vcs:` ops by `skills/task-engine/`
(the commit and tree protocol's ops plus its own), `skills/task-clean/`,
`skills/context-convert/`, `commands/session-save.md`, `skills/task-review/`
and `skills/task-iterate/`. `scripts/check-setup.sh` is its guard —
repo-local, silent on success, one line per violation: a malformed spec, a
declared fact the three setup commands do not offer, or a shipped claude-md or
hook feature `/project-setup` does not name
(`../../docs/authoring-guide.md` § The setup guard).

See `../../docs/authoring-guide.md` for canonical spec, including
semver bump rules, commit-control convention, three places task
status vocabulary must agree, and rule that multi-session skill keeps
its state in versioned project document.

## Internal patterns

- **Filename = folder name = `name` field.** Every verb resolves by
  filename, never by `name` ([cmd-ls.md](./cmd-ls.md) § Internal patterns),
  so a mismatched `name` is silently ignored; the authoring guide flags this
  as a common mistake.
- **Skills are folders, not single files.** Bare `skills/foo.md` is
  ignored by every script. See `feature_kind` in
  [shared-lib-kinds.md](./shared-lib-kinds.md).
- **Supporting files are read on demand.** A skill folder's non-`SKILL.md`
  files exist so the common path stays cheap: `SKILL.md` names the branch
  and the file to read when it fires, and nothing else reads them.
  `skills/task-implement/` (seven), `skills/product-design/` (six),
  `skills/architect/` (seven), `skills/pipeline-revise/` (four, one per
  branch), `skills/task-review/remote-diffs.md`,
  `skills/context-build/nested.md` and
  `skills/context-update/nested.md` (one each) all follow this.
  `skills/task-iterate/` has none, and says so in its body so nobody goes
  looking for one. Whole
  folder is copied on install regardless — the saving is tokens per run,
  not bytes on disk.
- **`skills/task-engine/references/` and `skills/pipeline-engine/references/`
  are the other thing entirely.** Those files are read by OTHER features, not by their own `SKILL.md`, which is why
  the skill needs `requires:` and a plain supporting file does not. A skill's
  own supporting file is private to it and needs no declaration; a file
  another feature reads is a cross-feature dependency and must be declared, or
  it installs into a dangling path. See
  `../../docs/authoring-guide.md` § "Keeping the two `council-gate.md` copies
  in step" for the case where this does NOT apply (an optional dependency,
  which `requires:` cannot express).
- **A shipped body cites another shipped file by a path relative to
  itself**, never by an absolute install home — `../../CLAUDE.md`
  § Versioning and `../../docs/authoring-guide.md` § `requires:`.
- **`scripts/check-home-paths.sh` guards that** — its contract is
  `../../CLAUDE.md` § Versioning and `../../docs/authoring-guide.md` § The
  home-path guard. Two passes: `grep` one line at a time, then an awk two-line window that
  catches a citation wrapped across a line break (continuation line's
  blockquote marker and indentation stripped), reported against the line the
  literal starts on. The pattern reaches that awk through the environment
  (`ENVIRON`), never `-v`, whose escape processing strips the regex's
  backslashes and leaves `$` an end-of-line anchor. Asking whether an
  optional feature is installed goes by name, never by path —
  `../../docs/authoring-guide.md` § "Asking whether a feature is installed:
  name it"; for the one place a home is derived, see `probes.md` § *Which
  install home — both of them*.
  No CI and no pre-commit hook, so `CLAUDE.md` § Versioning plus each task's
  acceptance criteria are the whole enforcement mechanism.
- **No state file.** Versions live in frontmatter; what's installed is
  whatever exists under `$CLAUDE_HOME`. See `../../CLAUDE.md` hard rules.

## Domain dependencies

- None beyond [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds and the shipped inventory this
  contract applies to; § Cross-references for the verbs and libraries.

## When to read the source

- None beyond [features.md](./features.md) § When to read the source.
