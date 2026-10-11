# Pipeline dashboard

A global skill that, while pipeline work runs or whenever the user asks how
things stand, keeps a private claude.ai Artifact page showing the project's
progress — milestone, runbook steps, tasks, features — live, and shows on it
any question waiting for the user's answer; plus a compact text snapshot on
request. Bundled with it: the page template, a generator that turns the
project's indexes into the page's data, and the text renderer.

## Purpose

A `/runbook-run` or a multi-task `/task-implement` runs for hours, mostly
unattended, and its state is scattered across `TASKS.md`, `RUNBOOKS.md`, a
runbook body and `FEATURES.md`. The director wants to glance at a phone and
see where the run is, and — the costly case — to notice at once that the run
is blocked on a question only they can answer. A live Artifact page is the
one surface reachable from anywhere; the terminal stays the only place
answers are given.

The prototype built for one project was approved as a design; this feature
generalises it so every value comes from the project's own indexes.

## Scope and non-goals

In scope:

- The skill body: activation, ownership, refresh triggers, publish protocol,
  pending-question protocol, chat lines, degradation.
- The generator (data for the page, and the text snapshot) and the page.
- Per-project state in the user scope.
- One citation line in `runbook-run` and `task-implement`.

Non-goals:

- **Collecting answers on the page.** The page never takes input; every
  answer is typed in the Claude Code terminal.
- **Split panes or terminal side panels.** Tried and rejected by the user.
- **Printing the text snapshot on every event.** Only on request.
- **Writing in the working tree.** No state, no generated file, no commit in
  the project.
- **Subagents publishing.** Only the orchestrating session owns the
  dashboard.
- **A second artifact for the same project**, on any machine.
- **Hard dependency.** The orchestrators cite the skill by name; without it
  they behave exactly as without the citation.
- **New dependencies.** No jq or Python; the page loads only Google Fonts.

## Architecture

Built on bash and awk per `technical-direction.md` (no jq, git-bash on
Windows); the page is a self-contained HTML Artifact with one data file.
The skill is a skill-kind feature with supporting files
(`.claude/context/features.md`), installed globally like the rest of the
pipeline.

### Skill body — `skill:pipeline-dashboard`

The protocol the orchestrating session follows.

- **Activation.** The `description` makes it load on its own whenever a
  pipeline run starts or is in progress in a project with `.claude/TASKS.md`
  or `.claude/RUNBOOKS.md`, and whenever the user asks about progress
  ("come siamo messi", "a che punto siamo", "dashboard").
- **Ownership.** Only the main session regenerates and publishes; a
  subagent never writes the dashboard's state or calls the Artifact tool.
  Subagents still change the indexes, and the main session sees those
  changes through the watcher.
- **Ordering.** Regenerate only after every status marker of the event is
  written — task status, step mark, `RUNBOOKS.md` — so the page never shows
  a state the files have already left.
- **Refresh triggers.** Run start and run end (a failure stop included);
  every task status change, seen by the watcher; every runbook step
  transition; a question for the user, and again once answered; a request.
  After each republish, one short line in chat in Italian naming what
  changed ("Dashboard aggiornata: è partito il task 221."), with no version
  or URL except on the first publish, which gives the link.
- **Watcher.** The Monitor tool (deferred, loaded by ToolSearch) runs a
  10-second snapshot of the in-scope task statuses and emits one line per
  change; each line is an event. Monitors expire after 30 minutes: re-armed
  while the run is active, with one short line only when re-arming after a
  gap.
- **Degradation.** Generator error, publish refused, Monitor or Artifact tool
  unavailable: one warning line, and the run continues untouched — the
  dashboard never blocks or slows the pipeline.

### Generator

A bundled script; one awk pass over the indexes. It writes the page's data
file, or with a text flag prints the text snapshot from the same model, so
the two views can never disagree. Fast on git-bash: a single awk process,
file existence tested inside awk. Every index may be absent; the generator
emits whatever exists and marks what it could not read, which the page
shows as such rather than as zero progress.

### Page

The approved prototype's design, made generic: Italian UI, the "mixing desk"
look (Familjen Grotesk, IBM Plex Sans, IBM Plex Mono from Google Fonts),
colour tokens on `:root` with the dark variant under
`prefers-color-scheme` guarded by `:root:not([data-theme="light"])` and
repeated under `[data-theme="dark"]`; done green, running amber with a pulse
(off under `prefers-reduced-motion`), todo grey, failed red. Sections, top to
bottom: header (eyebrow `<project> · milestone <id>`, h1
`Avanzamento <milestone>`, a subtitle derived from the data); the pending
banner; three VU meters ("Passi del runbook", "Task <milestone> completati"
with segments capped near 47, "Feature <milestone> chiuse"); the "In corso"
box; the "Tracklist del runbook" (per step: number, feature or label, task
range and d/t, one square per task with a `#id title — STATUS` tooltip and
PARTIAL / INCORRECT / STALE in red, status chip, `Done:` line); legend;
footer "Aggiornato <generated> · dati da TASKS.md, FEATURES.md e dal
runbook". Phone width with a 16 px gutter and no horizontal scroll; the DOM
is built with `textContent`, never `innerHTML` from data. Without a milestone
the eyebrow and h1 name the project and the meters drop the milestone label.

