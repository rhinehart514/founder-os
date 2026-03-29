#!/usr/bin/env bash
# Prediction statistics for /retro
# Usage: bash scripts/prediction-stats.sh
# Output: accuracy, domain breakdown, calibration, recent wrong predictions
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"

echo "── prediction stats ──"
if [[ ! -f "$PRED_FILE" ]]; then
    echo "  no predictions.tsv"
    exit 0
fi

TOTAL=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
UNGRADED=$((TOTAL - GRADED))
CORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
PARTIAL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
WRONG=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" { c++ } END { print c+0 }')

echo "  total: $TOTAL"
echo "  graded: $GRADED (ungraded: $UNGRADED)"
echo "  correct: $CORRECT · partial: $PARTIAL · wrong: $WRONG"

# Accuracy + calibration
if [[ "$GRADED" -gt 0 ]]; then
    EFFECTIVE=$(echo "$CORRECT $PARTIAL $GRADED" | awk '{printf "%.0f", ($1 + $2 * 0.5) / $3 * 100}' 2>/dev/null || echo "?")
    echo "  accuracy: ${EFFECTIVE}%"
    if [[ "$EFFECTIVE" != "?" ]]; then
        ACC=${EFFECTIVE%.*}
        if [[ "$ACC" -gt 70 ]]; then
            echo "  ⚠ too safe — predictions need to be bolder"
        elif [[ "$ACC" -lt 50 ]]; then
            echo "  ⚠ model needs work — review prediction quality"
        else
            echo "  ✓ well-calibrated (50-70% range)"
        fi
    fi
fi

# Domain breakdown: extract domain keywords from prediction text
echo ""
echo "  ── by domain ──"
tail -n +2 "$PRED_FILE" | awk -F'\t' '
$6 != "" {
    pred = tolower($3)
    grade = $6
    # Extract domain from prediction text
    domain = "other"
    if (pred ~ /score|scoring|health/) domain = "score"
    else if (pred ~ /craft|taste|visual|design|ui|ux/) domain = "craft"
    else if (pred ~ /delivery|feature|value/) domain = "delivery"
    else if (pred ~ /assert|belief|eval/) domain = "eval"
    else if (pred ~ /command|skill|cli/) domain = "commands"
    else if (pred ~ /learn|predict|model|retro|knowledge/) domain = "learning"
    else if (pred ~ /doc|readme|onboard/) domain = "docs"
    else if (pred ~ /approach|architecture|refactor/) domain = "approach"

    total[domain]++
    if (grade == "yes") correct[domain]++
    else if (grade == "partial") correct[domain] += 0.5
}
END {
    for (d in total) {
        acc = (total[d] > 0) ? int(correct[d] / total[d] * 100) : 0
        flag = ""
        if (total[d] >= 3 && acc < 40) flag = " ⚠ overconfident"
        if (total[d] < 3) flag = " (insufficient data)"
        printf "  %-12s %3d%% (%d graded)%s\n", d, acc, total[d], flag
    }
}' | sort -t'%' -k1 -rn 2>/dev/null || echo "  (no domain data)"

# Recent wrong predictions (highest learning value)
echo ""
echo "  ── recent wrong ──"
tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" { print "  ✗ "$1" · "$3 }' | tail -5
WRONG_COUNT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" { c++ } END { print c+0 }')
if [[ "$WRONG_COUNT" -eq 0 ]]; then
    echo "  (none — either well-calibrated or not enough predictions)"
fi

# Oldest ungraded
echo ""
echo "  ── ungraded backlog ──"
if [[ "$UNGRADED" -gt 0 ]]; then
    OLDEST=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { print $1; exit }')
    echo "  $UNGRADED ungraded (oldest: $OLDEST)"
    tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { print "  · "$1" · "$3 }' | head -5
else
    echo "  all caught up"
fi
