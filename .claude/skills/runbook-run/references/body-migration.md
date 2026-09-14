# Migrating a runbook body to `<id>-<name>.md`

Authority for: moving a legacy body from `.claude/runbooks/<name>.md` to
`.claude/runbooks/<id>-<name>.md` — the rename, when it may not happen, how it
is staged, the collision stop, and the non-git mapping. Nothing else.

**Read it only when the migration check in `runbook-schema.md` § *The store*
has fired** — a writing command's block has a `File:` whose file name does not
begin with `<id>-`. A run with nothing to migrate never opens this file.

**Its readers are exactly two:** `/runbook-run`, in its *Resolve* step, and
`/runbook-create --append`, once it has resolved its target. No other command
reads it or migrates a body: `/runbook-clean` deletes whatever `File:` names,
the read-only commands never write, and the single-step amend in
`step-amend.md` writes at `File:` and leaves the file name alone.

---

## Never while `[RUNNING]`

A body is **never** migrated while its runbook's index `Status:` is
`[RUNNING]`, under any flag. A live orchestrator — possibly an older version on
another machine, possibly this one resuming — holds the body's path from its
own *Resolve* and re-reads it every step; moving the file under it breaks that
run. A `[RUNNING]` runbook keeps its current `File:` path, and the command
works at that path.

**A resume never migrates.** The interrupted run left the body where it was,
and it stays there for the rest of that run.

## The rename

1. **Target check.** The target is `.claude/runbooks/<id>-<name>.md`, from the
   block's id and name. If a file already exists at that path, **stop and
   report** both paths — the block's `File:` and the occupied target — and
   rename nothing, rewrite nothing, overwrite nothing.
2. **Move.** `mv .claude/runbooks/<name>.md .claude/runbooks/<id>-<name>.md`
   — the old path is the one `File:` holds. A plain move, never `git mv`: see
   § *Staging*.
3. **Rewrite `File:`.** In the runbook's index block, change the `File:` line's
   value to the new path. Nothing else in the block or the body changes: same
   heading, steps, markers and `Done:` lines.
4. **Use the new path** for every later read and write in this command.

A `File:` that names a file which does not exist is not a migration: the
command handles it as it handles any missing body — stop and report.

## Staging

The rename lands in **the writing command's own one commit**, never a commit of
its own, and that commit carries **both** paths — the old one's removal and the
new one's addition — beside `.claude/RUNBOOKS.md`, so git records a rename.

**Nothing is staged at migration time.** That is why the move is a plain `mv`:
`git mv` would stage both halves at once, and any commit made before the
command's own — a step's `/task-implement` committing its work, the user's next
unrelated commit — runs a plain `git commit` over the whole index and would
carry the rename away from the `File:` rewrite, leaving a commit whose body path
and index disagree. At commit time stage all three by explicit path:

```
git add -- <old path> <new path> .claude/RUNBOOKS.md
```

`git add` on the old path stages its removal, since the file is tracked and
gone from the working tree. Hold the old path from the migration until that
commit — after the rewrite, `File:` no longer names it. Never a catch-all.

Under `--no-commit` the move and the `File:` rewrite still happen — they are
the command's effect — and stay uncommitted with the rest of its writes. The
same holds for a command that migrates and then stops before it commits
anything — a run that finds nothing to select, for instance: the rename stays
unstaged in the tree, and the command's report names both paths so the user
can commit them together.

## Non-git VCS

On a project whose `CLAUDE.md` defines a `## VCS` section overriding git, use
that VCS's move command in place of `git mv` (for Plastic SCM, `cm move`), so
the move is recorded as a move rather than a delete plus an add, and check in
both paths with the command's own checkin. When the VCS has no move command,
move the file and check in the removal and the addition together.
