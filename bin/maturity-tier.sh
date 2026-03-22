#!/usr/bin/env bash
# maturity-tier.sh — Determines project maturity tier from score + eval data.
# Consumed by /plan, /go, session_start to route behavior by stage.
# Output: structured tier data with recommended actions.
set -euo pipefail

PROJECT_DIR="${1:-.}"

# --- Check dependencies ---
if ! command -v jq &>/dev/null; then
    # Fallback: output "fix" tier with warning when jq unavailable
    if [[ "${2:-}" == "--json" ]]; then
        echo '{"tier":"fix","score":0,"health":0,"eval_avg":0,"eval_count":0,"eval_min":0,"eval_min_feature":"","features_above_70":0,"features_below_50":0,"assertion_pass":0,"assertion_total":0,"focus":"Install jq to unlock tier detection","actions":"brew install jq","skills":"/go","avoid":""}'
    else
        echo "=== MATURITY TIER ==="
        echo "tier: fix (jq unavailable — install with: brew install jq)"
        echo "=== END TIER ==="
    fi
    exit 0
fi

# --- Read score ---
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
SCORE=0
HEALTH=0
ASSERTION_PASS=0
ASSERTION_TOTAL=0
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    SCORE=$(jq -r '.score // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    HEALTH=$(jq -r '.health_min // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    ASSERTION_PASS=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    ASSERTION_TOTAL=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
fi

# --- Read eval averages ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
EVAL_AVG=0
EVAL_COUNT=0
EVAL_MIN=100
EVAL_MIN_FEATURE=""
FEATURES_ABOVE_70=0
FEATURES_BELOW_50=0
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    EVAL_DATA=$(jq -r '
        to_entries
        | map(select(.value.score != null and .value.score > 0))
        | {
            count: length,
            avg: (if length > 0 then ([.[].value.score] | add / length | floor) else 0 end),
            min_score: (if length > 0 then ([.[].value.score] | min) else 0 end),
            min_feature: (if length > 0 then (sort_by(.value.score) | first | .key) else "" end),
            above_70: ([.[] | select(.value.score >= 70)] | length),
            below_50: ([.[] | select(.value.score < 50)] | length)
        }
        | "\(.count)\t\(.avg)\t\(.min_score)\t\(.min_feature)\t\(.above_70)\t\(.below_50)"
    ' "$EVAL_CACHE" 2>/dev/null || echo "0\t0\t0\t\t0\t0")

    IFS=$'\t' read -r EVAL_COUNT EVAL_AVG EVAL_MIN EVAL_MIN_FEATURE FEATURES_ABOVE_70 FEATURES_BELOW_50 <<< "$EVAL_DATA"
fi

# --- Determine tier ---
# Tiers represent what the system should DO, not just a label.
#
# fix:        Structure broken. Fix health, build, basic assertions.
# deepen:     Structure works. Features need depth. Eval-driven task generation.
# strengthen: Features exist. Push weakest ones up. Research unknowns.
# expand:     Structure solid (85+), but features still shallow (<70 avg eval).
#             The gap between "healthy codebase" and "good product."
# mature:     Both structure (85+) and features (70+ avg) are strong.
#             Time to ideate, research, find users, ship.

TIER="fix"
if [[ "$SCORE" -ge 85 ]] && [[ "$EVAL_AVG" -ge 70 ]]; then
    TIER="mature"
elif [[ "$SCORE" -ge 85 ]]; then
    TIER="expand"
elif [[ "$SCORE" -ge 70 ]]; then
    TIER="strengthen"
elif [[ "$SCORE" -ge 50 ]]; then
    TIER="deepen"
fi

# --- Determine recommended actions per tier ---
case "$TIER" in
    fix)
        FOCUS="Fix broken things. No ideation. Pure delivery."
        ACTIONS="fix failing assertions|improve health score|complete basic feature implementations"
        SKILLS="/go|/eval|/assert"
        AVOID="/ideate|/research market|/ship|/money"
        ;;
    deepen)
        FOCUS="Features need depth. Eval-driven task generation."
        ACTIONS="run /eval to surface gaps|work through eval tasks per feature|add assertion coverage"
        SKILLS="/eval|/go|/plan|/assert"
        AVOID="/ideate|/ship|/money"
        ;;
    strengthen)
        FOCUS="Push weakest features up. Research unknowns before building."
        ACTIONS="target weakest sub-scores on highest-weight features|research unknown territory|strengthen assertion coverage"
        SKILLS="/eval|/go|/plan|/research|/assert"
        AVOID="/ideate broad|/money|/ship (unless thesis proven)"
        ;;
    expand)
        FOCUS="Structure is solid. Features need depth before breadth."
        ACTIONS="deep eval weakest features|research unknowns in knowledge model|consider /ideate when bottleneck features can't improve without new capabilities|run /strategy to check positioning"
        SKILLS="/eval|/go|/plan|/research|/ideate (gated)|/strategy"
        AVOID="/ship (features not ready)|building new features before existing ones score 70+"
        ;;
    mature)
        FOCUS="Core is strong. Expand, find users, ship."
        ACTIONS="run /ideate for evidence-weighted expansion|run /research for highest-info unknowns|run /strategy to check market position|consider /ship or /money|run /taste for visual quality"
        SKILLS="/ideate|/research|/strategy|/ship|/money|/taste|/product"
        AVOID="polishing features already at 80+|adding features without user signal"
        ;;
esac

# --- Output ---
if [[ "${2:-}" == "--json" ]]; then
    cat <<ENDJSON
{
  "tier": "$TIER",
  "score": $SCORE,
  "health": $HEALTH,
  "eval_avg": $EVAL_AVG,
  "eval_count": $EVAL_COUNT,
  "eval_min": $EVAL_MIN,
  "eval_min_feature": "$EVAL_MIN_FEATURE",
  "features_above_70": $FEATURES_ABOVE_70,
  "features_below_50": $FEATURES_BELOW_50,
  "assertion_pass": $ASSERTION_PASS,
  "assertion_total": $ASSERTION_TOTAL,
  "focus": "$FOCUS",
  "actions": "$(echo "$ACTIONS" | tr '|' '\n' | sed 's/^/    /')",
  "skills": "$SKILLS",
  "avoid": "$AVOID"
}
ENDJSON
else
    echo "=== MATURITY TIER ==="
    echo "tier: $TIER"
    echo "score: $SCORE  health: $HEALTH  eval_avg: $EVAL_AVG ($EVAL_COUNT features)"
    echo "eval_min: $EVAL_MIN ($EVAL_MIN_FEATURE)"
    echo "features_above_70: $FEATURES_ABOVE_70  features_below_50: $FEATURES_BELOW_50"
    echo ""
    echo "focus: $FOCUS"
    echo "actions:"
    echo "$ACTIONS" | tr '|' '\n' | while IFS= read -r a; do
        echo "  · $a"
    done
    echo "skills: $SKILLS"
    echo "avoid: $AVOID"
    echo "=== END TIER ==="
fi
