---
name: runbook-describe
version: 0.3.3
type: command
description: Print a compact summary of one runbook — its index line, header, and one line per step with marker, title, dependencies and who it needs — without opening a step prompt. Use it to see where a runbook stands.
requires: skill:runbook-run
---

# /runbook-describe
# Global command: print a compact summary of one runbook — heading, one header
# line, one line per step with an optional one-line done: summary, and a
# closing count. Read-only — never modifies any file. Reads the index and
# extracts lines from exactly one body, at its index block's `File:` path —
# never a full read of the body, never a step prompt, never a task body,
# never another runbook. Task ids in a `Done:` line are printed as written
# and never followed. Runs no shell command including git, and corrects no
# status, count or marker however wrong it looks against the body.
# Usage: /runbook-describe <id|name|id-name>
# Examples: /runbook-describe implement-ecc-import
#           /runbook-describe 3
#           /runbook-describe 3-implement-ecc-import

GOAL
Answer the question `/runbook-list` deliberately cannot: **what are this
runbook's steps, and how did the finished ones go?** The listing gives one line
per runbook from the index alone. This command gives one runbook moderately
more — one line per step and a one-line record per finished step — and nothing
like the body itself. Its cost is roughly the lines it prints; a reader who
needs the prompts, the `Context:` notes or the full `Done:` record opens the
file.

It is a diagnostic / orientation command. It must not write, edit, or commit
anything.

$ARGUMENTS

---

THE ARTIFACT

The store, the body schema, the four step markers, the `Done:` line, the
`Needs:` field, the four-status vocabulary, the index block and the id are all
specified in
`../skills/runbook-run/references/runbook-schema.md`.
Read it before parsing either file. **Nothing about the artifact is restated
here** — a second copy is the copy that drifts, and a describe whose idea of
the markers has drifted from the runner's describes a runbook nobody has.

---

THE READ BUDGET

**The index, and selected lines of one body.** `.claude/RUNBOOKS.md` is read
for the runbook's index block. From the body at that block's `File:` path, the
command pulls **only the lines it prints**, by targeted line extraction with
the Grep tool (with line numbers) — never a full Read of the body:

- the header fields `Created:`, `Source:`, `Model:` and `Archive:`;
- the step headings — `##` lines carrying a marker and a number;
- each step's `Depends on:` and `Needs:` lines;
- the first line of each step's `Done:`;
- the fence lines of the ```prompt``` blocks, used only to discard any match
  that falls inside a prompt block. Nothing between the fences is read or
  printed.

Attach each field to the nearest preceding step heading. The
`## Do not re-propose` heading is not a step and its contents are not read.

`Archive:` is optional and absent on every runbook never pruned, so the pass
usually finds nothing for it. Its absence is the common case, not a malformed
body: extract it when it is there, and print nothing for it when it is not.
Adding it costs no extra pass — it is one more field of the same Grep over the
same body.

A body whose extracted lines do not fit the schema — a step with no
`Depends on:`, a heading without a number — is **reported as found**, in one
line of prose. Never compensate by reading more of the body.

The bound is the whole point of the command, so it is absolute:

- never a full Read of the body, and never the text of a ```prompt``` block;
- never a second runbook body, and never a walk of `.claude/runbooks/`;
- never a file under `.claude/tasks/`, the archive included — a task id in a
  `Done:` line is printed as written and never resolved;
- never `.claude/domain/`, `.claude/context/`, or any source file.

The Grep tool is not a shell command, so this still runs no shell.

`/runbook-list`'s never-open-a-body rule is not weakened by this command's
existence; the two are a deliberate pair. A `--verbose` flag on the listing
would have destroyed the property the listing is built around, which is why
this is a separate command.

---

RESOLVING THE ARGUMENT

`$ARGUMENTS`, trimmed, names one runbook — as `<id>`, `<name>` or
`<id>-<name>`. It is resolved to exactly one index block by
`runbook-schema.md` § *Resolving a runbook argument*, whose checks, errors and
ambiguity report are not restated here.

- **No argument** — print the usage line and stop. Do not pick a runbook,
  do not default to the most recent, and do not fall back to listing them all;
  that is `/runbook-list`.
- **An argument that does not resolve** — unknown, a compound whose halves
  disagree, or an ambiguity — report it as the schema says, list the runbooks
  that do exist (id, status and name, from the index), and stop. Never guess
  at a near match, and never fall back from one half of an argument to the
  other.
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

2. Extract the body lines named in THE READ BUDGET from the block's `File:`
   path, and attach each to its step.

