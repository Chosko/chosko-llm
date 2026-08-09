# Authoring guide

This guide covers how to write new **commands** and **skills** in this repo so
the `chosko-llm` CLI can install them.

## docs/ is authoring-time-only — never a runtime source

`scripts/cmd-add.sh` installs only `commands/`, `skills/`, `claude-md/`, and
`statusline/` into `~/.claude/`. `docs/` is never copied there, and a deployed
command/skill runs with the user's own project as its working directory, not
this repo — so a path like `docs/authoring-guide.md` does not exist at
runtime for an installed feature.

This document (and README.md, and a task's Hints when the task is about
improving this repo) may safely reference `docs/` paths, because those are
read by a human or by Claude Code working **on this repo**, at authoring
time. What must **never** happen: a `commands/*.md` or `skills/*/SKILL.md`
body instructing the agent executing that command/skill to read a `docs/`
path at runtime. Any procedural content a shipped command or skill actually
needs must be stated inline in that command/skill's own file — or, if it
needs to reach the user's global `CLAUDE.md`, shipped as a `claude-md`
feature, since that's the only `docs`-adjacent content that actually gets
merged into an installed target. See CLAUDE.md's "Authoritative references"
section for the one-line pointer back to this note.

## Frontmatter schema

Every feature file starts with a YAML frontmatter block. All four fields are
required.

```markdown
---
name: refactor-reviewer
version: 1.2.0
type: command            # or: skill
description: One short sentence summarizing the feature.
---

# Body of the command/skill in markdown follows...
```

| Field         | Rules                                                                    |
| ------------- | ------------------------------------------------------------------------ |
| `name`        | kebab-case. MUST match the filename (without `.md`) or the skill folder. |
| `version`     | Semantic version, e.g. `0.1.0`, `1.2.0`. Required — install will refuse without it. |
| `type`        | `command` for `commands/*.md`, `skill` for `skills/*/SKILL.md`, `claude-md` for `claude-md/*.md`, `statusline` for `statusline/*.sh`. |
| `description` | A single paragraph, no line breaks. For a simple feature, one short sentence is enough. A command or skill with several flags/modes may use a longer, multi-clause description that documents them — that detail is what `chosko-llm show <feature>` and (for skills) Claude Code's own skill-discovery listing surface to the user before they read the body. `chosko-llm ls` does not print `description` at all (see its `NAME KIND INSTALLED LATEST STATUS` columns), so description length never affects that table. |

### `replaces:` — the optional fifth field

A fifth key, `replaces:`, is optional and unset on almost every feature. Set it
only when a feature **changes kind** — most often when `commands/<n>.md` is
rewritten as `skills/<n>/SKILL.md`.

Install is copy-based and never prunes, so without it the old artifact stays
installed forever next to the new one: two definitions of one `/<n>` slash
command. `update --all` would only report
`Skipping command '<n>': no source in managed clone.` and leave it there.

```markdown
---
name: context-build
version: 1.0.0
type: skill
description: Build a navigation context layer.
replaces: command:context-build
---
```

| Field      | Rules                                                                  |
| ---------- | ---------------------------------------------------------------------- |
| `replaces` | Optional. A kind-prefixed spec: `command:<name>`, `skill:<name>`, `claude-md:<name>`, or `statusline:<name>`. Names the artifact this feature supersedes. A feature may not name itself. |

What the CLI does with it:

- `chosko-llm add <spec>` / `chosko-llm update <spec>` — after installing the
  feature, if the named artifact is installed, remove it (same deletion
  semantics as `chosko-llm rm` for that kind) and log
  `Migrated command 'context-build' -> skill 'context-build'`. If it is not
  installed, nothing happens and nothing is logged.
- `chosko-llm update --all` — when an installed artifact has no source in the
  managed clone, the clone is scanned for a feature declaring `replaces:` for
  it. On a hit, the replacement is installed and the stale artifact removed. On
  no hit, the usual `Skipping … no source in managed clone.` warning is emitted.

Two lessons from the first real migration (`context-build` and `context-update`,
both `commands/<n>.md` → `skills/<n>/SKILL.md` in v0.46.0):

- **Delete the old file in the same commit that adds the new one.** `replaces:`
  cleans up the *user's* install; it does nothing about the clone. Leaving
  `commands/<n>.md` in the repo alongside `skills/<n>/SKILL.md` gives two
  sources for one name, and `resolve_feature` has to be disambiguated with a
  `command:` / `skill:` prefix on every call.
