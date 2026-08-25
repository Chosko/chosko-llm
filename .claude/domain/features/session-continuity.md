# Session continuity

Two commands, `/session-save` and `/session-resume`, that write and read a
per-project handoff file so work survives the end of a conversation. The file
lives beside the project's other `.claude/` artifacts, links to whatever
document the session was working on, and shrinks to a pointer when the running
skill already keeps its own resume artifact.

## Purpose

A conversation ends and its context dies with it. The task backlog records
*what* was done; `.claude/context/` records *where things are*. Neither records
the middle: what was tried and failed, what was deliberately not tried, which
files are half-finished, and what the exact next step was. That knowledge is
re-derived from scratch every time a session ends mid-flight, at full token
cost and with no guarantee the re-derivation matches.

This feature captures it once, at the moment it is still known.

The schema is borrowed from ECC's `save-session` / `resume-session` pair, with
three deliberate departures: the store is per-project rather than global, the
file links to the project document the work belongs to, and a session running a
skill that already has a resume artifact writes a pointer instead of a
duplicate.

## Scope and non-goals

In scope: the `.claude/sessions/` store, the two commands, the full and pointer
file forms, artifact detection, and the resolution rules `/session-resume` uses
to pick a file.

Deliberately out:

- **A global session store.** ECC writes to `~/.claude/session-data/`, which
  mixes every project into one bucket and puts runtime state inside the
  directory `chosko-llm` installs features into. Sessions are per-project, full
  stop. See [technical-direction.md](../technical-direction.md).
- **State the CLI reads.** No `chosko-llm` subcommand walks `.claude/sessions/`.
  Session files are context for an agent, never input to the tooling. The hard
  rule that filesystem plus frontmatter is the only state stands unchanged.
- **Automatic saving.** No hook, no Stop trigger, no autosave. The user decides
  a session is worth preserving. An automatically written handoff nobody asked
  for is the same rot the feature exists to prevent.
- **Duplicating a skill's own resume artifact.** When one exists, the session
  file points at it and says nothing else. Two accounts of the same state that
  can disagree is worse than one.
