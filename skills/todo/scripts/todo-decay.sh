#!/usr/bin/env bash
# todo-decay.sh — Finds stale backlog items by age bracket.
# >7d untagged: flag for tagging or kill
# >14d: flag as stale — promote, kill, or convert to /research
# >30d: suggest kill with reason
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"

echo "── todo decay ──"

if [[ ! -f "$TODOS" ]]; then
    echo "  no todos.yml — nothing to decay"
    exit 0
fi

TODAY=$(date +%s)
DECAY_COUNT=0

# Parse todos into blocks — each block is one item
# We use awk to extract id, title, status, feature, created_at per item
awk '
/^\s*- title:/ { if (id != "") print id "\t" title "\t" status "\t" feature "\t" created; id=""; title=""; status=""; feature=""; created="" }
/^\s*- title:/ { gsub(/.*- title: *"?/, ""); gsub(/"$/, ""); title=$0 }
/^\s*id:/ { gsub(/.*id: */, ""); id=$0 }
/^\s*status:/ { gsub(/.*status: */, ""); status=$0 }
/^\s*feature:/ { gsub(/.*feature: */, ""); feature=$0 }
/^\s*created_at:/ { gsub(/.*created_at: */, ""); gsub(/["'\'']/, ""); created=$0 }
END { if (id != "") print id "\t" title "\t" status "\t" feature "\t" created }
' "$TODOS" | while IFS=$'\t' read -r id title status feature created; do
    # Only check non-done items
    if [[ "$status" == "done" ]]; then continue; fi
    if [[ -z "$created" || "$created" == "null" ]]; then continue; fi

    # Parse date
    CREATED_TS=$(date -j -f "%Y-%m-%d" "$created" +%s 2>/dev/null || date -d "$created" +%s 2>/dev/null || echo "0")
    if [[ "$CREATED_TS" == "0" ]]; then continue; fi

    AGE_DAYS=$(( (TODAY - CREATED_TS) / 86400 ))

    if [[ "$AGE_DAYS" -ge 30 ]]; then
        echo "  ⚠ [$id] \"$title\"  ${AGE_DAYS}d"
        echo "    feature: ${feature:-untagged} · status: $status"
        echo "    → 30+ days. Kill it, promote it, or convert to /research?"
        echo ""
        DECAY_COUNT=$((DECAY_COUNT + 1))
    elif [[ "$AGE_DAYS" -ge 14 ]]; then
        echo "  ⚠ [$id] \"$title\"  ${AGE_DAYS}d"
        echo "    feature: ${feature:-untagged} · status: $status"
        echo "    → Stale. Promote / Kill / Needs /research?"
        echo ""
        DECAY_COUNT=$((DECAY_COUNT + 1))
    elif [[ "$AGE_DAYS" -ge 7 && -z "$feature" ]]; then
        echo "  ⚠ [$id] \"$title\"  ${AGE_DAYS}d"
        echo "    untagged · status: $status"
        echo "    → 7+ days untagged. Tag or kill."
        echo ""
        DECAY_COUNT=$((DECAY_COUNT + 1))
    fi
done

if [[ "$DECAY_COUNT" -eq 0 ]]; then
    echo "  ✓ no stale items — backlog is healthy"
fi