- **Version the new artifact above the old one.** `update --all` compares
  versions, so the replacement must be a bump on what the user has installed, or
  the migration path is never taken. Continue the old feature's version series
  rather than restarting at `0.1.0` — a command-to-skill rewrite is not a new
  feature to its users.

**Drop the key a release or two after the migration has propagated.** It exists
to fix up installs that predate the rename; once everyone has run
`chosko-llm upgrade && chosko-llm update --all`, it is dead weight, and a stale
`replaces:` will delete a genuinely new artifact if someone later reuses the old
name for the old kind.

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
   description: One short sentence summarizing the feature.
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

The 7-step task workflow is encoded twice: as the `/task-implement` prompt
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

## Keeping the two `council-gate.md` copies in step

The optional claude-council decision gate is encoded twice, as
`skills/architect/council-gate.md` and
`skills/product-design/council-gate.md`. **Touch one, touch the other.**

This duplication is forced by the install model, not an oversight — do not
"fix" it by extracting a shared file. Skills install as self-contained
folders: `cmd-add` copies `skills/<name>/` recursively into `$CLAUDE_HOME`,
and nothing outside that folder travels with it. A shared file at, say,
`skills/_shared/council-gate.md` would exist in this repo and be absent on
every machine that installed the skill — the worst possible failure, because
it works for the author and breaks for everyone else. Two folders, two
copies, one obligation to keep them aligned.

Each copy carries a header naming its sibling, so an editor who opens one
learns about the other immediately.

The two files are intentionally *near*-identical, not identical. The
divergences are flagged inline in both, and there are exactly two:

1. **Fold-back target.** `/architect` folds surviving minority dissent into
   the feature document's Open questions section; `/product-design` folds it
   into `product-design.md`'s design decisions (or
   `technical-direction.md`'s open-decisions section when the axis is
   recorded as explicitly open).
2. **The PHASE 3 write barrier.** `/architect` forbids writing any file
   before PHASE 3, so its copy documents the narrow carve-out that lets
   claude-council write its own report and transcript.
   `/product-design` has no such prohibition — it stubs documents in PHASE 1
   and writes in PHASE 3, 5, and 7 — so its copy says explicitly that no
   carve-out is needed.

A third difference is structural rather than textual: `/product-design`'s
copy is gated to PHASE 6's greenfield branch, since brownfield is
confirm-and-record over a stack that already exists and has no fork to
pressure-test.

Anything else that drifts between the two is a bug.

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

## A question the user picks an answer from needs parallel arms

When a skill asks the user to choose, the answer is often rendered as
selectable options, and the labels are derived by re-voicing the question in
the user's mouth. Re-voicing happens **per arm**. So a disjunction whose arms
have different grammatical subjects yields labels that disagree about who
"I" is.

`skills/product-roadmap/` is the worked example, having shipped the bug
first. PHASE 0 asked:

> Do you already have an ordering in mind, or should I propose one?

Unambiguous as prose — the agent is speaking throughout. Rendered as options
it produced `I have an ordering` (I = the user, from arm one) beside
`I'll propose one` (I = the agent, echoing arm two): one pronoun naming two
people in one list. The option descriptions flipped with them, "*You* draft
an ordering" against "*You* tell me the sequence…".

Three rules, cheapest first:

- **Prefer no disjunction at all.** A single arm cannot disagree with itself.
  "Do you have an ordering in mind? If not, I'll propose one." puts the
  question in the first sentence and the default in the second — and the
  second is a *statement*, not an arm, so it never becomes a label.
- **Where both paths must be on screen, make the arms parallel** — same
  subject, same form — so re-voicing transforms both or neither. Possessive
  noun phrases do this well: "start from your ordering, or from my draft?"
  flips as a pair into "my ordering" / "your draft", and a collision becomes
  structurally impossible rather than merely unlikely.
- **Pin the reply mapping in the skill body.** Wording governs what an agent
  is *likely* to render; only a stated mapping governs what it *must*. One
  line — yes → `given`, no → `propose` — removes the last thing being
  re-derived on every run.

The test to apply before shipping any such question: *can one arm be re-voiced
without the other changing the same way?* If it can, the labels will
eventually disagree.

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

## Commit-and-push convention

