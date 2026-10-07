# Setup sync

Brings `/project-setup`, `/task-setup` and `/domain-setup` back in line with
the features they set up, and adds a guard that keeps them there. Every
per-project fact a feature reads — a `CLAUDE.md` line and its values, a
claude-md section, a VCS operation — is declared once, in the frontmatter of
the feature that states its rule, and a repo-local script fails whenever a
declared fact is not offered by setup.

## Purpose

The setup commands have drifted from the features they set up: the testing policy is asked only on Unity projects
and offers two of its three values; `/task-setup`'s no-test-suite answer
writes no marker; the `## VCS` mapping template lacks the operations later
features run; `/task-setup` and `/domain-setup` carry their own copies of
schemas that moved on; claude-md sections a feature hard-depends on are never
offered; and dead citations and history lines remain. Each drift is cheap to
fix and silent until a run trips on it in a project set up before the
feature it concerns.

The recurrence is the real problem. Nothing ties a feature that starts
reading a new per-project fact to the setup that should offer it, so the
drift comes back with the next feature. This feature fixes the drift and
makes the tie mechanical.

## Scope and non-goals

In scope: the listed fixes to the three setup commands; replacing their
schema copies with citations; the `project-policy:` frontmatter key and its
declarations; the parser tolerance; the `scripts/check-setup.sh` guard and
its registration in `CLAUDE.md`.

Deliberately out:

- **Re-running setup on existing projects.** Nothing migrates a project set
  up earlier; the user re-runs `/project-setup` or adds the line by hand.
- **A setup-time validator.** The guard runs at authoring time in this repo,
  like `check-routing.sh`; no shipped feature checks a project's `CLAUDE.md`
  against the declarations.
- **Semantic checks.** The guard proves a declared fact is *offered*, not
  that setup explains it well or writes it in the right place.
- **Statuslines.** Global-only and not a project fact; setup never offers
  them and the guard does not ask it to.
- **The Unity removal itself** — [unity-mcp-removal](./unity-mcp-removal.md)
  owns deleting `/project-setup`'s Unity MCP offer.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: markdown
features, a minimal awk frontmatter parser in `scripts/lib.sh`, and
repo-local bash guards beside `check-routing.sh`, `check-home-paths.sh` and
`check-changelog.sh`. No new dependency.

### The drift fixes

`/project-setup` (see `.claude/context/setup-commands.md`):

- **Testing policy on every project.** The test-suite question moves out of
  the Unity-only subsection and is asked everywhere, offering all three
  values — `skip-tests`, `full-tdd`, `skip-tests-unattended` — with the
  marker line written into `CLAUDE.md`. The Unity subsection keeps only the
  dirty-tree noise section.
- **Interaction policy.** Offers the `Interaction policy: attended|unattended`
  line ([interaction-policy](./interaction-policy.md)), `attended` the
  suggested answer, the line omitted when the user keeps the default.
- **VCS mapping rows.** The `## VCS` template gains rows for `git mv`,
  `git rm`, `git show` and `git branch`, beside the existing ones.
- **Non-git warning.** When it injects a `## VCS` section it says in one
  line that a non-git VCS disables parking: `--unattended` is refused by the
  parking features and an unattended run stops at a question instead of
  parking.
- **Claude-md sections and hooks.** Offers each shipped claude-md section —
  `editing-discipline` (named as required by `/doc-consolidate`, which
  hard-stops without it), `git-commit-style`, `tool-usage-policy` — and the
  `remote-session-protocol` hook, each installed with `chosko-llm add
  --local`.
- **Next steps.** The final report suggests the pipeline's entry points,
  `/product-design` and `/architect`, when the domain layer was set up.
- **No history line.** The "it was a command before v0.46.0" aside
  goes.

`/task-setup` (see `.claude/context/task-backlog.md`):

- The no-test-suite option writes the testing-policy marker.
- The dead "LOCATING THE TEST RUNNER" citation points at "RESOLVING THE
  TEST RUNNER".
- The index format gains `Target:`.
- Its task-add references cite relative paths to the installed `/task-add`,
  not repo paths.

`/domain-setup`: the `FEATURES.md` entry's `Source:` line gains the optional
` (<milestone-slug>)` suffix.

### Schema copies become citations

