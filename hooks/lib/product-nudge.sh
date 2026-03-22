#!/usr/bin/env bash
# product-nudge.sh — Product intelligence lines for session boot card.
# Extracted to hooks/lib/ following the self-checks.sh pattern.
# Returns PRODUCT_LINES variable with 0-3 lines of product context.
#
# Required env: PROJECT_DIR, C_DIM, C_NC

PRODUCT_LINES=""

VALUE_CACHE="$PROJECT_DIR/.claude/cache/product-value.json"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
CLAIM_CACHE="$PROJECT_DIR/.claude/cache/claim-verify.json"

# Bail gracefully if no caches exist
[[ ! -f "$VALUE_CACHE" ]] && [[ ! -f "$EVAL_CACHE" ]] && return 0 2>/dev/null || true

_product_lines=""

# Line 1: Product model one-liner (from product-value.json)
if [[ -f "$VALUE_CACHE" ]] && command -v jq &>/dev/null; then
    MODEL=$(jq -r '.product_type // empty' "$VALUE_CACHE" 2>/dev/null)
    SURFACE_COUNT=$(jq -r '.value_loop | length' "$VALUE_CACHE" 2>/dev/null)
    TOP_SURFACES=$(jq -r '[.value_loop[:5][] | split("/")[1] // .] | join(", ")' "$VALUE_CACHE" 2>/dev/null)
    if [[ -n "$MODEL" ]]; then
        _product_lines="${C_DIM}product${C_NC}     ${MODEL} · ${SURFACE_COUNT} value surfaces"
    fi
fi

# Line 2: Top value surfaces
if [[ -n "$TOP_SURFACES" && "$TOP_SURFACES" != "null" ]]; then
    _product_lines="${_product_lines}\n              ${C_DIM}value loop${C_NC} ${TOP_SURFACES}"
fi

# Line 3: Highest-priority nudge
NUDGE=""

# Priority 1: Feature trending "worse" in eval-cache
if [[ -z "$NUDGE" && -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    WORSE=$(jq -r 'to_entries[] | select(.value.delta == "worse") | "\(.key) (\(.value.score))"' "$EVAL_CACHE" 2>/dev/null | head -1)
    if [[ -n "$WORSE" ]]; then
        NUDGE="${C_RED:-}↓${C_NC} ${WORSE} trending worse"
    fi
fi

# Priority 2: Claim verdict = gap or broken
if [[ -z "$NUDGE" && -f "$CLAIM_CACHE" ]] && command -v jq &>/dev/null; then
    GAP=$(jq -r '.features | to_entries[] | select(.value.verdict == "gap" or .value.verdict == "broken") | "\(.key): \(.value.verdict)"' "$CLAIM_CACHE" 2>/dev/null | head -1)
    if [[ -n "$GAP" ]]; then
        NUDGE="${C_YELLOW:-}!${C_NC} ${GAP} — claim not delivering"
    fi
fi

# Priority 3: Journey stage with 0 surfaces
if [[ -z "$NUDGE" && -f "$VALUE_CACHE" ]] && command -v jq &>/dev/null; then
    EMPTY_STAGE=$(jq -r '.journey_funnel | to_entries[] | select(.value.count == 0) | .key' "$VALUE_CACHE" 2>/dev/null | head -1)
    if [[ -n "$EMPTY_STAGE" ]]; then
        NUDGE="${C_YELLOW:-}○${C_NC} ${EMPTY_STAGE} stage has 0 surfaces"
    fi
fi

# Priority 4: Unmet customer need (from outside-in analysis)
OUTSIDE_IN_CACHE="$PROJECT_DIR/.claude/cache/outside-in.json"
if [[ -z "$NUDGE" && -f "$OUTSIDE_IN_CACHE" ]] && command -v jq &>/dev/null; then
    TOP_UNMET=$(jq -r '(.unmet_needs // [])[0].need // empty' "$OUTSIDE_IN_CACHE" 2>/dev/null)
    if [[ -n "$TOP_UNMET" ]]; then
        NUDGE="${C_YELLOW:-}◇${C_NC} unmet: ${TOP_UNMET}"
    fi
fi

# Priority 5: Eval cache staleness (>3 days old)
if [[ -z "$NUDGE" && -f "$EVAL_CACHE" ]]; then
    CACHE_AGE_DAYS=$(( ( $(date +%s) - $(stat -f%m "$EVAL_CACHE" 2>/dev/null || stat -c%Y "$EVAL_CACHE" 2>/dev/null || echo "0") ) / 86400 ))
    if [[ "$CACHE_AGE_DAYS" -gt 3 ]]; then
        NUDGE="${C_DIM}eval-cache is ${CACHE_AGE_DAYS}d old — 19 consumers reading stale data${C_NC}"
    fi
fi

if [[ -n "$NUDGE" ]]; then
    _product_lines="${_product_lines}\n              ${C_DIM}·${C_NC} ${NUDGE}"
fi

if [[ -n "$_product_lines" ]]; then
    PRODUCT_LINES="$_product_lines"
fi
