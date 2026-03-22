#!/usr/bin/env bash
# task_completed.sh — TaskCompleted hook (BLOCKING)
# Quality gate: blocks task completion if assertions regressed.
# Only gates on /go tasks. Other skills pass through.
# Target: <5s (runs assertion check).

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(pwd)

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _TC_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_TC_SOURCE" ]]; do _TC_SOURCE="$(readlink "$_TC_SOURCE")"; done
    _TC_DIR="$(cd "$(dirname "$_TC_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_TC_DIR/.." && pwd)"
fi

# Colors
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_DIM='\033[2m'
C_NC='\033[0m'

# --- Only gate on /go skill tasks ---
SKILL=""
if command -v jq &>/dev/null; then
    SKILL=$(echo "$INPUT" | jq -r '.skill // ""' 2>/dev/null || echo "")
else
    # Fallback: grep for skill field
    SKILL=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"skill"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

if [[ "$SKILL" != "go" && "$SKILL" != "/go" ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# --- Read baseline assertions from eval-cache.json ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
BASELINE_PASS=0
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    BASELINE_PASS=$(jq -r '.assertion_pass_count // 0' "$EVAL_CACHE" 2>/dev/null || echo "0")
fi

# --- Run fast assertion check ---
EVAL_SCRIPT="$FOUNDER_DIR/bin/eval.sh"
if [[ ! -x "$EVAL_SCRIPT" ]]; then
    # Can't run eval — fail open
    echo '{"decision": "allow"}'
    exit 0
fi

EVAL_OUTPUT=$("$EVAL_SCRIPT" --no-llm --score 2>/dev/null || echo "")

# Parse current assertion pass count from eval output
# eval.sh --score outputs a number or JSON with pass count
CURRENT_PASS=0
if [[ -n "$EVAL_OUTPUT" ]]; then
    if command -v jq &>/dev/null; then
        CURRENT_PASS=$(echo "$EVAL_OUTPUT" | jq -r '.assertion_pass_count // .pass // 0' 2>/dev/null || echo "0")
    fi
    # Fallback: try to parse as plain number
    if [[ "$CURRENT_PASS" == "0" && "$EVAL_OUTPUT" =~ ^[0-9]+$ ]]; then
        CURRENT_PASS="$EVAL_OUTPUT"
    fi
fi

# --- Compare against baseline ---
if [[ "$CURRENT_PASS" =~ ^[0-9]+$ && "$BASELINE_PASS" =~ ^[0-9]+$ ]]; then
    if [[ "$CURRENT_PASS" -lt "$BASELINE_PASS" ]]; then
        REGRESSED=$((BASELINE_PASS - CURRENT_PASS))
        echo "{\"decision\": \"block\", \"reason\": \"Assertions regressed: ${CURRENT_PASS} passing (was ${BASELINE_PASS}, lost ${REGRESSED}). Revert or fix before completing task.\"}"
        exit 0
    fi
fi

# --- Assertions held or improved, or couldn't measure — allow ---
if [[ "$CURRENT_PASS" -gt "$BASELINE_PASS" && "$BASELINE_PASS" -gt 0 ]]; then
    GAINED=$((CURRENT_PASS - BASELINE_PASS))
    echo -e "${C_GREEN}✓${C_NC} assertions: ${CURRENT_PASS} passing ${C_DIM}(+${GAINED})${C_NC}" >&2
fi

echo '{"decision": "allow"}'