`/task-setup`'s copies of the index and body formats are replaced by
citations of their owner (`task-engine`'s `resolution.md` for the index and
`/task-add` for the body); `/domain-setup`'s copy of the `FEATURES.md` entry
is replaced by a citation of `/architect`'s `feature-doc-template.md`. Each
citation is relative, per the home-path guard, and each command declares
the `requires:` that makes it resolvable. With the copies gone, the
`Target:` and `Source:` fixes above land in the owners, where they already
hold, and the setup commands carry no schema text to drift.

### The `project-policy:` key

A new optional frontmatter key on any feature that **states the rule** for
a per-project fact — not on every feature that consumes it. Its value is a
comma-separated list of specs, each `<kind>:<value>`:

- `line:<marker text>=<v1>|<v2>|…` — a `CLAUDE.md` line and its allowed
  values, the marker text without its trailing colon. Example:
  `line:Testing policy for /task-implement=skip-tests|full-tdd|skip-tests-unattended`.
- `section:<claude-md feature>` — a claude-md section the feature reads or
  requires, e.g. `section:editing-discipline`.
- `vcs:<op>` — a git operation the feature runs and a `## VCS` mapping must
  translate, e.g. `vcs:mv`.

Declared where the rule lives: the interaction-policy line by
`interaction-engine`, the testing-policy line by `task-engine`, which holds
the testing-policy resolution, `section:editing-discipline` by `/doc-consolidate`, and each
`vcs:` op by the features whose own bodies run it (`git mv` and `git show`
in `/task-clean`, `git branch` in task parking, and so on). The full set of
declarations is settled at planning time against the bodies as they then
stand.

The CLI parser tolerates the key: `_FM_AWK` already drops unknown keys, and
the key joins its allowlist so `read_frontmatter_field` can return it to the
guard (see `.claude/context/shared-lib-frontmatter.md`). No CLI verb acts on
it; `cmd-add` and `cmd-update` are unaffected.

### The guard, `scripts/check-setup.sh`

Repo-local and authoring-time only, modelled on `check-routing.sh`: sources
`lib.sh`, `set -euo pipefail`, silent on success, non-zero naming each
violation on its own line. It fails when:

1. a declared `line:` spec is not offered by setup — the marker text, or
   any one of its allowed values, does not appear in the setup bodies
   (`/project-setup`, `/task-setup`, `/domain-setup` taken together);
2. a declared `vcs:` op has no `git <op>` row in `/project-setup`'s
   `## VCS` mapping template;
3. a declared `section:` names no shipped claude-md feature, or is not
   offered by `/project-setup`;
4. a shipped claude-md or hook feature is not offered by `/project-setup`,
   whether or not anything declares it.

It proves presence, never wording. `CLAUDE.md` § Versioning registers it
beside the other guards: run it after adding or changing a `project-policy:`
declaration, adding a claude-md or hook feature, or editing a setup command.
Guard only — it bumps nothing itself.

## Data and state

- **`project-policy:`** — frontmatter, on the declaring feature only.
  Source of truth for which per-project facts exist.
- **Setup bodies** — the offer, matched by text.
- **Projects' `CLAUDE.md`** — written by setup, read by the features; this
  feature changes what setup offers, not how features read it.

No state file, no index of declarations: the guard derives everything from
the frontmatter and the bodies on each run.

## Interfaces and contracts

```
project-policy: line:<marker>=<v1>|<v2>, section:<claude-md>, vcs:<op>
./scripts/check-setup.sh      silent on success; non-zero, one line per violation
```

Failure contract: a malformed spec (no `kind:` prefix, an unknown kind, a
`line:` with no `=`) is itself a violation naming the file. A feature
carrying the key installs exactly as before.

## Dependencies

- [interaction-policy](./interaction-policy.md) — the `Interaction policy`
  line setup offers and `interaction-engine` declares.
- [unattended-parking](./unattended-parking.md) — the non-git refusal the
  setup warning names, and the testing-policy value `skip-tests-unattended`.
- [quick-implement](./quick-implement.md) — moves the testing-policy
  resolution into `task-engine`, which then carries its declaration.
- [unity-mcp-removal](./unity-mcp-removal.md) — edits the same
  `/project-setup` passages.
- [shared-phase-engine](./shared-phase-engine.md) — the `requires:` field
  the setup commands use for their new citations.
- [pipeline-engine](./pipeline-engine.md) — `check-routing.sh`, the guard's
  model.
