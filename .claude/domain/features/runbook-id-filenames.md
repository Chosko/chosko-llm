# Runbook id-prefixed filenames

A runbook's body file carries its id in front of its name:
`.claude/runbooks/<name>.md` becomes `.claude/runbooks/<id>-<name>.md`, using
the id `.claude/RUNBOOKS.md` assigned it (`runbook-slug` with id 3 is
`3-runbook-slug.md`). Every runbook command that takes a runbook argument
accepts it in any of three forms: the id alone, the name alone, or
`<id>-<name>`. Existing bodies move to the new name lazily, one runbook at a
time, and never while that runbook is being run.

## Purpose

The id was added to runbooks as a command-line alias
([runbook-suite](./runbook-suite.md) § The store): something short to type in
place of a kebab-case name. But the directory never showed it. A reader
browsing `.claude/runbooks/` saw names with no ids, and a reader of
`/runbook-list` saw ids with no file names. Prefixing the id to the file name
connects the two. The directory sorts roughly in creation order, and the
number typed at a command line is the one visible on disk.

Accepting `<id>-<name>` as an argument follows from that. Once the file is
called `3-runbook-slug.md`, `3-runbook-slug` is what a user copies from a
directory listing or a tab completion, and refusing it would be friction the
rename itself created.

## Scope and non-goals

In scope:

- the new body path;
- `File:` as the one place a body path comes from;
- the three-form resolution rule and the naming restriction that keeps it
  unambiguous;
- the lazy migration and the separate reference file that carries it;
- every runbook consumer that opens a body or resolves a runbook argument.

Deliberately out:

- **Making the id the identity.** The id is still an alias.
  - The runbook's name is still what errors, reports, relay blocks and the
    body heading (`# Runbook: <name>`) use.
  - The body carries no id of its own; the file name carries it, and the index
    stays its authority.
  - This keeps the earlier rejection of an id-primary design in
    [runbook-suite](./runbook-suite.md) intact.
- **An eager migration.** No migration script ships, no sweep renames every
  legacy body at once, and the change that lands this feature renames no
  existing body. A sweep would make `/runbook-run` write other runbooks' files,
  breaking its two-files contract, and would put unrelated renames in
  bookkeeping commits.
- **Renaming a `[RUNNING]` runbook, under any flag.** No override exists; see
  *Migration*.
- **More argument forms.** A file name with `.md`, a path, a prefix match or a
  near-match are not accepted. The three forms were settled by the user.
- **A lint for un-prefixed `File:` values.** During lazy migration a legacy
  path is a legal, expected state. A `/pipeline-check` finding for it would be
  noise, and `/pipeline-check` never opens bodies anyway.
- **Changing `/runbook-list`.** It takes no runbook argument and never prints
  `File:`, so nothing it does changes.
- **Changing ids.** An id is stable, so a body's file name, once prefixed,
  never changes again. A runbook rename is still a rename, as it always was.

## Architecture

Built on the repo's existing shape, per [product-design.md](../product-design.md):
markdown bodies of shipped commands and skills, installed by copy. It extends
the runbook asset kind owned by
`skills/runbook-run/references/runbook-schema.md`, which remains the single
authority for the store, the index block and the resolution rule. Every
consumer cites the schema and restates none of it.

### `File:` becomes the authority for a body's path

Before this feature, most consumers built the body path from the name, and only
`/runbook-clean` read the index block's `File:` line. After it, **every command
opens a runbook's body at the path its `File:` line holds, and never builds the
path from the name.** That one change lets both file-name shapes exist side by
side:

- A block for a new runbook says `File: .claude/runbooks/<id>-<name>.md`.
- A block not yet migrated still says `File: .claude/runbooks/<name>.md`, and
  stays correct.

The `File:` line's format is unchanged; only its value is new. The
index-as-summary rule still holds. `File:` was already in the index, and the id
it now embeds is the assigned id, whose authority was already the index.

### The resolution rule

This replaces *a bare all-digits argument is an id, anything else a name*. An
argument resolves to exactly one index block, by these checks in order:

1. **All digits** — an id.
2. **Exactly equal to a block's name** — that name.
3. **Of the shape `<digits>-<rest>`, where block `<digits>` exists and its name
   is `<rest>`** — that block. If block `<digits>` exists under a different
   name, it is an error naming both: the id's actual runbook, and that `<rest>`
   is not it. Also an error if `<rest>` is some other runbook's name. It never
   falls back to the id alone or to the name alone, because a mismatched
   compound is a typo, and either half picked silently would act on the wrong
   runbook.
4. **Anything else** — unknown. Reported as today, by listing the runbooks that
   exist.

**Why the rule is unambiguous rather than heuristic.**

- **New names can't start with a numeric segment.** `/runbook-create` refuses a
  name whose first kebab segment is all digits (`2026-migration`), with a
  suggested alternative, just as it refuses a name already taken. So for every
  runbook created from now on, checks 2 and 3 can never both match.
- **Name before prefix protects existing names.** A runbook authored earlier
  with such a name still resolves by its exact name, and no existing invocation
  form changes meaning.
