#!/usr/bin/env bash
# Show rubric status for all features — which have rubrics, which don't
# Usage: bash scripts/rubric-status.sh
# Cross-references founder.yml features against .claude/cache/rubrics/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUBRIC_DIR="$PROJECT_DIR/.claude/cache/rubrics"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

echo "── rubric status ──"

# Collect feature names from founder.yml
FEATURES=()
if [[ -f "$FOUNDER_YML" ]]; then
    # Extract feature names (lines that start a feature block under features:)
    while IFS= read -r line; do
        name=$(echo "$line" | sed 's/:.*//' | xargs)
        [[ -n "$name" ]] && FEATURES+=("$name")
    done < <(grep -E '^\s{2}\w' "$FOUNDER_YML" | grep -v '^\s*#' | grep -v '^\s*-' | head -30 2>/dev/null || true)
fi

if [[ ${#FEATURES[@]} -eq 0 ]]; then
    echo "  no features found in config/founder.yml"
    exit 0
fi

ANCHORED=0
UNANCHORED=0
STALE=0
NOW=$(date +%s)
STALE_DAYS=14

for feature in "${FEATURES[@]}"; do
    RUBRIC="$RUBRIC_DIR/$feature.json"
    if [[ -f "$RUBRIC" ]] && command -v jq &>/dev/null; then
        SCORE=$(jq -r '.last_score // "?"' "$RUBRIC" 2>/dev/null)
        DATE=$(jq -r '.last_scored // "?"' "$RUBRIC" 2>/dev/null)
        DATE_SHORT=$(echo "$DATE" | cut -d'T' -f1)
        GAPS=$(jq -r '.known_gaps | length' "$RUBRIC" 2>/dev/null || echo 0)
        CRITERIA=$(jq -r '[.delivery_criteria, .craft_criteria, .viability_criteria] | map(length) | add' "$RUBRIC" 2>/dev/null || echo 0)
        HISTORY=$(jq -r '.score_history | length' "$RUBRIC" 2>/dev/null || echo 0)

        # Check staleness
        if [[ "$DATE" != "?" ]]; then
            SCORED_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${DATE%%.*}" +%s 2>/dev/null || echo 0)
            DAYS_AGO=$(( (NOW - SCORED_TS) / 86400 ))
            if [[ "$DAYS_AGO" -gt "$STALE_DAYS" ]]; then
                echo "  $feature: $SCORE/100 (scored $DATE_SHORT, STALE ${DAYS_AGO}d) $CRITERIA criteria, $GAPS gaps, $HISTORY evals"
                STALE=$((STALE + 1))
            else
                echo "  $feature: $SCORE/100 (scored $DATE_SHORT) $CRITERIA criteria, $GAPS gaps, $HISTORY evals"
            fi
        else
            echo "  $feature: $SCORE/100 (date unknown) $CRITERIA criteria, $GAPS gaps"
        fi
        ANCHORED=$((ANCHORED + 1))
    else
        echo "  $feature: NO RUBRIC — first eval will be unanchored"
        UNANCHORED=$((UNANCHORED + 1))
    fi
done

echo ""
echo "  total: ${#FEATURES[@]} features, $ANCHORED anchored, $UNANCHORED unanchored, $STALE stale"
if [[ "$UNANCHORED" -gt 0 ]]; then
    echo "  warning: unanchored features have no variance protection"
fi
if [[ "$STALE" -gt 0 ]]; then
    echo "  warning: stale rubrics may not reflect current code"
fi
