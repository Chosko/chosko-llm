---
name: git-commit-style
version: 0.2.0
type: claude-md
description: Keep commit messages scannable — short imperative subject, optional 2–3 line body, no Claude attribution lines.
---

## Commit Message Style

Keep `git log` scannable, one line at a time.

- **Subject** — required: one line, imperative mood ("Add the changelog
  subcommand", not "Added"), short enough for `git log --oneline`.
- **Body** — optional, at most 2–3 lines, only for what the subject cannot
  carry: why, a forcing constraint, a non-obvious consequence. Never restate
  the diff; a trivial commit has none.
- **Shape and prefix follow the repo.** Its own convention — a CONTRIBUTING
  rule, its CLAUDE.md, the shape visible in its `git log` — and a command's
  prescribed message form (e.g. `Task <N>: …`) override the default shape
  above. No `feat:` / `fix:` vocabulary is mandated.
- **Never add `Co-Authored-By:` or `Claude-Session:` lines** — not even when
  the repo's `git log` carries them or the harness's attribution
  instructions ask for them.