- **One residual case is reported, not guessed.** Only a legacy name that is
  exactly `<id>-<another runbook's name>` could match two blocks. That is
  reported as an ambiguity naming both, never resolved by guessing.

### Migration

**How it works:** existing bodies are renamed lazily, one runbook at a time,
never while that runbook is `[RUNNING]`. Only a command already writing that
runbook renames it.

**The check is inline and small.** A writing command has already read the
block. When the file name in the block's `File:` doesn't begin with `<id>-`,
the body needs migrating. That one-sentence test lives in `runbook-schema.md`
beside the rule that `File:` is authoritative. It is the only part of the
migration a run that doesn't need one ever reads.

**The protocol lives in its own reference file:**
`skills/runbook-run/references/body-migration.md`. It carries:

- the rename itself: `git mv` to `<id>-<name>.md`, then rewrite `File:`;
- the `[RUNNING]` exclusion and why it exists;
- how the rename is staged: both the old and the new path go into the command's
  one commit;
- what to do when the target path already exists: stop and report, never
  overwrite;
- the non-git VCS mapping.

The file is separate so that a run with nothing to migrate never loads the
protocol. That covers every runbook created after this feature lands, and
every legacy runbook after its first write. The file lives beside the schema
because `cmd-add` installs a skill folder whole, so it ships with every
command that already `requires: skill:runbook-run`.

**Who reads it, and when.** Exactly two commands, and only after the inline
check has found an un-prefixed `File:`:

- **`/runbook-run`**, in its *Resolve* step, before it marks the runbook
  `[RUNNING]`:
  - The runbook it is about to run is by definition not yet `[RUNNING]` under
    this run.
  - If the index says `[RUNNING]`, the one-run-per-runbook rule already decides
    whether the run stops or resumes. A resume never migrates: the interrupted
    run left the body where it was, and it stays there.
  - The run then uses the new path for its whole life.
  - The rename lands in its first step commit, so `/runbook-run` still writes
    only the runbook and the index.
- **`/runbook-create --append`**, once PHASE 1 has resolved the target and
  before any material is gathered, unless the target is `[RUNNING]`.
  - A `[RUNNING]` target is appended to at its current `File:` path. That is
    the running-session-only append, and moving a body under a live
    orchestrator is exactly what the exclusion forbids.

**Never read by:**

- `/runbook-clean`, which deletes whatever `File:` names;
- `/runbook-describe` and `/runbook-list`, which are read-only;
- `/pipeline-patch`, `/pipeline-revise` and `/pipeline-check`;
- the single-step amend in `step-amend.md`, which writes at `File:` and leaves
  the name alone.

A new runbook never needs it, because `/runbook-create` writes the prefixed
name from the start.

**Why an in-flight run keeps working.** A run already in progress when this
feature lands — including the runbook this feature was designed inside — is
safe on every path:

- It is `[RUNNING]`, so no new-version command renames its body.
- Its orchestrator does not redo *Resolve* mid-run. It re-reads the body at the
  path it resolved at the start.
- An orchestrator of the old version builds that path from the name. The file
  still exists under that name, because nothing renamed it.
- An orchestrator that re-reads the updated schema mid-run and learns that
  `File:` is authoritative finds `File:` still holding the old path.
- Once such a runbook reaches `[DONE]`, nothing ever renames it. It keeps its
  legacy name until `/runbook-clean` prunes it, which deletes by `File:`.

That leftover is harmless, since `File:` stays authoritative.

**Version skew is accepted, not engineered around.** An old-version
orchestrator on another machine that tries to run a runbook a new-version
command has already migrated won't find the body at the path it builds. The
remedy is `chosko-llm update`, as for any skew between a shipped command and
the artifacts newer commands write.

### Consumers and what each must change

This describes each consumer's responsibility, not an edit plan.
`/task-add` produces the edit plan against the bodies as they then stand.

- **`runbook-schema.md`**:
  - § The store: the new path; `File:` as the authority for the body path; the
    three-form rule; the leading-numeric-segment refusal; the one-sentence
    migration check, citing `body-migration.md`.
  - § The index block: shows the new `File:` value.
  - The paragraph calling the id "an alias, never a replacement" keeps its
    meaning but no longer says the body file is `<name>.md`.
- **`body-migration.md`** (new): the migration protocol above, and nothing else.
- **`/runbook-run`**:
  - its argument table accepts the three forms;
  - *Resolve* reads the body at `File:` and runs the migration check, reading
    `body-migration.md` only on a hit;
  - *Re-read* uses the resolved path;
  - its commit stages the `File:` path, and both paths on a migrating step.
- **The subagent contract**:
  - gains a third placeholder, `<FILE>`, filled from the runbook's `File:`, for
    the rule forbidding a step's agent to edit the body;
  - the relay file names stay built from `<RUNBOOK>` and `<N>`;
  - the maintainer's rationale records why `<FILE>` is acceptable where a relay
    path was not: the orchestrator knows `File:` before it spawns, and a relay
    path it would have to invent.
- **`/runbook-create`**:
  - writes new bodies at `<id>-<name>.md`. This makes it take the id from the
    counter **before** writing the body rather than after, so the counter
    advance and the block append still land in one index write;
  - its plan shows the prefixed `File:`;
  - it enforces the name restriction;
  - `--append` resolves by the three-form rule and runs the migration check;
  - staging and its own never-write list name the `File:` path.
