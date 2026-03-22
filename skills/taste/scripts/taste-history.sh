#!/usr/bin/env bash
# taste-history.sh — Shows taste score trends over time per dimension.
# Classifies each dimension: improving, slow, stable, stuck, regressing.
# Usage: bash scripts/taste-history.sh [project-dir] [dimension]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
FOCUS_DIM="${2:-}"
HISTORY="$PROJECT_DIR/.claude/evals/taste-history.tsv"

echo "── taste history ──"

if [[ ! -f "$HISTORY" ]]; then
    echo "  no taste evaluations yet"
    echo "  run: /taste <url>"
    exit 0
fi

EVAL_COUNT=$(tail -n +2 "$HISTORY" | wc -l | tr -d ' ')
echo "  evaluations: $EVAL_COUNT"

if [[ "$EVAL_COUNT" -lt 2 ]]; then
    echo "  need 2+ evals for trends. run /taste <url> again."
    exit 0
fi

# Read header
HEADER=$(head -1 "$HISTORY")
IFS=$'\t' read -ra COLS <<< "$HEADER"

declare -A COL_MAP
for i in "${!COLS[@]}"; do
    COL_MAP["${COLS[$i]}"]=$((i + 1))
done

# Show overall trajectory
echo ""
echo "  ▸ overall trajectory"
OVERALL_COL=${COL_MAP[overall]:-3}
tail -n +2 "$HISTORY" | awk -F'\t' -v col="$OVERALL_COL" '{printf "    %s  %s/100\n", $1, $col}' | tail -10

# Compute trends per dimension
DIMS=(hierarchy breathing_room contrast polish emotional_tone information_density wayfinding distinctiveness scroll_experience layout_coherence information_architecture)

classify_trend() {
    local first="$1" last="$2" count="$3"
    local delta=$((last - first))

    if [[ $delta -gt 10 ]]; then
        echo "improving|+$delta"
    elif [[ $delta -ge 5 ]]; then
        echo "slow|+$delta"
    elif [[ $delta -ge -4 && $delta -le 4 ]]; then
        if [[ $count -ge 3 ]]; then
            echo "stuck|$delta"
        else
            echo "stable|$delta"
        fi
    else
        echo "regressing|$delta"
    fi
}

declare -a IMPROVING=() SLOW=() STABLE=() STUCK=() REGRESSING=()

for dim in "${DIMS[@]}"; do
    if [[ -n "$FOCUS_DIM" && "$dim" != "$FOCUS_DIM" ]]; then
        continue
    fi

    col=${COL_MAP[$dim]:-0}
    [[ $col -eq 0 ]] && continue

    # Get all scores for this dimension
    SCORES=$(tail -n +2 "$HISTORY" | awk -F'\t' -v c="$col" '{print $c}' | grep -v '^$')
    SCORE_COUNT=$(echo "$SCORES" | wc -l | tr -d ' ')

    if [[ $SCORE_COUNT -lt 2 ]]; then
        continue
    fi

    FIRST=$(echo "$SCORES" | head -1)
    LAST=$(echo "$SCORES" | tail -1)

    RESULT=$(classify_trend "$FIRST" "$LAST" "$SCORE_COUNT")
    CLASS="${RESULT%%|*}"
    DELTA="${RESULT##*|}"

    # Build timeline string (last 5)
    TIMELINE=$(echo "$SCORES" | tail -5 | tr '\n' ' ' | sed 's/ *$//')
    ENTRY=$(printf "%-28s %s  [%s]" "$dim" "$TIMELINE" "$DELTA")

    case "$CLASS" in
        improving) IMPROVING+=("$ENTRY") ;;
        slow)      SLOW+=("$ENTRY") ;;
        stable)    STABLE+=("$ENTRY") ;;
        stuck)     STUCK+=("$ENTRY") ;;
        regressing) REGRESSING+=("$ENTRY") ;;
    esac
done

if [[ -n "$FOCUS_DIM" ]]; then
    # Single dimension deep dive
    col=${COL_MAP[$FOCUS_DIM]:-0}
    if [[ $col -gt 0 ]]; then
        echo ""
        echo "  ▸ $FOCUS_DIM — all scores"
        tail -n +2 "$HISTORY" | awk -F'\t' -v c="$col" '{printf "    %s  %s/100\n", $1, $c}' | tail -20
    fi
    exit 0
fi

echo ""
if [[ ${#IMPROVING[@]} -gt 0 ]]; then
    echo "  ▸ improving (delta > +10)"
    for e in "${IMPROVING[@]}"; do echo "    $e"; done
fi

if [[ ${#SLOW[@]} -gt 0 ]]; then
    echo "  ▸ slow progress (+5 to +10)"
    for e in "${SLOW[@]}"; do echo "    $e"; done
fi

if [[ ${#STABLE[@]} -gt 0 ]]; then
    echo "  ▸ stable (-4 to +4)"
    for e in "${STABLE[@]}"; do echo "    $e"; done
fi

if [[ ${#STUCK[@]} -gt 0 ]]; then
    echo "  ▸ stuck (3+ evals, <5pt change) — current approach exhausted"
    for e in "${STUCK[@]}"; do echo "    $e"; done
fi

if [[ ${#REGRESSING[@]} -gt 0 ]]; then
    echo "  ▸ regressing (delta < -5)"
    for e in "${REGRESSING[@]}"; do echo "    $e"; done
fi

# Date range
FIRST_DATE=$(tail -n +2 "$HISTORY" | head -1 | cut -f1)
LAST_DATE=$(tail -1 "$HISTORY" | cut -f1)
echo ""
echo "  range: $FIRST_DATE to $LAST_DATE ($EVAL_COUNT evals)"