The pending modal: where, title, question, options with the recommended one
highlighted and marked "(consigliata)", "Perché la consiglio: …", and
"Rispondi nel terminale di Claude Code con la lettera dell'opzione". It opens
by itself once per question id (remembered in `localStorage` inside
try/catch), reopens from the banner, closes on button, backdrop or Esc, with
focus moved in and restored.

### Text snapshot

On a progress question in chat: a compact code block — header, step and task
bars, the last two done steps and every remaining one with a mini bar per
step, the running task under its step, the last three tasks done.

### Citation in the orchestrators

`runbook-run` and `task-implement` each gain one line: while orchestrating,
the main session follows the `pipeline-dashboard` skill when it is available.
The line names the skill and restates none of its rules.

## Data and state

- **The project's indexes** — the source of truth for every value shown;
  read on each regeneration, never written.
  - Milestone: the `[ACTIVE]` block of `.claude/PLAN.md` — id, title,
    `Features:`. None (no plan, or no active block): scope is every task.
  - Features: each listed feature's `Status:` and `Tasks:` from
    `FEATURES.md`.
  - Tasks: the milestone's tasks `{id, title, status, feature}` from
    `TASKS.md`; an id absent there but present in the task archive counts
    DONE.
  - Runbook: the first `[RUNNING]` block of `RUNBOOKS.md`, else the last —
    name, status, and from its body the steps `## [m] <n>. <title>` with
    their `Done:` line, up to `## Do not re-propose`. A step's tasks come from
    `(task N)` / `(tasks N–M)` in its title, else from the tasks whose
    `Feature:` is the feature slug the title names.
  - Units in flight: the worktree registry, `worktrees/<unit>/HEAD` under the
    common git dir, probed per shown task and per step without a git call; a
    `wt/task-<N>` entry renders the task `IN PROGRESS`, a
    `wt/runbook-<id>-step-<n>` entry the step running
    ([worktree-isolation](./worktree-isolation.md)).
- **The data model** (generated, never hand-written): `milestone`,
  `features`, `tasks`, `runbook`, `pending`, `generated` (local timestamp),
  plus the project label and the list of indexes that could not be read.
- **Per-project state**, in `${CLAUDE_HOME:-$HOME/.claude}/pipeline-dashboard/<slug>/`:
  `url` (the artifact link), `index.html` and the data file (what is
  published, through a copy in the session scratchpad, since the Artifact
  tool publishes only from the working directories or the scratchpad),
  `pending.json`. The slug comes from the `origin` remote
  (`<owner>-<repo>`, lower case), else the repository folder's name.
- **The artifact** — one per project. Its `<title>` is fixed per project
  (`Pipeline <repo>`), which is what lets another machine find it.

## Interfaces and contracts

- **Publish.** First publish for a project on a machine with no stored `url`:
  list the user's artifacts and look for the project's fixed title; found →
  read it and republish to it; not found → publish the page with its data
  file and icon `chart`. Either way, store the `url`. Every later update, in
  any session: read the stored `url`, then republish to it. A publish that
  is refused is one warning line; the stored `url` is kept.
- **Pending question.** Written by the orchestrator, in Italian, when a
  question waits for the user, then the dashboard republishes; cleared to
  `null` once answered, then republishes again:
  `{"id", "where", "title", "question", "options": [{"key", "text"}], "recommended", "why"}`,
  `id` stable and unique per question (e.g. `step5-task150-q1`).
- **Generator.** Run from the project root; writes the data file into the
  state folder, or prints the text snapshot with its text flag; exit 0 with a
  partial model when indexes are missing; a non-zero exit only when it cannot
  write at all.
- **Chat lines.** One per republish, Italian, naming the change; the link
  only on the first publish or when asked.
- **Failure contract.** No dashboard failure ever fails, pauses or delays a
  run; no data is invented — unreadable sources are named on the page.

## Dependencies

- **Artifact tool** (claude.ai): publish, read, list. Absent → text snapshot
  only, one warning.
- **Monitor tool** (deferred): the status watcher. Absent → refresh only on
  the explicit triggers, one warning.
- **runbook-suite**, **task-archive**, **production-plan**, **backlog
  ordering**: the formats read (`RUNBOOKS.md` blocks and step markers, the
  archive rule, the `PLAN.md` block, `TASKS.md` blocks and `Feature:`).
- **unattended-parking**: a parked question is a pending question when the
  orchestrator relays it.
- **pipeline-statusline**: none at run time; both read the same indexes with
  separate code (copy-on-install shares none), and their scopes differ — the
  status line follows the runbook, the dashboard the active milestone.
- **Google Fonts**, for the page's three families.
