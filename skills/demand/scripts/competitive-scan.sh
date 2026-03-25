#!/usr/bin/env bash
# competitive-scan.sh — Outputs structured competitor data, checks market-context.json freshness.
# Usage: bash scripts/competitive-scan.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
MARKET_CTX="$PROJECT_DIR/.claude/cache/market-context.json"
MARKET_BASE="$PROJECT_DIR/.claude/cache/market-context-base.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

echo "── competitive scan ──"

# --- Market context freshness ---
echo ""
echo "  ── market context ──"
if [[ -f "$MARKET_CTX" ]] && command -v jq &>/dev/null; then
    LAST_UPDATED=$(jq -r '.last_updated // "unknown"' "$MARKET_CTX" 2>/dev/null || echo "unknown")
    CATEGORY=$(jq -r '.category // "unknown"' "$MARKET_CTX" 2>/dev/null || echo "unknown")
    SATURATION=$(jq -r '.saturation // "unknown"' "$MARKET_CTX" 2>/dev/null || echo "unknown")
    TRAJECTORY=$(jq -r '.trajectory // "unknown"' "$MARKET_CTX" 2>/dev/null || echo "unknown")

    echo "  source: market-context.json"
    echo "  updated: $LAST_UPDATED"
    echo "  category: $CATEGORY"
    echo "  saturation: $SATURATION"
    echo "  trajectory: $TRAJECTORY"

    # Freshness check (stale if >7 days)
    if command -v python3 &>/dev/null && [[ "$LAST_UPDATED" != "unknown" ]]; then
        DAYS_OLD=$(python3 -c "
from datetime import datetime
try:
    d = datetime.strptime('$LAST_UPDATED', '%Y-%m-%d')
    print((datetime.now() - d).days)
except:
    print(-1)
" 2>/dev/null || echo "-1")
        if [[ "$DAYS_OLD" -gt 7 ]]; then
            echo "  ! stale: $DAYS_OLD days old — run /strategy market to refresh"
        elif [[ "$DAYS_OLD" -ge 0 ]]; then
            echo "  fresh: $DAYS_OLD days old"
        fi
    fi

    # --- Competitor listing ---
    echo ""
    echo "  ── competitors ──"
    COMP_COUNT=$(jq '.competitors | length' "$MARKET_CTX" 2>/dev/null || echo 0)
    if [[ "$COMP_COUNT" -gt 0 ]]; then
        jq -r '.competitors[] | "    \(.name) — threat:\(.threat) — \(.notes // .traction // "no notes")"' "$MARKET_CTX" 2>/dev/null
    else
        echo "    (none tracked)"
    fi

    # --- Pricing landscape ---
    echo ""
    echo "  ── pricing landscape ──"
    HAS_PRICING=$(jq 'has("pricing_landscape")' "$MARKET_CTX" 2>/dev/null || echo "false")
    if [[ "$HAS_PRICING" == "true" ]]; then
        jq -r '.pricing_landscape | "    range: \(.range // "unknown")\n    model: \(.dominant_model // "unknown")\n    solo viable: \(.solo_viable // "unknown")"' "$MARKET_CTX" 2>/dev/null
    else
        echo "    (no pricing data)"
    fi

    # --- Proven channels ---
    echo ""
    echo "  ── channels ──"
    HAS_CHANNELS=$(jq 'has("channels")' "$MARKET_CTX" 2>/dev/null || echo "false")
    if [[ "$HAS_CHANNELS" == "true" ]]; then
        PROVEN=$(jq -r '.channels.proven // [] | join(", ")' "$MARKET_CTX" 2>/dev/null || echo "none")
        UNTESTED=$(jq -r '.channels.untested // [] | join(", ")' "$MARKET_CTX" 2>/dev/null || echo "none")
        echo "    proven: $PROVEN"
        echo "    untested: $UNTESTED"
    else
        echo "    (no channel data)"
    fi

elif [[ -f "$MARKET_BASE" ]]; then
    echo "  source: base model only (no project-specific market data)"
    echo "  ! run /strategy market <domain> to build project-specific context"
else
    echo "  ! no market context — run /strategy market <domain>"
fi

# --- Category from founder.yml ---
if [[ -f "$FOUNDER_YML" ]]; then
    echo ""
    echo "  ── founder.yml signals ──"
    CATEGORY_YML=$(grep -m1 'category:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*category: *//' | sed 's/#.*//' | tr -d '"' || echo "")
    VALUE_USER=$(grep -m1 'user:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*user: *//' | sed 's/#.*//' | tr -d '"' || echo "")
    [[ -n "$CATEGORY_YML" ]] && echo "    category: $CATEGORY_YML"
    [[ -n "$VALUE_USER" ]] && echo "    target user: $VALUE_USER"
    if [[ -z "$VALUE_USER" || "$VALUE_USER" == "users" || "$VALUE_USER" == "developers" || "$VALUE_USER" == "teams" ]]; then
        echo "    ! generic user — name a specific person and their situation"
    fi
fi

echo ""
echo "── competitive scan complete ──"
