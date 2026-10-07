---
name: session-list
version: 0.1.0
type: command
description: Print the handoffs under .claude/sessions/ one line each, newest first — date, slug, what the session was anchored to and its next step — without opening any of them. Use it to find the handoff to describe or resume.
requires: command:session-save
---

# /session-list
# Global command: print one line per handoff in `.claude/sessions/`, newest
# first — when it was saved, its slug, its `Work:` value and the first
# sentence of its exact next step, or the artifact a pointer-form file points
# at. A handoff with orchestrate-mode area handoffs beside it shows how many.
# Read-only — writes, deletes, stages and commits nothing, and corrects no
# file however malformed. Reads with one search over the store and never a
# full file; runs no shell command. A missing or empty store is not an error.
# Usage: /session-list
# Examples: /session-list

GOAL
Show which handoffs exist and what each is about, so the right one can be
found without opening files. This is an orientation command: it must not
write, edit or commit anything, and it does not brief — describing one
handoff is `/session-describe`, loading one is `/session-resume`.

$ARGUMENTS

`$ARGUMENTS` is ignored: this command takes no argument and no filter.

---

THE STORE

The file names, the two file forms, the header block (`Work:`, `Running:`,
and `Resume from:` in the pointer form) and the section headings are
`/session-save`'s, and are not restated here.

A **session** is a top-level file in `.claude/sessions/` carrying a `Work:`
line — `/session-resume`'s candidacy rule. Anything else is skipped silently:
a file with no `Work:` line, `pending/`, and every subfolder and its
contents. A subfolder whose name is the stem of a session file holds that
session's orchestrate-mode area handoffs, `agent-<area>.md`; it is counted,
never read.

---

READ BUDGET

- **One search** — the Grep tool over `.claude/sessions/`, for lines
  starting `Work:`, `Resume from:` or the *Exact next step* section heading,
  with the two lines after each match, so the heading's first non-blank line
  comes with it. Matches in subfolders are dropped.
- **One listing per session that has a subfolder** — the file-listing tool
  on `.claude/sessions/<session-file-stem>/`, counting the `agent-*.md`
  filenames. No area handoff is opened.
- **Never a full read** of any file, and no shell command of any kind —
  no `ls`, `grep`, `find` or `git`.

The cost stays flat in the size of each handoff: header lines and one line
of each next step, whatever the files hold.

---

WORKFLOW

1. If `.claude/sessions/` does not exist, or the search finds no session,
   print one line and stop:

   > No saved sessions in this project — `/session-save` writes one.

   Do not create the directory and do not offer to.

2. Sort the sessions on the **full filename**, descending — the newest
   first, ties broken the way `/session-resume` breaks them.

3. Print one line per session, inside one fenced code block so the
   alignment survives markdown rendering:

   ```
   <YYYY-MM-DD HH:MM>  <slug>  <Work: value>  — <first sentence of the next step>
   ```

   - Date, time and slug come from the filename,
     `YYYY-MM-DD-HHMM-<slug>.md`. A filename outside that shape prints its
     stem in place of all three.
   - The next step is the first sentence of the first non-blank line under
     the *Exact next step* heading — up to its first `.`, `?` or `!`, or the
     end of that line.
   - A **pointer-form** file — one carrying `Resume from:` — prints
     `→ <Resume from: path>` in place of the next step and ends its line
     with `[pointer]`.
   - A session with a subfolder of its stem ends its line with
     `[areas: <n>]`, n being the number of `agent-*.md` files in it.
   - Pad every column to the widest value present. Truncate nothing.

4. After the lines, inside the same fenced block, print the count:
   `4 sessions.` — `1 session.` for one.

The whole shape, for reference:

```
2026-08-26 09:10  orchestrate-checkout  task 141                                   — Run the checkout area's verification recipe.  [areas: 3]
2026-08-24 14:32  product-design        document .claude/domain/product-design.md  → .claude/domain/design-process.md  [pointer]
2026-08-24 14:30  ecc-import-arch       none — cross-feature architecture session  — Author the remaining two feature documents.

3 sessions.
```

A session missing a field prints what it has — no next-step line leaves that
column empty. A file that looks malformed is listed as found and never
corrected.

---

DO NOT:
- Suggest which session to resume, or comment on a session's age. Just list.
