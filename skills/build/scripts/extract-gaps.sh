#!/usr/bin/env bash
# extract-gaps.sh — Pull every actionable gap from eval, taste, flows, assertions
# Outputs JSON array of tasks sorted by priority (weight × gap size)
set -uo pipefail

PROJECT_DIR="${1:-.}"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
TASTE_DIR="$PROJECT_DIR/.claude/evals/reports"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
TODOS_FILE="$PROJECT_DIR/.claude/plans/todos.yml"

if ! command -v jq &>/dev/null; then
    echo '{"error": "jq required"}' >&2
    exit 1
fi

# --- Eval gaps ---
eval_tasks="[]"
if [[ -f "$EVAL_CACHE" ]] && jq empty "$EVAL_CACHE" 2>/dev/null; then
    eval_tasks=$(jq '
        to_entries
        | map(select(.value.gaps != null and (.value.gaps | length) > 0))
        | map({
            feature: .key,
            score: (.value.score // 0),
            delivery: (.value.delivery_score // 0),
            craft: (.value.craft_score // 0),
            gaps: .value.gaps
        })
        | map(. as $f | .gaps[] | {
            title: .,
            feature: $f.feature,
            source: "/eval",
            score: $f.score,
            dimension: (if ($f.delivery < $f.craft) then "delivery" else "craft" end)
        })
    ' "$EVAL_CACHE" 2>/dev/null || echo "[]")
fi

# --- Taste issues ---
taste_tasks="[]"
latest_taste=$(ls -t "$TASTE_DIR"/taste-*.json 2>/dev/null | head -1)
if [[ -n "$latest_taste" ]]; then
    taste_tasks=$(jq -r '
        [.dimensions // {} | to_entries[]
        | select(.value.score < 70)
        | {
            title: ("taste: \(.key) at \(.value.score) — \(.value.notes // "needs improvement")"),
            feature: "visual",
            source: "/taste",
            score: .value.score,
            dimension: "craft"
        }]
    ' "$latest_taste" 2>/dev/null || echo "[]")
fi

# --- Flows issues ---
flows_tasks="[]"
latest_flows=$(ls -t "$TASTE_DIR"/flows-*.json 2>/dev/null | head -1)
if [[ -n "$latest_flows" ]]; then
    flows_tasks=$(jq -r '
        [(.issues // [])[]
        | select((.fixed // false) == false)
        | {
            title: ("flow \(.severity): \(.description // .issue // "unnamed issue")"),
            feature: (.feature // "behavioral"),
            source: "/taste flows",
            score: (if .severity == "blocker" then 0 elif .severity == "major" then 30 else 60 end),
            dimension: "delivery"
        }]
    ' "$latest_flows" 2>/dev/null || echo "[]")
fi

# --- Get feature weights ---
weights="{}"
if [[ -f "$FOUNDER_YML" ]]; then
    _raw_weights=$(awk '
        /^features:/ { in_features = 1; next }
        in_features && /^[a-z]/ { in_features = 0 }
        in_features && /^  [a-z][a-z_-]*:$/ { feat = $1; sub(/:$/, "", feat) }
        in_features && /weight:/ && feat { gsub(/[^0-9]/, "", $2); if ($2+0 > 0) print feat " " $2; feat = "" }
    ' "$FOUNDER_YML" 2>/dev/null)
    if [[ -n "$_raw_weights" ]]; then
        weights=$(echo "$_raw_weights" | jq -Rs '
            split("\n") | map(select(. != "")) | map(split(" ") | {(.[0]): (.[1] | tonumber)}) | add // {}
        ')
    fi
fi

# --- Count existing todos to detect duplicates ---
existing_count=0
if [[ -f "$TODOS_FILE" ]]; then
    existing_count=$(grep -c '^ *- id:' "$TODOS_FILE" 2>/dev/null | tr -d ' \n' || echo "0")
fi
[[ -z "$existing_count" ]] && existing_count=0

# --- Merge and prioritize ---
jq -n --argjson eval "$eval_tasks" \
      --argjson taste "$taste_tasks" \
      --argjson flows "$flows_tasks" \
      --argjson weights "$weights" \
      --argjson existing "$existing_count" '
    ($eval + $taste + $flows)
    | map(. + {
        weight: ($weights[.feature] // 1),
        gap: (80 - (.score // 0)),
        priority_score: (($weights[.feature] // 1) * (80 - (.score // 0)))
    })
    | sort_by(-.priority_score)
    | {
        total_gaps: length,
        existing_todos: $existing,
        by_feature: (group_by(.feature) | map({(.[0].feature): length}) | add // {}),
        by_dimension: (group_by(.dimension) | map({(.[0].dimension): length}) | add // {}),
        tasks: .
    }
'
