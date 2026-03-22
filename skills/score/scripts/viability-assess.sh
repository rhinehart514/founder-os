#!/usr/bin/env bash
# viability-assess.sh — Check viability cache freshness and data sources
# Usage: viability-assess.sh [project-dir] [feature]
# Returns: freshness status and whether agents should be spawned

set -uo pipefail

PROJECT_DIR="${1:-.}"
TARGET_FEATURE="${2:-all}"
NOW=$(date +%s)
STALE_SECS=259200  # 72 hours

VIABILITY_CACHE="$PROJECT_DIR/.claude/cache/viability-cache.json"
MARKET_CONTEXT="$PROJECT_DIR/.claude/cache/market-context.json"
CUSTOMER_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
PRODUCT_SPEC="$PROJECT_DIR/config/product-spec.yml"

file_age_secs() {
    local file="$1"
    local field="${2:-assessed_at}"
    if [[ ! -f "$file" ]]; then
        echo "999999"
        return
    fi
    local ts
    ts=$(jq -r ".$field // .assessed_at // .analyzed_at // .cached_at // empty" "$file" 2>/dev/null)
    if [[ -z "$ts" ]]; then
        # Fall back to file mtime
        local mtime
        mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo "0")
        echo $(( NOW - mtime ))
        return
    fi
    local epoch
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || date -d "$ts" +%s 2>/dev/null || echo "0")
    echo $(( NOW - epoch ))
}

echo "viability data sources"
echo "───────────────────────────────────"

# Check viability cache
echo -n "viability-cache.json  "
if [[ -f "$VIABILITY_CACHE" ]]; then
    age=$(file_age_secs "$VIABILITY_CACHE")
    if [[ $age -lt $STALE_SECS ]]; then
        echo "fresh ($(( age / 3600 ))h ago)"
    else
        echo "STALE ($(( age / 86400 ))d ago) — agents needed"
    fi
else
    echo "MISSING — agents needed"
fi

# Check market context
echo -n "market-context.json   "
if [[ -f "$MARKET_CONTEXT" ]]; then
    age=$(file_age_secs "$MARKET_CONTEXT")
    competitors=$(jq '.competitors | length' "$MARKET_CONTEXT" 2>/dev/null || echo "0")
    echo "present  ${competitors} competitors  $(( age / 3600 ))h ago"
else
    echo "MISSING — market-analyst agent needed"
fi

# Check customer intel
echo -n "customer-intel.json   "
if [[ -f "$CUSTOMER_INTEL" ]]; then
    age=$(file_age_secs "$CUSTOMER_INTEL")
    themes=$(jq '.themes | length' "$CUSTOMER_INTEL" 2>/dev/null || echo "0")
    echo "present  ${themes} themes  $(( age / 3600 ))h ago"
else
    echo "MISSING — customer agent needed"
fi

# Check strategy
echo -n "strategy.yml          "
if [[ -f "$STRATEGY" ]]; then
    echo "present"
else
    echo "MISSING — run /strategy"
fi

# Check product spec
echo -n "product-spec.yml      "
if [[ -f "$PRODUCT_SPEC" ]]; then
    echo "present"
else
    echo "MISSING — run /discover"
fi

# Decision
echo ""
echo "───────────────────────────────────"

needs_agents=false
viability_age=$(file_age_secs "$VIABILITY_CACHE")

if [[ ! -f "$VIABILITY_CACHE" ]] || [[ $viability_age -gt $STALE_SECS ]]; then
    needs_agents=true
fi

if [[ ! -f "$MARKET_CONTEXT" ]] || [[ ! -f "$CUSTOMER_INTEL" ]]; then
    needs_agents=true
fi

if $needs_agents; then
    echo "SPAWN AGENTS: viability data is stale or missing"
    echo "  spawn: market-analyst (competitive landscape)"
    echo "  spawn: customer (demand signals)"
    echo ""
    # Determine viability cap and source
    if [[ ! -f "$MARKET_CONTEXT" ]] && [[ ! -f "$CUSTOMER_INTEL" ]]; then
        echo "cap: 30 (no external data)"
        echo "source: capped"
    elif [[ -f "$MARKET_CONTEXT" ]] && [[ -f "$CUSTOMER_INTEL" ]]; then
        echo "cap: 60 (intelligence available, agents needed for full range)"
        echo "source: intelligence (synthesize.sh will use cached intelligence)"
    elif [[ -f "$MARKET_CONTEXT" ]]; then
        echo "cap: 45 (market context only)"
        echo "source: intelligence-partial"
    else
        echo "cap: 45 (customer intel only)"
        echo "source: intelligence-partial"
    fi
else
    echo "DATA FRESH: score from cached viability-cache.json (agent-backed)"
    # Show per-feature viability if available
    if [[ -f "$VIABILITY_CACHE" ]] && [[ "$TARGET_FEATURE" != "all" ]]; then
        jq -r --arg f "$TARGET_FEATURE" '.features[$f] // {} | "  \($f): \(.viability_score // "?")  uvp:\(.uvp_clarity // "?") gap:\(.competitive_gap // "?") demand:\(.demand_signal // "?") pos:\(.positioning // "?")"' "$VIABILITY_CACHE" 2>/dev/null
    elif [[ -f "$VIABILITY_CACHE" ]]; then
        jq -r '.features // {} | to_entries[] | "  \(.key): \(.value.viability_score // "?")  confidence:\(.value.confidence // "?")"' "$VIABILITY_CACHE" 2>/dev/null
    fi
fi
