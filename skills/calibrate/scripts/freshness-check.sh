#!/usr/bin/env bash
# freshness-check.sh — Reports age and status of all calibration artifacts.
# Zero context cost: runs at skill load to show calibration state.
# Usage: bash scripts/freshness-check.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
NOW_EPOCH=$(date +%s)

# Artifact definitions: name | path | max_age_days
ARTIFACTS=(
  "founder-profile|$HOME/.claude/knowledge/founder-taste.md|30"
  "design-system|$PROJECT_DIR/.claude/design-system.md|7"
  "anti-slop|$PROJECT_DIR/.claude/cache/anti-slop.md|14"
  "taste-market|$PROJECT_DIR/.claude/cache/taste-market.json|14"
  "market-snapshot|$PROJECT_DIR/.claude/cache/market-snapshot.md|14"
  "calibration-history|$PROJECT_DIR/.claude/cache/calibration-history.json|999"
)

echo "── calibration freshness ──"

FRESH=0
STALE=0
MISSING=0
TOTAL=${#ARTIFACTS[@]}

for entry in "${ARTIFACTS[@]}"; do
    IFS='|' read -r name path max_days <<< "$entry"

    if [[ ! -f "$path" ]]; then
        printf "  %-22s · missing\n" "$name"
        MISSING=$((MISSING + 1))
        continue
    fi

    # Get file age in days
    MOD_EPOCH=$(stat -f "%m" "$path" 2>/dev/null || stat -c "%Y" "$path" 2>/dev/null)
    AGE_DAYS=$(( (NOW_EPOCH - MOD_EPOCH) / 86400 ))

    # Get file size for quality signal
    SIZE=$(wc -c < "$path" | tr -d ' ')
    if [[ "$SIZE" -lt 50 ]]; then
        printf "  %-22s · empty (%s bytes)\n" "$name" "$SIZE"
        MISSING=$((MISSING + 1))
        continue
    fi

    if [[ "$AGE_DAYS" -gt "$max_days" ]]; then
        printf "  %-22s ▸ stale (%dd old, max %dd)\n" "$name" "$AGE_DAYS" "$max_days"
        STALE=$((STALE + 1))
    else
        printf "  %-22s ✓ fresh (%dd)\n" "$name" "$AGE_DAYS"
        FRESH=$((FRESH + 1))
    fi
done

echo ""
if [[ "$MISSING" -gt 0 || "$STALE" -gt 0 ]]; then
    echo "  $FRESH fresh · $STALE stale · $MISSING missing (of $TOTAL)"
    if [[ "$MISSING" -gt 2 ]]; then
        echo "  run: /calibrate (full calibration)"
    elif [[ "$STALE" -gt 0 ]]; then
        echo "  run: /calibrate refresh"
    fi
else
    echo "  all $TOTAL artifacts fresh"
fi
