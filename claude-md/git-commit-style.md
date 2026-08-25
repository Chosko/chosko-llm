---
name: git-commit-style
version: 0.1.0
type: claude-md
description: Keep commit messages scannable — short imperative subject, optional 2–3 line body, Claude trailers only on big commits.
---

## Commit Message Style

A commit message is read in `git log`, one line at a time. Write it so that
log stays scannable.

**Subject.** One line, imperative mood ("Add the changelog subcommand", not
"Added" or "Adds"), short enough to read whole in `git log --oneline`. It is
the only part that is always required.

**Body.** OPTIONAL, and at most 2–3 lines when present. Write one only when
it carries something the subject cannot — why the change was made, a
constraint that forced this shape, a consequence a reader would otherwise
miss. Never restate the diff: the diff is already in the commit. On a trivial
commit, write no body at all.

No type-prefix vocabulary is mandated here — no `feat:` / `fix:` requirement.
Whatever prefix convention a repo already uses is the one to use.

**Trailers — only on big commits.** `Co-Authored-By: <model>` and
`Claude-Session: <url>` are added only when the commit is big, and "big" is a
size test, not a judgement call: **5 or more files changed, or 200 or more
changed lines (insertions + deletions)**. Below that threshold both trailers
are omitted — not "optional", omitted. Check it mechanically before
committing with `git diff --cached --shortstat`.

Those numbers are roughly the 75th percentile of the `chosko-llm` repo's own
history (median 3 files / 82 changed lines; p75 6 files / 250 changed lines
over the last 200 commits), i.e. the top quarter of commits by size.

**Local style wins.** This is a default shape, not a mandate. A repo's own
convention — a CONTRIBUTING rule, its CLAUDE.md, or simply the shape visible
in its `git log` — overrides it, and so does any command's own prescribed
message form (e.g. task-engine's `Task <N>: …`, `Add task <N>: …`,
`task-clean: remove tasks …`). The trailer threshold is a default the same
way: a repo's own trailer convention, whether written down or just visible as
an existing `Co-Authored-By` habit in `git log`, wins over the numbers above.
