---
name: pipeline-suggest
version: 0.1.0
type: skill
description: 'Name, in one line, the pipeline command a free-form request fits. Trigger whenever the user asks in their own words to build, change, fix, remove or sequence work — "add a login to the page", "fix this bug", "drop the export step", "do this before that" — on a project that has a .claude/FEATURES.md or a .claude/TASKS.md, and the request does not already name a slash command. Emits one or two lines naming the command and stops; asks nothing, reads nothing beyond two file-existence probes, writes nothing, and invokes nothing. Not for: a question; a request that names a command; a request that says "just do it" or "directly"; work already under way in a /task-implement run; an enumeration inside an explanation; a follow-up list meant for later sessions, which runbook-suggest owns; or a project with neither a feature index nor a backlog.'
requires: skill:pipeline-engine, skill:pipeline-revise, command:pipeline-patch
---

# /pipeline-suggest
# Global skill: name the pipeline command a free-form request fits, in one
# line. Not invoked by the user — selected from the description above.

**The description is the mechanism.** Claude Code picks a skill from its
`description`, so there is no hook and no event registration anywhere in this
feature — the frontmatter above is the whole trigger, conditions and
anti-triggers both. Fire rate is tuned by narrowing the description after
observing real sessions, never by a flag.

**The gate: two probes, nothing more.** Does `.claude/FEATURES.md` exist; does
`.claude/TASKS.md` exist. Both absent: say nothing and end. A probe that errors
counts as absent. No third probe and no read of the engine's `probes.md` — this
skill needs to know whether a pipeline exists, not its shape.

**The shape table** maps request shape → command. It is not the engine's routing
table (feature → consumes / produces / owns): different job, different content.

| Request shape | Command |
| --- | --- |
| A new capability or a feature-sized addition | `/architect` |
| A bug, a small change or a chore | `/task-add` |
| A small change to something already planned | `/pipeline-patch` |
| A large change, an insertion at a point in the sequence, a deletion or a reorder of planned work | `/pipeline-revise` |
| "What should I build next" | `/production-status` |
| "Is the backlog consistent" | `/pipeline-check` |
| An ordered list of follow-ups | none — `runbook-suggest` already fires |
| A design-level decision | `/product-design` |
| A milestone or release question | `/product-roadmap` or `/production-plan` |

**Silence, or at most two lines, then stop.** A request that matches no row, or
only the follow-up row, gets no output. Otherwise the first line names the
command — both, when two rows match — and quotes the phrase in the request that
matched; an optional second says the parent can proceed directly instead.
Restate nothing of the request's substance. No failure path adds a third line.

**Do not.** Never invoke what you suggest. Never ask a question or gate
anything — the parent continues past the line exactly as it would have. Never
write. Never open a file beyond the two probes: no reference file, not
`routing.md`, and not the contents of the two files probed for.

**No suppression list, deliberately** — it would be a state file. A repeated
request earns a repeated line, bounded by the silence rules, not by memory.
