#!/usr/bin/env bash
# todo-stats.sh — Backlog health: counts by status, age distribution, feature clustering, stale items.
# Outputs structured text. Run on every /todo show and /todo health.
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"

echo "── todo stats ──"

if [[ ! -f "$TODOS" ]]; then
    echo "  no todos.yml — backlog is empty"
    exit 0
fi

# --- Counts by status ---
TOTAL=$(grep -c '^\s*- title:' "$TODOS" || true)
ACTIVE=$(grep -c 'status: active' "$TODOS" || true)
BACKLOG=$(grep -c 'status: backlog' "$TODOS" || true)
DONE=$(grep -c 'status: done' "$TODOS" || true)
TOTAL=${TOTAL:-0}; ACTIVE=${ACTIVE:-0}; BACKLOG=${BACKLOG:-0}; DONE=${DONE:-0}
OPEN=$((ACTIVE + BACKLOG))

echo "  total: $TOTAL · active: $ACTIVE · backlog: $BACKLOG · done: $DONE"
if [[ "$TOTAL" -gt 0 ]]; then
    echo "  completion: $((DONE * 100 / TOTAL))%"
fi
echo ""

# --- Age distribution ---
TODAY=$(date +%s)
echo "  age distribution:"
STALE_7=0; STALE_14=0; STALE_30=0; FRESH=0

while IFS= read -r date_str; do
    date_str=$(echo "$date_str" | sed 's/.*created[_at]*: *//' | tr -d "'\"")
    if [[ -z "$date_str" || "$date_str" == "null" ]]; then continue; fi
    # Parse date — handles YYYY-MM-DD
    if CREATED=$(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || date -d "$date_str" +%s 2>/dev/null); then
        AGE_DAYS=$(( (TODAY - CREATED) / 86400 ))
        if [[ "$AGE_DAYS" -ge 30 ]]; then
            STALE_30=$((STALE_30 + 1))
        elif [[ "$AGE_DAYS" -ge 14 ]]; then
            STALE_14=$((STALE_14 + 1))
        elif [[ "$AGE_DAYS" -ge 7 ]]; then
            STALE_7=$((STALE_7 + 1))
        else
            FRESH=$((FRESH + 1))
        fi
    fi
done < <(grep -E 'created(_at)?:' "$TODOS" 2>/dev/null)

echo "    <7d: $FRESH · 7-14d: $STALE_7 · 14-30d: $STALE_14 · >30d: $STALE_30"
echo ""

# --- Feature clustering ---
echo "  by feature:"
grep -E '^\s*feature:' "$TODOS" 2>/dev/null | sed 's/.*feature: *//' | sort | uniq -c | sort -rn | head -10 | while read -r count tag; do
    if [[ "$count" -ge 3 ]]; then
        echo "    $tag: $count items (cluster)"
    else
        echo "    $tag: $count items"
    fi
done
TAGGED=$(grep -c '^\s*feature:' "$TODOS" || true)
TAGGED=${TAGGED:-0}
UNTAGGED_CT=$((TOTAL > TAGGED ? TOTAL - TAGGED : 0))
if [[ "$UNTAGGED_CT" -gt 0 ]]; then
    echo "    (untagged): $UNTAGGED_CT items"
fi
echo ""

# --- By source ---
echo "  by source:"
grep 'source:' "$TODOS" 2>/dev/null | sed 's/.*source: *//' | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /' || echo "    (no source data)"
echo ""

# --- Stale items list ---
if [[ $((STALE_7 + STALE_14 + STALE_30)) -gt 0 ]]; then
    echo "  ⚠ stale items: $((STALE_7 + STALE_14 + STALE_30)) need attention"
fi
