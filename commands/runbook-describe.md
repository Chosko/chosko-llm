---
name: runbook-describe
version: 0.1.0
type: command
description: Print one runbook in depth — its header (created, source, model, sequencing, companion), its index status and progress, and every step enumerated with its number, marker, title, dependencies, whether it needs a person, and the Done: line a run wrote for it. Takes the runbook's kebab-case name or the numeric id the index assigns it. This is the one read-only runbook command allowed to open a body, and it opens exactly one — the runbook asked about, never a walk of .claude/runbooks/ — which is the trade it exists to make against /runbook-list, whose whole contract is that it never opens one. A step's Needs: line is printed as authored; a step without one is read from its prompt block and may carry an inferred note, always labelled as inferred and never rendered as though it were authored. Writes nothing, runs no shell command including git, and corrects no status, count or marker however wrong it looks against the body.
requires: skill:runbook-run
---

# /runbook-describe
# Global command: print one runbook in full — header, status, and every step
# with its marker, dependencies, human-intervention need and Done: line.
# Read-only — never modifies any file. Opens the index and exactly one body
# under `.claude/runbooks/`.
# Usage: /runbook-describe <name>
#        /runbook-describe <id>
# Examples: /runbook-describe implement-ecc-import
#           /runbook-describe 3

GOAL
Answer the question `/runbook-list` deliberately cannot: **what is actually in
this runbook?** The listing gives one line per runbook from the index alone,
which is what keeps its cost flat. This command spends the read the listing
refuses to, on exactly one runbook, and prints what only the body holds — the
steps, their order, their dependencies, which of them need a person, and what
the ones that have run recorded.

It is a diagnostic / orientation command. It must not write, edit, or commit
anything.

$ARGUMENTS

---

THE ARTIFACT

The store, the body schema, the four step markers, the `Done:` line, the
`Needs:` field, the four-status vocabulary, the index block and the id are all
specified in
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
Read it before parsing either file. **Nothing about the artifact is restated
here** — a second copy is the copy that drifts, and a describe whose idea of
the markers has drifted from the runner's describes a runbook nobody has.

---

WHAT THIS COMMAND READS

**Two files, and no more.** `.claude/RUNBOOKS.md`, for the runbook's index
block, and `.claude/runbooks/<name>.md`, for its body.

Opening a body is this command's whole reason to exist, and it is bounded:
**exactly the one runbook the argument resolved to**. Never a second body,
never a walk of `.claude/runbooks/`, never "while I am here" — the cost stays
bounded by the size of one runbook, which is what makes reading it in full safe
to do at all.

`/runbook-list`'s never-open-a-body rule is not weakened by this command's
existence; the two are a deliberate pair. The listing answers *which runbooks
exist and how far did they get* for all of them at index cost; this answers
*what is in this one* for one of them at body cost. A `--verbose` flag on the
listing would have destroyed the property the listing is built around, which is
why this is a separate command.

It reads no source file, no `.claude/context/`, no `.claude/domain/`, and no
other runbook.

---

RESOLVING THE ARGUMENT

`$ARGUMENTS`, trimmed, names one runbook — its kebab-case name, or the numeric
id its index block carries. The resolution rule is `runbook-schema.md`'s one
rule and is not restated: a bare all-digits argument is an id, anything else a
name.

- **No argument** — print the usage line and stop. Do not pick a runbook,
  do not default to the most recent, and do not fall back to listing them all;
  that is `/runbook-list`.
- **An unknown name or id** — say which argument did not resolve, list the
  runbooks that do exist (id, status and name, from the index), and stop.
  Never guess at a near match, and never fall back from an id that matched
  nothing to a name that looks similar.
- **A missing or empty `.claude/RUNBOOKS.md`** — not an error. One line and
  stop:

  > No runbooks in this project — `/runbook-create` authors one.

  Do not create the file and do not suggest a setup command; runbooks need no
  setup step.
- **An index block whose `File:` path does not resolve** — print the block's
  fields, then say plainly that the body is missing at that path. Do not error
  out, do not create anything, and do not correct the index.

---

WORKFLOW

1. Read `.claude/RUNBOOKS.md` and resolve the argument to one block, per
   RESOLVING THE ARGUMENT.

2. Read that runbook's body at the block's `File:` path. This is the one body
   this command opens.

3. Parse the body per `runbook-schema.md`: the header fields, then every step
   — its marker, number and title from the `##` heading, then its
   `Depends on:`, its `Needs:` where present, its `Context:`, its ```prompt```
   block, and its `Done:` line where a run has written one. Parse the trailing
   `## Do not re-propose` section if there is one.

