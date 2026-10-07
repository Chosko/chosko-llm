---
name: git-commit-style
version: 0.1.2
type: claude-md
description: Keep commit messages scannable — short imperative subject, optional 2–3 line body, Claude trailers only on big commits.
---

## Commit Message Style

Write each commit message so that `git log`, read one line at a time, stays
scannable.

**Local style wins.** The rules below are a default shape, not a mandate.
- A repo's own convention overrides them — a CONTRIBUTING rule, its
  CLAUDE.md, or simply the shape visible in its `git log`.
- A command's own prescribed message form overrides them too (e.g.
  task-engine's `Task <N>: …`, `Add task <N>: …`, `task-clean: archive tasks …`).
- The trailer threshold is a default the same way: a repo's own trailer
  convention, whether written down or just visible as an existing
  `Co-Authored-By` habit in `git log`, wins over the numbers below.

**Subject.** Always required; the only part that is.
- One line, imperative mood ("Add the changelog subcommand", not "Added" or
  "Adds").
- Short enough to read whole in `git log --oneline`.

**Body.** OPTIONAL; at most 2–3 lines when present.
- Write one only when it carries something the subject cannot — why the
  change was made, a constraint that forced this shape, a consequence a
  reader would otherwise miss.
- Never restate the diff: the diff is already in the commit.
- On a trivial commit, write no body at all.

**Prefix.** No type-prefix vocabulary is mandated — no `feat:` / `fix:`
requirement. Use whatever prefix convention the repo already uses.

**Trailers — only on big commits.**
- Add `Co-Authored-By: <model>` and `Claude-Session: <url>` only when the
  commit is big.
- "Big" is a size test, not a judgement call: **5 or more files changed, or
  200 or more changed lines (insertions + deletions)**.
- Below that threshold omit both trailers — not "optional", omitted.
- Check it mechanically before committing with `git diff --cached --shortstat`.
