#!/usr/bin/env bash
# evidence-tracker.sh — For each evidence item in current version, checks status.
# Maps evidence to predictions and eval data.
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"

echo "── evidence tracker ──"

if [[ ! -f "$ROADMAP" ]]; then
    echo "  no roadmap.yml"
    exit 0
fi

CURRENT=$(grep -m1 '^current:' "$ROADMAP" 2>/dev/null | sed 's/^current: *//' | tr -d ' ' || echo "?")
THESIS=$(awk "/^  ${CURRENT}:/{found=1} found && /thesis:/{print; exit}" "$ROADMAP" 2>/dev/null | sed 's/.*thesis: *//' | sed 's/"//g' || echo "?")

echo "  version: $CURRENT"
echo "  thesis: \"$THESIS\""
echo ""

# Use awk to extract evidence items from current version
# Output format: id|question|status|evidence (one line per item)
ITEMS=$(awk -v ver="$CURRENT" '
    BEGIN { in_ver=0; in_ev=0; id=""; q=""; st=""; ev="" }
    /^  v[0-9]/ {
        if (in_ver && id != "") { print id "|" q "|" st "|" ev }
        if ($0 ~ "^  " ver ":") { in_ver=1; in_ev=0 }
        else if (in_ver) { exit }
        next
    }
    in_ver && /evidence_needed:/ { in_ev=1; next }
    in_ver && in_ev && /- id:/ {
        if (id != "") { print id "|" q "|" st "|" ev }
        id=$0; sub(/.*id: */, "", id)
        q=""; st=""; ev=""
        next
    }
    in_ver && in_ev && /question:/ { q=$0; sub(/.*question: */, "", q); gsub(/"/, "", q); next }
    in_ver && in_ev && /status:/ { st=$0; sub(/.*status: */, "", st); next }
    in_ver && in_ev && /evidence:/ { ev=$0; sub(/.*evidence: */, "", ev); gsub(/"/, "", ev); next }
    END { if (id != "") print id "|" q "|" st "|" ev }
' "$ROADMAP" 2>/dev/null || true)

PROVEN=0
DISPROVEN=0
PARTIAL=0
OPEN=0
TOTAL=0

if [[ -z "$ITEMS" ]]; then
    echo "  no evidence_needed items found for $CURRENT"
else
    echo "  ▾ evidence items"
    echo ""
    while IFS='|' read -r EV_ID EV_Q EV_STATUS EV_EVIDENCE; do
        [[ -z "$EV_ID" ]] && continue
        TOTAL=$((TOTAL + 1))

        case "$EV_STATUS" in
            proven) ICON="✓"; PROVEN=$((PROVEN + 1)) ;;
            partial) ICON="~"; PARTIAL=$((PARTIAL + 1)) ;;
            disproven) ICON="✗"; DISPROVEN=$((DISPROVEN + 1)) ;;
            *) ICON="·"; OPEN=$((OPEN + 1)) ;;
        esac

        echo "  $ICON $EV_ID — $EV_STATUS"
        echo "    question: $EV_Q"
        [[ -n "$EV_EVIDENCE" ]] && echo "    evidence: $EV_EVIDENCE"

        # Check for related predictions
        if [[ -f "$PRED_FILE" ]]; then
            SEARCH_TERM=$(echo "$EV_Q" | cut -c1-30)
            RELATED=$(grep -i -c -F -e "$EV_ID" -e "$SEARCH_TERM" "$PRED_FILE" 2>/dev/null || true)
            RELATED=$(echo "$RELATED" | tr -d '[:space:]')
            RELATED=${RELATED:-0}
            if [[ "$RELATED" -gt 0 ]]; then
                CORRECT=$(grep -i -F -e "$EV_ID" -e "$SEARCH_TERM" "$PRED_FILE" 2>/dev/null | awk -F'\t' '$5 == "yes"' | wc -l | tr -d ' ' || echo "0")
                echo "    predictions: $RELATED related ($CORRECT correct)"
            fi
        fi
        echo ""
    done <<< "$ITEMS"
fi

echo "── summary ──"
echo "  total: $TOTAL"
echo "  proven: $PROVEN  partial: $PARTIAL  disproven: $DISPROVEN  open: $OPEN"
if [[ $TOTAL -gt 0 ]]; then
    PCT=$((PROVEN * 100 / TOTAL))
    echo "  evidence completion: ${PCT}%"
fi

# Feature scores for context
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo ""
    echo "  ▾ feature scores (for evidence mapping)"
    jq -r 'to_entries[] | select(.value.score != null) | "    \(.key): \(.value.score) (d:\(.value.delivery_score // "?") c:\(.value.craft_score // "?") v:\(.value.viability_score // "?")"' "$EVAL_CACHE" 2>/dev/null || true
fi

# Stall detection
if [[ -d "$PROJECT_DIR/.git" ]]; then
    LAST_CHANGE=$(git -C "$PROJECT_DIR" log -1 --format="%ar" -- ".claude/plans/roadmap.yml" 2>/dev/null || echo "unknown")
    echo ""
    echo "  last roadmap change: $LAST_CHANGE"
fi

echo ""
echo "── end tracker ──"
