#!/usr/bin/env bash
# plateau-check.sh — Detect N consecutive flat moves.
# Usage: bash scripts/plateau-check.sh [project-dir] [threshold] [--verbose]
# Exit 0 = no plateau, Exit 1 = plateau detected
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
THRESHOLD="${2:-3}"
VERBOSE=false
[[ "${3:-}" == "--verbose" ]] && VERBOSE=true

HISTORY="$PROJECT_DIR/.claude/scores/history.tsv"

# Also check build-log for session-level plateau
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/data/go}"
BUILD_LOG="$DATA_DIR/build-sessions.jsonl"

echo "=== PLATEAU CHECK (threshold: $THRESHOLD flat moves) ==="

# --- Score history plateau ---
if [[ -f "$HISTORY" ]]; then
    SCORES=$(tail -n "$((THRESHOLD + 1))" "$HISTORY" | awk -F'\t' '{print $5}' | grep -E '^[0-9]+$')
    COUNT=$(echo "$SCORES" | wc -l | tr -d ' ')

    if [[ "$COUNT" -lt "$((THRESHOLD + 1))" ]]; then
        echo "score history: not enough data ($COUNT scores, need $((THRESHOLD + 1)))"
    else
        PREV=""
        FLAT_COUNT=0
        DELTAS=""
        while IFS= read -r score; do
            if [[ -n "$PREV" ]]; then
                DELTA=$((score - PREV))
                ABS_DELTA=${DELTA#-}
                DELTAS="$DELTAS $DELTA"
                if [[ "$ABS_DELTA" -lt 2 ]]; then
                    FLAT_COUNT=$((FLAT_COUNT + 1))
                fi
            fi
            PREV="$score"
        done <<< "$SCORES"

        if [[ "$FLAT_COUNT" -ge "$THRESHOLD" ]]; then
            echo "SCORE PLATEAU: $FLAT_COUNT consecutive flat moves (delta <2)"
            $VERBOSE && echo "  deltas:$DELTAS"
            echo "  action: STOP building. Current approach is exhausted."
            echo "  try: /ideate [feature], research Unknown Territory, or change approach entirely"
        else
            echo "score history: no plateau ($FLAT_COUNT/$THRESHOLD flat)"
            $VERBOSE && echo "  recent deltas:$DELTAS"
        fi
    fi
else
    echo "score history: no history.tsv found"
fi

# --- Session-level plateau (from build-log) ---
if [[ -f "$BUILD_LOG" ]] && command -v jq &>/dev/null; then
    RECENT=$(tail -n "$THRESHOLD" "$BUILD_LOG" 2>/dev/null)
    SESSION_CT=$(echo "$RECENT" | wc -l | tr -d ' ')

    if [[ "$SESSION_CT" -ge "$THRESHOLD" ]]; then
        # Count sessions with zero or negative score delta
        # Avoid subshell scope bug: use process substitution instead of pipe
        ZERO_DELTA=0
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            D=$(echo "$line" | jq -r '(.score_after // 0) - (.score_before // 0)' 2>/dev/null || echo "0")
            [[ "$D" -le 0 ]] && ZERO_DELTA=$((ZERO_DELTA + 1))
        done <<< "$RECENT"
        if [[ "$ZERO_DELTA" -ge "$THRESHOLD" ]]; then
            echo ""
            echo "SESSION PLATEAU: $THRESHOLD consecutive sessions with no score improvement"
            echo "  action: rethink at a higher level — /strategy or /ideate, not more building"
        fi
    fi
fi

echo ""

# Final exit code
if [[ "${FLAT_COUNT:-0}" -ge "$THRESHOLD" ]]; then
    exit 1
else
    exit 0
fi
