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
| `type`        | `command` for `commands/*.md`, `skill` for `skills/*/SKILL.md`.          |
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
  and `/project-setup` write their output and leave it in the working tree
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
commits its own output.

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
