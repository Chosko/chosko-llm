---
name: tool-usage-policy
version: 0.2.0
type: claude-md
description: Enforce Read/Write/Edit/Glob/Grep tools over shell commands for file operations.
---

## CRITICAL: Tool Usage Policy

When reading, creating, or modifying files, always use the built-in tools
(Read, Write, Edit, MultiEdit) rather than shell commands (PowerShell, bash,
`cat`, `echo >`, `cp`, `mv`, etc.).

Prefer tools over shell for:
- Reading file contents → Read tool
- Writing or overwriting files → Write tool
- Patching files → Edit / MultiEdit tool
- Listing directory contents → LS tool

Use the PowerShell or Bash tool only when a task genuinely requires shell execution
(running a build, executing a test suite, invoking a CLI that has no
equivalent tool).

**IMPORTANT — use the right shell for each tool:** The Bash tool runs bash/sh.
The PowerShell tool runs PowerShell. Never pass PowerShell syntax
(`Get-Content`, `$env:VAR`, `| Select-Object`, etc.) to the Bash tool, and
never pass bash syntax to the PowerShell tool. Match the command syntax to
the tool you are calling.
