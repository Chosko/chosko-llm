---
name: runbook-list
version: 0.2.0
type: command
description: Print the project's runbooks as a compact listing — id, status, name, steps done over total, creation date, source and the runbook's one-line title — one line each, with the halt reason printed as a continuation line under any failed runbook and a trailing summary counting the runbooks by status. The id is the shorthand every other runbook- command accepts in place of a name; a block written before ids prints `-` in that column and is left alone, since backfilling belongs to a command that writes the index. Takes an optional status filter, matched without brackets and case-insensitively; an unknown status names the valid ones rather than printing nothing. A missing or empty index is not an error. Read-only — reads .claude/RUNBOOKS.md and nothing else, never opens a file under .claude/runbooks/, runs no shell command, and corrects no status however wrong it looks.
requires: skill:runbook-run
---

# /runbook-list
# Global command: print the project's runbooks as a compact listing — id,
# status, name, progress, provenance and one-line title — optionally filtered
# by status. Read-only — never modifies any file. Reads
# `.claude/RUNBOOKS.md`, and nothing else; the runbook bodies under
# `.claude/runbooks/` are NOT opened by this command.
# Usage: /runbook-list
#        /runbook-list <STATUS>
# Examples: /runbook-list
#           /runbook-list running
#           /runbook-list FAILED

GOAL
Give the user a quick, scannable view of every runbook in the project: how to
refer to it, what it is, how far it got, when it was authored, where it came
from, and — when it halted — why. This is a diagnostic / orientation command. It must not
write, edit, or commit anything.

One pass: read `.claude/RUNBOOKS.md`, parse each block, apply the optional
status filter, print. That is the whole command.

$ARGUMENTS

---

THE ARTIFACT

The four-status vocabulary and the shape of an index block — its five fields
and the conditional `Failed at:` line — are specified in
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
Read it before parsing the index. **Neither is restated here** — a second
copy is the copy that drifts, and a listing whose idea of the status set has
drifted from the runner's is worse than no listing.

---

NEVER OPEN A BODY

Everything this command prints comes from `.claude/RUNBOOKS.md`. **No file
under `.claude/runbooks/` is opened, on any path** — not to count steps, not
to check a marker, not to confirm a status the index reports.

This is `/task-list`'s discipline of never opening a file under
`.claude/tasks/`, and it is not an optimisation to be traded away under
pressure. It is why the index carries derived fields such as `Steps:` and
`Failed at:` at all, and it is what keeps this command's cost flat in the
number of runbooks rather than in their size.

---

THE STATUS FILTER

`$ARGUMENTS`, when non-empty, is a **display filter and nothing else** —
never a selector, and never a status this command writes anywhere.

Match it **without brackets and case-insensitively**, the convention
`/task-list` already uses: `running`, `RUNNING` and `Running` all select the
same runbooks. Surrounding whitespace is tolerated.

An argument that matches none of the statuses in `runbook-schema.md` is not
silently empty output — a silent empty result is indistinguishable from
having no matching runbooks. Say the status is unknown and **name the valid
ones**, taking them from that file rather than from memory, then stop
without printing a listing.

---

WORKFLOW

1. Read `.claude/RUNBOOKS.md`.

   If it does not exist, or holds no blocks, that is **not an error**. Print
   one line and stop:

   > No runbooks in this project — `/runbook-create` authors one.

   Do not create the file, do not offer to, and do not say anything about
   `.claude/runbooks/` being absent.

2. Parse every block in the file, in the order they appear, per
   `runbook-schema.md` § *The index block*: the runbook's id, name and
   one-line title from the heading, then `Status:`, `Created:`, `Source:`,
   `Steps:`, and the `Failed at:` line where one is present. `File:` is parsed
   but not printed — the listing prints the name, which names the body file.

3. Apply the filter from THE STATUS FILTER above, if one was given.