3. Render exactly this shape, and nothing more:

   ```
   3. implement-ecc-import   [RUNNING]   4/7   —   Land the ECC import architecture
      Created: 2026-09-01   Source: /architect ecc-import   Model: sonnet

      [x] 1. Add the requires: field to the frontmatter contract
             done: a1b2c3d — added the field and its cmd-add resolution (+1 wrong premise)
      [!] 2. Wire cmd-rm's dependents guard            deps: 1
             done: FAILED — <first clause of the reason>
      [ ] 3. Update the authoring guide                 deps: 1, 2   needs: agent+human

      7 steps: 4 done, 1 failed, 2 pending.
      Step 3 needs a person present.
   ```

   **The heading line.** Id, name, status, progress and title, from the index.
   For a `[FAILED]` runbook, and only for one, follow it with the index's
   `Failed at:` line as a continuation, exactly as `/runbook-list` renders it.

   **The header line.** One line: `Created:`, `Source:`, `Model:`. Nothing
   else from the header on this line — no `Sequencing:`, no `Companion:`, no
   `Last step number:` — and no count of `## Do not re-propose` items. The one
   other header field that is ever printed, `Archive:`, gets its own line
   below.

   **The archived-ids line.** One further line, directly under the header
   line, **printed only when the body carries an `Archive:` line** — the ids
   as the body holds them, ascending, followed by a short parenthetical
   saying they were pruned and count as done:

   ```
   3. implement-ecc-import   [PENDING]   3/5   —   Land the ECC import architecture
      Created: 2026-09-01   Source: /architect ecc-import   Model: sonnet
      Archived: 1, 2, 3   (pruned; counted as done)

      [!] 4. Wire cmd-rm's dependents guard            deps: 1
             done: FAILED — <first clause of the reason>
      [ ] 6. Update the authoring guide                deps: 1, 2

      5 steps: 3 done, 1 failed, 1 pending.
   ```

   It sits in the header region, above the step list, so the step list is
   never read as the whole runbook — a reader who met the archived ids after
   the list would already have read a partial list as complete, which is the
   failure this line exists to remove.

   **A runbook that has never been pruned renders exactly as it does
   otherwise, line for line**: no `Archived:` line, no empty placeholder, no
   changed count. That is the common case — `Archive:` is absent on every
   runbook never pruned and is never written empty.

   A body whose every step has been pruned is a legal body, not a malformed
   one. It renders its heading, its header line, its `Archived:` line and its
   count (`7 steps: 7 done.`) and nothing between them. Do not report it as
   an error, and do not render an empty step list with no explanation.

   **The step lines.** One line per step, in body order:

   - the marker **as the body carries it** — `[ ]`, `[~]`, `[x]`, `[!]` —
     first on the line, then the number and the title;
   - `deps:` on the same line, only when the step has dependencies. A step
     whose `Depends on:` is `none` prints nothing for it. A surviving
     `Depends on:` naming an archived id is printed **verbatim**, like any
     other: do not annotate it, do not mark it satisfied, and do not
     cross-reference it against the `Archived:` line. The two lines sitting
     in one render is the whole mechanism;
   - `needs:` on the same line, only when the step carries an authored `Needs:`
     value that is not `agent`. A step without a `Needs:` line prints nothing.

   **The `done:` line.** At most one, under a step that has a `Done:` line: the
   commit sha(s) and a short summary of what was done. Wrong premises are shown
   only as a count, `(+N wrong premise)` or `(+N wrong premises)`. A `[!]`
   step's line opens with `FAILED —` and the first clause of its reason. Task
   ids the `Done:` line mentions are printed as written.

   No `context:` line and no `Context:` text of any kind. No prompt text, in
   whole or in part.

   **The closing lines.** One line counting the steps by marker — only the
   non-zero counts, the singular for one step, `[~]` named "in progress".
   **Every id on the `Archive:` line counts as done and as present**, per
   `runbook-schema.md` § *An archived id counts as `[x]`* and the index's
   `Steps:` accounting one level down: the total is the steps present plus
   the archived ids, and the done count is the present `[x]` steps plus the
   same archived ids. That is what keeps this count agreeing with the
   progress figure in the heading line printed a moment earlier. When
   any step has an authored `Needs:` value other than `agent`, one further line
   naming those step numbers — "Step 3 needs a person present." or "Steps 2
   and 5 need a person present." — because it is the fact that decides whether
   the run can be started and left.

---

DO NOT:
- Read the body in full. Extract only the lines THE READ BUDGET names, and
  report a malformed body as found rather than reading more of it.
- Print, quote, summarise or read a ```prompt``` block, in whole or in part.
- Open anything under `.claude/tasks/`, the archive included, or resolve a task
  id a `Done:` line mentions. Print it as written.
- Open a second runbook body, or walk `.claude/runbooks/`. Exactly one body,
  the one asked about.
- Open `.claude/domain/`, `.claude/context/` or any source file.
- Print `Sequencing:`, `Companion:`, any `Context:` text, or the
  `## Do not re-propose` section or its count.
- Print `Last step number:`. It is deliberately omitted, not overlooked: this
  command answers *what are this runbook's steps, and how did the finished
  ones go*, and the counter answers neither — it is bookkeeping for
  `/runbook-create --append`, the only thing that assigns from it. `Archive:`
  is the opposite case and is printed for the opposite reason: without it the
  render is wrong, not merely less informative.
- Print an `Archived:` line on a runbook whose body carries no `Archive:`
  line, or an empty one. Absent is the common case and renders nothing.
- Print more than one `done:` line per step, or the wrong premises themselves
  rather than their count.
- Infer a `Needs:` value for a step that has none. A step without an authored
  `Needs:` line prints nothing.
- Write, edit, create or commit anything, and run no shell command of any
  kind, including `git`.
- Add, edit or persist any line in a body or in the index. Authoring is
  `/runbook-create`'s by line, and the run's lines are `/runbook-run`'s.
- Correct a status, a `Steps:` count, a marker or a `Failed at:` line, however
  wrong the index looks against the lines just extracted. Reconciliation
  belongs to `/runbook-run`. Reporting an inconsistency in prose is fine;
  editing it is not. Deriving the closing count from the body's steps **and
  its `Archive:` line** is derivation, not reconciliation — it is how the
  count is arrived at every time, pruned runbook or not. An index `Steps:`
  count that disagrees with the derived one is still reported in prose and
  never corrected: no file is written and no shell is run.
- Restate the body schema, the markers, the `Needs:` values, the status
  vocabulary or the index block in this body. They are
  `../skills/runbook-run/references/runbook-schema.md`,
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
