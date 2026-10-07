# Contributing to chosko-llm

This page is for working on the repo itself. Using chosko-llm is covered in
the [README](README.md); the rules for writing a feature live in
[docs/authoring-guide.md](docs/authoring-guide.md), which this page points
into rather than repeats.

## Developer install

Clone the repo and run the installer from your working copy; it derives the
origin URL from the local git remote:

```sh
git clone https://github.com/Chosko/chosko-llm.git chosko-llm
cd chosko-llm
./install.sh
```

Edits in the working copy reach `~/.claude/` only through
`chosko-llm update`: installs are copies, never symlinks.

## Authoring features

| Kind | Lives in | Guide |
| --- | --- | --- |
| Command | `commands/<name>.md` | [Authoring a command](docs/authoring-guide.md#commands) |
| Skill | `skills/<name>/SKILL.md` + supporting files | [Authoring a skill](docs/authoring-guide.md#skills) |
| CLAUDE.md snippet | `claude-md/<name>.md` | [authoring guide](docs/authoring-guide.md) |
| Status line | `statusline/<name>.sh` | [Authoring a statusline](docs/authoring-guide.md#statusline) |
| Hook | `hooks/<name>.sh` | [Authoring a hook](docs/authoring-guide.md#hook) |

- **Frontmatter.** Every feature needs `name`, `version`, `type` and
  `description`; `add` and `update` refuse a file without `version`. The
  optional keys (`replaces:`, `requires:`, the hook-only `event:` /
  `matcher:`, and the loading-control keys) are in
  [Frontmatter schema](docs/authoring-guide.md#frontmatter-schema).
- **The `description` is short by contract.** Claude Code injects every
  installed feature's description into the system prompt, so each one is a
  cost every session pays. Flags and contracts go in the body's leading `#`
  header instead. See
  [The description contract](docs/authoring-guide.md#the-description-contract).

## Versioning

Two version axes: a feature's own `version:` frontmatter, and the root
`VERSION` that `install.sh` reports. A shipped change bumps root `VERSION`
and adds a matching `CHANGELOG.md` section; a feature change bumps both
axes. Project documentation and the repo-local skills under
`.claude/skills/` bump neither. The full rule, including what counts as
documentation, is in [Versioning](docs/authoring-guide.md#versioning).

## Guards

Authoring-time checks, run by hand; each is silent on success and fails
naming the violation.

| Script | Run it after |
| --- | --- |
| [`scripts/check-changelog.sh`](scripts/check-changelog.sh) | bumping `VERSION` |
| [`scripts/check-home-paths.sh`](scripts/check-home-paths.sh) | editing any body under `commands/` or `skills/` |
| [`scripts/check-routing.sh`](scripts/check-routing.sh) | adding, renaming or removing a pipeline feature, or editing the routing table |

Details: [the routing guard](docs/authoring-guide.md#the-routing-guard),
[the home-path guard](docs/authoring-guide.md#the-home-path-guard).

## Repo layout

| Path | Purpose |
| --- | --- |
| `install.sh` / `uninstall.sh` | Bootstrap the managed clone and `~/bin` proxy / tear them down. |
| `VERSION` / `CHANGELOG.md` | Repo-level version stamp and the user-facing changes per version, newest first. `upgrade` reads the changelog to print what a pull changed. |
| `bin/chosko-llm`, `bin/chosko-llm.cmd` | The proxy copied to `~/bin/` by `install.sh`, and its Windows shim. |
| `scripts/lib.sh` | Shared shell helpers: logging, frontmatter, path resolution. |
| `scripts/cmd-*.sh` | One file per CLI subcommand; the proxy delegates here. |
| `scripts/check-*.sh` | The authoring-time guards above. Not subcommands. |
| `commands/`, `skills/`, `claude-md/`, `statusline/`, `hooks/` | The shipped features, one kind per folder. |
| `docs/reference.md` | The complete feature and CLI reference the README links into. |
| `docs/authoring-guide.md` | How to write a feature of any kind. |
| `docs/cli-help.txt` | Help text rendered by `chosko-llm help`. |
| `.claude/context/`, `.claude/domain/` | This repo's own navigation and domain layers. |
| `.claude/skills/` | Repo-local audit skills (`/context-budget`, `/rule-overlap`). Unversioned, never installed. |
| `.claude/TASKS.md`, `.claude/tasks/` | This repo's own backlog. |
