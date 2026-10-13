---
name: pipeline-dashboard
version: 0.3.1
type: skill
project-policy: line:Pipeline dashboard policy=on|off
description: 'Print a text snapshot of where the pipeline work stands — milestone, runbook steps, tasks — and, for a run with the dashboard switched on, keep a private Artifact page of it live with any question waiting for the user. Trigger only when the user explicitly asks for an overview of the pipeline''s progress ("how far along is the pipeline", "pipeline status", "show the dashboard") in a project with a .claude/TASKS.md or .claude/RUNBOOKS.md. Not for: a question about one task, feature or step; git, CI or build status; a run already in progress, which names this skill itself when its dashboard is on. Followed by the orchestrating session only, never by a subagent.'
---

# /pipeline-dashboard
# Global skill: print a text snapshot of the pipeline's progress when the
# user asks for an overview of it, and, for a run with the dashboard switched
# on, keep one private claude.ai Artifact per project live with that progress
# and any question waiting for the user. Opt-in, off by default: on for a run
# with `--dashboard`, off with `--no-dashboard`, otherwise on only when the
# project's `CLAUDE.md` carries `Pipeline dashboard policy: on`. When off, nothing
# below the opt-in rule is read and nothing is published. Not invoked by the
# user — selected from the description above, and named by `runbook-run` and
# `task-implement`. State lives in the user scope, never in the working
# tree; nothing is committed.
# Usage: Pipeline dashboard policy: on              (line in the project's CLAUDE.md)
#        /runbook-run <runbook> --dashboard | --no-dashboard
#        /task-implement <tasks> --dashboard | --no-dashboard
# Bundled: `./references/protocol.md` (what the main session does while the
# dashboard is on), `./scripts/generate.sh` (the page's data, the page
# itself, the text snapshot), `./scripts/watch.sh` (task status events for
# the Monitor tool), `./assets/index.html` (the page).

GOAL
Show the user where pipeline work stands whenever they ask, and — when the
project or the run opts in — let them follow a long run from a live page that
also shows the question the run is waiting on.

- A project that does not opt in pays nothing beyond this file.
- Keep every state file in the user scope, never in the working tree; commit
  nothing.
- Follow this skill in the orchestrating session only, never in a subagent.

---

OPT-IN

Resolve it once per run of `/runbook-run` or `/task-implement`:

- `--dashboard` → on for that run; `--no-dashboard` → off for that run,
  whatever the project says.
- Neither flag → the line `Pipeline dashboard policy: on` in the project's
  `CLAUDE.md` turns it on; `Pipeline dashboard policy: off`, or no such
  line, leaves it off.

Then:

- **On** → read `./references/protocol.md` and follow it for the rest of
  the run, in the main session only.
- **Off** → do nothing more for the run: no generator, no watcher, no
  publish, no chat line.

---

TEXT SNAPSHOT

When the user asks for an overview of the pipeline's progress, whatever the
opt-in:

- Run `./scripts/generate.sh --text` from the project root and print its
  output in a code block.
- Never print it on every event.
- Never open split panes or terminal side panels for it.
