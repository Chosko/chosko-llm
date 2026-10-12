---
name: pipeline-dashboard
version: 0.2.0
type: skill
description: 'Report how the pipeline work stands — milestone, runbook steps, tasks — as a text snapshot, and, for a run with the dashboard switched on, keep a private Artifact page of that progress live, with any question waiting for the user. Trigger whenever the user asks how far along the work is ("how far along are we", "progress", "dashboard") in a project with a .claude/TASKS.md or .claude/RUNBOOKS.md, and whenever a /runbook-run or /task-implement run with the dashboard switched on is in progress. Followed by the orchestrating session only, never by a subagent.'
---

# /pipeline-dashboard
# Global skill: print a text snapshot of the pipeline's progress when the
# user asks how things stand, and, for a run with the dashboard switched on,
# keep one private claude.ai Artifact per project live with that progress and
# any question waiting for the user. Opt-in, off by default: on for a run
# with `--dashboard`, off with `--no-dashboard`, otherwise on only when the
# project's `CLAUDE.md` carries `Pipeline dashboard: on`. When off, nothing
# below the opt-in rule is read and nothing is published. Not invoked by the
# user — selected from the description above, and named by `runbook-run` and
# `task-implement`. State lives in the user scope, never in the working
# tree; nothing is committed.
# Usage: Pipeline dashboard: on                     (line in the project's CLAUDE.md)
#        /runbook-run <runbook> --dashboard | --no-dashboard
#        /task-implement <tasks> --dashboard | --no-dashboard
# Bundled: `./references/protocol.md` (what the main session does while the
# dashboard is on), `./scripts/generate.sh` (the page's data, the page
# itself, the text snapshot), `./scripts/watch.sh` (task status events for
# the Monitor tool), `./assets/index.html` (the page).

GOAL
The user sees where pipeline work stands whenever they ask, and — when the
project or the run opts in — can follow a long run from a live page that
also shows the question the run is waiting on. A project that does not opt in
pays nothing beyond this file.

---

OPT-IN

For a run of `/runbook-run` or `/task-implement`:

- `--dashboard` turns the dashboard on for that run, and `--no-dashboard`
  turns it off, whatever the project says;
- with neither, a line `Pipeline dashboard: on` in the project's `CLAUDE.md`
  turns it on;
- anything else leaves it off.

**On** → read `./references/protocol.md` and follow it for the rest of the
run, in the main session only. **Off** → do nothing more for the run: no
generator, no watcher, no publish, no chat line.

---

TEXT SNAPSHOT

When the user asks how the work stands, whatever the opt-in: run
`./scripts/generate.sh --text` from the project root and print its output in
a code block. Never print it on every event, and never open split panes or
terminal side panels for it.