- **Committing.** `/session-save` writes the file and reports its path. It does
  not commit, does not push, and offers no `--commit`. Nor does it touch
  `.gitignore` — see [The store](#the-store).
- **Cross-machine or cross-project handoff.** A session file is readable by
  anyone given the path, but nothing in the feature moves it anywhere.

## Architecture

Two commands (`commands/session-save.md`, `commands/session-resume.md`), not
skills: each is a single-pass reporter with no conversation and no supporting
files, the same register `/task-list` and `/production-status` occupy.

### The store

`.claude/sessions/`, created on first save. One file per save:

```
.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md
```

`<slug>` is a two-or-three word kebab-case summary of the work, not a random
id — it makes the directory listing readable, which is the only way the user
finds an old session. The timestamp prefix sorts chronologically and prevents
same-day collisions without a hash. Markdown, not `.tmp`: the file is a
document, and the extension should say so.

**The store is not gitignored, and neither command touches `.gitignore`.**
Session files are personal working state and will usually be noise in a diff,
which argues for ignoring the directory in `/task-setup` or `/project-setup`.
Against it: a session file is exactly the thing you would want to hand a
colleague, and silently ignoring it makes that harder. The tie goes to leaving
the decision with the user — `/session-save` prints a one-line note that the
file is untracked, and whether a handoff belongs in the repo's history is
theirs to settle per project.

### Two file forms

`/session-save` picks the form by detecting whether the work in flight already
has a resume artifact. **The command detects; the skills declare nothing.** A
skill that gains a resume artifact later needs no change here, and a skill that
loses one degrades to the full form on its own.

**Pointer form** — written when an artifact is found. The whole file:

```markdown
# Session: 2026-08-24 14:32

Work: document .claude/domain/product-design.md
Running: /product-design
Resume from: .claude/domain/design-process.md

Read that file. It holds the state; this one only says where it is.
```

No narrative, no file table, no decisions. Anything more would be a second
account of state the artifact already owns.

**Full form** — written when no artifact is found, which is the generic case.
An **optional one-paragraph preamble** may sit between the header block and
section 1, framing the handoff; the nine sections follow, in this order,
adapted from ECC's schema:

1. **What we are building** — the goal in the session's own terms.
2. **What worked (with evidence)** — each claim carries the command output,
   test name, or file that proves it. A claim without evidence is a guess and
   is written as one.
3. **What did not work (and why)** — the highest-value section. This is what
   the next session would otherwise repeat.
4. **What has not been tried yet** — the approaches considered and skipped, so
   they are not mistaken for approaches already ruled out.
5. **Current state of files** — table: file, status
   (Complete / In progress / Broken / Not started), notes.
6. **Decisions made** — with the reason, so they can be revisited rather than
   silently inherited.
7. **Blockers and open questions.**
8. **Exact next step** — one action, concrete enough to start on.
9. **Environment and setup notes** — anything non-obvious about how to run
   things.

ECC's rule is adopted verbatim and matters: **write every section, using
"N/A" or "nothing yet" where a section is genuinely empty.** A skipped section
is indistinguishable from an overlooked one; an honest empty section is
information.

### Artifact detection

A **resume artifact** is a *project-scoped state document carrying a resume
marker* — a current-stage, phase, or next-step line a later session reads to
know where the last one stopped. Both properties are required: it lives inside
the user's project rather than inside an installed skill folder, and its marker
is rewritten as the work progresses. This is exactly the class of document
[docs/authoring-guide.md](../../../docs/authoring-guide.md) § "State that
outlives a session belongs in a project document" defines.

`/session-save` resolves the artifact in two steps, in order:

1. **Known-artifact table**, carried in the command body — a small explicit map
   from skill to artifact path. Today it has one row: `/product-design` →
   `.claude/domain/design-process.md`, whose current-stage marker is a resume
   point. The table is short by design and grows only when a skill actually
   ships a document meeting the definition above.
2. **Recency check** — if no table entry matches, look for a file written this
   session that carries a resume marker. If found, offer the pointer form; if
   the user declines, write the full form.

No artifact found, or no skill running: full form.

`/task-implement` deliberately has **no row**, and the design originally gave
it one pointing at `./delegated-runs.md`. That was wrong twice over:
`skills/task-implement/delegated-runs.md` is a static shipped instruction file
holding no session state, and its path is relative to the installed skill
folder rather than to the project. A pointer form built on it would have
discarded the whole handoff and left behind a link to a file that says nothing
about this session. `/task-implement`'s state is a half-finished working tree
plus what was tried — it writes no resume marker anywhere, so its sessions take
the full form.

The `Running:` line the table keys off is **inferred from the conversation**,
not read from state — the command has no reliable way to interrogate what skill
is in flight, and reading state to find out would be a second source of truth.
When the inference is unclear it asks the user once, which is cheap and honest.

### The `Work:` line

One typed line links the session to the document the work belongs to. Four
forms:

| Value | Written when | Points at |
|---|---|---|
| `task <n>` | a task was being implemented or authored | `.claude/tasks/<n>.md` |
| `feature <slug>` | `/architect` or feature-level design work | `.claude/domain/features/<slug>.md` |
| `document <path>` | product-design, roadmap, plan, or context work | that file |
| `none` | generic session with no anchor | — |

`none` is a first-class value, not a failure. A debugging session that touched
no backlog document is exactly the case the generic form exists for, and
inventing a link for it would make the link untrustworthy everywhere else. It
may carry a short trailing explanation after an em dash — `none — cross-feature
architecture session, five features authored` — which keeps an anchorless
session legible without inventing an anchor for it.

### Resolution in `/session-resume`

| Argument | Behaviour |
|---|---|
| *(none)* | newest candidate in `.claude/sessions/` |
| `YYYY-MM-DD` | newest candidate from that date |
| a path | read that file directly |

Three forms, not four. A **task-number selector** — newest file whose `Work:`
line names a given task — was designed in and dropped: `/task-implement` runs
are the least likely sessions to be paused, being much shorter than the
product-design and architect sessions this feature exists for, so a selector
scoped to them is too specific for the actual usage. `Work:` keeps `task <n>`
as a value; only the lookup by it goes.

**Only a file carrying a `Work:` line is a candidate.** The store holds
companion documents too — a hand-written notes file, a scratch plan dropped
beside the real thing — which the original design assumed it did not, and
without the check one of those would be selected as "the newest file" and
briefed from as though it were a handoff. `Work:` is mandatory in both forms
`/session-save` writes, which makes it the cheapest reliable discriminator. A
non-candidate is skipped silently: the directory is allowed to hold other
things. A path given explicitly is read as given, with no candidacy check.

Two files can share an identical `YYYY-MM-DD-HHMM` prefix, so "newest" is
ambiguous on the prefix alone; ties break deterministically on the **full
filename**, descending. The picked file is named on the first line of output,
which is what makes a wrong tie-break correctable — the user re-runs with an
explicit path.

On a **pointer-form** file, `/session-resume` follows the `Resume from:` path
and briefs from the artifact, using the session file only for its header block.
When that path no longer resolves it says so on its own line and briefs from
the pointer file's header alone, calling the briefing thin. The file it resumed
*from* is always the session file, never the artifact: the artifact belongs to
the skill that maintains it and is never named for deletion.

After reading, `/session-resume` emits a fixed briefing — what was being built,
what must not be retried, the exact next step — and then **stops and waits**.
It never starts work, never edits, never runs a command. Resuming into
unrequested action is the failure mode that makes handoff tooling untrustworthy.

Two edge cases are handled explicitly: a file older than 14 days is flagged as
stale before the briefing, and a file referencing paths that no longer exist
names each missing path rather than briefing as if they were there.

### Pruning

Old session files are pruned by finishing the work, not by a flag. The
mechanism has three parts, split across both commands:

1. **`/session-resume` hands over the deletion.** Its briefing ends by naming
   the file it resumed from and telling the resumed session to delete that file
   once the `Work:` it describes is finished — deletion being part of
   finishing, not cleanup afterwards. This is an *instruction, not an action*,
   which is what keeps `/session-resume` strictly read-only, and stating the
   path explicitly is also what lets `/session-save` find it later.
2. **`/session-save` supersedes.** If the session ends before the work does,
   the file stays. The next `/session-save` in a conversation that resumed from
   a file writes its new snapshot and then deletes the file it resumed from, as
   superseded — so two snapshots of the same work never coexist. The path comes
   from the conversation, never from guessing at the directory; when it cannot
   be told, nothing is deleted.
3. **An unresumed file is never auto-deleted.** Nothing searches the directory
   for stale candidates. The >14-day flag `/session-resume` raises before a
   briefing is the only signal such a file will ever get.

There is no `--prune` flag. The directory can still grow if handoffs are
written and never resumed, which is the accepted cost of never deleting a file
the user did not demonstrably finish with.

## Data and state

The session file is the only artifact. It is written once per invocation and
never updated in place — a second save writes a second file, because a handoff
is a snapshot and rewriting history in it defeats the purpose.

Nothing derives from session files. `/task-list`, `/production-status` and every
`chosko-llm` subcommand are unaffected and unaware.

## Interfaces and contracts

```
/session-save                      write a session file for the current session
/session-save <slug>               override the generated slug
/session-resume                    load the newest session file
/session-resume <date|path>        load a specific one
```

Both commands need `name`, `version`, `type`, `description` frontmatter per
[docs/authoring-guide.md](../../../docs/authoring-guide.md). Start at
`version: 0.1.0`. Root `VERSION` takes a minor bump — two new features.

Contract with the rest of the pipeline: session files are inputs to humans and
agents, never to tooling. Any future feature that parses them is a design
error to be caught in review.

## Dependencies

None. Both commands are self-contained markdown, read and write only inside the
project, and work on a project that has no backlog, no context layer, and no
domain layer.

## Open questions

None outstanding. The three this document opened — whether the store should be
gitignored by default, how old files are pruned, and whether `/session-save`
can tell what skill is running — are all resolved above, under
[The store](#the-store), [Pruning](#pruning) and
[Artifact detection](#artifact-detection) respectively. The heading stays so
its emptiness is stated rather than inferred, the same honesty rule the
feature's own full form applies to an empty section.
