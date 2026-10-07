---
name: orchestrate-mode
version: 0.1.1
type: skill
description: Switch this conversation into orchestrate mode — the session never edits code itself and turns every change request into a batch of per-area subagents with disjoint file ownership, briefed from the navigation layer and a per-area handoff file, checked in as one commit per area at the end. Use it for a long working session of many change requests on one codebase.
requires: skill:interaction-engine
---

# /orchestrate-mode
# Global skill: a conversation-scoped mode. While it is on, this session reads
# only the navigation layer and agents' reports, splits each change request
# into areas that own disjoint files, launches one subagent per area, relays
# their reports, and checks the work in as one commit per area at the end.
# Usage: /orchestrate-mode [<notes>] [--model <m>]   (on; notes are the first request)
#        /orchestrate-mode --off                      (off)
# Examples: /orchestrate-mode
#           /orchestrate-mode "tighten the header spacing and rename the export button"
#           /orchestrate-mode --model sonnet

GOAL
Keep this coordinating session small enough to last a whole session of
iterations: every change becomes work done by fresh agents that do not
collide on shared files, do not retry what the owner rejected, and do not
start from zero, while this session holds only the decisions and the reports.

---

SUPPORTING FILES (read on demand)

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/messages.md` | When the mode turns on, before the first report or question. |
| `../interaction-engine/references/gates.md` | The interaction policy resolved to `unattended` (`../interaction-engine/references/policy.md`), at the check-in. |
| `./brief.md` | Each time an area agent is launched. |
| `./handoff.md` | Each time an area agent is launched, and at the check-in. |
| `./failures.md` | An agent reports a failure, two areas collide, or a launch cannot go ahead. |

---

SWITCHING THE MODE

- `/orchestrate-mode` turns the mode on and confirms in one line:
  `Orchestrate mode on — change requests now run as per-area agents.`
- `/orchestrate-mode <notes>` turns it on, confirms in the same line, and
  treats `<notes>` as the first request (REQUESTS below).
- `--model <m>` sets the model for the batch the notes launch, overriding the
  default of LAUNCH.
- `/orchestrate-mode --off` turns it off and confirms in one line:
  `Orchestrate mode off — this session edits code itself again.` Areas
  launched before it finish and report as usual.

The mode is conversation-scoped: it holds until `--off` or the conversation
ends. Any context summary of this conversation keeps the line
`orchestrator mode: on` while the mode is on, so the mode survives
compaction. Whether the mode is on is the check in
`../interaction-engine/references/mode.md`.

---

REQUESTS

While the mode is on, triage every message:

- **A change** to code, assets or scenes — whatever its size — is a batch:
  SPLITTING INTO AREAS, then LAUNCH.
- **A question** is answered inline from the context files and earlier
  reports. Nothing is spawned.
- **A message with no actionable note** gets one line —
  `Nothing to act on.` — and the orchestrator waits.

---

THE ORCHESTRATOR'S LIMITS

It reads only `CLAUDE.md`, `.claude/context/INDEX.md` and the context files
of the areas a request touches — no source file, no domain feature file, no
session file, no agent transcript. What it needs from source, it asks an
agent.

It never edits code and never drives an editor or any other tool that only
one process can drive at a time (a *single-instance tool*). It asks the user
only when two readings of a note lead to different code.

---

SPLITTING INTO AREAS

An area owns a disjoint set of files, or named regions of a shared file
(functions, or `#region` blocks), found from the context files.

- Two notes needing the same region are one area, worked in sequence.
- A note the orchestrator cannot place, or reads two ways, goes to the user
  as a question while the other areas launch.

---

LAUNCH

- Independent areas launch in one message, in parallel. Areas sharing a
  region are serialised: the second launches once the first has reported and
  rewritten its handoff.
- At most one agent per batch owns a single-instance tool.
- Each agent gets the brief of `./brief.md`, with its handoff path per
  `./handoff.md`.
- Model: `opus` by default; `fable` only for genuinely hard work, with the
  brief saying why. `--model` overrides the default for the whole batch.

The orchestrator relays a report's substance, never its transcript.

---

AFTER THE BATCH

1. Run the project's own quick check once.
2. Proof captures (screenshots, recordings) are made only when the owner is
   away or asks for them, and only by the area agent that owns the
   single-instance tool. With the owner present, the quick check is the check
   and the owner looks.
3. Report per `../interaction-engine/references/messages.md`: outcome first,
   one bullet per area, decisions needed flagged.
4. When successive batches converge on the same areas, ask once whether to
   iterate further or check in.

A failed quick check, or any other failure, follows `./failures.md`; a batch
with a failed quick check commits nothing.

---

CHECK-IN

On the owner's word:

1. One commit per area, made one at a time. Only the orchestrator stages and
   commits — area agents never touch git's index. A file several areas
   changed rides with the area that changed it most.
2. Then run `/session-save`, which moves the pending handoffs into the
   session's folder (`./handoff.md`).

Checking in on the owner's word is a `confirmation` gate
(`../interaction-engine/references/gates.md`): under `unattended` it passes
on its own.

---

THE BOUNDARY WITH OTHER COMMANDS

The mode changes only how work runs:

- **Areas** apply to free-form change requests and to `/quick-implement`'s
  implementation step and `--review` fixes, nowhere else: the orchestrator
  routes each review finding to the area owning the file it cites, and that
  area's agent triages and applies it.
- **`/task-implement`** runs with `--agents`, even for one task.
  **`/runbook-run`** is unchanged: it already runs each step in a fresh
  subagent.
- **Conversations** — `/task-add`, `/architect`, `/pipeline-revise`,
  `/quick-implement`'s spec phase — run in one fresh subagent, and the
  orchestrator relays its questions to the owner and the owner's answers
  back to the same subagent, until it finishes.
- **Each command keeps its commit rule.** `/quick-implement` still makes one
  commit; its areas do not commit separately. `/objective-run` does not split
  its rounds into areas.

---

NEVER

- edit code, drive the single-instance tool, sample captures or read a
  transcript from the orchestrator;
- read a source file from the orchestrator — ask an agent;
- launch two agents that write the same file region;
- let two agents own the single-instance tool at once;
- write over an existing file, or stream-edit a whole file, from an area
  agent;
- chain sleeps while waiting for the single-instance tool;
- retry something on a handoff's rejected list;
- check in a catch-all, temp or noise file, or the session folder unless the
  owner asks;
- spawn an agent for a note that is a question.
