---
name: runbook-suggest
version: 0.1.0
type: skill
description: 'Suggest capturing the follow-up actions of a conversation as a runbook, before the session that produced them closes. Trigger whenever a conversation produces an ordered list of follow-up actions meant for later, separate sessions — the tail of an /architect, /product-design or /product-roadmap run, a "next steps" or "landing prompts" list, "do these in order", "here is what to do next" — and there are three or more actions, or two or more with an ordering constraint, or any action that depends on decisions written down nowhere but this conversation. Emits one or two lines pointing at /runbook-create and stops; asks nothing, reads nothing, writes nothing, and creates no runbook. Not for: a single follow-up action; a list of things already done; a checklist this session is about to work through itself; an enumeration inside an explanation; a two-step list of simple prompts; or a list of tasks that belongs in the backlog, which is /task-add.'
requires: command:runbook-create
---

# /runbook-suggest
# Global skill: when a conversation ends with an ordered list of follow-up
# actions meant for later sessions, say once that /runbook-create can capture
# them. Not invoked by the user — selected from the description above.

**The description is the mechanism.** Claude Code picks a skill from its
`description`, so there is no hook, no `Stop` handler and no event
registration anywhere in this feature — the frontmatter above is the whole
trigger, and it carries both the conditions and the anti-triggers.

**The threshold.** Suggest only when the follow-ups would be *lost with the
conversation*: three or more actions, or two or more with an ordering
constraint, or any action that depends on decisions recorded nowhere on
disk. Never for a two-step list of simple prompts.

**Not this.** A single next action. A list of things already done. A
checklist this session is about to work through itself. An enumeration
inside an explanation. A list of tasks that belongs in the backlog — that is
`/task-add`'s job, not a runbook's.

**Emit one or two lines, then stop.** Say that `/runbook-create` will turn
these follow-ups into a runbook, or append them to one that already exists.
Name no runbook, do not say which runbooks exist, and do not say whether one
is running: `/runbook-create` with no arguments is what asks
new-versus-append and lists the choices, and that gate belongs to the
command the user chose to run.

**Ask nothing.** No question, no gate, no waiting — a question from a skill
that fired on a guess is an interruption at exactly the wrong moment. Open
no file: not `.claude/RUNBOOKS.md`, not a runbook body, nothing. Write
nothing, create nothing, and never invoke `/runbook-create` yourself.
Propose once per conversation; if the user says nothing, that is the answer.

**Fire rate is tuned after observing real sessions.** That is this skill's
method, not an open question — the threshold above cannot be settled on
paper. If it proves noisy, the fix is a narrower description, never a
suppression flag.
