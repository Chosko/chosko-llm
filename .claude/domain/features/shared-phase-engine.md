# Shared phase engine

A refactor of the `task-*` suite. The phase logic each command re-states in its
own words moves into one engine file that they all reference, leaving each
command or skill short enough to read in a sitting. Because a shared file can
only ship inside a skill folder, and because a feature that depends on another
feature is not something `chosko-llm` can currently express, the refactor
carries a small CLI change with it.

## Purpose

Four features carry the backlog's rules. When the extraction began,
`commands/task-add.md` was 834 lines, `skills/task-implement/SKILL.md` 773
(plus an 88-line `dirty-tree.md` beside it), `task-clean` 295 and `task-list`
240. Much of that bulk is the same material stated four times: how a task is
resolved from `TASKS.md`, what the status vocabulary means, how `Target:`
gates delegation, what `[STALE]` means and how it is detected, what the
dirty-tree protocol is, how commits and pushes are gated by `--no-commit` /
`--no-push`.

(An earlier draft of this document counted `task-enrich` as a fifth consumer.
It was deleted with the dual-LLM lane before the extraction started, so the
suite this feature restructures is four features, not five.)

Four copies of a rule is four things to update when the rule changes, and three
opportunities to forget. It is also, at these sizes, a direct context cost every
time one of them loads.

ECC's `orch-pipeline` is the pattern worth taking, and only the pattern: five
operation skills of about forty-five lines each, carrying nothing but three
settings, over one engine file that owns every phase. Nothing about ECC's
actual phases, gates, or TDD assumptions applies here.

## Scope and non-goals

In scope: extracting the shared material into an engine, deciding where the
engine lives so it can be referenced at runtime, the `requires:` frontmatter
field and the `cmd-add` / `cmd-rm` change that makes cross-feature
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

What the migration actually achieved, against the rough targets this document
set before it started:

| Feature | Before | After | Target | Met |
| --- | --- | --- | --- | --- |
| `task-add` | 834 | 731 | under 400 | no |
| `task-implement` | 773 + 88 (`dirty-tree.md`) | 708 | under 350 | no |
| `task-clean` | 295 | 228 | under 150 | no |
| `task-list` | 240 | 229 | under 150 | no |

Every target was missed, and the targets were the wrong measure. They were set
by dividing the total by the number of consumers, which assumes the bulk is
shared; it is not. What each body carries that no other body carries — a
`/task-add` phase script, `/task-implement`'s seven-step workflow and review
loop, `/task-list`'s rendering rules — is protected verbatim by the
behaviour-preservation contract at the top of this document, and it turned out
to be most of the length. The engine is 909 lines (848 across six reference
files, 61 in `SKILL.md`) and the duplication it absorbed is gone; treat the
figures above as a record of that, not as targets that were nearly hit.

The measure of success is not the line count but that a rule appears once, and
by that measure the extraction succeeded. Read the numbers as evidence about
where the bulk actually was.

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
colon, so the **value** needs no special handling — `skill:task-engine`
survives that split intact and `read_frontmatter_field` retrieves it. The
**key** did cost one edit: the parser emits only keys on an explicit
allowlist, so `requires` had to be added to that condition beside `name`,
`version`, `type`, `description`, `replaces`, `event` and `matcher`. One more
clause in one awk condition; no parser rewrite. (An earlier draft of this
document said it needed no change at all, which was wrong in exactly that
one way: a key absent from the allowlist is silently dropped.)

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

## Resolved during implementation

- **Does `cmd-add --all` need dependency handling? No, and it never will.**
  `--all` installs every feature in the managed clone, so every declared
  requirement is satisfied incidentally. The ordering worry was unfounded for
  the reason suspected: a feature resolves its requirement's path when an
  agent *runs* it, not when it is installed, so copy order within the run
  cannot matter. `cmd-add.sh` carries a comment above the `--all` branch
  saying so, to stop a later reader from adding resolution there.

## Open questions

- **Should `requires:` be validated at authoring time?** A typo produces a
  dependency that cannot be resolved, caught only on install. A cheap lint pass
  would catch it earlier. Related to the repo-local validation work in
  [repo-local-audits](./repo-local-audits.md). Still open — the implementation
  hardened the install-time path instead (a `requires:` entry with no kind
  prefix is a hard `die`, not a silent skip), which narrows the blast radius
  without moving the check earlier.
- **Is `task-engine` the right granularity?** One engine for the whole suite may
  prove too coarse — `resolution.md` and `commit.md` are useful to features
  outside `task-*`, and a future `refactor-*` migration might want them without
  taking `stale.md`. Splitting later is cheap; starting split is speculative.
  Still open; nothing in the migration decided it either way.
- **Does a non-invocable skill confuse the harness?** Still open, and now
  explicitly unverified. The mitigation shipped as designed — `task-engine`'s
  `description` opens by saying it is not a skill to invoke or suggest, and the
  body repeats it for an agent that opens the file without reading frontmatter
  — but no observation of real skill-selection behaviour has been made, because
  the engine has not yet been installed on a machine where that could be
  watched. Treat "the description is enough" as an assumption the suite already
  depends on, not as a finding.