4. Render the report in four parts, in this order.

   **Part 1 — the heading line.** Id, name, status, and progress from the
   index:

   ```
   3. implement-ecc-import   [RUNNING]   4/7   —   Land the ECC import architecture
   ```

   For a `[FAILED]` runbook, and only for one, follow it with the index's
   `Failed at:` line as a continuation, exactly as `/runbook-list` renders it.

   **Part 2 — the header.** The body's own header fields, one per line,
   labelled: `Created:`, `Source:`, `Model:`, `Sequencing:` and `Companion:`.
   Print `Sequencing:` in full and never summarise it — it is one line of
   prose stating the order *and why it is the order*, and the why is the part a
   reader came for. Omit `Companion:` entirely when the header has none.

   **Part 3 — the steps.** One block per step, in body order:

   ```
   [x] 1. Add the requires: field to the frontmatter contract
          depends on: none
          done:  a1b2c3d — added the field and its cmd-add resolution; the
                 "parse_frontmatter emits every key" premise was wrong, it
                 gates on an allowlist.

   [ ] 2. Wire cmd-rm's dependents guard
          depends on: 1
          needs: agent+human — the Unity editor step at checkpoint 2

   [ ] 3. Update the authoring guide
          depends on: 1, 2
   ```

   - The marker is printed **as the body carries it** — `[ ]`, `[~]`, `[x]`,
     `[!]` — and is the first thing on the line, so the shape of the run is
     readable down the left margin.
   - `depends on:` is always printed, `none` included, so a reader never has
     to wonder whether the line was missing or empty.
   - `needs:` is printed **only when the step is not plain `agent`** — see
     THE `Needs:` ANNOTATION below.
   - `done:` is printed whenever the step has a `Done:` line, for `[x]` and
     `[!]` alike, and is **rendered, not summarised**: the commit sha, the
     decisions and the wrong premises are the three things it records and all
     three are why a reader opened this. A `[!]` step's `Done:` line opens
     with the failure reason; print it first, as the body has it.
   - `Context:` bullets are printed under the step when it has any, beneath
     `done:`, each on its own line. Skip the field entirely when it is `none`.
   - **The ```prompt``` block is not printed.** It is the largest thing in the
     body and reproducing every one of them would make this command a slow way
     to `cat` the file. A reader who wants the prompts opens the file; this
     command exists to make that decision an informed one.

   **Part 4 — the trailing sections and the summary.** Print the number of
   items under `## Do not re-propose` when the runbook has that section — not
   the items themselves, which are prompt material. Close with one line
   counting the steps by marker:

   ```
   7 steps: 4 done, 1 failed, 2 pending.
   ```

   Include only the non-zero counts, use the singular for one step, and name
   `[~]` as "in progress". When any step is not plain `agent`, add one further
   line naming those step numbers, because it is the fact that decides whether
   the run can be started and left:

   ```
   Steps 2 and 5 need a person present.
   ```

---

THE `Needs:` ANNOTATION

A step's `Needs:` line, where the author wrote one, is **authoritative**.
Print it as the body carries it, with whatever the author wrote after it —
**unless the authored value is `agent`**, which prints nothing, exactly as an
absent line does. `runbook-schema.md` says `Needs: agent` is never written, so
finding one means a hand-edited body; it is still authoritative, and the
default is still silent.

A step with **no** `Needs:` line means `agent` per `runbook-schema.md`, and in
the ordinary case that is the whole story: print nothing, because the default
is silent and a runbook of ordinary agent work should not render a column of
noise.

There is one exception, and it is why this command is allowed to read a body at
all. A runbook written by hand, or authored before `Needs:` existed, carries no
such lines even where a step plainly does need a person. For a step with no
`Needs:` line, you **may** read its prompt block and, where it is clear that
executing the step requires something an agent cannot do — an editor-only
operation, a GUI wizard, a physical device, an external account — print an
inferred note:

```
[ ] 4. Import the prefab and check the console
       depends on: 3
       needs: (inferred) agent+human — the prompt describes an operation in
              the Unity editor. Not authored; /runbook-create --append can
              record it.
```

Three rules govern it, and they are what keep the inference honest:

- **It is always labelled `(inferred)`.** It never renders in the same form as
  an authored value. A reader must be able to tell, at a glance and without
  opening the body, which annotations the author wrote and which this command
  guessed.
- **It is only ever offered, never asserted.** An inference is a reading of
  prose, and the confidence bar is high: infer only where the prompt names the
  manual act, not where a step merely feels like it might involve one. When in
  doubt, print nothing — a missing annotation costs a reader far less than a
  wrong one.
- **It is never written anywhere.** This command does not add the `Needs:`
  line it inferred, does not offer to, and does not ask. Authoring is
  `/runbook-create`'s, by line; naming `--append` in the note, as above, is
  the whole of what this command does about it.

---

DO NOT:
- Open a second runbook body, or walk `.claude/runbooks/`. Exactly one body,
  the one asked about.
- Write, edit, create or commit anything, and run no shell command of any
  kind, including `git`.
- Add, edit or persist a `Needs:` line, or any other line, in a body or in the
  index — including the one this command inferred. Authoring is
  `/runbook-create`'s by line, and the run's lines are `/runbook-run`'s.
- Render an inferred `Needs:` value without the `(inferred)` label, or infer
  one for a step that already carries an authored `Needs:` line.
- Infer a `Needs:` value from a hunch. The prompt must name the manual act;
  otherwise print nothing.
- Correct a status, a `Steps:` count, a marker or a `Failed at:` line, however
  wrong the index looks against the body it just read. Reconciliation belongs
  to `/runbook-run`, which re-reads the body every step and rewrites the index
  from it. Reporting an inconsistency in prose is fine — and this is the one
  command positioned to notice one — but editing it is not.
- Print the ```prompt``` blocks. The command reports the runbook's shape and
  its record, not its contents.
- Restate the body schema, the markers, the `Needs:` values, the status
  vocabulary or the index block in this body. They are
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Treat a missing or empty `.claude/RUNBOOKS.md` as an error, create it, or
  suggest running a setup command.
- Suggest next actions, recommend whether to resume the runbook, or comment on
  how long it has been `[RUNNING]`. Describe it; the user decides.
- Run, resume, append to, or delete a runbook. Those are `/runbook-run`,
  `/runbook-create --append` and `/runbook-clean`.
- List every runbook when the argument is missing or unknown as though that
  were the answer. `/runbook-list` is the listing; here it is only ever an
  error's supporting detail.
