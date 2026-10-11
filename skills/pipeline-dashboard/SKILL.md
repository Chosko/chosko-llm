---
name: pipeline-dashboard
version: 0.2.0
type: skill
description: 'Keep a live, private Artifact dashboard of the pipeline progress — milestone, runbook steps, tasks — and show on it any question waiting for the user. Trigger whenever a /runbook-run, a /task-implement or any multi-task run starts or is in progress in a project with a .claude/TASKS.md or .claude/RUNBOOKS.md, and whenever the user asks how the work stands ("come siamo messi", "a che punto siamo", "dashboard"). Followed by the orchestrating session only, never by a subagent.'
---

# /pipeline-dashboard
# Global skill: keep one private claude.ai Artifact per project showing the
# pipeline's progress live while a run is in progress, with a banner and a
# modal for a question waiting for the user, and print a compact text
# snapshot when the user asks how things stand. Not invoked by the user —
# selected from the description above, and cited by `runbook-run` and
# `task-implement`. Only the orchestrating session regenerates and
# publishes. State lives in the user scope, never in the working tree;
# nothing is committed. A dashboard failure is one warning line and never
# blocks, pauses or slows the run.
# Bundled: `./scripts/generate.sh` (the page's data, the page itself, the
# text snapshot), `./scripts/watch.sh` (task status events for the Monitor
# tool), `./assets/index.html` (the page).

GOAL
While pipeline work runs, the user can open one link from anywhere and see
where the run is, and sees at once when the run waits for an answer from
them. Answers are always typed in the terminal; the page never takes input.

---

WHO DOES THIS

Only the main session — the one orchestrating the run — follows this skill.
A subagent, a delegated `/task-implement` agent or a runbook step's agent
never runs the generator, writes the state folder or calls the Artifact
tool; it changes the indexes as its own work requires, and the watcher
below carries those changes to the main session.

---

FILES

Run every script from the project root, by its path in this skill's folder.

- `./scripts/generate.sh --print-state-dir` prints the project's state
  folder, `${CLAUDE_HOME:-$HOME/.claude}/pipeline-dashboard/<slug>/`, where
  `<slug>` is `<owner>-<repo>` of the `origin` remote, else the folder name.
- `./scripts/generate.sh` reads `.claude/PLAN.md`, `FEATURES.md`,
  `TASKS.md`, `RUNBOOKS.md`, the runbook body and the task archive, plus the
  state folder's `pending.json`, and writes into the state folder
  `index.html` (from `./assets/index.html`, titled `Pipeline <project>`) and
  `data.js`; it prints the `data.js` path. Any index may be absent; a
  source it cannot read is named on the page, never shown as zero progress.
- `./scripts/generate.sh --text` prints the text snapshot.
- `./scripts/watch.sh` prints one line per task status change in
  `TASKS.md`, every 10 seconds.

The state folder holds `url`, `index.html`, `data.js` and `pending.json`.
Nothing is written in the working tree.

---

PUBLISHING

**Order.** Regenerate only after every status marker of the event is
written — the task's `Status:`, the step's mark, the `RUNBOOKS.md` block.
A page generated before the mark shows a state the files have already left.

**Every update:** run the generator, then copy the state folder's
`index.html` and `data.js` into `<scratchpad>/pipeline-dashboard/<slug>/` —
the Artifact tool publishes only files under the session's working
directories or its scratchpad, and the working tree is never the place —
and publish that copy:

- **`url` exists in the state folder** → `read` that URL with the Artifact
  tool (required before updating an artifact from an earlier conversation),
  then publish the copied `index.html` to that `url` with
  `files: {"data.js": <the copied data.js>}`.
- **No `url`** → list the user's artifacts and look for one titled
  `Pipeline <project>`, the project being the repository folder's name. Found
  → read it and publish to its URL as above. Not found → publish
  `index.html` with `files: {"data.js": …}`, `icon: "chart"` and a one-line
  description. Either way, write the URL to `<state>/url`.

A session with no scratchpad cannot publish: that is a failure, handled as
WHEN SOMETHING FAILS says.

One artifact per project, on every machine: never publish without `url`
when an artifact with the project's title exists.

---

WHEN TO REFRESH

1. The run starts, and the run ends — a stop on failure included.
2. A task's status changes: one watcher event.
3. A runbook step changes mark.
4. A question starts waiting for the user, and again once it is answered.
5. The user asks for it.

**The watcher.** At run start, load the Monitor tool (deferred: ToolSearch)
and arm it on `./scripts/watch.sh` with the maximum timeout and a
description naming the project. Each event line is trigger 2. A monitor
expires after 30 minutes: re-arm it while the run is still in progress, and
say so in one short line only when re-arming after a gap with no watch.
Stop it at run end.

**After each republish,** one short line in chat, in the user's language
(Italian by default), naming what changed — "Dashboard aggiornata: è partito
il task 221." No version number and no URL, except on the first publish of
the project, which gives the link, and whenever the user asks for it.

---

PENDING QUESTIONS

When a question waits for the user — relayed from a step, asked by
`/task-implement`, parked under `unattended` — the main session writes it to
`<state>/pending.json`, in the user's language, then refreshes:

```json
{"id": "step5-task150-q1", "where": "Passo 5 · record-production · task 150", "title": "…", "question": "…", "options": [{"key": "a", "text": "…"}], "recommended": "a", "why": "…"}
```

`id` is stable and unique per question. Once the user answers, write `null`
to the file and refresh again. The question is also asked in the terminal as
the orchestrating skill prescribes; the page only shows it.

---

TEXT SNAPSHOT

When the user asks how things stand, run `./scripts/generate.sh --text` and
print its output in a code block. Never print it on every event, and never
open split panes or terminal side panels for it.

---

WHEN SOMETHING FAILS

The generator errors, a publish is refused, the Artifact tool or the Monitor
tool is not available: print one warning line naming what failed and go on
with the run as if this skill were absent. Never retry in a loop, never wait
on the dashboard, never fabricate a value the indexes did not give. Without
the Artifact tool, the text snapshot on request is the whole of this skill.
