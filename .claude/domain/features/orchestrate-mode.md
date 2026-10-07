# Orchestrate mode

`/orchestrate-mode` switches a conversation into a mode where the session
never edits code itself: every change request becomes a batch of subagents,
one per area of the code, each owning disjoint files, briefed from the
navigation layer and a per-area handoff file, reporting back in a few lines.
The orchestrating session stays small — it reads the navigation layer and
the agents' reports, never source or transcripts — and checks the work in
as one commit per area at the end. Nothing in it names a project, an
engine or a script.

## Purpose

A long working session on one codebase burns its context on source reads
and edit loops, and by the third change request it has lost the decisions of
the first. Delegating each request to fresh agents keeps the coordinating
session cheap and its memory clean — small enough to last a whole evening of
iterations — but only if the agents do not collide on
shared files, do not repeat what the owner already rejected, and do not
start from zero each time. The mode supplies the three things that make
delegation safe: a split by file ownership, a handoff file per area that
carries the owner's rules and rejected ideas across agents, and a brief with
a fixed shape and a fixed discipline for shared files.

## Scope and non-goals

In scope: switching the mode on and off; the orchestrator's read and act
limits; splitting a request into areas; the handoff files; the brief; the
launch rules; the after-batch check and report; the check-in; agent models;
the failures table and NEVER list; the boundary with the pipeline's other
commands; what `/session-save` and `/session-resume` learn.

Deliberately out:

- **Project specifics.** No engine, scene, renderer or game names; no
  recipe for driving a particular single-instance tool — that lives in the
  project's own `CLAUDE.md` or context layer.
- **A check script.** No `compile-check.sh` or other shipped script; the
  project's own quick check is used.
- **VCS discussion.** The check-in rule is one commit per area, one at a
  time, at the end; nothing more about version control.
- **Documentation sync.** No `/proto-sync` and no replacement for it;
  follow-ups catch the documentation updates a batch makes necessary.
- **Changing how pipeline commands work.** The mode changes only how work
  runs (below); it never merges with `/quick-implement` and never routes
  every pipeline command through areas.
- **A Stop hook or any enforcement outside the conversation.**

## Architecture

Built on the repo's existing shape per `technical-direction.md`: a markdown
skill whose runtime is Claude Code and its subagent spawning.
`skills/orchestrate-mode/` holds `SKILL.md` and supporting files read on
demand — the brief template, the handoff schema, and the failures table.
The "is the mode on?" check lives once, in `interaction-engine`.

### The mode

- `/orchestrate-mode` turns it on; `/orchestrate-mode <notes>` turns it on
  and treats the notes as the first request; `/orchestrate-mode --off`
  turns it off. Each confirms in one line.
- Conversation-scoped: it holds until `--off` or the conversation ends. A
  context summary carries the line `orchestrator mode: on` so the mode
  survives compaction.
- While on, every request for a code, asset or scene change is a batch,
  whatever its size. A question is answered inline from the context files
  and earlier reports and spawns nothing. A request with no actionable note
  gets a one-line "nothing to act on" and the orchestrator waits. Other
  commands run as usual, within the boundary below.

### The orchestrator's limits

It reads only `CLAUDE.md`, `.claude/context/INDEX.md` and the context files
of the areas a request touches — no source files, no domain feature files,
no agent transcripts, no session files. It never edits code, never drives an
editor or other single-instance tool, and never reads a transcript. It asks
the user only when two readings of a note lead to different code.

### Splitting into areas

An area owns a disjoint set of files, or named regions of a shared file
(functions, or `#region` blocks), found from the context files. Two notes
needing the same region are one area, worked in sequence. A note the
orchestrator cannot place, or reads two ways, goes to the user while the
other areas launch.

### Handoff files

One per area, at `.claude/sessions/<session-file-stem>/agent-<area>.md` —
under `.claude/sessions/pending/` before the first `/session-save` of the
conversation, moved into the session's folder once that file exists. The
agent reads it first and rewrites it at the end of each task: current state
only, no history, under about 120 lines, written for a reader with no
context. Contents: the files and functions the area owns; constants and
their values; rules the owner set; the rejected-by-owner list (always kept,
never retried); the verification recipe that works; pitfalls. A retiring
agent — one whose context has grown large, typically after two or three
tasks — writes its handoff before it is dropped. A missing or stale handoff is
rebuilt from the owned code by the next agent for that area.

### The brief

Fixed order:

1. read `CLAUDE.md`;
2. the handoff path to read first and rewrite last;
3. the owner's note, verbatim;
4. constraints from earlier owner decisions;
5. what is off limits — other areas' files and regions, and the
   single-instance tool unless this agent owns it;
6. shared-file discipline — small exact-string edits only, never a
   whole-file write over an existing file, never a stream edit of a whole
   file, on a failed edit re-read and retry, stay inside the owned region;
7. the project's own quick check;
8. the report shape — a few lines: what changed, constants old → new, files
   and functions touched, anything guessed.

