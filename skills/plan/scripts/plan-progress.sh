#!/usr/bin/env bash
# plan-progress.sh — Show plan.yml progress + task status.
# Usage: bash scripts/plan-progress.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
PLAN_FILE="$PROJECT_DIR/.claude/plans/plan.yml"

echo "=== PLAN PROGRESS ==="

if [[ ! -f "$PLAN_FILE" ]]; then
    echo "  no active plan"
    echo "=== PROGRESS COMPLETE ==="
    exit 0
fi

count() { local n; n=$(grep -c "$@" 2>/dev/null) || true; echo "${n:-0}"; }
TOTAL=$(count -e '  title:' "$PLAN_FILE")
DONE=$(count 'status: done' "$PLAN_FILE")
TODO=$(count 'status: todo' "$PLAN_FILE")
IN_PROGRESS=$(count 'status: in_progress' "$PLAN_FILE")
SKIPPED=$(count 'status: skipped' "$PLAN_FILE")

PLAN_NAME=$(grep -m1 'name:' "$PLAN_FILE" 2>/dev/null | head -1 | sed 's/.*name: *//' | sed 's/"//g' || echo "unknown")
PLAN_DATE=$(grep -m1 'created:' "$PLAN_FILE" 2>/dev/null | sed 's/.*created: *//' || echo "?")
BOTTLENECK=$(grep -m1 'bottleneck:' "$PLAN_FILE" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' || echo "?")

echo "  plan: \"$PLAN_NAME\""
echo "  date: $PLAN_DATE  bottleneck: $BOTTLENECK"
echo "  done: $DONE/$TOTAL  in_progress: $IN_PROGRESS  remaining: $TODO  skipped: $SKIPPED"

if [[ "$TOTAL" -gt 0 ]]; then
    PCT=$((DONE * 100 / TOTAL))
    echo "  completion: ${PCT}%"
fi

# Show individual tasks
echo ""
echo "  tasks:"
IN_TASK=false
TITLE=""
while IFS= read -r line; do
    if echo "$line" | grep -q -e 'title:'; then
        TITLE=$(echo "$line" | sed 's/.*title: *//' | sed 's/"//g')
        IN_TASK=true
    elif $IN_TASK && echo "$line" | grep -q 'status:'; then
        STATUS=$(echo "$line" | sed 's/.*status: *//')
        case "$STATUS" in
            done) MARKER="[x]" ;;
            in_progress) MARKER="[~]" ;;
            skipped) MARKER="[-]" ;;
            *) MARKER="[ ]" ;;
        esac
        echo "    $MARKER $TITLE"
        IN_TASK=false
    fi
done < "$PLAN_FILE"

echo ""
echo "=== PROGRESS COMPLETE ==="