- **`/runbook-clean`**: resolution by the three-form rule; plan examples show
  prefixed paths. It already deletes at `File:`.
- **`/runbook-describe`**: resolution by the three-form rule; the body read at
  `File:`.
- **`step-amend.md`**: the body read and written at `File:`; resolution by the
  schema's rule.
- **`/pipeline-patch` and `pipeline-revise`**: the `runbook=` anchor accepts
  the three forms. Both already cite the schema, so only the notation changes.
- **`pipeline-engine`'s routing table**: the runbook rows' paths and argument
  notation. The routing guard, `check-routing.sh`, runs after that edit.
- **`pipeline-engine`'s graph**: edge E6's `File:` line text.

Documentation that describes the old shape follows as a documentation change:

- [runbook-suite](./runbook-suite.md), which states the body file stays
  `<name>.md`;
- the context layer.

## Data and state

- **The body path** is persisted in exactly one place: the index block's
  `File:` line. The file name on disk matches it, and the file name alone is
  never treated as a source of truth.
- **The id** is assigned by `/runbook-create` from `Last runbook number:`,
  unchanged. It now also appears in the body's file name, which is derived from
  the id and fixed at creation or migration. Ids are never reused or
  renumbered, so no file name ever has to change because of an id.
- **Migration state** is not stored anywhere. Whether a runbook is migrated is
  read off its own `File:` value. There is no flag, no marker and no lockfile,
  in keeping with the repo's no-state-files rule.
- **The `[RUNNING]` exclusion** reads the index `Status:` the writing command
  has already parsed, plus the existing one-run-per-runbook signals (`[RUNNING]`
  in the index, `[~]` in the tree). It adds none.
- **The body's content** is untouched by a migration: same heading, steps,
  markers and `Done:` lines. A migrating commit is a pure rename plus a one-line
  `File:` change in the index.

## Interfaces and contracts

```
/runbook-run <id|name|id-name> [...]
/runbook-create --append <id|name|id-name> [--before <step> | --after <step>]
/runbook-describe <id|name|id-name>
/runbook-clean [<id|name|id-name> ...] [--no-commit] [--no-push]
/pipeline-patch  runbook=<id|name|id-name> step=<n> "<change>"
/pipeline-revise runbook=<id|name|id-name> step=<n> "<change>"
```

`/runbook-list [<STATUS>]` is unchanged.

Contracts:

- **One block per argument.** An argument resolves to exactly one block, or the
  command stops before writing anything.
  - **An unknown argument** lists the runbooks that exist.
  - **A compound whose halves disagree** names the runbook the id belongs to.
  - **An ambiguity**, possible only through a legacy name, names both
    candidates.
- **A refused name** — a new name whose first kebab segment is all digits — is
  refused with one suggested alternative, like a name collision, before any
  file is written.
- **`File:` decides every body read and write.** A `File:` naming a file that
  doesn't exist is handled as each command already handles a missing body:
  `/runbook-clean` notes it in its plan; the others stop and report it.
- **A migration happens only inside a command that is already writing that
  runbook,** in that command's own commit, and never while it is `[RUNNING]`.
  If the target file name is already taken, the command stops and reports
  without renaming or overwriting anything.
- **Only `/runbook-run` and `/runbook-create --append` read `body-migration.md`,**
  and only after the inline check fires. No other command reads it.
- **The subagent contract is filled with exactly three placeholders:**
  `<RUNBOOK>`, `<N>`, `<FILE>`.

Versioning:

- Every shipped body touched bumps its own `version:`.
- Root `VERSION` and `CHANGELOG.md` move per task.
- The documentation tail (`runbook-suite.md`, context layer) is exempt.
- The committed repo-local installs under this repo's `.claude/commands/` and
  `.claude/skills/` follow through `chosko-llm update`.

## Dependencies

- **[runbook-suite](./runbook-suite.md)** — the asset kind this changes: the
  store, the index block with its id and counter, the one-run-per-runbook rule
  the `[RUNNING]` exclusion leans on, and the reference-file folder the new
  migration file joins.
- **[pipeline-engine](./pipeline-engine.md)** — the routing table and graph
  entries naming runbook paths and argument forms, and the routing guard run
  after they change.
- **[pipeline-revision](./pipeline-revision.md)** and
  **[owner-amend-arms](./owner-amend-arms.md)** — the `runbook=` anchor and the
  single-step amend, both of which resolve a runbook by the schema's rule and
  read its body.
- **[shared-phase-engine](./shared-phase-engine.md)** — the `requires:` field
  that already makes every runbook command depend on the `runbook-run` skill
  folder. That is why a new reference file there reaches its readers with no
  new edge.
- **[runbook-inline](./runbook-inline.md)** (`[PLANNED]`, tasks 209–210) — it
  edits `/runbook-run`'s body too, so tasks from the two features touch the same
  file and should be sequenced, not run in parallel. It doesn't change the
  resolve or body-path logic this feature changes.
- No external dependencies.
