#!/usr/bin/env bash
# cli-taste.sh — Capture CLI command output for taste evaluation.
# Runs a command, captures stdout/stderr with timing and metadata.
# Usage: bash scripts/cli-taste.sh "<command>" [project-dir]
# Output: JSON with captured output + metadata
set -uo pipefail

COMMAND="${1:?Usage: cli-taste.sh \"<command>\" [project-dir]}"
PROJECT_DIR="${2:-.}"

STDOUT_FILE=$(mktemp /tmp/founder-cli-stdout.XXXXXX)
STDERR_FILE=$(mktemp /tmp/founder-cli-stderr.XXXXXX)

START_S=$(date +%s)
EXIT_CODE=0
(cd "$PROJECT_DIR" && bash -c "$COMMAND") > "$STDOUT_FILE" 2> "$STDERR_FILE" || EXIT_CODE=$?
END_S=$(date +%s)
DURATION_MS=$(( (END_S - START_S) * 1000 ))

# Let python3 handle all parsing for safety
python3 - "$COMMAND" "$STDOUT_FILE" "$STDERR_FILE" "$EXIT_CODE" "$DURATION_MS" << 'PYEOF'
import json, sys, re

command = sys.argv[1]
stdout_file = sys.argv[2]
stderr_file = sys.argv[3]
exit_code = int(sys.argv[4])
duration_ms = int(sys.argv[5])

with open(stdout_file) as f:
    stdout = f.read()
with open(stderr_file) as f:
    stderr = f.read()

lines = stdout.split('\n')
line_count = len(lines)
char_count = len(stdout)
has_color = '\033[' in stdout or '\x1b[' in stdout
section_count = sum(1 for l in lines if re.match(r'^(▸|===|---|##|◆|▾)', l))

result = {
    "command": command,
    "stdout": stdout,
    "stderr": stderr,
    "exit_code": exit_code,
    "duration_ms": duration_ms,
    "line_count": line_count,
    "char_count": char_count,
    "has_color": has_color,
    "section_count": section_count
}

print(json.dumps(result, indent=2))
PYEOF

rm -f "$STDOUT_FILE" "$STDERR_FILE"
