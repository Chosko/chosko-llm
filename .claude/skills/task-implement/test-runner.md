# Test-runner inference heuristics

Read this only when RESOLVING THE TEST RUNNER step 2 fires — i.e. no
testing-policy marker and no project convention names the test command.

> **MIRRORED COPY** — the heuristics below are duplicated in
> `commands/task-setup.md` (TEST RUNNER INFERENCE). Any edit here must be
> mirrored there.

Infer the runner from the project's files:

- `pytest.ini` / `pyproject.toml` with `[tool.pytest.ini_options]` /
  `setup.cfg` with `[tool:pytest]` → `pytest`. Prefer
  `.venv/Scripts/python.exe -m pytest` on Windows or
  `.venv/bin/python -m pytest` on POSIX if a venv exists.
- `package.json` with a `test` script → `npm test` (or `pnpm test` /
  `yarn test` if a lockfile indicates it).
- `Cargo.toml` → `cargo test`.
- `go.mod` → `go test ./...`.
- `Gemfile` with rspec → `bundle exec rspec`.
- Other: scan for a `Makefile` target named `test` → `make test`.

If still ambiguous, ask the user before starting any task.

If nothing here matches AND there is no test directory (`tests/`, `test/`,
`__tests__/`, `spec/`), the project has no test suite — read
`./no-test-suite.md`.
