#!/usr/bin/env bash
# calibration-check.sh — Checks taste calibration state.
# Reports: founder profile, design system, dimension knowledge, staleness.
# Usage: bash scripts/calibration-check.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
FOUNDER_TASTE="$HOME/.claude/knowledge/founder-taste.md"
DESIGN_SYSTEM="$PROJECT_DIR/.claude/design-system.md"
DIM_KNOWLEDGE="$PROJECT_DIR/lens/product/eval/knowledge"
CAL_HISTORY="$PROJECT_DIR/.claude/cache/calibration-history.json"
TASTE_HISTORY="$PROJECT_DIR/.claude/evals/taste-history.tsv"

DIMS=(hierarchy breathing_room contrast polish emotional_tone information_density wayfinding distinctiveness scroll_experience layout_coherence information_architecture)

echo "── calibration state ──"

# --- Founder taste profile ---
echo ""
echo "  ▸ founder profile"
if [[ -f "$FOUNDER_TASTE" ]]; then
    MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$FOUNDER_TASTE" 2>/dev/null || stat -c "%y" "$FOUNDER_TASTE" 2>/dev/null | cut -d' ' -f1)
    echo "    status: exists"
    echo "    path: $FOUNDER_TASTE"
    echo "    modified: $MOD_DATE"

    # Check staleness (30 days)
    MOD_EPOCH=$(stat -f "%m" "$FOUNDER_TASTE" 2>/dev/null || stat -c "%Y" "$FOUNDER_TASTE" 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    AGE_DAYS=$(( (NOW_EPOCH - MOD_EPOCH) / 86400 ))
    if [[ $AGE_DAYS -gt 30 ]]; then
        echo "    WARNING: $AGE_DAYS days old — consider /taste calibrate profile"
    else
        echo "    age: ${AGE_DAYS}d (fresh)"
    fi
else
    echo "    status: missing"
    echo "    action: run /taste calibrate profile"
fi

# --- Design system ---
echo ""
echo "  ▸ design system"
if [[ -f "$DESIGN_SYSTEM" ]]; then
    MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$DESIGN_SYSTEM" 2>/dev/null || stat -c "%y" "$DESIGN_SYSTEM" 2>/dev/null | cut -d' ' -f1)
    LINES=$(wc -l < "$DESIGN_SYSTEM" | tr -d ' ')
    echo "    status: exists ($LINES lines)"
    echo "    path: $DESIGN_SYSTEM"
    echo "    modified: $MOD_DATE"

    # Quick content check
    TOKENS=0; COMPONENTS=0; RULES=0
    [[ -n "$(grep -i 'color\|spacing\|radius\|shadow\|typography' "$DESIGN_SYSTEM" 2>/dev/null)" ]] && TOKENS=1
    [[ -n "$(grep -i 'card\|button\|input\|nav' "$DESIGN_SYSTEM" 2>/dev/null)" ]] && COMPONENTS=1
    [[ -n "$(grep -i 'rule\|anti-\|never\|avoid' "$DESIGN_SYSTEM" 2>/dev/null)" ]] && RULES=1
    echo "    sections: tokens=$([[ $TOKENS -eq 1 ]] && echo "yes" || echo "no") components=$([[ $COMPONENTS -eq 1 ]] && echo "yes" || echo "no") rules=$([[ $RULES -eq 1 ]] && echo "yes" || echo "no")"
else
    echo "    status: missing"
    echo "    action: run /taste calibrate design-system"
fi

# --- Dimension knowledge ---
echo ""
echo "  ▸ dimension knowledge"
CALIBRATED=0
UNCALIBRATED=0
for dim in "${DIMS[@]}"; do
    if [[ -f "$DIM_KNOWLEDGE/$dim.md" ]]; then
        printf "    %-28s ✓ calibrated\n" "$dim"
        CALIBRATED=$((CALIBRATED + 1))
    else
        printf "    %-28s · uncalibrated\n" "$dim"
        UNCALIBRATED=$((UNCALIBRATED + 1))
    fi
done
echo ""
echo "    calibrated: $CALIBRATED/11"
if [[ $UNCALIBRATED -gt 0 ]]; then
    echo "    action: run /taste calibrate to research remaining dimensions"
fi

# --- Calibration history ---
echo ""
echo "  ▸ calibration history"
if [[ -f "$CAL_HISTORY" ]] && command -v jq &>/dev/null; then
    CAL_COUNT=$(jq '.calibrations | length' "$CAL_HISTORY" 2>/dev/null || echo 0)
    LAST_CAL=$(jq -r '.calibrations[-1].date // "unknown"' "$CAL_HISTORY" 2>/dev/null || echo "unknown")
    echo "    calibrations: $CAL_COUNT"
    echo "    last: $LAST_CAL"
else
    echo "    no calibration history"
fi

# --- Taste eval count ---
echo ""
echo "  ▸ eval data"
if [[ -f "$TASTE_HISTORY" ]]; then
    EVAL_COUNT=$(tail -n +2 "$TASTE_HISTORY" | wc -l | tr -d ' ')
    echo "    evaluations: $EVAL_COUNT"
    if [[ "$EVAL_COUNT" -gt 0 ]]; then
        LAST_DATE=$(tail -1 "$TASTE_HISTORY" | cut -f1)
        echo "    last eval: $LAST_DATE"
    fi
else
    echo "    no evaluations yet"
fi

# --- Summary ---
echo ""
echo "── readiness ──"
READY=0
TOTAL=3
[[ -f "$FOUNDER_TASTE" ]] && READY=$((READY + 1))
[[ -f "$DESIGN_SYSTEM" ]] && READY=$((READY + 1))
[[ $CALIBRATED -gt 0 ]] && READY=$((READY + 1))

if [[ $READY -eq $TOTAL ]]; then
    echo "  calibrated ($READY/$TOTAL) — evals will use founder profile + design system + dimension knowledge"
elif [[ $READY -gt 0 ]]; then
    echo "  partially calibrated ($READY/$TOTAL) — run /taste calibrate for full calibration"
else
    echo "  uncalibrated (0/$TOTAL) — evals will use default anchors only"
    echo "  run: /taste calibrate"
fi
