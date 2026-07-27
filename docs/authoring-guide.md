# Authoring guide

This guide covers how to write new **commands** and **skills** in this repo so
the `chosko-llm` CLI can install them.

## Frontmatter schema

Every feature file starts with a YAML frontmatter block. All four fields are
required.

```markdown
---
name: refactor-reviewer
version: 1.2.0
type: command            # or: skill
description: One-line summary used in `chosko-llm ls`.
---

# Body of the command/skill in markdown follows...
```

| Field         | Rules                                                                    |
| ------------- | ------------------------------------------------------------------------ |
| `name`        | kebab-case. MUST match the filename (without `.md`) or the skill folder. |
| `version`     | Semantic version, e.g. `0.1.0`, `1.2.0`. Required — install will refuse without it. |
| `type`        | `command` for `commands/*.md`, `skill` for `skills/*/SKILL.md`, `claude-md` for `claude-md/*.md`, `statusline` for `statusline/*.sh`. |
| `description` | One short line. Shown in `chosko-llm ls` and in skill discovery output.  |

## <a id="commands"></a>Authoring a command

1. Create `commands/<name>.md`.
2. Add the frontmatter block above with `type: command`.
3. Write the command body in markdown — instructions to Claude Code when the
   user invokes `/<name>`.
4. Verify the file is discoverable: from a clone where `install.sh` has been
   run, `./bin/chosko-llm ls --available` should show
   `<name>  command  <installed-or-—>  <version>`.

The filename **must** match the `name` frontmatter field. `chosko-llm ls`
matches by `name`, but `chosko-llm add <name>` resolves files by filename, so
a mismatch will break `update --all`.

## <a id="skills"></a>Authoring a skill

1. Create `skills/<name>/`.
2. Inside it, create `SKILL.md` with the frontmatter block above and
   `type: skill`.
3. Add any supporting files alongside `SKILL.md` — they will be copied
   recursively when the skill is installed.
4. The folder name **must** match the `name` frontmatter field.

## <a id="statusline"></a>Authoring a statusline

1. Create `statusline/<name>.sh`, a directly executable/sourceable bash
   script — it must remain valid as the actual `statusLine` command Claude
   Code shells out to.
2. Because a `.sh` file can't start with a YAML block the way a `.md` file
   can, the frontmatter lives inside a bash no-op heredoc placed right
   after the shebang:

   ```sh
   #!/usr/bin/env bash
   : <<'CHOSKO_FRONTMATTER'
   ---
   name: session-statusline
   version: 0.1.0
   type: statusline
   description: One-line summary used in `chosko-llm ls`.
   ---
   CHOSKO_FRONTMATTER
   # ... the actual status line script ...
   ```

   `parse_frontmatter` in `lib.sh` just scans for the first `---`/`---`
   pair regardless of where it sits in the file, so this reads identically
   to a `.md` frontmatter block while the shipped script stays a no-op to
   execute — `: <<'...'` is a bash null command reading (and discarding) a
   heredoc.
3. The folder name (minus `.sh`) **must** match the `name` frontmatter
   field, same rule as commands and skills.
4. `chosko-llm add <name>` installs the script to
   `$CLAUDE_HOME/statusline/<name>.sh` and then prints a copy-pasteable
   prompt for a Claude Code session to merge the top-level `"statusLine"`
   key into `$CLAUDE_HOME/settings.json` — this repo intentionally does not
   edit `settings.json` itself (arbitrary JSON shape this repo doesn't own,
   and the project avoids adding a `jq`/`python` dependency for shell-side
   brace-matching).

## Tool discipline is global — do not restate it

Do **not** add a `TOOL DISCIPLINE` block to a command or skill. The
`claude-md:tool-usage-policy` feature is merged into the user's global
`CLAUDE.md`, so it is already in force in every session: Read over `cat`,
Edit/Write over shell redirection, and matching the command syntax to the
shell tool you call. Seven near-identical copies of that policy cost tokens
on every invocation and drift apart; one artifact that ships into context
does not.

Soft dependency: installing `claude-md:tool-usage-policy` is the recommended
baseline for all commands and skills in this repo.

What *does* belong in a command is a constraint specific to **that** command
— e.g. "this is the only phase that shells out", or "never use the Write tool
on an existing body file". Put such a line in the section it governs, not in
a standalone block at the top.

## Keeping `/task-implement` and `task-impl` in step

The 8-step task workflow is encoded twice: as the `/task-implement` prompt
under `skills/task-implement/`, and as bash in `scripts/cmd-task-impl.sh` +
`scripts/lib-task-external.sh`. Nothing forces them to agree, so run the
parity guard whenever you touch **either** artifact:

```sh
./scripts/check-task-parity.sh
```

