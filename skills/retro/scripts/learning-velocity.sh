#!/usr/bin/env bash
# Learning velocity — tracks learning rate over time
# Usage: bash scripts/learning-velocity.sh
# Output: patterns added/updated per week, accuracy trend, model freshness
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"

echo "── learning velocity ──"

# 1. Model update frequency (commits touching experiment-learnings.md)
echo ""
echo "  ── model updates ──"
if [[ -f "$LEARNINGS" ]]; then
    # Count commits per week (last 4 weeks)
    for WEEKS_AGO in 0 1 2 3; do
        SINCE_DATE=$(date -v-$((WEEKS_AGO + 1))w +%Y-%m-%d 2>/dev/null || date -d "$((WEEKS_AGO + 1)) weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
        UNTIL_DATE=$(date -v-${WEEKS_AGO}w +%Y-%m-%d 2>/dev/null || date -d "$WEEKS_AGO weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
        if [[ -n "$SINCE_DATE" && -n "$UNTIL_DATE" ]]; then
            COUNT=$(git log --oneline --since="$SINCE_DATE" --until="$UNTIL_DATE" -- "$LEARNINGS" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$WEEKS_AGO" -eq 0 ]]; then
                LABEL="this week"
            else
                LABEL="${WEEKS_AGO}w ago"
            fi
            echo "  $LABEL: $COUNT updates"
        fi
    done

    # Last update date
    LAST_UPDATE=$(git log -1 --format="%ai" -- "$LEARNINGS" 2>/dev/null | cut -d' ' -f1)
    if [[ -n "$LAST_UPDATE" ]]; then
        echo "  last update: $LAST_UPDATE"
    fi
else
    echo "  no experiment-learnings.md"
fi

# 2. Prediction frequency trend
echo ""
echo "  ── prediction frequency ──"
if [[ -f "$PRED_FILE" ]]; then
    for WEEKS_AGO in 0 1 2 3; do
        SINCE_DATE=$(date -v-$((WEEKS_AGO + 1))w +%Y-%m-%d 2>/dev/null || date -d "$((WEEKS_AGO + 1)) weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
        UNTIL_DATE=$(date -v-${WEEKS_AGO}w +%Y-%m-%d 2>/dev/null || date -d "$WEEKS_AGO weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
        if [[ -n "$SINCE_DATE" && -n "$UNTIL_DATE" ]]; then
            COUNT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v s="$SINCE_DATE" -v u="$UNTIL_DATE" '$1 >= s && $1 < u { c++ } END { print c+0 }')
            if [[ "$WEEKS_AGO" -eq 0 ]]; then
                LABEL="this week"
            else
                LABEL="${WEEKS_AGO}w ago"
            fi
            echo "  $LABEL: $COUNT predictions"
        fi
    done
else
    echo "  no predictions.tsv"
fi

# 3. Accuracy trend (rolling 5-prediction windows)
echo ""
echo "  ── accuracy trend ──"
if [[ -f "$PRED_FILE" ]]; then
    tail -n +2 "$PRED_FILE" | awk -F'\t' '
    $6 != "" {
        n++
        if ($6 == "yes") score[n] = 1
        else if ($6 == "partial") score[n] = 0.5
        else score[n] = 0
        dates[n] = $1
    }
    END {
        if (n < 5) {
            printf "  insufficient data (%d graded, need 5+)\n", n
            exit
        }
        # Show rolling windows of 5
        windows = 0
        for (i = 5; i <= n; i++) {
            sum = 0
            for (j = i-4; j <= i; j++) sum += score[j]
            acc = int(sum / 5 * 100)
            windows++
            if (windows <= 5) {
                printf "  window %d-%d: %d%%\n", i-4, i, acc
            }
        }
        # Trend direction
        if (n >= 10) {
            early_sum = 0; late_sum = 0
            half = int(n/2)
            for (i = 1; i <= half; i++) early_sum += score[i]
            for (i = half+1; i <= n; i++) late_sum += score[i]
            early_acc = early_sum / half * 100
            late_acc = late_sum / (n - half) * 100
            diff = late_acc - early_acc
            if (diff > 10) trend = "improving"
            else if (diff < -10) trend = "declining"
            else trend = "stable"
            printf "  trend: %s (early %.0f%% → late %.0f%%)\n", trend, early_acc, late_acc
        }
    }' 2>/dev/null || echo "  (no accuracy data)"
fi

# 4. Model freshness summary
echo ""
echo "  ── freshness ──"
if [[ -f "$LEARNINGS" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        AGE=$(( ($(date +%s) - $(stat -f %m "$LEARNINGS")) / 86400 ))
    else
        AGE=$(( ($(date +%s) - $(stat -c %Y "$LEARNINGS")) / 86400 ))
    fi
    if [[ "$AGE" -le 3 ]]; then
        echo "  model: fresh ($AGE days old)"
    elif [[ "$AGE" -le 7 ]]; then
        echo "  model: aging ($AGE days) — consider a retro"
    else
        echo "  model: stale ($AGE days) ⚠ needs attention"
    fi
fi
