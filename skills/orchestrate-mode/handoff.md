# Area handoff files

One file per area carries the area's state from one agent to the next.

## Path

- Before this conversation's first `/session-save`:
  `.claude/sessions/pending/agent-<area>.md`.
- After it: `.claude/sessions/<stem>/agent-<area>.md`, where `<stem>` is the
  session file's name without `.md`. `/session-save` moves the pending files
  there.

`<area>` is a short kebab-case name for the area, kept the same for the whole
conversation.

## Contents

Written for a reader with no context:

- the files and functions (or named regions) the area owns;
- constants and their current values;
- rules the owner set;
- the rejected-by-owner list — always kept, never retried;
- the verification recipe that works;
- pitfalls.

## Rules

- **Current state only.** No history, no log of past tasks.
- **About 120 lines at most.**
- **Read first, rewrite at the end.** The agent reads it before anything else
  and rewrites it as the last act of every task.
- **Retiring agents.** An agent whose context has grown large — typically
  after two or three tasks — writes its handoff before it is dropped; the
  area's next task goes to a fresh agent.
- **Rebuild when missing or stale.** The next agent for the area rebuilds it
  from the code regions the area owns, then continues.

The orchestrator never reads a handoff's contents; it passes the path.