Features that write files split into two groups, each exposing one opt-in
flag so the user can override the default commit behaviour. The split is about
*behaviour*, not kind — several members of both groups (`/context-build`,
`/context-update`, `/context-convert`, `/task-implement`, `/product-design`,
`/architect`) ship as skills, and the rules below apply to them unchanged:

- **Authoring commands (uncommitted by default).** `/context-build`,
  `/context-convert`, `/task-enrich`, `/refactor-codebase`, `/refactor-tests`,
  `/task-setup`, `/domain-setup`, `/unity-mcp-setup`, `/product-design`,
  `/architect`, and
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
  it. Never branch or tag. Push only via the commit-and-push protocol below.
- On a non-git VCS, honour the project CLAUDE.md `## VCS` mapping
  (e.g. git→`cm` for Plastic SCM).

`/project-setup --commit` is the one orchestrator: it commits its own
artifacts first, then invokes its nested commands with `--commit` so each
commits its own output (`/task-setup`, `/domain-setup`, `/context-build`, and
`/unity-mcp-setup`, in that order).

### The push protocol

Every command that commits (whether by default or under `--commit`) also
pushes, once it has actually committed something, using this single
algorithm — author it here once; a dependent command references this
section by name rather than re-deriving it.

**Git projects only** (see the non-git exemption below):

1. **Pull at start.** Right after the command's own precondition/setup
   checks, and before any of its normal work begins, run `git pull` on the
   current branch. A conflict stops the run immediately, before any of the
   command's work happens — report the conflict output and tell the user to
   resolve manually and re-run. "Already up to date" or a clean fast-forward:
   proceed normally.
2. Do the command's own work and commit exactly as already specified above
   (unchanged: explicit paths only, no empty commits, no
   `--no-verify`/`--amend`, report-and-stop on commit failure).
3. **Pre-push re-sync.** Immediately before pushing, run `git pull` again —
   other commits may have landed upstream while the command was running. A
   clean fast-forward/merge: continue to push. A conflict: abort the merge,
   leave the local commit intact, do **not** push, and report that the
   commit exists locally but could not be synced — the user must resolve and
   push manually.
4. **Push.** `git push`. On failure (rejected, no upstream, no remote):
   report the exact output and stop. Never retry, never force-push.

**`--no-push` flag.** Every pushing command accepts `--no-push` to skip
steps 1, 3, and 4 above while still committing as it does today.
- For auto-committing commands (`/task-add`, `/task-clean`,
  `/task-implement`, `/context-update`), `--no-commit` implies `--no-push`
  — there is nothing to push.
- For authoring commands (`/context-build`, `/context-convert`, `/task-enrich`,
  `/refactor-codebase`, `/refactor-tests`, `/task-setup`, `/domain-setup`,
  `/unity-mcp-setup`, `/product-design`, `/architect`, `/project-setup`),
  which only commit under `--commit`, `--commit --no-push` is a valid
  combination: commit locally, skip the sync/push cycle.

**Non-git VCS exemption.** When the project's CLAUDE.md defines a `## VCS`
section overriding git (e.g. Plastic SCM), skip the entire pull → re-sync →
push sequence unconditionally — only the commit (checkin) step runs. This is
a project-level fact recorded once in that project's CLAUDE.md by
`/project-setup`, not something each command re-decides per run.

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
- **Committing a new `scripts/*.sh` non-executable.** The proxy `exec`s
  `scripts/cmd-<sub>.sh` directly, with no `bash` prefix, so a subcommand
  tracked at `644` fails outright on any clone where `install.sh` has not
  run. Three code paths blanket-`chmod +x "$CHOSKO_LLM_HOME"/scripts/*.sh`
  (`install.sh`, `cmd-upgrade.sh`, `cmd-channel.sh`), which hides the mistake
  from users but leaves the tracked mode wrong — and it then re-dirties the
  working tree of every developer who runs the CLI against their own clone.
  Everything under `scripts/` is `755`, sourced libraries included. Fix:
  `git update-index --chmod=+x scripts/<file>.sh`.
- **Telling a shipped command/skill to read a `docs/` path at runtime.**
  `docs/` is never installed to `~/.claude/`, so the executing agent has no
  such file at hand — this creates a dangling reference the moment the
  command runs in a deployed target. Fix: inline the procedure in the
  command/skill body itself, or ship it as a `claude-md` feature if it needs
  to reach the user's global `CLAUDE.md`.
