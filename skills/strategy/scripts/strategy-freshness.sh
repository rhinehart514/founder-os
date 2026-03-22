#!/usr/bin/env bash
# strategy-freshness.sh — Checks strategy.yml age, flags staleness, shows what changed since last strategy.
# Usage: bash scripts/strategy-freshness.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
STRATEGY_YML="$PROJECT_DIR/.claude/plans/strategy.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"

echo "── strategy freshness ──"

# --- Strategy.yml existence and age ---
if [[ ! -f "$STRATEGY_YML" ]]; then
    echo "  ! no strategy.yml — this is the first strategy session"
    echo "  action: will create from scratch"
    echo ""
    echo "── strategy freshness complete ──"
    exit 0
fi

echo "  file: $STRATEGY_YML"

# File modification time
if [[ "$(uname)" == "Darwin" ]]; then
    LAST_MOD=$(stat -f '%Sm' -t '%Y-%m-%d' "$STRATEGY_YML" 2>/dev/null || echo "unknown")
else
    LAST_MOD=$(stat -c '%y' "$STRATEGY_YML" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
fi
echo "  last modified: $LAST_MOD"

# Age in days
if command -v python3 &>/dev/null && [[ "$LAST_MOD" != "unknown" ]]; then
    DAYS_OLD=$(python3 -c "
from datetime import datetime
try:
    d = datetime.strptime('$LAST_MOD', '%Y-%m-%d')
    print((datetime.now() - d).days)
except:
    print(-1)
" 2>/dev/null || echo "-1")
    if [[ "$DAYS_OLD" -gt 3 ]]; then
        echo "  ! stale: $DAYS_OLD days old (threshold: 3 days)"
    elif [[ "$DAYS_OLD" -ge 0 ]]; then
        echo "  fresh: $DAYS_OLD days old"
    fi
fi

# --- Previous diagnosis summary ---
echo ""
echo "  ── previous diagnosis ──"
PREV_STAGE=$(grep -m1 'stage:' "$STRATEGY_YML" 2>/dev/null | sed 's/.*stage: *//' | sed 's/#.*//' | tr -d ' "' || echo "unknown")
PREV_BOTTLENECK=$(grep -m1 'bottleneck:' "$STRATEGY_YML" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/#.*//' || echo "unknown")
echo "    stage: $PREV_STAGE"
echo "    bottleneck: $PREV_BOTTLENECK"

# --- What changed since last strategy ---
echo ""
echo "  ── changes since last strategy ──"

# Commits since last strategy
if [[ "$LAST_MOD" != "unknown" ]]; then
    COMMITS_SINCE=$(git -C "$PROJECT_DIR" log --oneline --since="$LAST_MOD" 2>/dev/null | wc -l | tr -d ' ')
    echo "    commits: $COMMITS_SINCE"

    if [[ "$COMMITS_SINCE" -gt 0 ]]; then
        echo "    recent:"
        git -C "$PROJECT_DIR" log --oneline --since="$LAST_MOD" 2>/dev/null | head -10 | while read -r line; do
            echo "      $line"
        done
    fi
fi

# Eval score changes
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo ""
    echo "    feature scores:"
    jq -r 'to_entries[] | select(.value.score != null) | "      \(.key): \(.value.score) (delta: \(.value.delta // "none"))"' "$EVAL_CACHE" 2>/dev/null
fi

# New predictions since last strategy
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]] && [[ "$LAST_MOD" != "unknown" ]]; then
    NEW_PREDS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$LAST_MOD" '$1 >= d' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$NEW_PREDS" -gt 0 ]]; then
        echo ""
        echo "    new predictions: $NEW_PREDS"
        tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$LAST_MOD" '$1 >= d {print "      " $2 " [" $6 "]"}' 2>/dev/null | head -5
    fi
fi

# Todo changes
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS" ]]; then
    ACTIVE_TODOS=$(grep -c 'status: active\|status: open' "$TODOS" 2>/dev/null || echo 0)
    DONE_TODOS=$(grep -c 'status: done\|status: closed' "$TODOS" 2>/dev/null || echo 0)
    echo ""
    echo "    todos: $ACTIVE_TODOS active, $DONE_TODOS done"
fi

echo ""
echo "── strategy freshness complete ──"
