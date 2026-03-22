#!/usr/bin/env bash
# dimension-summary.sh — Structured output of all 11 dimensions from latest eval.
# Shows scores, deltas, weakest/strongest, prescriptions pending.
# Usage: bash scripts/dimension-summary.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
HISTORY="$PROJECT_DIR/.claude/evals/taste-history.tsv"
REPORTS_DIR="$PROJECT_DIR/.claude/evals/reports"

DIMS=(hierarchy breathing_room contrast polish emotional_tone information_density wayfinding distinctiveness scroll_experience layout_coherence information_architecture)

echo "── dimension summary ──"

if [[ ! -f "$HISTORY" ]]; then
    echo "  no taste evaluations yet"
    echo "  run: /taste <url>"
    exit 0
fi

EVAL_COUNT=$(tail -n +2 "$HISTORY" | wc -l | tr -d ' ')
echo "  evaluations: $EVAL_COUNT"

if [[ "$EVAL_COUNT" -eq 0 ]]; then
    echo "  no data rows in history"
    exit 0
fi

# Read header to map dimension names to column indices
HEADER=$(head -1 "$HISTORY")
IFS=$'\t' read -ra COLS <<< "$HEADER"

declare -A COL_MAP
for i in "${!COLS[@]}"; do
    COL_MAP["${COLS[$i]}"]=$((i + 1))
done

# Latest row
LATEST=$(tail -1 "$HISTORY")
IFS=$'\t' read -ra LATEST_VALS <<< "$LATEST"
LATEST_DATE="${LATEST_VALS[0]}"
LATEST_URL="${LATEST_VALS[1]}"
LATEST_OVERALL="${LATEST_VALS[2]}"

echo "  latest: $LATEST_DATE  $LATEST_URL"
echo "  overall: $LATEST_OVERALL/100"
echo ""

# Previous row for deltas
PREV_VALS=()
if [[ "$EVAL_COUNT" -gt 1 ]]; then
    PREV=$(tail -n +2 "$HISTORY" | tail -2 | head -1)
    IFS=$'\t' read -ra PREV_VALS <<< "$PREV"
fi

# Collect scores for sorting
declare -A SCORES
declare -A DELTAS
WEAKEST_DIM=""
WEAKEST_SCORE=101
STRONGEST_DIM=""
STRONGEST_SCORE=-1

echo "  ▸ gates"
for dim in layout_coherence information_architecture; do
    idx=${COL_MAP[$dim]:-0}
    if [[ $idx -gt 0 ]]; then
        score="${LATEST_VALS[$((idx - 1))]:-}"
        delta=""
        if [[ ${#PREV_VALS[@]} -gt 0 ]]; then
            prev_score="${PREV_VALS[$((idx - 1))]:-}"
            if [[ -n "$prev_score" && -n "$score" ]]; then
                delta=$((score - prev_score))
                [[ $delta -gt 0 ]] && delta="+$delta"
            fi
        fi
        SCORES[$dim]="${score:-?}"
        DELTAS[$dim]="$delta"
        printf "    %-28s %s/100  %s\n" "$dim" "${score:-?}" "${delta:+[$delta]}"
    fi
done

# Check gate cap
LC_SCORE="${SCORES[layout_coherence]:-0}"
IA_SCORE="${SCORES[information_architecture]:-0}"
if [[ "$LC_SCORE" -lt 30 || "$IA_SCORE" -lt 30 ]] 2>/dev/null; then
    echo "    CAPPED AT 30 — fix the skeleton before decorating"
fi

echo ""
echo "  ▸ dimensions (weakest first)"

# Collect non-gate dimensions with scores
declare -a DIM_LINES=()
for dim in "${DIMS[@]}"; do
    [[ "$dim" == "layout_coherence" || "$dim" == "information_architecture" ]] && continue
    idx=${COL_MAP[$dim]:-0}
    if [[ $idx -gt 0 ]]; then
        score="${LATEST_VALS[$((idx - 1))]:-0}"
        delta=""
        if [[ ${#PREV_VALS[@]} -gt 0 ]]; then
            prev_score="${PREV_VALS[$((idx - 1))]:-}"
            if [[ -n "$prev_score" && -n "$score" ]]; then
                delta=$((score - prev_score))
                [[ $delta -gt 0 ]] && delta="+$delta"
            fi
        fi
        DIM_LINES+=("$score|$dim|$delta")

        if [[ "$score" -lt "$WEAKEST_SCORE" ]] 2>/dev/null; then
            WEAKEST_SCORE="$score"
            WEAKEST_DIM="$dim"
        fi
        if [[ "$score" -gt "$STRONGEST_SCORE" ]] 2>/dev/null; then
            STRONGEST_SCORE="$score"
            STRONGEST_DIM="$dim"
        fi
    fi
done

# Sort by score ascending (weakest first)
IFS=$'\n' SORTED=($(printf '%s\n' "${DIM_LINES[@]}" | sort -t'|' -k1 -n))
unset IFS

for entry in "${SORTED[@]}"; do
    IFS='|' read -r score dim delta <<< "$entry"
    printf "    %-28s %s/100  %s\n" "$dim" "$score" "${delta:+[$delta]}"
done

echo ""
echo "  weakest:  $WEAKEST_DIM ($WEAKEST_SCORE)"
echo "  strongest: $STRONGEST_DIM ($STRONGEST_SCORE)"

# Check for latest report with prescriptions
if [[ -d "$REPORTS_DIR" ]]; then
    LATEST_REPORT=$(ls -t "$REPORTS_DIR"/taste-*.json 2>/dev/null | head -1)
    if [[ -n "$LATEST_REPORT" ]] && command -v jq &>/dev/null; then
        RX_COUNT=$(jq '[.dimensions | to_entries[] | select(.value.prescription != null and .value.prescription != "")] | length' "$LATEST_REPORT" 2>/dev/null || echo 0)
        if [[ "$RX_COUNT" -gt 0 ]]; then
            echo ""
            echo "  ▸ pending prescriptions: $RX_COUNT"
            jq -r '.dimensions | to_entries[] | select(.value.prescription != null and .value.prescription != "") | "    \(.key): \(.value.prescription)"' "$LATEST_REPORT" 2>/dev/null
        fi
    fi
fi
