#!/usr/bin/env bash
# session_end.sh — SessionEnd hook (non-blocking)
# Guaranteed session summary. More complete than stop.sh session logging.
# Writes to .claude/sessions/YYYY-MM-DD-HHMMSS.yml.
# Target: <200ms.

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(pwd)

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SE_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SE_SOURCE" ]]; do _SE_SOURCE="$(readlink "$_SE_SOURCE")"; done
    _SE_DIR="$(cd "$(dirname "$_SE_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_SE_DIR/.." && pwd)"
fi

# Colors
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_NC='\033[0m'

# --- Parse session metadata from input JSON ---
SESSION_DURATION=""
SESSION_TURNS=""
if command -v jq &>/dev/null; then
    SESSION_DURATION=$(echo "$INPUT" | jq -r '.duration_ms // empty' 2>/dev/null || true)
    SESSION_TURNS=$(echo "$INPUT" | jq -r '.turns // empty' 2>/dev/null || true)
fi

# --- Ensure sessions directory ---
SESSIONS_DIR="$PROJECT_DIR/.claude/sessions"
mkdir -p "$SESSIONS_DIR"

SESSION_FILE="$SESSIONS_DIR/$(date +%Y-%m-%d-%H%M%S).yml"
TODAY=$(date +%Y-%m-%d)

# --- Score delta: before (from git) vs after (from cache) ---
CACHE_FILE="$PROJECT_DIR/.claude/cache/score-cache.json"
SCORE_BEFORE=""
SCORE_AFTER=""

if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
    SCORE_AFTER=$(jq -r '.score // empty' "$CACHE_FILE" 2>/dev/null || true)
fi

# Previous score from git HEAD
PREV_CACHE=$(git -C "$PROJECT_DIR" show HEAD:"$CACHE_FILE" 2>/dev/null || true)
if [[ -n "$PREV_CACHE" ]] && command -v jq &>/dev/null; then
    SCORE_BEFORE=$(echo "$PREV_CACHE" | jq -r '.score // empty' 2>/dev/null || true)
fi

# --- Assertions delta ---
ASSERT_BEFORE=""
ASSERT_AFTER=""
if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
    ASSERT_AFTER=$(jq -r '.assertion_pass_count // empty' "$CACHE_FILE" 2>/dev/null || true)
    ASSERT_TOTAL=$(jq -r '.assertion_count // empty' "$CACHE_FILE" 2>/dev/null || true)
fi
if [[ -n "$PREV_CACHE" ]] && command -v jq &>/dev/null; then
    ASSERT_BEFORE=$(echo "$PREV_CACHE" | jq -r '.assertion_pass_count // empty' 2>/dev/null || true)
fi

# --- Ungraded predictions count ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
UNGRADED_COUNT=0
PREDICTIONS_TODAY=0
if [[ -f "$PRED_FILE" ]]; then
    UNGRADED_COUNT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { c++ } END { print c+0 }')
    PREDICTIONS_TODAY=$(grep -c "^${TODAY}" "$PRED_FILE" 2>/dev/null) || PREDICTIONS_TODAY=0
fi

# --- Commits this session (approximate: commits today) ---
COMMITS_TODAY=0
COMMITS_TODAY=$(git -C "$PROJECT_DIR" log --oneline --since="$TODAY" 2>/dev/null | wc -l | tr -d ' ') || COMMITS_TODAY=0

# --- Learnings from today's predictions ---
LEARNINGS=""
if [[ -f "$PRED_FILE" ]]; then
    while IFS=$'\t' read -r _d _a _p _e _r _c mu; do
        [[ "$_d" != "$TODAY" ]] && continue
        [[ -z "$mu" ]] && continue
        LEARNINGS="${LEARNINGS}\n  - \"${mu}\""
    done < <(tail -n +2 "$PRED_FILE")
fi

# --- Write session YAML ---
{
    echo "date: $TODAY"
    echo "time: $(date +%H:%M:%S)"
    [[ -n "$SESSION_DURATION" ]] && echo "duration_ms: $SESSION_DURATION"
    [[ -n "$SESSION_TURNS" ]] && echo "turns: $SESSION_TURNS"
    [[ -n "$SCORE_BEFORE" ]] && echo "score_before: $SCORE_BEFORE"
    [[ -n "$SCORE_AFTER" ]] && echo "score_after: $SCORE_AFTER"
    [[ -n "$ASSERT_BEFORE" ]] && echo "assertions_before: $ASSERT_BEFORE"
    [[ -n "$ASSERT_AFTER" && -n "$ASSERT_TOTAL" ]] && echo "assertions_after: ${ASSERT_AFTER}/${ASSERT_TOTAL}"
    echo "predictions_today: $PREDICTIONS_TODAY"
    echo "ungraded_predictions: $UNGRADED_COUNT"
    echo "commits: $COMMITS_TODAY"
    if [[ -n "$LEARNINGS" ]]; then
        echo "learnings:"
        printf "%b\n" "$LEARNINGS"
    fi
} > "$SESSION_FILE"

# --- Output summary ---
DELTA_DISPLAY=""
if [[ -n "$SCORE_BEFORE" && -n "$SCORE_AFTER" && "$SCORE_BEFORE" =~ ^[0-9]+$ && "$SCORE_AFTER" =~ ^[0-9]+$ ]]; then
    DELTA=$((SCORE_AFTER - SCORE_BEFORE))
    if [[ "$DELTA" -gt 0 ]]; then
        DELTA_DISPLAY="${C_GREEN}+${DELTA}${C_NC}"
    elif [[ "$DELTA" -lt 0 ]]; then
        DELTA_DISPLAY="${C_RED}${DELTA}${C_NC}"
    else
        DELTA_DISPLAY="${C_DIM}±0${C_NC}"
    fi
fi

# --- Vault sync (persist learnings to Obsidian) ---
if [[ -f "$FOUNDER_DIR/bin/vault-sync.sh" ]]; then
    bash "$FOUNDER_DIR/bin/vault-sync.sh" "$PROJECT_DIR" 2>/dev/null || true
fi

# --- Demand sync (persist demand data to Obsidian) ---
if [[ -f "$FOUNDER_DIR/bin/demand-sync.sh" ]]; then
    bash "$FOUNDER_DIR/bin/demand-sync.sh" "$PROJECT_DIR" 2>/dev/null || true
fi

echo -e "${C_DIM}session logged${C_NC} ${C_DIM}·${C_NC} commits: ${COMMITS_TODAY}${DELTA_DISPLAY:+  ${C_DIM}·${C_NC}  score: ${DELTA_DISPLAY}}${UNGRADED_COUNT:+  ${C_DIM}·${C_NC}  ${UNGRADED_COUNT} ungraded predictions}"