It exits non-zero if a status tag (`[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
`[PARTIAL]`, `[IN PROGRESS]`, `[DONE]`, `[SKIP]`, `[STALE]`) is unknown to or
missing from one side, or if the two sides disagree on the eight per-task
steps. `[SKIP]` and `[STALE]` are deliberately prompt-only in
`BASH_REQUIRED_TAGS` — the bash side excludes non-eligible tasks by omission.

The guard checks the cheap invariants, not full behavioural parity.

### The status vocabulary lives in three places

Any change to the task status vocabulary must land in all three, in the same
commit, or the guard fails:

1. The prompt side — `skills/task-implement/` (every canonical tag must
   appear somewhere in it).
2. `scripts/check-task-parity.sh` — the `CANONICAL_TAGS` list, and
   `BASH_REQUIRED_TAGS` only if the orchestrator actually acts on the tag.
3. `scripts/cmd-task-impl.sh` — the implementable-status allowlist: both the
   `resolve_all` awk selection and the per-task `case` in `implement_one`.

`[STALE]` (added in v0.15.0) is the worked example. It is canonical, it is
prompt-only in `BASH_REQUIRED_TAGS`, and the orchestrator refuses it
explicitly rather than skipping it — so it touches all three places for three
different reasons. A partial rollout of a status tag fails the guard, which is
the point: the two encodings of the workflow cannot be allowed to drift
silently.

## State that outlives a session belongs in a project document

A skill whose phases span multiple sessions must keep its state in a
versioned document inside the project, not in conversation history and not
behind a `--resume` flag. Conversation is gone next session; a flag is not
remembered weeks later.

`skills/product-design/` is the pattern: `.claude/domain/design-process.md`
records the method, the phase list, and a current-stage marker, and every
phase transition rewrites that marker **before** the phase ends. A later run
detects the document, reads the stage, summarizes where the last session
stopped, and offers to resume or start fresh — with no argument to pass.

Two rules make it work:

- **The marker is load-bearing.** A phase that ends without rewriting it
  degrades every later resume, and does so silently: the documents look
  finished while the marker points at the wrong place. Say so explicitly in
  the skill.
- **The marker is the state, not the documents.** A resume reads the marker
  to decide where to pick up, and reports a mismatch with the documents
  rather than re-deriving the stage from their contents.

## Versioning

Use semver. Bump rules:

| Change                                                            | Bump  |
| ----------------------------------------------------------------- | ----- |
| Wording, typos, clarifications that don't change behavior         | patch |
| New capability inside the same task / additional optional inputs  | minor |
| Behavior change, removed capability, renamed flags, breaking I/O  | major |

Always bump after a meaningful edit. `ls` displays the installed and latest
versions side by side, so a forgotten bump leaves both columns showing the
same value and users have no signal that there is anything to refresh.

## Commit-control convention

Commands that write files split into two groups, each exposing one opt-in
flag so the user can override the default commit behaviour:

- **Authoring commands (uncommitted by default).** `/context-build`,
  `/task-enrich`, `/refactor-codebase`, `/refactor-tests`, `/task-setup`,
  `/domain-setup`, `/unity-mcp-setup`, `/product-design`, `/architect`, and
  `/project-setup` write their output and leave it in the working tree
  for review. They accept **`--commit`** to commit what they wrote at the
  end.
- **Auto-committing commands.** `/task-add`, `/task-clean`,
  `/task-implement`, and `/context-update` commit automatically. They accept
  **`--no-commit`** to write their changes but skip the commit.

When adding a new command that writes files, follow the same rules:

- `--commit` and `--no-commit` are mutually exclusive — passing both is an
  error with a clear message.
- Stage ONLY the explicit paths the command wrote. Never use a catch-all
  (`git add -A` / `git add .` / `git add -u`).
- Make no empty commit: if the run wrote nothing, commit nothing.
- Never use hook-skipping or history-rewriting flags (`--no-verify`,
  `--amend`, `--no-gpg-sign`); surface a hook failure and let the user fix
  it. Never push, branch, or tag.
- On a non-git VCS, honour the project CLAUDE.md `## VCS` mapping
  (e.g. git→`cm` for Plastic SCM).

`/project-setup --commit` is the one orchestrator: it commits its own
artifacts first, then invokes its nested commands with `--commit` so each
commits its own output (`/task-setup`, `/domain-setup`, `/context-build`, and
`/unity-mcp-setup`, in that order).

## Common mistakes

- **Missing frontmatter or missing `version`.** The CLI refuses to install.
  Fix: add a complete frontmatter block.
- **`name` doesn't match filename / folder name.** Listings get inconsistent;
  resolution by name may pick the wrong file. Fix: rename one to match.
- **Forgetting to bump `version` after editing.** Users won't see the update.
  Fix: bump per the table above before committing.
- **Skill in the wrong place.** A skill must be a folder under `skills/` with
  a `SKILL.md` inside. A bare `skills/foo.md` will be ignored.
- **Editing the managed clone (`~/.chosko-llm/`) directly.** `chosko-llm upgrade`
  will refuse to fast-forward over local changes. Always edit the working repo,
  push, then `upgrade`.