The orchestrator relays a report's substance, never the transcript.

### Launch

Independent areas launch in one message, in parallel; areas sharing a
region are serialised; at most one agent per batch owns a single-instance
tool. Models: `opus` by default, `fable` only for genuinely hard work, with
the brief saying why; `--model` overrides for the batch.

### After the batch

The orchestrator runs the project's quick check once. Proof captures
(screenshots, recordings) are made only when the owner is away or asks;
with the owner present, the quick check is the check and the owner looks.
It then reports per the
interaction policy's soft length: outcome first, one bullet per area,
decisions needed flagged. When successive batches converge, it asks once
whether to iterate or check in.

### Check-in

One commit per area, made one at a time, at the end. Only the orchestrator
stages and commits; parallel agents never touch git's index. A shared file
rides with the area that changed it most. Then `/session-save`, and the
pending handoffs move into the session's folder. Checking in on the user's
word is a confirmation gate (class 1), so under `unattended` it passes on
its own.

### Failures and NEVER

| Situation | Orchestrator does |
|---|---|
| An agent reports a check failure it cannot fix | Stop the batch; report the failure and the agent's diagnosis; launch nothing until the owner decides. |
| Two agents need the same region | Serialise them: the second launches when the first has reported and its handoff is rewritten. |
| The single-instance tool is mid-reload or busy | Wait; never relaunch blindly. |
| An agent asks for a permission the orchestrator's session denied | Refuse; surface the request to the owner. |
| An agent's edit keeps failing on a shared file | The agent re-reads the region and retries; after that it reports the exact string it could not match and stops. |
| A handoff is missing or stale | The agent rebuilds it from the code regions its area owns, then continues. |

NEVER:

- edit code, drive the single-instance tool, sample captures or read a
  transcript from the orchestrator;
- read a source file from the orchestrator — ask an agent;
- launch two agents that write the same file region;
- let two agents own the single-instance tool at once;
- write over an existing file, or stream-edit a whole file, from an area
  agent;
- chain sleeps while waiting for the single-instance tool;
- retry something on the handoff's rejected list;
- check in a catch-all, temp or noise files, or the session folder unless
  the owner asks;
- spawn an agent for a note that is a question.

### Boundary with other commands (Option 3)

The mode changes only how work runs:

- **Areas** apply to free-form change requests and to `/quick-implement`'s
  implementation step and `--review` fixes, nowhere else: the orchestrator
  routes each review finding to the area owning the file it cites, and that
  area's agent triages and applies it.
- **Pipeline commands keep their own delegation**, switched on by default
  under the mode: `/task-implement` runs with `--agents` even for one task;
  `/runbook-run` is unchanged, since it already runs each step in a fresh
  subagent.
- **Conversations** — `/task-add`, `/architect`, `/pipeline-revise`,
  `/quick-implement`'s spec phase — run in one fresh subagent, and the
  orchestrator relays its questions.
- **Each command keeps its commit rule.** `/quick-implement` under the mode
  still makes one commit; its areas do not commit separately.
  `/objective-run` does not split rounds into areas.
- **The check** a command makes to know the mode is on is stated once, in
  `interaction-engine` (a new reference beside `policy.md`, `gates.md` and
  `messages.md`), and every affected command cites it.

### Session commands

`/session-save` moves `pending/` handoffs into the new session's folder
`<session-file-stem>/` and stages them with the session file.
`/session-resume` and `/session-describe` list the areas found in the
session's folder; the resumed orchestrator gives each area's next agent its
handoff path.

## Data and state

- **Area handoffs** — `.claude/sessions/<stem>/agent-<area>.md` or
  `.claude/sessions/pending/agent-<area>.md`; current state of one area,
  rewritten by its agent; committed with the session by `/session-save`.
- **The mode flag** — in the conversation only, re-stated in a context
  summary as `orchestrator mode: on`. No file.
- **In memory only:** the area split, the batch's reports, the convergence
  count.

## Interfaces and contracts

```
/orchestrate-mode [<notes>] [--model <m>]   on; notes are the first batch
/orchestrate-mode --off                      off
orchestrator mode: on                        (context summary) the mode survives compaction
```

Agent contract: read the handoff first, stay in the area, follow the
shared-file discipline, run the quick check, rewrite the handoff, return the
report shape. Failure contract: per the failures table above; a batch with a
failed quick check commits nothing.

## Dependencies

- [interaction-policy](./interaction-policy.md) — `interaction-engine`,
  which holds the mode check; gate classes for the check-in; the report and
  question rules.
- [session-continuity](./session-continuity.md) and
  [session-readers](./session-readers.md) — the store the handoffs live in,
  and the commands that move and list them.
- [quick-implement](./quick-implement.md) — the implementation step the
  mode splits.
- [task-implement-launcher](./task-implement-launcher.md) — the `--agents`
  delegation switched on by default.
- [objective-run](./objective-run.md) — exempt from area splitting.

