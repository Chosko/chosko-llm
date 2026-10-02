# cmd-add: per-name isolation

## Overview

Covers how `scripts/cmd-add.sh` installs several features in one invocation
without one failure stopping the rest. The rest of `cmd-add`:
[cmd-add.md](./cmd-add.md).

## Public API

- None of its own; CLI and exit codes: [cmd-add.md](./cmd-add.md) § Public API.

## Internal patterns

- **Per-name isolation via subshell.** `add_one` wraps its
  whole body in `( ... )` so any `die` inside — `resolve_feature`,
  `require_versioned_source`, the "already installed" checks —
  terminates only that subshell, not the parent script; the caller's
  `for spec in "$@"` loop keeps going and tracks a `failed` flag.
  `resolve_feature` failure is doubly nested (its own `die` fires
  inside the `<(...)` process substitution feeding `mapfile`), so
  `add_one` explicitly checks `kind`/`name` came back non-empty rather
  than relying on `mapfile` raising an error.

## Domain dependencies

- None beyond [cmd-add.md](./cmd-add.md) § Domain dependencies.

## Cross-references

- [cmd-add.md](./cmd-add.md) — the hub: CLI, exit codes, scope and
  dependency rules, and the other internal patterns of `add_one`.

## When to read the source

- Changing multi-name looping or best-effort/continue-on-error
  semantics → `add_one` function and the trailing `for spec in "$@"`
  loop in `cmd-add.sh`.
