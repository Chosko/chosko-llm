---
name: pipeline-check
version: 0.1.0
type: command
description: Report structural drift across the pipeline's indexes — FEATURES.md, TASKS.md, PLAN.md and RUNBOOKS.md — as findings grouped by artifact, each with its ERROR or WARNING severity and the one command that fixes it, closing on a count of both; a clean project prints one line. feature=<slug> scopes the report to that feature and to the tasks and plan edges that name it. An absent index drops its findings rather than failing the run. Read-only — writes nothing, creates nothing, commits nothing, flips no status, never opens a file under .claude/tasks/ (the archive included), .claude/runbooks/ or .claude/domain/features/, and runs no shell beyond the probe.
requires: skill:pipeline-engine
---

# /pipeline-check
# Global command: report drift across the pipeline's indexes — a reference
# between them that does not resolve, or a state its owner has not acted on —
# each finding with the one command that fixes it. Read-only.
# Usage: /pipeline-check
#        /pipeline-check feature=<slug>
# Examples: /pipeline-check
#           /pipeline-check feature=password-auth

GOAL
Read the pipeline's indexes, evaluate the drift catalogue over the edges
between them, and print every finding with its fix — or one line saying there
is none. This command reports; every fix belongs to the owner the finding
names, and nothing here applies one.

$ARGUMENTS

---

THE ENGINE

Everything this command evaluates is defined in `pipeline-engine` and read
from it by path:

- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/probes.md`
  — the probe, its verdict line and the reuse rule;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/graph.md`
  — the edges between the indexes, and which vanish with an absent index;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/lint.md`
  — the finding catalogue: detection rules, severities, fix commands, output
  templates and the two failure rules;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/routing.md`
  — the owner each fix command routes to, and this command's own row.

This command restates no probe, no edge and no finding. What follows is only
what it does differently.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for `feature=<slug>`; set FEATURE to the slug and strip it.

Anything else in `$ARGUMENTS` is not a recognised argument. Say so in one
line and carry on with the default report — this command never refuses over
its own arguments.

---

WORKFLOW

1. **Probe.** Run the probe from `probes.md`, or reuse a verdict line already
   in the conversation where its reuse rule allows. The probe is the only
   shell command this run may execute — the one stated departure from
   `/production-status`, which runs none at all.

2. **Read the indexes the probe found**, with the Read tool, read-only — each
   of the four that exists, and nothing else. `backlog=partial` does not say
   which half exists: try `.claude/TASKS.md`, and count it absent when it is
   not there.

3. **Stop only on a project with no index.** When step 2 read none of
   `.claude/FEATURES.md`, `.claude/TASKS.md`, `.claude/PLAN.md` and
   `.claude/RUNBOOKS.md`, print one line and stop:

   > No pipeline index in this project — nothing to check. `/task-setup`
   > creates the backlog; `/domain-setup` creates the feature index.

   This is the command's only stop. Every other combination runs.

4. **Resolve FEATURE**, when set. A slug with no entry in
   `.claude/FEATURES.md` — or a project with no `FEATURES.md` — is never
   reported as a clean run: say in one line that the slug is unknown, list the
   slugs that do exist (or say there is no feature index), and run the
   default, unscoped report.

5. **Evaluate `lint.md`** over `graph.md`'s edges on the indexes read,
   applying both of its failure rules: an absent index drops its findings, and
   a malformed block is reported while the run continues.

   Under FEATURE, keep only the findings that touch the feature: its own entry
   (L6, L8, L11); the tasks whose `Feature:` names it or whose id is on its
   `Tasks:` line, with the precondition findings and cycles through them; and
   the plan lines that name the slug (L9). No runbook finding is in scope:
   `RUNBOOKS.md` ties no runbook to a slug (`graph.md` E7), and this command
   opens no runbook body to find one.

---

OUTPUT

**A clean run prints exactly one line**, naming the indexes read:

```
No drift — read FEATURES.md, TASKS.md, RUNBOOKS.md.
```

Under FEATURE it opens `No drift for feature <slug> —` instead. Nothing else
is printed: no verdict echo, no empty group, no count of zero.

**Otherwise**, print inside one fenced code block, so the lines stay literal:

- the findings, grouped under their artifact's name, the groups in this fixed
  order — `FEATURES.md`, `PLAN.md`, `TASKS.md`, `RUNBOOKS.md` — with an empty
  group omitted;
- within a group, in catalogue order, then in the order the offending line
  appears in its index;
- each finding rendered from its `lint.md` output template exactly, its fix
  command verbatim;
- then one summary line counting both severities.

```
FEATURES.md
  WARNING FEATURES.md feature password-auth — [PLANNED], every task on Tasks: resolved → flip to [DONE]

TASKS.md
  ERROR   TASKS.md task 42 — Preconditions: 57 was never assigned (Last task number: 51) → /pipeline-patch
  WARNING TASKS.md task 44 — [STALE]: feature session-handling was re-architected after this task was written → /pipeline-revise

1 ERROR, 2 WARNING — read FEATURES.md, TASKS.md, RUNBOOKS.md.
```

The counts are for a human's eye. There is no exit-code contract, no `--fix`
and no `--quiet`: an exit code would invite a caller to gate on the report,
and every fix is its owner's to apply.

---

READ-ONLY

This command writes nothing, creates nothing, commits nothing and flips no
status. It opens no file under `.claude/tasks/` — **`.claude/tasks/archive/`
included** — none under `.claude/runbooks/`, and none under
`.claude/domain/features/`. It runs no shell command beyond the probe.

It runs when the user invokes it, and at no other time.

DO NOT:
- Write, edit, create or commit anything — no status flip, no fix for a
  finding this run reported, no cached report.
- Open a task body, an archived body, a runbook body, a feature document or a
  design document. Every finding is derived from index lines.
- Run any shell command other than the probe, `git` included.
- Refuse over an absent index, a malformed block, an unknown `feature=` slug
  or an unrecognised argument. Each is reported, and the run carries on.
- Print a finding `lint.md` does not define, reword its template, or name a
  fix other than the one it gives.
