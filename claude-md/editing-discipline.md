---
name: editing-discipline
version: 0.1.0
type: claude-md
description: Keep rules documents current instead of layered — supersede the old sentence, keep history out of the body, state rules rather than decisions, cite instead of paraphrasing, and carry a change's consequences in the same edit.
---

## Editing Discipline

A rules document — a CLAUDE.md, a skill or command body, a feature document,
a context file — describes the current state. It is read by whoever comes
next, who needs the rule, not the road to it. Every edit follows these rules.

1. **Supersede.** A changed rule edits the sentence that states it. The old
   sentence goes; it is not kept beside the new one, qualified, or softened.
2. **No history in the body.** No "previously", "now", "no longer", "used
   to"; no dates or task ids as provenance. Git holds the history. The
   exceptions are the artifacts whose job is history: `CHANGELOG.md`, the
   task archive, session handoffs.
3. **State the rule, not the decision.** One reason clause, only when it
   changes how the rule applies. The rest of the reasoning belongs to the
   domain layer, not to the rule.
4. **One rule, one place.** Everywhere else cites it by path. A paraphrase is
   a second copy, and the second copy is the one that drifts.
5. **A rule misread once gets clearer wording**, not more adjectives and not
   a second bullet saying the same thing harder.
6. **A DO NOT bullet that negates a sentence already in the body is deleted.**
   The body already says it.
7. **Edit the section, not the sentence.** Read the whole section and rewrite
   it as if written fresh with the new rule in.
8. **Before finishing an edit**, for each sentence added, ask whether an
   existing sentence now overlaps it, contradicts it, or describes a state
   that no longer holds. If so, merge the two into one sentence carrying the
   whole current meaning. A sentence whose meaning is now fully carried
   elsewhere goes.
9. **A change carries its consequences.** Every passage the approved change
   makes stale is updated in the same edit, whoever owns the file. A new
   decision is never smuggled in as a consequence.
