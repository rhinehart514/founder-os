#!/usr/bin/env bash
# work-impact.sh — Shows which recent work actually moved scores.
# Reads git log + eval-cache to compute work-to-impact ratio.
# Usage: bash scripts/work-impact.sh [project-dir] [days]
set -euo pipefail

PROJECT_DIR="${1:-.}"
DAYS="${2:-7}"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
HISTORY="$PROJECT_DIR/.claude/scores/history.tsv"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"

echo "── work-impact (last ${DAYS}d) ──"

# --- Date calculation (macOS + Linux) ---
SINCE=$(date -v-${DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")

# --- Commit volume ---
COMMITS=0
if [[ -n "$SINCE" ]]; then
    COMMITS=$(git -C "$PROJECT_DIR" log --oneline --since="$SINCE" 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  commits: $COMMITS (since $SINCE)"

# --- Commits per day ---
if [[ "$COMMITS" -gt 0 && "$DAYS" -gt 0 ]]; then
    CPD=$(python3 -c "print(f'{$COMMITS/$DAYS:.1f}')" 2>/dev/null || echo "?")
    echo "  commits/day: $CPD"
    if [[ "$COMMITS" -gt $((DAYS * 15)) ]]; then
        echo "  ! burnout signal: >15 commits/day sustained"
    fi
fi

# --- Score delta from history ---
if [[ -f "$HISTORY" ]] && [[ -n "$SINCE" ]]; then
    FIRST_SCORE=$(awk -F'\t' -v d="$SINCE" '$1 >= d {print $5; exit}' "$HISTORY" 2>/dev/null || echo "")
    LAST_SCORE=$(tail -1 "$HISTORY" | cut -f5 2>/dev/null || echo "")
    if [[ -n "$FIRST_SCORE" && -n "$LAST_SCORE" && "$FIRST_SCORE" =~ ^[0-9]+$ && "$LAST_SCORE" =~ ^[0-9]+$ ]]; then
        DELTA=$((LAST_SCORE - FIRST_SCORE))
        echo "  score: $FIRST_SCORE -> $LAST_SCORE (delta: $DELTA)"
        if [[ "$COMMITS" -gt 0 ]]; then
            PTS_PER_COMMIT=$(python3 -c "print(f'{$DELTA/$COMMITS:.2f}')" 2>/dev/null || echo "?")
            echo "  pts/commit: $PTS_PER_COMMIT"
        fi
        if [[ "$COMMITS" -gt 10 && "$DELTA" -lt 3 ]]; then
            echo "  ! high effort, low impact: $COMMITS commits for $DELTA pts"
        fi
        if [[ "$DELTA" -gt 15 ]]; then
            echo "  ! suspicious jump: $DELTA pts in $DAYS days — verify not cosmetic"
        fi
    else
        echo "  score: no history data for this period"
    fi
else
    echo "  score: no history file"
fi

# --- Per-feature deltas from eval-cache ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo ""
    echo "  ── feature deltas ──"
    # Features with positive delta
    MOVERS=$(jq -r 'to_entries[] | select(.value.delta != null and .value.delta != "same" and .value.delta != "none" and .value.delta != "new") | "\(.key): \(.value.score) (delta: \(.value.delta))"' "$EVAL_CACHE" 2>/dev/null)
    STALE=$(jq -r 'to_entries[] | select(.value.delta == "same" or .value.delta == null) | select(.value.score != null) | "\(.key): \(.value.score) (no movement)"' "$EVAL_CACHE" 2>/dev/null)

    if [[ -n "$MOVERS" ]]; then
        echo "  moved:"
        echo "$MOVERS" | while read -r line; do echo "    $line"; done
    fi
    if [[ -n "$STALE" ]]; then
        echo "  stale:"
        echo "$STALE" | while read -r line; do echo "    $line"; done
    fi
    if [[ -z "$MOVERS" && -z "$STALE" ]]; then
        echo "    (no feature-level delta data)"
    fi
fi

# --- What was actually worked on (commit message clustering) ---
echo ""
echo "  ── work clusters ──"
if [[ -n "$SINCE" ]]; then
    # Group by first word after conventional commit prefix
    git -C "$PROJECT_DIR" log --oneline --since="$SINCE" 2>/dev/null | \
        sed 's/^[a-f0-9]* //' | \
        sed 's/^feat: /feat /; s/^fix: /fix /; s/^refactor: /refactor /; s/^chore: /chore /' | \
        cut -d' ' -f1 | sort | uniq -c | sort -rn | head -5 | \
        while read -r count word; do
            echo "    $word: $count commits"
        done
fi

# --- Prediction health ---
if [[ -f "$PRED_FILE" ]]; then
    echo ""
    echo "  ── prediction health ──"
    TOTAL_PRED=$(tail -n +2 "$PRED_FILE" 2>/dev/null | wc -l | tr -d ' ')
    RECENT_PRED=0
    if [[ -n "$SINCE" ]]; then
        RECENT_PRED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$SINCE" '$1 >= d' 2>/dev/null | wc -l | tr -d ' ')
    fi
    UNGRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" || $6 == "ungraded"' 2>/dev/null | wc -l | tr -d ' ')
    echo "    total: $TOTAL_PRED, recent (${DAYS}d): $RECENT_PRED, ungraded: $UNGRADED"
    if [[ "$RECENT_PRED" -lt 3 ]]; then
        echo "    ! prediction starvation: <3 predictions in ${DAYS} days"
    fi
fi

echo ""
echo "── work-impact complete ──"
