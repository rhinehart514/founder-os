@REM # Polyglot launcher (batch + bash)
@REM # Windows: runs as .cmd batch file
@REM # Unix: runs as bash via the shebang-like trick below
@echo off
goto :batch

#!/usr/bin/env bash
# Unix path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
exec bash "$PLUGIN_ROOT/hooks/$1"

:batch
@REM Windows path
setlocal
set "SCRIPT_DIR=%~dp0"
if not defined CLAUDE_PLUGIN_ROOT set "CLAUDE_PLUGIN_ROOT=%SCRIPT_DIR%.."
call bash "%CLAUDE_PLUGIN_ROOT%\hooks\%~1"
endlocal
