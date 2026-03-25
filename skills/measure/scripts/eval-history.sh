#!/usr/bin/env bash
# Show eval score history per feature from eval-cache.json and rubrics
# Usage: bash scripts/eval-history.sh [feature]
# If feature specified, show detailed history. Otherwise show all features.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
RUBRIC_DIR="$PROJECT_DIR/.claude/cache/rubrics"
FEATURE="${1:-}"

echo "── eval history ──"

if [[ ! -f "$CACHE" ]]; then
    echo "  no eval-cache.json — run /eval to establish baseline"
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "  jq not installed — cannot parse eval-cache.json"
    exit 0
fi

show_feature() {
    local name="$1"
    local score delta_vs delta cached_at d c v

    score=$(jq -r --arg f "$name" '.[$f].score // "?"' "$CACHE" 2>/dev/null)
    [[ "$score" == "?" || "$score" == "null" ]] && return

    d=$(jq -r --arg f "$name" '.[$f].delivery_score // "?"' "$CACHE" 2>/dev/null)
    c=$(jq -r --arg f "$name" '.[$f].craft_score // "?"' "$CACHE" 2>/dev/null)
    v=$(jq -r --arg f "$name" '.[$f].viability_score // "?"' "$CACHE" 2>/dev/null)
    delta=$(jq -r --arg f "$name" '.[$f].delta // "new"' "$CACHE" 2>/dev/null)
    delta_vs=$(jq -r --arg f "$name" '.[$f].delta_vs // ""' "$CACHE" 2>/dev/null)
    cached_at=$(jq -r --arg f "$name" '.[$f].cached_at // "?"' "$CACHE" 2>/dev/null | cut -d'T' -f1)

    # Build trend line from rubric score_history
    local history_line=""
    local rubric="$RUBRIC_DIR/$name.json"
    if [[ -f "$rubric" ]]; then
        history_line=$(jq -r '.score_history // [] | map(tostring) | join(" -> ")' "$rubric" 2>/dev/null)
    fi

    echo "  $name: $score  d:$d c:$c v:$v  ($delta vs $delta_vs)  scored $cached_at"
    if [[ -n "$history_line" && "$history_line" != "" ]]; then
        echo "    trend: $history_line -> $score"
    fi

    # Detailed mode: show gaps and strengths
    if [[ -n "$FEATURE" ]]; then
        local gaps strengths evidence
        gaps=$(jq -r --arg f "$name" '.[$f].gaps // [] | .[] | "    gap: " + .' "$CACHE" 2>/dev/null)
        strengths=$(jq -r --arg f "$name" '.[$f].strengths // [] | .[] | "    str: " + .' "$CACHE" 2>/dev/null)
        evidence=$(jq -r --arg f "$name" '.[$f].evidence // ""' "$CACHE" 2>/dev/null)
        [[ -n "$evidence" && "$evidence" != "null" ]] && echo "    evidence: $evidence"
        [[ -n "$gaps" ]] && echo "$gaps"
        [[ -n "$strengths" ]] && echo "$strengths"

        # Show rubric criteria
        if [[ -f "$rubric" ]]; then
            echo "    rubric criteria:"
            jq -r '.delivery_criteria // [] | .[] | "      d: " + .' "$rubric" 2>/dev/null
            jq -r '.craft_criteria // [] | .[] | "      c: " + .' "$rubric" 2>/dev/null
            jq -r '.viability_criteria // [] | .[] | "      v: " + .' "$rubric" 2>/dev/null
            local known_gaps
            known_gaps=$(jq -r '.known_gaps // [] | .[] | "      gap: " + .' "$rubric" 2>/dev/null)
            [[ -n "$known_gaps" ]] && echo "$known_gaps"
        fi
    fi
}

if [[ -n "$FEATURE" ]]; then
    show_feature "$FEATURE"
else
    # Show all features sorted by score (worst first)
    jq -r 'to_entries | sort_by(.value.score) | .[].key' "$CACHE" 2>/dev/null | while read -r name; do
        show_feature "$name"
    done

    # Summary stats
    echo ""
    TOTAL=$(jq 'length' "$CACHE" 2>/dev/null)
    AVG=$(jq '[.[].score] | add / length | floor' "$CACHE" 2>/dev/null)
    WORST=$(jq -r 'to_entries | min_by(.value.score) | .key + " (" + (.value.score | tostring) + ")"' "$CACHE" 2>/dev/null)
    BEST=$(jq -r 'to_entries | max_by(.value.score) | .key + " (" + (.value.score | tostring) + ")"' "$CACHE" 2>/dev/null)
    echo "  $TOTAL features, avg $AVG, worst: $WORST, best: $BEST"
fi
