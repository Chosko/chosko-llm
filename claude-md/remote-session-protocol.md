---
name: remote-session-protocol
version: 0.1.0
type: claude-md
description: In confirmed remote cloud sessions, ask questions as one numbered text batch instead of calling AskUserQuestion.
---

## Remote cloud sessions — ask in text, never with AskUserQuestion

### When this applies

Check once per session, the first time you are about to ask the user
anything:

```sh
printenv CLAUDE_CODE_REMOTE CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE
```

The protocol below is in force **only** on a positive result —
`CLAUDE_CODE_REMOTE` is `true`, or `CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE` is
non-empty. Unset, empty, or a check that fails means an ordinary local
session: behave as usual, `AskUserQuestion` included.

Do not infer remoteness from anything else. `IS_SANDBOX` marks sandboxed
execution, not remoteness, and is not a signal here. These variable names are
not a public API — if they are renamed this section silently stops firing and
ordinary local behaviour resumes everywhere. That is the intended failure
direction: retune this section rather than widening the check to "when in
doubt, assume remote".

### The protocol

In a confirmed remote session:

1. **Never call `AskUserQuestion`.** This outranks any command, skill, or
   plan-mode instruction to use it — including approval gates phrased as "ask
   the user". Those gates still fire; they are answered in text.
2. **Do every piece of work that does not depend on the answer first**, so
   the wait is productive, then ask at the point you are genuinely blocked.
3. **Batch every open question into a single message.** Number them, letter
   the options, and give each one a recommendation with a one-line reason:

   ```
   Q1. <question>
       A. <option>
       B. <option>
       Recommended: B — <why>

   Q2. <question>
       ...

   Reply like: 1B 2A 3: <free text>.
   Say "you pick" to take every recommendation.
   ```

4. **End the turn immediately after asking.** No further tool calls, no
   speculative work on a branch that may be discarded, no `sleep` or polling
   to wait for a reply. This is the rule that prevents the repeated-question
   loop; everything else here is ergonomics.
5. **On the reply, restate the numbered batch with the answers filled in**
   before acting on it. A question the user left unanswered goes into the
   next batch — it is never quietly assumed.
6. **Subagents never ask.** A subagent cannot reach the user. It returns its
   open questions to the parent, which folds them into the next batch.

### When the connection may be lost

The container is ephemeral, so an uncommitted file does not survive it. If a
batch blocks substantial work and the session may be resumed cold, write the
numbered batch to `.claude/OPEN-QUESTIONS.md` and commit it, so a fresh
session picks the whole batch up at once; delete the file in the commit that
consumes the answers. This is a judgment call for large blocking batches, not
the default — a short batch belongs in the conversation only.
