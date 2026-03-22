#!/usr/bin/env bash
# subagent_stop.sh — Log agent activity on completion.
# Hook: SubagentStop event. Target: <50ms.
# Appends to .claude/sessions/agent-activity.tsv.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Read hook input from stdin
INPUT=$(cat)

# Parse agent info from JSON input
AGENT_NAME=$(echo "$INPUT" | grep -o '"agent_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"agent_name"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "unknown")
AGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"agent_type"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "unknown")
DURATION=$(echo "$INPUT" | grep -o '"duration_ms"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/"duration_ms"[[:space:]]*:[[:space:]]*//' 2>/dev/null || echo "0")

# Ensure sessions directory exists
SESSIONS_DIR=".claude/sessions"
mkdir -p "$SESSIONS_DIR"

TSV_FILE="$SESSIONS_DIR/agent-activity.tsv"

# Write header if file doesn't exist
if [[ ! -f "$TSV_FILE" ]]; then
    printf "date\tagent_name\tagent_type\tduration_ms\n" > "$TSV_FILE"
fi

# Append entry
printf "%s\t%s\t%s\t%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$AGENT_NAME" "$AGENT_TYPE" "$DURATION" >> "$TSV_FILE"

echo -e "${DIM}✓ ${AGENT_NAME} (${AGENT_TYPE}) completed in ${DURATION}ms${NC}"
