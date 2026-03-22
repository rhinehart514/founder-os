#!/usr/bin/env bash
# product-scan.sh — Scans all product state into structured output.
# Zero context cost — only the output enters the conversation.
set -euo pipefail

PROJECT_DIR="${1:-.}"

# --- Value hypothesis ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    echo "=== VALUE HYPOTHESIS ==="
    # Extract value section
    awk '/^value:/,/^[a-z]/{if(/^[a-z]/ && !/^value:/) exit; print}' "$FOUNDER_YML" 2>/dev/null || echo "(no value section)"
    echo ""

    # Extract user definition
    echo "=== USER ==="
    grep -E '^\s+user:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*user:\s*//' || echo "(no user defined)"
    echo ""

    # Extract signals
    echo "=== SIGNALS ==="
    awk '/^\s+signals:/,/^[a-z]/{if(/^[a-z]/) exit; print}' "$FOUNDER_YML" 2>/dev/null | tail -n +2 || echo "(no signals)"
    echo ""

    # Extract features list
    echo "=== FEATURES ==="
    awk '/^features:/,/^[a-z]/{if(/^[a-z]/ && !/^features:/) exit; print}' "$FOUNDER_YML" 2>/dev/null | grep -E '^\s+-\s+name:|weight:|status:' | paste - - - 2>/dev/null || echo "(no features)"
    echo ""
fi

# --- Eval cache ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "=== EVAL SCORES ==="
    jq -r 'to_entries[] | select(.value.score != null) | "\(.key): \(.value.score)/100 (delivery:\(.value.delivery_score // "?") craft:\(.value.craft_score // "?") viability:\(.value.viability_score // "?")) delta:\(.value.delta // "none")"' "$EVAL_CACHE" 2>/dev/null || echo "(parse error)"
    echo ""

    # Feature maturity breakdown
    echo "=== MATURITY ==="
    jq -r 'to_entries[] | select(.value.score != null) |
      if .value.score >= 90 then "\(.key): proven (\(.value.score))"
      elif .value.score >= 70 then "\(.key): polished (\(.value.score))"
      elif .value.score >= 50 then "\(.key): working (\(.value.score))"
      elif .value.score >= 30 then "\(.key): building (\(.value.score))"
      else "\(.key): planned (\(.value.score))"
      end' "$EVAL_CACHE" 2>/dev/null || echo "(parse error)"
    echo ""

    # Delivery vs craft gap (polishing-before-delivering detector)
    echo "=== DELIVERY vs CRAFT GAP ==="
    jq -r 'to_entries[] | select(.value.craft_score != null and .value.delivery_score != null) |
      select((.value.craft_score - .value.delivery_score) > 15) |
      "  WARNING: \(.key) — craft \(.value.craft_score) > delivery \(.value.delivery_score). Polishing before delivering."' "$EVAL_CACHE" 2>/dev/null
    jq -r 'to_entries[] | select(.value.craft_score != null and .value.delivery_score != null) |
      select((.value.craft_score - .value.delivery_score) <= 15) |
      "  OK: \(.key) — delivery \(.value.delivery_score), craft \(.value.craft_score)"' "$EVAL_CACHE" 2>/dev/null
    echo ""
fi

# --- Customer intel ---
CUST_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
if [[ -f "$CUST_INTEL" ]] && command -v jq &>/dev/null; then
    echo "=== CUSTOMER SIGNALS ==="
    jq -r '.demand_signals[]? // empty' "$CUST_INTEL" 2>/dev/null | head -5
    jq -r '.themes[]? // empty' "$CUST_INTEL" 2>/dev/null | head -5
    echo ""
else
    echo "=== CUSTOMER SIGNALS ==="
    echo "(no customer-intel.json — run /discover or /research for customer data)"
    echo ""
fi

# --- Strategy ---
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY" ]]; then
    echo "=== STRATEGY ==="
    grep -E 'stage:|bottleneck:|last_updated:' "$STRATEGY" 2>/dev/null || echo "(minimal strategy)"
    echo ""
fi

# --- Roadmap thesis ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    echo "=== CURRENT THESIS ==="
    awk '/^  v[0-9].*status: active/,/^  v[0-9]/{if(/^  v[0-9]/ && !/status: active/) exit; print}' "$ROADMAP" 2>/dev/null | head -20 || echo "(no active thesis)"
    echo ""
fi

# --- Assertions health ---
BELIEFS="$PROJECT_DIR/config/beliefs.yml"
if [[ -f "$BELIEFS" ]]; then
    TOTAL=$(grep -c '^\s*-\s*claim:' "$BELIEFS" 2>/dev/null || echo "0")
    echo "=== ASSERTIONS ==="
    echo "  total: $TOTAL beliefs defined"
    echo ""
fi

# --- Git context ---
echo "=== RECENT WORK (last 10 commits) ==="
git -C "$PROJECT_DIR" log --oneline -10 2>/dev/null || echo "(not a git repo)"
echo ""

# --- README existence and first line ---
if [[ -f "$PROJECT_DIR/README.md" ]]; then
    echo "=== README HEADLINE ==="
    head -3 "$PROJECT_DIR/README.md"
    echo ""
fi

echo "=== PRODUCT SCAN COMPLETE ==="
