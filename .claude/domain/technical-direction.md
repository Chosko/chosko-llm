# Technical direction — chosko-llm

A confirmed existing stack, not a greenfield choice. `chosko-llm` is a bash
CLI plus a body of markdown whose runtime is Claude Code itself. Nothing
recorded here was selected during the design process; it was read off a
shipping implementation and confirmed, with the genuinely undecided parts
moved to the open-decisions section at the end.

## Stack

**The CLI is POSIX-ish bash.** Every script under `scripts/` opens with
`set -euo pipefail` and sources `scripts/lib.sh`. Text handling is `awk`,
`sed`, and `grep`. There is no yq, jq, Python, or other language runtime,
and adding one is a hard rule violation — see
[`../../CLAUDE.md`](../../CLAUDE.md). Frontmatter is read by
`parse_frontmatter` in `lib.sh`: a flat key/value `awk` scanner over the
first `---` block, recognizing five keys.

**Shipped features are markdown.** A command or skill is a prompt executed
by an agent, not code the CLI runs. This is the product's defining
technical fact: the frontmatter contract carries the weight a type system
would carry elsewhere, and it is why there is no test suite. The one
shipped statusline is bash.

**Windows runs through git-bash.** `bin/chosko-llm.cmd` locates it and
forwards; all behaviour stays single-sourced in the bash proxy.

Bootstrap and staying current drove this choice: they must work on a fresh
machine before anything is installed, so bash and git are the floor. The
six authoring features drove nothing, being markdown.

## Topology / architecture

A modular monolith of shell scripts, one process per invocation.
`bin/chosko-llm` is a thin proxy — parse the subcommand, exec
`scripts/cmd-<sub>.sh` from the managed clone. Shared helpers live in
`scripts/lib.sh`; `scripts/lib-task-external.sh` holds backlog helpers
beneath the task orchestrator.

One boundary matters: the proxy, `install.sh`, and `uninstall.sh` cannot
source `lib.sh`, because they must run before the managed clone has any
scripts. They reimplement minimal logging and path defaults instead.

The other structural fact is two copies of the repository rather than one —
the working repository where features are authored, and the managed clone
at `$CHOSKO_LLM_HOME` that the proxy reads from. The reason is sandbox
isolation, recorded in [product-design.md](./product-design.md).

The largest single component is `scripts/cmd-task-impl.sh`, the external-LLM
orchestrator. Nothing in the current feature set threatens to overload it.

## Data and storage

No database, no lockfile, no index. The filesystem is the state and
frontmatter is the record: `ls --available` walks the managed clone, `ls
--installed` walks `$CLAUDE_HOME`, and the version comparison is between
the two frontmatter values.

The indices the product does keep are markdown, versioned with the project
and readable by both humans and agents: `.claude/TASKS.md`,
`.claude/FEATURES.md`, and the context and domain `INDEX.md` files.

One exception exists to the no-state-file rule:
`$CHOSKO_LLM_HOME/.auto-upgrade-state`, gitignored, holding the
auto-upgrade preference and the last-run date. It is scoped deliberately —
machine-local preferences only, never feature state.

No blob storage. `export` writes into `$CHOSKO_LLM_EXPORT_DIR`, defaulting
to `~/claude-exports`.

## Async / queueing

Nothing is queued. There is no broker, no job runner, and no scheduler.

One opportunistic hook exists: `scripts/auto-upgrade.sh` runs inline from
the proxy before each dispatch, fires `chosko-llm upgrade` at most once per
calendar day, and can never abort the requested command. It stamps
`last_run` before upgrading, so a failure does not retry all day. That is
the entirety of the product's out-of-band work.

## Hosting and deployment

Runs on the user's machine. Nothing is hosted. GitHub holds the repository,
which is also the distribution channel.

Deploying a change means committing and pushing from the working
repository. Users receive it with `chosko-llm upgrade`, which pulls the
managed clone and refreshes the proxy; installed copies move only on
`chosko-llm update`. The two are separate acts by design.
`chosko-llm channel <branch>` points the managed clone at unmerged work.

There is no promotion path, no environments, and no CI. Re-running
`install.sh` is required only when the proxy or the Windows shim itself
changed.

## Inter-component protocols

- **CLI internals** — process exec. The proxy execs the subcommand script.
  No IPC, no daemon, no shared memory.
- **Distribution** — git over HTTPS.
- **External implementers** — subprocess. `aider` is driven with `--read`
  prompts and task bodies by `chosko-llm task-impl`; the Unity editor is
  driven over MCP.
- **The authoring half** — documents. The real protocol between the design
  pipeline, the backlog, and implementation is files with agreed schemas:
  feature document → task body → code. The schemas are specified in
  [product-workflow.md](./product-workflow.md) and
  [task-workflow.md](./task-workflow.md). Using documents rather than
  conversation is what makes the handoff survive across sessions, machines,
  and people.

## Cross-cutting concerns

**Auth and identity** — none. Access control is GitHub repository
permissions: the owner writes, teammates open pull requests.

**Observability** — none. Terminal logging through `lib.sh` helpers; no
metrics, traces, or telemetry. Premature for the product's stage.

**Testing** — no test suite, by design. Changes are verified by reading the
diff and running the CLI against a real clone. One mechanical guard exists,
`scripts/check-task-parity.sh`, which checks that the task status
vocabulary stays in sync across the files that duplicate it. It is invoked
by Claude at authoring time when task-related work touches that vocabulary
— not by CI, and not by any command or skill. When that invocation should
happen is currently convention rather than written contract; see open
decisions.

**Regulatory and data residency** — none apply. No user data leaves the
machine, and the only network traffic is git against the user's own
repository.

## Explicitly open decisions

- **Native Windows support.** git-bash is required today, located by
  `bin/chosko-llm.cmd`. This is an accepted limitation rather than a
  decision. PowerShell and WSL are both named as possible routes; neither
  has been evaluated. The cost that matters is ongoing maintenance of a
  second implementation, not the initial effort.
- **When `check-task-parity.sh` runs.** The guard exists and is referenced
  in `docs/authoring-guide.md`, `task-workflow.md`, and
  `product-workflow.md`, but nothing invokes it and no document states who
  should. Writing that protocol down is outstanding work.
- **Local install drift.** Copies placed with `--local` can fall behind the
  global version, and `ls` / `update` have no local awareness. Deliberately
  unaddressed until the drift is shown to cost something.
- **The frontmatter parser's ceiling.** `parse_frontmatter` cannot express
  list values, nested maps, or folded strings. No trigger has been set for
  revisiting the no-dependency rule — the decision is to handle it if and
  when a feature actually needs it.
