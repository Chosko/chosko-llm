---
name: pipeline-check
version: 0.3.1
type: command
description: Report structural drift across the pipeline's indexes — FEATURES.md, TASKS.md, PLAN.md and RUNBOOKS.md — as findings grouped by artifact, each with its severity and the one command that fixes it. Use it when an index looks out of step with another, or before revising planned work.
requires: skill:pipeline-engine, skill:interaction-engine
---

# /pipeline-check
# Global command: report drift across the pipeline's indexes — a reference
# between them that does not resolve, or a state its owner has not acted on —
# each finding with its ERROR or WARNING severity and the one command that
# fixes it. Read-only (see READ-ONLY).
# Usage: /pipeline-check
#        /pipeline-check feature=<slug>      (scope to that feature and the tasks and plan edges naming it)
#        /pipeline-check <args> --attended | --unattended   (accepted; this command has no gate)
# Examples: /pipeline-check
#           /pipeline-check feature=password-auth

GOAL
Read the pipeline's indexes, evaluate the drift catalogue over the edges
between them, and print every finding with its fix — or one line saying there
is none. Apply no fix: every fix belongs to the owner the finding names.

$ARGUMENTS

---

THE ENGINE

Read everything this command evaluates from `pipeline-engine`, by path:

- `../skills/pipeline-engine/references/probes.md`
  — the probe, its verdict line and the reuse rule;
- `../skills/pipeline-engine/references/graph.md`
  — the edges between the indexes, and which vanish with an absent index;
- `../skills/pipeline-engine/references/lint.md`
  — the finding catalogue: detection rules, severities, fix commands, output
  templates and the two failure rules;
- `../skills/pipeline-engine/references/routing.md`
  — the owner each fix command routes to, and this command's own row.

This file restates no probe, no edge and no finding; it states only what this
command does differently.

---

ARGUMENT PARSING

- Scan `$ARGUMENTS` for `feature=<slug>`; set FEATURE to the slug and strip it.
- Strip `--attended` and `--unattended`. They have no effect here — this
  command has no gate and asks nothing — and are accepted so a parent can hand
  its policy down. `../skills/interaction-engine/references/policy.md`
  § *Argument errors* still applies to the pair. The only interaction-engine
  rule that reaches this command is the plain-language rule, through
  `lint.md`'s templates.
- Anything else in `$ARGUMENTS` is not a recognised argument: say so in one
  line and carry on with the default report. Never refuse over this command's
  own arguments.

---

WORKFLOW

1. **Probe.** Run the probe from `probes.md`, or reuse a verdict line already
   in the conversation where its reuse rule allows. The probe is the only
   shell command this run may execute — the one stated departure from
   `/production-status`, which runs none at all.

2. **Read the indexes the probe found**, with the Read tool, read-only — each
   of the four that exists.
   - `backlog=partial` does not say which half exists: try `.claude/TASKS.md`,
     and count it absent when it is not there.
   - The only other files a run opens are the bodies `lint.md` § *What no rule
     reads* names for L12 and L13 — each `[PARKED]` task's, each
     non-`[DONE]` runbook's. Read them in step 5, when those findings are
     evaluated, and only for the heading or the markers the finding checks.
   - When the probe's `specs` count is above `0`, list `.claude/specs/*.md`
     with the Glob tool for L14 — a listing, never a read of a spec.

3. **Stop only on a project with no index.** When step 2 read none of
   `.claude/FEATURES.md`, `.claude/TASKS.md`, `.claude/PLAN.md` and
   `.claude/RUNBOOKS.md`, print one line and stop:

   > No pipeline index in this project — nothing to check. `/task-setup`
   > creates the backlog; `/domain-setup` creates the feature index.

   This is the command's only stop. Run every other combination.

4. **Resolve FEATURE**, when set. A slug with no entry in
   `.claude/FEATURES.md` — or a project with no `FEATURES.md` — is never
   reported as a clean run: say in one line that the slug is unknown, list the
   slugs that do exist (or say there is no feature index), and run the
   default, unscoped report.

5. **Evaluate `lint.md`** over `graph.md`'s edges on the indexes read,
   applying both of its failure rules: an absent index drops its findings, and
   a malformed block is reported while the run continues.

   Under FEATURE, keep only the findings that touch the feature:
   - its own entry (L6, L8, L11);
   - the tasks whose `Feature:` names it or whose id is on its `Tasks:` line,
     with the precondition findings and cycles through them and L12 on a
     parked one;
   - the plan lines that name the slug (L9).

   No runbook finding is in scope: `RUNBOOKS.md` ties no runbook to a slug
   (`graph.md` E7), and this command opens no runbook body to find one — L13
   reads a body for its markers, never for its prompt blocks. L14 is not in
   scope either: a spec carries no `Feature:` line to tie it to a slug.

---

OUTPUT

**A clean run prints exactly one line**, naming the indexes read:

```
No drift — read FEATURES.md, TASKS.md, RUNBOOKS.md.
```

Under FEATURE it opens `No drift for feature <slug> —` instead. Print nothing
else: no verdict echo, no empty group, no count of zero.

**Otherwise**, print inside one fenced code block, so the lines stay literal:

- the findings, grouped under their artifact's name, the groups in this fixed
  order — `FEATURES.md`, `PLAN.md`, `TASKS.md`, `RUNBOOKS.md`,
  `.claude/specs/` — with an empty group omitted;
- within a group, in catalogue order, then in the order the offending line
  appears in its index;
- each finding rendered from its `lint.md` output template exactly, its fix
  command verbatim — never a finding `lint.md` does not define, a reworded
  template (each is already written message first, identifiers last) or a fix
  other than the one it gives;
- then one summary line counting both severities.

```
FEATURES.md
  WARNING Every task of a feature is finished, but the feature is still marked planned (FEATURES.md feature password-auth, [PLANNED]) → flip to [DONE]

TASKS.md
  ERROR   A task waits on a task that was never created (TASKS.md task 42, Preconditions: 57, Last task number: 51) → /pipeline-revise
  WARNING A task was written before its feature's design changed, so it may ask for the old design (TASKS.md task 44, [STALE], feature session-handling) → /pipeline-revise

1 ERROR, 2 WARNING — read FEATURES.md, TASKS.md, RUNBOOKS.md.
```

The counts are for a human's eye. There is no exit-code contract, no `--fix`
and no `--quiet`: every fix is its owner's to apply.

---

READ-ONLY

- Write, edit, create or commit nothing — no status flip, no fix for a
  finding this run reported, no cached report.
- Open no file under `.claude/tasks/archive/` and none under
  `.claude/domain/features/`, and no design document.
- Under `.claude/tasks/` and `.claude/runbooks/`, open exactly the bodies
  `lint.md` § *What no rule reads* names for L12 and L13, and read nothing
  else in them — never a prompt block, never a handoff's question. Derive
  every other finding from index lines.
- List `.claude/specs/` for L14; open no spec.
- Run no shell command beyond the probe, `git` included.
- Never refuse over an absent index, a malformed block, an unknown `feature=`
  slug or an unrecognised argument: report each and carry on.
- Run only when the user invokes this command.
