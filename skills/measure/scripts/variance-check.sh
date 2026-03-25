#!/usr/bin/env bash
# Check if proposed score has dangerous variance from rubric/cache
# Usage: bash scripts/variance-check.sh <feature> <proposed_score>
# Exit 0 = ok, Exit 1 = variance warning (investigate before publishing)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEATURE="${1:?usage: variance-check.sh <feature> <proposed_score>}"
PROPOSED="${2:?usage: variance-check.sh <feature> <proposed_score>}"

RUBRIC="$PROJECT_DIR/.claude/cache/rubrics/$FEATURE.json"
CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"

# Try rubric first (most reliable anchor)
if [[ -f "$RUBRIC" ]] && command -v jq &>/dev/null; then
    LAST_SCORE=$(jq -r '.last_score // 0' "$RUBRIC" 2>/dev/null)
    DELTA=$((PROPOSED - LAST_SCORE))
    ABS_DELTA=${DELTA#-}

    if [[ "$ABS_DELTA" -gt 15 ]]; then
        echo "VARIANCE: proposed $PROPOSED vs rubric $LAST_SCORE (delta: ${DELTA})"
        echo "  investigate before publishing — same code should get same score"
        echo "  check: has the code changed enough to justify ${ABS_DELTA}pt swing?"

        # Show score history if available
        HISTORY=$(jq -r '.score_history // [] | join(", ")' "$RUBRIC" 2>/dev/null)
        if [[ -n "$HISTORY" ]]; then
            echo "  history: [$HISTORY]"
        fi
        exit 1
    else
        echo "ok: proposed $PROPOSED vs rubric $LAST_SCORE (delta: ${DELTA})"
        exit 0
    fi
fi

# Fall back to eval-cache
if [[ -f "$CACHE" ]] && command -v jq &>/dev/null; then
    CACHED_SCORE=$(jq -r --arg f "$FEATURE" '.[$f].score // 0' "$CACHE" 2>/dev/null)
    if [[ "$CACHED_SCORE" != "0" && "$CACHED_SCORE" != "null" ]]; then
        DELTA=$((PROPOSED - CACHED_SCORE))
        ABS_DELTA=${DELTA#-}

        if [[ "$ABS_DELTA" -gt 15 ]]; then
            echo "VARIANCE: proposed $PROPOSED vs cached $CACHED_SCORE (delta: ${DELTA})"
            echo "  no rubric found — using eval-cache as anchor"
            echo "  investigate before publishing"
            exit 1
        else
            echo "ok: proposed $PROPOSED vs cached $CACHED_SCORE (delta: ${DELTA})"
            exit 0
        fi
    fi
fi

echo "no anchor: first score for $FEATURE — no variance check needed"
exit 0
