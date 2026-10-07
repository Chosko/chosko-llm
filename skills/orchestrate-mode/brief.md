# The area brief

Every area agent is launched with a brief in this fixed order. Fill each part;
none is skipped.

1. **Read `CLAUDE.md`** first, and follow its navigation instructions.
2. **The handoff.** Its path, per `./handoff.md`. Read it before anything
   else; rewrite it as the last act of the task. When it is missing or stale,
   rebuild it from the code regions this area owns, then continue.
3. **The owner's note**, verbatim.
4. **Constraints** from earlier owner decisions in this conversation that
   bear on this area.
5. **Off limits** — every other area's files and regions, named; and the
   single-instance tool unless this agent owns it.
6. **Shared-file discipline:**
   - small exact-string edits only;
   - never a whole-file write over an existing file;
   - never a stream edit of a whole file;
   - on a failed edit, re-read the region and retry once; if it fails again,
     report the exact string that did not match and stop;
   - stay inside the owned region.
7. **The quick check** — the project's own quick check, run before
   reporting. Do not stage or commit anything.
8. **The report shape** — a few lines:
   - what changed;
   - constants, old → new;
   - files and functions touched;
   - anything guessed.

When the work is genuinely hard and the agent runs on `fable`, the brief says
why in one line under part 3.
