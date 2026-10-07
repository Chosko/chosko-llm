---
name: pipeline-engine
version: 0.4.1
type: skill
description: Reference library for the pipeline as a whole — one authority per rule the pipeline features share, under references/ (the project probe and verdict line, the index graph, the routing table, the drift catalogue); read by path by the pipeline-* features, never invoked.
disable-model-invocation: true
---

# pipeline-engine
# Reference library, read by path by /pipeline-check and pipeline-revise
# while they run; not invoked.

> **Not directly invocable.**
>
> - This skill is the one home of what every pipeline feature needs to know
>   about the whole pipeline. It has no command, arguments or behaviour of its
>   own.
> - Nothing invokes `/pipeline-engine`; nothing should suggest it.
> - `/pipeline-check` and `pipeline-revise` cite the files below by path while
>   they run; those files are the only content here.

> **Install path assumption:** `chosko-llm add skill:pipeline-engine` writes
> this skill under the same home as the features that read it, whichever home
> that is.
>
> - Name a file here by a path **relative to the citing body**, never an
>   absolute home path, counting directories up to the install home and back
>   down:
>   - from a command: `../skills/pipeline-engine/references/<file>.md`;
>   - from a file at another skill's root:
>     `../pipeline-engine/references/<file>.md`;
>   - from a file under another skill's `references/`:
>     `../../pipeline-engine/references/<file>.md`;
>   - between two files in this skill: `./<file>.md`.
> - Why: `CLAUDE_HOME` governs where `install.sh` and the `scripts/cmd-*.sh`
>   verbs *write* — `--local` included, which repoints the whole home to
>   `$PWD/.claude` — but the executing agent expands
>   `${CLAUDE_HOME:-$HOME/.claude}` itself and always lands on the global
>   home. Citing body and cited file are always siblings under one root, so a
>   relative path works in either scope with no probing or fallback.
> - One exception: the probe in `./references/probes.md` derives both install
>   homes in shell, because `sh` cannot resolve a skill by name; that file
>   states the rule it satisfies.

---

## How to read a reference file

- Read a file only when a run needs its rule — a consumer that only needs the
  verdict line has no reason to open the finding catalogue.
- The four files cite each other by name (`graph.md`'s edges are what
  `lint.md`'s findings walk; `probes.md` takes its list of pipeline features
  from `routing.md`'s rows). Follow a citation only when its rule is needed.
- A rule owned by another skill — the `TASKS.md` schema and the archive rule
  by `task-engine`, the runbook store by `runbook-run`, the `PLAN.md` schema
  by `/production-status` — is cited by installed path; the file here states
  only what the pipeline adds on top of it. Each file here names the lines it
  reads, so reading an index never requires following a citation.
- **This `SKILL.md` carries no rule text.** It exists only because a skill
  folder needs a versioned `SKILL.md` for `chosko-llm` to install it. Every
  rule lives in a reference file.

## The map

| Reference file | Owns |
| -------------- | ---- |
| `references/probes.md` | The fixed set of cheap filesystem probes that describe a project's pipeline setup, the one verdict line every consumer prints, and the rule for reusing a verdict already in the conversation — including the writers whose runs invalidate it. |
| `references/graph.md` | How the pipeline's indexes point at each other: each edge by the artifact and line it lives on, its direction, which side is authoritative, which command writes each side, what consumes it, and which edges vanish when an index is absent. |
| `references/routing.md` | One row per pipeline feature — what it consumes, what it produces, which artifact lines it owns, its preconditions, its argument shape and the path to its amend entry, or why it has none — and the table's contract as the revision suite's ownership authority. |
| `references/lint.md` | The closed catalogue of structural drift findings: each finding's detection rule over the graph, its severity, its one fixing command and its output template, plus the two failure rules. |

Each file is the **single authority** for its rule; a consuming feature cites
the file and states only what it does differently.
