# Shared phase engine

A refactor of the `task-*` suite. The phase logic each command re-states in its
own words moves into one engine file that they all reference, leaving each
command or skill short enough to read in a sitting. Because a shared file can
only ship inside a skill folder, and because a feature that depends on another
feature is not something `chosko-llm` can currently express, the refactor
carries a small CLI change with it.

## Purpose

`commands/task-add.md` is 879 lines. `skills/task-implement/SKILL.md` is 708.
`task-clean` is 295, `task-list` 240, `task-enrich` 184. Much of that bulk is
the same material stated five times: how a task is resolved from `TASKS.md`,
what the status vocabulary means, how `Target:` gates delegation, what `[STALE]`
means and how it is detected, what the dirty-tree protocol is, how commits and
pushes are gated by `--no-commit` / `--no-push`.

Five copies of a rule is five things to update when the rule changes, and four
opportunities to forget. It is also, at these sizes, a direct context cost every
time one of them loads.

ECC's `orch-pipeline` is the pattern worth taking, and only the pattern: five
operation skills of about forty-five lines each, carrying nothing but three
settings, over one engine file that owns every phase. Nothing about ECC's
actual phases, gates, or TDD assumptions applies here.

## Scope and non-goals

In scope: extracting the shared material into an engine, deciding where the
engine lives so it can be referenced at runtime, the `requires:` frontmatter
field and the `cmd-add` / `cmd-update` change that makes cross-feature
references safe, and the order the suite is migrated in.

Deliberately out:

- **Changing any behaviour.** This is a pure restructuring. Every command keeps
  its usage lines, flags, prompts, and output. A run before and after the
  refactor produces the same result. Behaviour changes ride separately, in
  [task-peer-review](./task-peer-review.md) and
  [task-implement-launcher](./task-implement-launcher.md).
- **Adopting ECC's phases.** No size classifier, no research phase, no TDD
  mandate, no approval gates beyond the ones this suite already has.
- **A general dependency resolver.** `requires:` is a flat list, resolved one
  level deep, with no version constraints and no transitive resolution. The
  moment it needs a solver it has outgrown this repo's rules.
- **Refactoring other suites in this slice.** `context-*`, `product-*` and
  `refactor-*` are plausible later candidates. Prove the pattern on `task-*`
  first.

## Architecture

### Why the engine must live in a skill

`cmd-add` installs a skill with `cp -R` of the whole folder, so any supporting
file beside a `SKILL.md` ships with it. A command is a single `.md` file and can
carry nothing. The engine therefore lives in a skill folder, and the other
features reach it by path.

That path is stable and already has precedent in this repo: the vendored
`claude-council` skill opens by naming its own install location as
`${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/`. The same form works
here, and it respects the `CLAUDE_HOME` override rule rather than hardcoding
`~/.claude`.

New feature `skills/task-engine/`:

```
skills/task-engine/
  SKILL.md              what the engine is; not directly invocable
  references/
    resolution.md       TASKS.md parsing, `all` / `next` / explicit lists
    status.md           the status vocabulary and its transitions
    targets.md          Target: values and the delegation guard
    stale.md            [STALE] detection against FEATURES.md
    tree.md             the dirty-tree protocol
    commit.md           commit/push gating, --no-commit / --no-push
```

Each reference file is the single authority for its rule. The consuming
features cite it by path and state only what they do differently.

`SKILL.md` exists because `cmd-add` requires it — it needs versioned
frontmatter to be installable — and it carries the map of which reference file
covers what. It is not a skill the user invokes, which its `description` says
plainly so it does not surface as a suggestion.

### What the consumers become

Each `task-*` feature keeps its own front matter, usage lines, and the logic
genuinely unique to it, and replaces its restatements with a reference:

```markdown
Task resolution follows
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`.
This command additionally skips tasks whose status is terminal.
```

Rough targets, to be confirmed as the extraction proceeds: `task-add` from 879
lines to under 400, `task-implement` from 708 to under 350, the three smaller
commands to under 150 each. The measure of success is not the line count but
that a rule appears once.

### The `requires:` field

A command that reads a file inside another installed feature breaks if that
feature is not installed. Today nothing prevents `chosko-llm add
command:task-add` without `skill:task-engine`, and the failure would surface as
an agent following a dangling path mid-run.

New optional frontmatter key, on any feature kind:

```yaml
requires: skill:task-engine
```

Comma-separated for more than one. `parse_frontmatter` splits on the first
colon and returns whatever keys it finds, so it needs no change at all — the
value `skill:task-engine` survives that split intact and `read_frontmatter_field`
retrieves it.

The CLI change is confined to two scripts:

- **`cmd-add`** — after resolving a feature, read `requires:`; install any named
  feature not already installed, reporting each as a dependency install; then
  install the requested feature. One level deep only. A missing dependency in
  the managed clone is an error that aborts that feature, consistent with
  existing best-effort multi-feature semantics.
- **`cmd-rm`** — before removing a feature, check whether any *installed*
  feature `requires:` it. If so, name them and refuse unless `--force` is
  passed. Removing an engine out from under five consumers silently is the
  failure this guards.

`cmd-update` needs no change: it re-copies what is installed, and a dependency
already installed is already in that set. `cmd-ls` gains nothing; the field is
visible through `cmd-show`, which prints frontmatter already.

This stays within the repo's rules: no new dependency, no lockfile, no state
file. The requirement is declared in frontmatter and resolved against the
filesystem at install time, which is exactly how every other fact in this
system is stored.

### Migration order

1. Land the `requires:` field and the `cmd-add` / `cmd-rm` changes, with no
   feature using it yet. Inert on its own, and independently verifiable.
2. Create `skills/task-engine/` with the reference files, extracted verbatim
   from the current bodies — no rewording during extraction, so any behaviour
   change is a visible diff rather than a paraphrase.
3. Migrate one consumer, `task-list` — the smallest, and read-only, so a
   regression is obvious and harmless.
4. Migrate the rest: `task-clean`, `task-add`, `task-implement` last because it
   is the one changing for other reasons.

Steps 3 and 4 each bump the migrated feature's `version:` and root `VERSION`.

## Data and state

None. The engine is prose read at runtime, the same as every other feature body.
The `requires:` field is frontmatter, resolved at install time and never
persisted anywhere else.

## Interfaces and contracts

```yaml
requires: skill:task-engine            # new optional frontmatter key, any kind
requires: skill:task-engine, command:x # comma-separated
```

```
chosko-llm add command:task-add        # installs skill:task-engine first
chosko-llm rm skill:task-engine        # refuses; names the dependents
chosko-llm rm skill:task-engine --force
```

Hard contracts:

- The refactor changes no observable behaviour of any `task-*` feature.
- Every rule extracted appears in exactly one reference file.
- Dependency resolution is one level deep, unversioned, and non-transitive.
- Shipped bodies reference `${CLAUDE_HOME:-...}` paths, never `~/.claude`, and
  never `docs/` — that rule is unchanged and this feature must not weaken it.

## Dependencies

- **[task-implement-launcher](./task-implement-launcher.md)** and
  **[task-peer-review](./task-peer-review.md)** both edit
  `skills/task-implement/SKILL.md`. Land both before migrating that file, or
  the refactor and the behaviour changes collide in the largest body in the
  repo.
- The dual-LLM lane deletion touches the same file and should go first, so the
  extraction does not carry dead material into the engine.

## Open questions

- **Does `cmd-add --all` need dependency handling?** It installs everything, so
  every dependency is satisfied incidentally. Ordering could still matter if a
  consumer is copied before its engine; probably harmless since resolution
  happens at run time, not install time, but worth a deliberate decision.
- **Should `requires:` be validated at authoring time?** A typo produces a
  dependency that cannot be resolved, caught only on install. A cheap lint pass
  would catch it earlier. Related to the repo-local validation work in
  [repo-local-audits](./repo-local-audits.md).
- **Is `task-engine` the right granularity?** One engine for the whole suite may
  prove too coarse — `resolution.md` and `commit.md` are useful to features
  outside `task-*`, and a future `refactor-*` migration might want them without
  taking `stale.md`. Splitting later is cheap; starting split is speculative.
- **Does a non-invocable skill confuse the harness?** `task-engine` is a skill
  that should never be suggested. Its `description` can say so, but whether that
  is enough to keep it out of skill selection needs checking against real
  behaviour before the suite depends on it.
