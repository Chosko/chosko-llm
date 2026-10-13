# Pipeline dashboard protocol

Read by path by `../SKILL.md`, only once a run's dashboard has resolved on;
followed by the main session for the rest of that run.

---

WHO DOES THIS

- Only the main session — the one orchestrating the run — follows this
  protocol.
- A subagent, a delegated `/task-implement` agent or a runbook step's subagent
  never runs the generator, writes the state folder or calls the Artifact
  tool. It changes the indexes as its own work requires; the watcher below
  carries those changes to the main session.

---

FILES

Run every script from the project root, by its path in the skill's folder.

- `../scripts/generate.sh --print-state-dir` prints the project's state
  folder, `${CLAUDE_HOME:-$HOME/.claude}/pipeline-dashboard/<slug>/`, where
  `<slug>` is `<owner>-<repo>` of the `origin` remote, else the folder name.
- `../scripts/generate.sh` reads `.claude/PLAN.md`, `FEATURES.md`,
  `TASKS.md`, `RUNBOOKS.md`, the runbook body and the task archive, plus the
  state folder's `pending.json`, and writes into the state folder
  `index.html` (from `../assets/index.html`, titled `Pipeline <project>`) and
  `data.js`; it prints the `data.js` path. Any index may be absent; a
  source it cannot read is named on the page, never shown as zero progress.
- `../scripts/watch.sh` prints one line per task status change in
  `TASKS.md`, every 10 seconds.

The state folder holds `url`, `index.html`, `data.js` and `pending.json`.
Nothing is written in the working tree.

---

PUBLISHING

**Order.** Regenerate only after every status marker of the event is
written — the task's `Status:`, the step's mark, the `RUNBOOKS.md` block, a
feature's `Status:` in `FEATURES.md`. A page generated before the mark shows
a state the files have already left.

**Every update.**
1. Run the generator.
2. Copy the state folder's `index.html` and `data.js` into
   `<scratchpad>/pipeline-dashboard/<slug>/`. The Artifact tool publishes
   only files under the session's working directories or its scratchpad,
   and the working tree is never the place.
3. Publish that copy:
   - **`url` exists in the state folder** → before this session's first
     publish to it, `read` that URL once with the Artifact tool (required
     before updating an artifact from an earlier conversation). Then, on
     every update, that first one included, publish the copied `index.html`
     to that `url` with `files: {"data.js": <the copied data.js>}`. Do not
     read it again later in the same session.
   - **No `url`** → list the user's artifacts and look for one titled
     `Pipeline <project>`, the project being the repository folder's name.
     - Found → read it and publish to its URL as above.
     - Not found → publish `index.html` with `files: {"data.js": …}`,
       `icon: "chart"` and a one-line description.
     - Either way, write the URL to `<state>/url`.
- A session with no scratchpad cannot publish: treat it as a failure, per
  WHEN SOMETHING FAILS.
- One artifact per project, on every machine: never publish without `url`
  when an artifact with the project's title exists.

---

WHEN TO REFRESH

1. The run starts, and the run ends — a stop on failure included.
2. A task's status changes: one watcher event.
3. A runbook step changes mark.
4. A question starts waiting for the user, and again once it is answered.
5. The user asks for it.

**The watcher.**
- At run start, load the Monitor tool (deferred: ToolSearch) and arm it on
  `../scripts/watch.sh` with the maximum timeout and a description naming
  the project. Each event line is trigger 2.
- A monitor expires after 30 minutes: re-arm it while the run is still in
  progress, and say so in one short line only when re-arming after a gap
  with no watch.
- Stop it before the run-end refresh.

**After each republish.**
- Print one short line in chat naming what changed — "Dashboard updated:
  task 221 started."
- No version number and no URL, except on the first publish of the project,
  which gives the link, and whenever the user asks for it.

---

PENDING QUESTIONS

When a question waits for the user — relayed from a step, asked by
`/task-implement`, parked under `unattended`:

- Write it to `<state>/pending.json`, in English, then refresh:

```json
{"id": "step5-task150-q1", "where": "Step 5 · record-production · task 150", "title": "…", "question": "…", "options": [{"key": "a", "text": "…"}], "recommended": "a", "why": "…"}
```

- Keep `id` stable and unique per question.
- Once the user answers, write `null` to the file and refresh again.
- The question is still asked in the terminal as the orchestrating skill
  prescribes; the page only shows it.

---

WHEN SOMETHING FAILS

The generator errors, a publish is refused, the Artifact tool or the Monitor
tool is not available:

- Print one warning line naming what failed and go on with the run as if the
  dashboard were off.
- Never retry in a loop, never wait on the dashboard, never fabricate a value
  the indexes did not give.
