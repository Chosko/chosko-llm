@echo off
setlocal

rem Locate git-bash — probe common Git for Windows install paths first,
rem then fall back to `where bash` (last resort; may resolve WSL bash which
rem has a different $HOME and managed-clone location).
set "BASH_EXE="
if exist "%ProgramFiles%\Git\bin\bash.exe"                  set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramFiles(x86)%\Git\bin\bash.exe"    set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LocalAppData%\Programs\Git\bin\bash.exe"

if not defined BASH_EXE (
    for /f "delims=" %%B in ('where bash 2^>nul') do (
        if not defined BASH_EXE set "BASH_EXE=%%B"
    )
)

if not defined BASH_EXE (
    echo chosko-llm: bash not found. >&2
    echo Install Git for Windows ^(https://git-scm.com^) and try again. >&2
    exit /b 1
)

"%BASH_EXE%" "%~dp0chosko-llm" %*
exit /b %ERRORLEVEL%
