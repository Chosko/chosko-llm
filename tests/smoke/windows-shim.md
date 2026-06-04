# Smoke test: windows-shim

**Type:** CLI entry point (Windows-only)
**Source:** bin/chosko-llm.cmd, install.sh

## Setup

- Git for Windows installed (`%ProgramFiles%\Git\bin\bash.exe` exists).
- Run `install.sh` from Git Bash on Windows. Confirm it prints:
  - "Installed chosko-llm.cmd (Windows cmd/PowerShell shim)"
  - A Windows PATH reminder message showing the native `BIN_DIR` path.
- Confirm `~/bin/chosko-llm.cmd` (and `~/bin/chosko-llm`) exist.
- Add the `BIN_DIR` Windows path to your Windows PATH (System Properties →
  Advanced → Environment Variables → Path → Edit → New), then open a fresh
  cmd.exe and PowerShell window.

## Steps

### cmd.exe

1. `chosko-llm help`
2. `chosko-llm ls --available`
3. `chosko-llm add <feature>`
4. `chosko-llm show <feature>`
5. `chosko-llm rm <feature>`
6. `chosko-llm unknown-subcmd` — expect exit code 2 and an error message.

### PowerShell

7. Repeat steps 1–6 from a PowerShell window.

### Exit-code propagation

8. From cmd.exe: `chosko-llm unknown-subcmd & echo ERRORLEVEL=%ERRORLEVEL%`
   — must print `ERRORLEVEL=2`.
9. From PowerShell: `chosko-llm unknown-subcmd; $LASTEXITCODE` — must print `2`.

### Bash auto-detect fallback

10. Temporarily rename `%ProgramFiles%\Git\bin\bash.exe` (or set
    `BASH_EXE` to a non-existent path by editing the .cmd manually).
    Run `chosko-llm help` — expect a clear "bash not found" error on
    stderr and exit code 1.

### Install idempotency (re-run install.sh)

11. From Git Bash, re-run `install.sh`. Confirm:
    - The old `chosko-llm.cmd` is backed up to `chosko-llm.cmd.bak.<ts>`.
    - A fresh `chosko-llm.cmd` is placed in `~/bin`.

## Expected

1–7. All subcommands behave identically to running from Git Bash.
8–9. Exit code from the bash proxy is propagated faithfully to Windows.
10.  Stderr shows `chosko-llm: bash not found. Install Git for Windows...`;
     exit code is 1.
11.  Backup file created; fresh shim installed; no other files modified.

## Notes

- Colored output (`ls` table) and actionable suggestions (footer after `ls`)
  may be absent — cmd.exe and PowerShell do not allocate a PTY, so `[ -t 1 ]`
  and `[ -t 2 ]` return false inside the bash proxy. This is documented
  baseline behavior, not a bug.
- WSL users should run `chosko-llm` from within WSL (where `~/.chosko-llm`
  is the WSL home). The shim's `where bash` fallback can find
  `C:\Windows\System32\bash.exe` (WSL), which has a different `$HOME` —
  the explicit git-bash paths are probed first to avoid this.
