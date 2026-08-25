---
name: task-engine
version: 0.1.1
type: skill
description: Reference library for the task-* features — one authority per rule they share. Six files under references/ own backlog resolution and the TASKS.md schema, the status vocabulary and its transitions, Target: values and the delegation guard, [STALE] handling, the dirty-tree prompt protocol, and commit/push gating with --no-commit / --no-push. NOT a skill the user invokes and never a skill to suggest — it takes no arguments, runs nothing, and produces no output; /task-add, /task-list, /task-clean and /task-implement read its files by path while they run, and only they should ever open it.
---

# task-engine

> **Not directly invocable.** This skill exists so that the rules the
> `task-*` features share have exactly one home. It has no command, no
> arguments and no behaviour of its own. Nothing invokes `/task-engine`;
> nothing should suggest it. `/task-add`, `/task-list`, `/task-clean` and
> `/task-implement` cite the files below by path while they run, and those
> files are the only content here.

> **Install path assumption:** this skill assumes installation at
> `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/` — where
> `chosko-llm add skill:task-engine` writes it. A feature that reads a file
> here names it as
> `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md`,
> never as a hardcoded home path — the `CLAUDE_HOME` override has to keep
> working.

---

## The map

| Reference file | Owns |
| -------------- | ---- |
| `references/resolution.md` | Where the backlog lives, the `.claude/TASKS.md` summary-block schema, the not-initialised stop, when a per-task body file may be opened, and the `all` / `next` / explicit-list selectors. |
| `references/status.md` | The eight status tags and what each means, which are terminal, which are implementable, how a status filter is accepted, and the legal transitions. |
| `references/targets.md` | The three `Target:` values, the `## Manual interventions` pairing rule, what each target means at implementation time, and the delegation guard. |
| `references/stale.md` | What `[STALE]` means, who sets and clears it, how the originating feature is found, and how each feature treats a stale task. |
| `references/tree.md` | The dirty-tree prompt protocol and the folding rules that follow from it. |
| `references/commit.md` | Commit and push gating: `--no-commit` / `--no-push`, pull-at-start, what may be staged, one commit per unit of work, and commit/push failure handling. |

Each file is the **single authority** for its rule. A consuming feature cites
the file and states only what it does differently.

---

## How to read a reference file

Every reference file was extracted **verbatim** from the feature bodies that
previously each carried their own copy of the rule. Where those copies said
the same thing in different words, the file carries the fuller statement
unchanged and records the other copies' material divergences as explicit
per-consumer notes. So a file reads as:

- the shared rule, in the words one of the consumers already used, and
- a `Per-consumer notes` section naming which feature departs from it and how.

A note attributed to a feature applies to that feature only. Wording that
names a phase or step (`PHASE 5`, `Step 7`, `WORKFLOW step 3`) is the
originating feature's own label and is kept as it stood.

**This `SKILL.md` carries no rule text.** It exists because `chosko-llm`
installs a skill folder, and a folder needs a versioned `SKILL.md` to be
installable at all. Every rule lives in a reference file; adding rule text
here would recreate the duplication the engine exists to remove.