4. Render the output as a single compact block, **inside one fenced code
   block** so the alignment survives markdown rendering. One line per
   runbook, in index order:

   ```
   <id>. [STATUS]  <name>  <done>/<total>  <created>  <source>  <title>
   ```

   - Pad every column so the next one aligns. Take the padding from the widest
     value actually present, not from a hardcoded width.
   - The **id** leads the line, right-aligned within its column and followed
     by a `.`, so it reads as an identifier rather than a count. A block with
     no id yet prints `-` in that column — the backfill belongs to a command
     that writes the index, and this one does not (see DO NOT).
   - The **one-line title** closes the line. It is the short description of
     what the runbook is for, and it is the field that makes a listing
     answerable without opening anything — the name alone is an identifier,
     not a description.
   - `Steps:` is printed **verbatim** as the index carries it.
   - For a `[FAILED]` runbook, and **only** for a `[FAILED]` runbook, print
     the halt reason as a continuation line indented under the status
     column:

     ```
     ↳ failed at step <n> — <reason>
     ```

     A `[FAILED]` block with no `Failed at:` line prints the runbook's line
     and no continuation. Do not go looking in the body for the reason.
   - Do not reorder the runbooks by status, date, or anything else. Index
     order is the order.
   - Do not truncate a long title, name, or halt reason. Let it overflow.

5. After the per-runbook lines, inside the same fenced code block, print a
   one-line summary counting the runbooks by status, lower-cased:

   ```
   3 runbooks: 1 done, 1 failed, 1 pending.
   ```

   Include only the non-zero counts. Use the singular for one runbook. When
   a filter was applied, the summary covers the filtered subset and names
   the filter instead of breaking down counts of one status:

   ```
   1 runbook shown (filter: FAILED).
   ```

6. If the filter matches zero runbooks, say so explicitly — "No runbooks
   with status `[FAILED]`." — and print no fenced block at all.

The whole rendered shape, for reference:

```
  1. [DONE]     ecc-import-landing      7/7   2026-08-24  /architect run       Land the ECC import architecture
  2. [FAILED]   cli-dependency-field    2/5   2026-08-25  manual               Add a requires: field to the CLI
     ↳ failed at step 3 — the managed clone was on the wrong channel
  5. [PENDING]  context-layer-refresh   0/3   2026-08-26  /product-design run  Rebuild the context layer

  3 runbooks: 1 done, 1 failed, 1 pending.
```

---

DO NOT:
- Open any file under `.claude/runbooks/`. The bodies exist for
  `/runbook-run`; this command is purely an index reader.
- Write, edit, create or commit anything, and run no shell command of any
  kind, including `git`.
- Assign an id, write a `Last runbook number:` counter, or backfill an index
  that predates ids — `runbook-schema.md` § *Backfilling an index written
  before ids* gives that to the three commands that write the index, and this
  is not one of them. An id-less block prints `-` and is left alone.
- Correct a status, a `Steps:` count or a `Failed at:` line, however wrong
  it looks against the rest of the index. Reconciliation belongs to the
  command that already has the body open — `/runbook-run` re-reads the body
  every step and fixes the index from it. Reporting an inconsistency in
  prose is fine; editing it is not.
- Restate the status vocabulary or the index block's shape in this body.
  They are
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Print the `↳` continuation for anything other than a `[FAILED]` runbook.
- Print a runbook's `File:` path, its step titles, its prompts, or any
  `Done:` line. None of those are in the index, and reaching for them means
  opening a body. The one-line title from the heading is not one of these —
  it is in the index, and printing it costs nothing.
- Treat a missing or empty `.claude/RUNBOOKS.md` as an error, create it, or
  suggest running a setup command — runbooks need no setup step.
- Suggest next actions, recommend which runbook to resume, or comment on how
  long one has been `[RUNNING]`. Just list.
- Run, resume, append to, or delete a runbook. Those are `/runbook-run`,
  `/runbook-create --append` and `/runbook-clean`.
