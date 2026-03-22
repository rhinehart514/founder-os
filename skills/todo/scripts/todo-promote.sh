#!/usr/bin/env bash
# todo-promote.sh — Finds todos that should graduate to assertions or activate.
# Two modes:
#   (no args)     — smart promote: suggest highest-leverage item from eval-cache bottleneck
#   graduate <id> — check if a completed todo should become an assertion (recurring pattern)
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
MODE="${2:-promote}"
ITEM_ID="${3:-}"
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
BELIEFS="$PROJECT_DIR/lens/product/eval/beliefs.yml"

# --- Smart promote: find bottleneck feature, suggest matching todo ---
if [[ "$MODE" == "promote" ]]; then
    echo "── smart promote ──"

    if [[ ! -f "$EVAL_CACHE" ]] || ! command -v jq &>/dev/null; then
        echo "  no eval-cache or jq — showing oldest unpromoted item instead"
        # Fallback: oldest backlog item
        grep -A3 'status: backlog' "$TODOS" 2>/dev/null | grep -E 'title:|id:' | head -4
        exit 0
    fi

    # Find bottleneck: lowest score feature
    BOTTLENECK=$(jq -r '
        to_entries
        | map(select(.value.score != null))
        | sort_by(.value.score)
        | .[0]
        | "\(.key)\t\(.value.score)\t\(.value.delivery_score // "?")\t\(.value.craft_score // "?")\t\(.value.viability_score // "?")"
    ' "$EVAL_CACHE" 2>/dev/null)

    if [[ -z "$BOTTLENECK" ]]; then
        echo "  no scored features in eval-cache"
        exit 0
    fi

    BN_FEATURE=$(echo "$BOTTLENECK" | cut -f1)
    BN_SCORE=$(echo "$BOTTLENECK" | cut -f2)
    BN_D=$(echo "$BOTTLENECK" | cut -f3)
    BN_C=$(echo "$BOTTLENECK" | cut -f4)
    BN_V=$(echo "$BOTTLENECK" | cut -f5)

    echo "  bottleneck: $BN_FEATURE ($BN_SCORE) — d:$BN_D c:$BN_C v:$BN_V"

    # Find weakest dimension
    WEAKEST_DIM="delivery"; WEAKEST_VAL="$BN_D"
    if [[ "$BN_C" != "?" ]] && [[ "$BN_C" -lt "${WEAKEST_VAL:-999}" ]] 2>/dev/null; then
        WEAKEST_DIM="craft"; WEAKEST_VAL="$BN_C"
    fi
    if [[ "$BN_V" != "?" ]] && [[ "$BN_V" -lt "${WEAKEST_VAL:-999}" ]] 2>/dev/null; then
        WEAKEST_DIM="viability"; WEAKEST_VAL="$BN_V"
    fi
    echo "  weakest dimension: $WEAKEST_DIM ($WEAKEST_VAL)"
    echo ""

    # Find backlog todos tagged to bottleneck feature
    echo "  matching todos:"
    awk -v feat="$BN_FEATURE" '
    /^\s*- title:/ { title=$0; id=""; status=""; feature="" }
    /^\s*id:/ { gsub(/.*id: */, ""); id=$0 }
    /^\s*status:/ { gsub(/.*status: */, ""); status=$0 }
    /^\s*feature:/ { gsub(/.*feature: */, ""); feature=$0 }
    /^\s*$/ || /^items:/ {
        if (feature == feat && status == "backlog" && id != "") {
            gsub(/.*- title: *"?/, "", title); gsub(/"$/, "", title)
            print "    ▸ [" id "] " title
        }
    }
    ' "$TODOS" 2>/dev/null

    echo ""
    echo "  suggestion: promote a $BN_FEATURE todo to target $WEAKEST_DIM ($WEAKEST_VAL)"
fi

# --- Graduation check: has this pattern recurred? ---
if [[ "$MODE" == "graduate" ]]; then
    echo "── graduation check ──"

    if [[ -z "$ITEM_ID" ]]; then
        echo "  usage: todo-promote.sh <project-dir> graduate <item-id>"
        exit 1
    fi

    # Extract the completed item's title and feature
    ITEM_TITLE=$(awk -v id="$ITEM_ID" '
    /^\s*id:/ { gsub(/.*id: */, ""); current_id=$0 }
    /^\s*- title:/ { gsub(/.*- title: *"?/, ""); gsub(/"$/, ""); current_title=$0 }
    /^\s*feature:/ { gsub(/.*feature: */, ""); current_feature=$0 }
    /^\s*status: done/ {
        if (current_id == id) { print current_title "\t" current_feature; exit }
    }
    ' "$TODOS" 2>/dev/null)

    if [[ -z "$ITEM_TITLE" ]]; then
        echo "  item $ITEM_ID not found or not done"
        exit 1
    fi

    TITLE=$(echo "$ITEM_TITLE" | cut -f1)
    FEATURE=$(echo "$ITEM_TITLE" | cut -f2)

    echo "  completed: \"$TITLE\" (feature: ${FEATURE:-untagged})"

    # Check for similar done items (share 2+ keywords)
    echo ""
    echo "  similar completed items:"
    # Extract keywords from title (words >3 chars)
    KEYWORDS=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | awk 'length > 3' | head -5)

    MATCHES=0
    for kw in $KEYWORDS; do
        grep -i "$kw" "$TODOS" 2>/dev/null | grep -B5 'status: done' | grep 'title:' | while read -r line; do
            echo "    · $line"
        done
        CT=$(grep -i "$kw" "$TODOS" 2>/dev/null | grep -B5 'status: done' | grep -c 'title:' 2>/dev/null || echo 0)
        MATCHES=$((MATCHES + CT))
    done

    if [[ "$MATCHES" -gt 1 ]]; then
        echo ""
        echo "  ⚠ recurring pattern detected ($MATCHES similar completions)"
        echo "  → suggest graduating to assertion on feature: ${FEATURE:-unknown}"
    else
        echo "    (no recurring pattern found)"
    fi

    # Check eval-cache for regression on this feature
    if [[ -n "$FEATURE" && -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
        DELTA=$(jq -r --arg f "$FEATURE" '.[$f].delta // "none"' "$EVAL_CACHE" 2>/dev/null)
        if [[ "$DELTA" == "down" || "$DELTA" == "regression" ]]; then
            echo ""
            echo "  ⚠ feature $FEATURE has regressed — strong graduation signal"
        fi
    fi
fi
