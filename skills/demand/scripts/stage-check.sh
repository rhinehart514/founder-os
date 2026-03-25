#!/usr/bin/env bash
# stage-check.sh — Mechanically determines project stage from eval-cache, features, and user signals.
# Outputs structured stage assessment. Zero context cost.
# Usage: bash scripts/stage-check.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
CUST_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
STRATEGY_YML="$PROJECT_DIR/.claude/plans/strategy.yml"

echo "── stage check ──"

# --- Declared stage ---
STAGE="unknown"
if [[ -f "$FOUNDER_YML" ]]; then
    STAGE=$(grep -m1 'stage:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*stage: *//' | sed 's/#.*//' | tr -d ' "' || echo "unknown")
fi
echo "  declared: $STAGE"

# --- Eval-derived signals ---
TOTAL_FEATURES=0
PLANNED=0      # 0-29
BUILDING=0     # 30-49
WORKING=0      # 50-69
POLISHED=0     # 70-89
PROVEN=0       # 90+
AVG_SCORE=0
WORST_FEATURE=""
WORST_SCORE=100
BEST_FEATURE=""
BEST_SCORE=0
CRAFT_GT_DELIVERY=0

if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    TOTAL_FEATURES=$(jq 'to_entries | map(select(.value.score != null)) | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    PLANNED=$(jq '[to_entries[] | select(.value.score != null and .value.score < 30)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    BUILDING=$(jq '[to_entries[] | select(.value.score != null and .value.score >= 30 and .value.score < 50)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    WORKING=$(jq '[to_entries[] | select(.value.score != null and .value.score >= 50 and .value.score < 70)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    POLISHED=$(jq '[to_entries[] | select(.value.score != null and .value.score >= 70 and .value.score < 90)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    PROVEN=$(jq '[to_entries[] | select(.value.score != null and .value.score >= 90)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)

    if [[ "$TOTAL_FEATURES" -gt 0 ]]; then
        AVG_SCORE=$(jq '[to_entries[] | select(.value.score != null) | .value.score] | add / length | floor' "$EVAL_CACHE" 2>/dev/null || echo 0)
        WORST_FEATURE=$(jq -r 'to_entries | map(select(.value.score != null)) | sort_by(.value.score) | .[0] | .key' "$EVAL_CACHE" 2>/dev/null || echo "?")
        WORST_SCORE=$(jq 'to_entries | map(select(.value.score != null)) | sort_by(.value.score) | .[0] | .value.score' "$EVAL_CACHE" 2>/dev/null || echo "?")
        BEST_FEATURE=$(jq -r 'to_entries | map(select(.value.score != null)) | sort_by(-.value.score) | .[0] | .key' "$EVAL_CACHE" 2>/dev/null || echo "?")
        BEST_SCORE=$(jq 'to_entries | map(select(.value.score != null)) | sort_by(-.value.score) | .[0] | .value.score' "$EVAL_CACHE" 2>/dev/null || echo "?")
    fi

    # Polishing-before-delivering check: craft > delivery + 15
    CRAFT_GT_DELIVERY=$(jq '[to_entries[] | select(.value.craft_score != null and .value.delivery_score != null) | select(.value.craft_score > .value.delivery_score + 15)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
fi

echo "  features: $TOTAL_FEATURES (planned:$PLANNED building:$BUILDING working:$WORKING polished:$POLISHED proven:$PROVEN)"
echo "  avg score: $AVG_SCORE"
echo "  worst: $WORST_FEATURE at $WORST_SCORE"
echo "  best: $BEST_FEATURE at $BEST_SCORE"

# --- User count signals ---
USERS="unknown"
if [[ -f "$CUST_INTEL" ]] && command -v jq &>/dev/null; then
    USERS=$(jq -r '.user_count // .users // "unknown"' "$CUST_INTEL" 2>/dev/null || echo "unknown")
fi
if [[ -f "$FOUNDER_YML" ]]; then
    YML_USERS=$(grep -m1 'users:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*users: *//' | sed 's/#.*//' | tr -d ' "' || echo "")
    [[ -n "$YML_USERS" ]] && USERS="$YML_USERS"
fi
echo "  users: $USERS"

# --- Mechanical stage determination ---
echo ""
echo "  ── stage diagnosis ──"

# Infer stage from signals
INFERRED="pre-product"
if [[ "$TOTAL_FEATURES" -eq 0 ]]; then
    INFERRED="pre-product"
    echo "  inferred: pre-product (no features scored)"
elif [[ "$AVG_SCORE" -lt 30 ]]; then
    INFERRED="pre-product"
    echo "  inferred: pre-product (avg score $AVG_SCORE < 30)"
elif [[ "$WORKING" -eq 0 && "$POLISHED" -eq 0 && "$PROVEN" -eq 0 ]]; then
    INFERRED="one"
    echo "  inferred: stage one (no features at working+)"
elif [[ "$USERS" == "unknown" || "$USERS" == "0" || "$USERS" == "1" ]]; then
    INFERRED="one"
    echo "  inferred: stage one (users: $USERS)"
elif [[ "$USERS" -le 10 ]] 2>/dev/null; then
    INFERRED="some"
    echo "  inferred: stage some (users: $USERS)"
elif [[ "$USERS" -le 100 ]] 2>/dev/null; then
    INFERRED="many"
    echo "  inferred: stage many (users: $USERS)"
else
    INFERRED="growth"
    echo "  inferred: growth (users: $USERS)"
fi

# --- Warnings ---
echo ""
echo "  ── warnings ──"
WARN_COUNT=0

if [[ "$BUILDING" -gt 3 ]]; then
    echo "  ! feature sprawl: $BUILDING features in building range (30-49)"
    ((WARN_COUNT++))
fi

if [[ "$CRAFT_GT_DELIVERY" -gt 0 ]]; then
    echo "  ! polishing before delivering: $CRAFT_GT_DELIVERY features have craft > delivery + 15"
    ((WARN_COUNT++))
fi

if [[ "$INFERRED" == "one" && "$POLISHED" -gt 0 ]]; then
    echo "  ! polished features at stage one — shipping value > polish at this stage"
    ((WARN_COUNT++))
fi

if [[ "$INFERRED" != "$STAGE" && "$STAGE" != "unknown" ]]; then
    echo "  ! stage mismatch: declared=$STAGE inferred=$INFERRED"
    ((WARN_COUNT++))
fi

if [[ "$WARN_COUNT" -eq 0 ]]; then
    echo "  (none)"
fi

echo ""
echo "── stage check complete ──"
