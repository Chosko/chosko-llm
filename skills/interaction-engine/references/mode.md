# Orchestrate mode — is it on?

Authority for: the one check a feature makes to know whether orchestrate mode
is on in this conversation.

Read by every feature whose behaviour changes under orchestrate mode, at the
point that behaviour applies. What a citing feature does with the answer is
stated in that feature, never here.

---

## The check

Orchestrate mode is **on** when either holds:

- this conversation turned it on with `/orchestrate-mode` and has not since
  turned it off with `/orchestrate-mode --off`; or
- a context summary of this conversation carries the line
  `orchestrator mode: on`.

Otherwise it is **off**.

The mode belongs to the conversation alone: no file, flag or `CLAUDE.md` line
records it, and a subagent the orchestrator spawns is not in orchestrate mode
unless its own conversation turned it on.

## Not part of the policy

The mode is independent of the interaction policy (`./policy.md`): it changes
how work runs, never which gates wait. Under either policy a citing feature
applies `./gates.md` and `./messages.md` exactly as it would with the mode
off.
