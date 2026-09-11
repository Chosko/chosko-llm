---
name: pipeline-engine
version: 0.1.0
type: skill
description: Reference library for the pipeline as a whole — one authority per rule the pipeline-revision features share. Four files under references/ own the project probe and the one verdict line every consumer prints, the graph of how the pipeline's indexes point at each other, the routing table of what each pipeline feature consumes, produces and owns, and the catalogue of drift findings. NOT a skill the user invokes and never a skill to suggest — it takes no arguments, runs nothing, and produces no output; /pipeline-check reads its files by path while it runs, and only the features that declare requires: skill:pipeline-engine should ever open it.
---

# pipeline-engine

> **Not directly invocable.** This skill exists so that what every pipeline
> feature needs to know about the pipeline as a whole has exactly one home. It
> has no command, no arguments and no behaviour of its own. Nothing invokes
> `/pipeline-engine`; nothing should suggest it. `/pipeline-check` cites the
> files below by path while it runs, and those files are the only content
> here.

> **Install path assumption:** this skill assumes installation at
> `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/` — where
> `chosko-llm add skill:pipeline-engine` writes it. A feature that reads a file
> here names it as
> `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/<file>.md`,
> never as a hardcoded home path — the `CLAUDE_HOME` override has to keep
> working.

---

## The map

| Reference file | Owns |
| -------------- | ---- |
| `references/probes.md` | The fixed set of cheap filesystem probes that describe a project's pipeline setup, the one verdict line every consumer prints, and the rule for reusing a verdict already in the conversation — including the writers whose runs invalidate it. |
| `references/graph.md` | How the pipeline's indexes point at each other: each edge by the artifact and line it lives on, its direction, which side is authoritative, which command writes each side, what consumes it, and which edges vanish when an index is absent. |
| `references/routing.md` | One row per pipeline feature — what it consumes, what it produces, which artifact lines it owns, its preconditions and its argument shape — and the table's contract as the revision suite's ownership authority. |
| `references/lint.md` | The closed catalogue of structural drift findings: each finding's detection rule over the graph, its severity, its one fixing command and its output template, plus the two failure rules. |

Each file is the **single authority** for its rule. A consuming feature cites
the file and states only what it does differently.

---

## How to read a reference file

Read a file when a run needs its rule, and not before — a consumer that only
needs the verdict line has no reason to open the finding catalogue. The four
files cite each other by name (`graph.md`'s edges are what `lint.md`'s
findings walk; `probes.md` takes its list of pipeline features from
`routing.md`'s rows), and a citation is followed only when the rule it points
at is actually needed.

Where a rule belongs to another skill — the `TASKS.md` schema and the archive
rule to `task-engine`, the runbook store to `runbook-run`, the `PLAN.md`
schema to `/production-status` — the file here cites it by installed path and
states only what the pipeline adds on top of it. A citation names the rule's
home; the lines a file here reads are named in that file, so following a
citation is never required to read an index.

**This `SKILL.md` carries no rule text.** It exists because `chosko-llm`
installs a skill folder, and a folder needs a versioned `SKILL.md` to be
installable at all. Every rule lives in a reference file; adding rule text
here would recreate the duplication the engine exists to remove.
