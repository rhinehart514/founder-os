#!/usr/bin/env bash
# synthesize.sh — Compute unified score from all tier caches
# Usage: synthesize.sh [project-dir] [feature]
# Outputs JSON with per-feature unified scores and product total
#
# The unified score answers: "Does the user get value?"
# Every tier measures a different facet of user value delivery.
# This applies to any product surface — web, CLI, API, docs.
#
# Viability: reads viability-cache.json first (agent-backed).
# Falls back to scoring from accumulated intelligence files
# (market-context.json + customer-intel.json). No intelligence = capped at 30.

set -uo pipefail

# Resolve founder-os root (for sourcing shared libs)
_SYNTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_FOUNDER_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$_SYNTH_DIR/../../.." && pwd)}"

# Source shared config reader for _cfg_from_file()
# shellcheck source=../../../bin/lib/config.sh
source "$_FOUNDER_ROOT/bin/lib/config.sh"

PROJECT_DIR="${1:-.}"
TARGET_FEATURE=""
OUTPUT_MODE="json"

# Parse args: synthesize.sh [project-dir] [feature] [--text]
shift || true
for _arg in "$@"; do
    case "$_arg" in
        --text) OUTPUT_MODE="text" ;;
        --json) OUTPUT_MODE="json" ;;
        --*) ;; # ignore unknown flags
        *) TARGET_FEATURE="$_arg" ;;
    esac
done

EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
VIABILITY_CACHE="$PROJECT_DIR/.claude/cache/viability-cache.json"
MARKET_CONTEXT="$PROJECT_DIR/.claude/cache/market-context.json"
CUSTOMER_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
DEMAND_CACHE="$PROJECT_DIR/.claude/cache/demand-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
TASTE_DIR="$PROJECT_DIR/.claude/evals/reports"

# --- Read feature weights from founder.yml ---
get_feature_weight() {
    local feat="$1"
    _cfg_from_file "$FOUNDER_YML" "features.${feat}.weight" "1"
}

get_active_features() {
    awk '
        /^  [a-z][a-z_-]*:$/ { feat = $1; sub(/:$/, "", feat) }
        /status: active/ && feat { print feat; feat = "" }
        /status: killed/ && feat { feat = "" }
    ' "$FOUNDER_YML" 2>/dev/null
}

# --- Health gate check ---
# If health gate is FAIL, the unified score is 0 regardless of feature scores.
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
# --- Read belief/assertion counts from score-cache ---
_belief_pass=0
_belief_total=0
_belief_score=0
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    _belief_pass=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null)
    _belief_total=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null)
    if [[ "$_belief_total" -gt 0 ]]; then
        _belief_score=$(( _belief_pass * 100 / _belief_total ))
    fi
fi
# First-run fallback: if score-cache.json doesn't exist, generate it so the
# health gate isn't silently skipped on initial synthesis.
# Skip when called from score.sh (FOUNDER_SCORE_DEPTH set) to prevent recursion.
if [[ ! -f "$SCORE_CACHE" ]] && [[ -x "$_FOUNDER_ROOT/bin/score.sh" ]] && [[ "${FOUNDER_SCORE_DEPTH:-0}" -eq 0 ]]; then
    echo "synthesize: first run — generating health cache via score.sh" >&2
    bash "$_FOUNDER_ROOT/bin/score.sh" "$PROJECT_DIR" --json --quiet >/dev/null 2>&1 || true
fi
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    _health_gate=$(jq -r '.health_gate // "PASS"' "$SCORE_CACHE" 2>/dev/null)
    if [[ "$_health_gate" == "FAIL" ]]; then
        _health_min=$(jq -r '.health_min // 0' "$SCORE_CACHE" 2>/dev/null)
        if [[ "$OUTPUT_MODE" == "text" ]]; then
            echo "Unified Score: 0/100  (HEALTH GATE FAIL — health ${_health_min} < threshold)"
            echo ""
            echo "Fix structural issues first. Run \`founder score .\` for details."
        else
            echo "{\"synthesized_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"features\":{},\"product_score\":0,\"confidence\":\"blocked\",\"health_gate\":\"FAIL\",\"health_min\":${_health_min},\"tiers_filled\":0,\"total_weight\":0,\"opportunity_context\":null}"
        fi
        exit 0
    fi
fi

# --- Pre-validate eval cache (once, before per-feature reads) ---
_eval_cache_valid=false
_eval_cache_empty=true
if [[ -f "$EVAL_CACHE" ]]; then
    if jq empty "$EVAL_CACHE" 2>/dev/null; then
        _eval_cache_valid=true
        # Check if cache has any feature entries (not just {})
        _feat_count=$(jq 'keys | length' "$EVAL_CACHE" 2>/dev/null || echo "0")
        [[ "$_feat_count" -gt 0 ]] && _eval_cache_empty=false
    else
        echo "synthesize: eval cache corrupted — run /eval to rebuild." >&2
    fi
fi

# --- Eval age computation (score decay) ---
get_eval_age_days() {
    local feat="$1"
    if [[ "$_eval_cache_valid" == true ]]; then
        local cached_at
        cached_at=$(jq -r --arg f "$feat" '.[$f].cached_at // empty' "$EVAL_CACHE" 2>/dev/null)
        if [[ -n "$cached_at" ]]; then
            local cached_epoch now_epoch
            # macOS date vs GNU date
            if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$cached_at" "+%s" &>/dev/null; then
                cached_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$cached_at" "+%s" 2>/dev/null)
            else
                cached_epoch=$(date -d "$cached_at" "+%s" 2>/dev/null)
            fi
            now_epoch=$(date "+%s")
            if [[ -n "$cached_epoch" && -n "$now_epoch" ]]; then
                echo $(( (now_epoch - cached_epoch) / 86400 ))
                return
            fi
        fi
    fi
    echo "-1"
}

# --- Read eval cache (tier 2: delivery + craft) ---
get_eval_scores() {
    local feat="$1"
    if [[ "$_eval_cache_valid" == true ]]; then
        local result
        result=$(jq -r --arg f "$feat" '.[$f] // {} | "\(.delivery_score // 0) \(.craft_score // 0) \(.confidence_interval // 0)"' "$EVAL_CACHE" 2>/dev/null)
        if [[ -z "$result" || "$result" == "null null null" ]]; then
            echo "0 0 0"
        else
            echo "$result"
        fi
    else
        echo "0 0 0"
    fi
}

# --- Read latest taste report (tier 3: visual OR CLI) ---
get_visual_score() {
    # Check for CLI taste first (for CLI products), then web taste
    local cli_latest
    cli_latest=$(ls -t "$TASTE_DIR"/cli-taste-*.json 2>/dev/null | head -1)
    if [[ -n "$cli_latest" ]]; then
        local _cli_err _cli_result
        _cli_err=$(mktemp /tmp/founder-cli-taste-err.XXXXXX)
        _cli_result=$(jq -r '.overall // -1' "$cli_latest" 2>"$_cli_err")
        rm -f "$_cli_err"
        if [[ "$_cli_result" != "-1" && "$_cli_result" != "null" ]]; then
            echo "$_cli_result"
            return
        fi
    fi

    local latest
    latest=$(ls -t "$TASTE_DIR"/taste-*.json 2>/dev/null | head -1)
    if [[ -z "$latest" ]]; then
        echo "-1"
        return
    fi
    local _taste_err
    _taste_err=$(mktemp /tmp/founder-taste-err.XXXXXX)
    local _taste_result
    _taste_result=$(jq -r '
        [.dimensions // {} | to_entries[] | .value.score // 0] |
        if length > 0 then (add / length | floor) else -1 end
    ' "$latest" 2>"$_taste_err")
    if [[ $? -ne 0 ]]; then
        echo "synthesize: taste report parse error in $(basename "$latest") — $(head -1 "$_taste_err"). Run /taste to regenerate." >&2
        rm -f "$_taste_err"
        echo "-1"
        return
    fi
    rm -f "$_taste_err"
    echo "$_taste_result"
}

# --- Read latest flows report (tier 4: behavioral) ---
get_behavioral_score() {
    local latest
    latest=$(ls -t "$TASTE_DIR"/flows-*.json 2>/dev/null | head -1)
    if [[ -z "$latest" ]]; then
        echo "-1"
        return
    fi
    local _flows_err
    _flows_err=$(mktemp /tmp/founder-flows-err.XXXXXX)
    local _flows_result
    _flows_result=$(jq -r '
        def count_severity(s): [.issues[]? | select(.severity == s and (.fixed // false | not))] | length;
        100 - (count_severity("blocker") * 25) - (count_severity("major") * 10) - (count_severity("minor") * 3) |
        if . < 0 then 0 else . end
    ' "$latest" 2>"$_flows_err")
    if [[ $? -ne 0 ]]; then
        echo "synthesize: flows report parse error in $(basename "$latest") — $(head -1 "$_flows_err"). Run /taste flows to regenerate." >&2
        rm -f "$_flows_err"
        echo "-1"
        return
    fi
    rm -f "$_flows_err"
    echo "$_flows_result"
}

# --- Read viability (tier 5) ---
# Priority: viability-cache.json (agent-backed) > intelligence-derived > cap at 30
get_viability_score() {
    local feat="$1"

    # 1. Agent-backed viability cache (authoritative)
    if [[ -f "$VIABILITY_CACHE" ]]; then
        local v _via_err
        _via_err=$(mktemp /tmp/founder-via-err.XXXXXX)
        v=$(jq -r --arg f "$feat" '.features[$f].viability // -1' "$VIABILITY_CACHE" 2>"$_via_err")
        if [[ $? -ne 0 ]]; then
            echo "synthesize: viability cache parse error — $(head -1 "$_via_err"). Run /score viability to rebuild." >&2
            rm -f "$_via_err"
        else
            rm -f "$_via_err"
            if [[ "$v" != "-1" && "$v" != "null" ]]; then
                echo "$v"
                return
            fi
        fi
    fi

    # 2. Derive from accumulated intelligence files
    local has_market=false has_customer=false
    [[ -f "$MARKET_CONTEXT" ]] && has_market=true
    [[ -f "$CUSTOMER_INTEL" ]] && has_customer=true

    if $has_market && $has_customer; then
        # Both sources: score up to 60 (full range requires agent assessment)
        # Check if sources mention this feature's category
        local market_signals customer_signals
        market_signals=$(jq -r '.demand_signals | length' "$MARKET_CONTEXT" 2>/dev/null || echo "0")
        customer_signals=$(jq -r '.demand_signals | length' "$CUSTOMER_INTEL" 2>/dev/null || echo "0")
        local base=40
        [[ "$market_signals" -gt 3 ]] && base=$((base + 10))
        [[ "$customer_signals" -gt 3 ]] && base=$((base + 10))
        echo "$base"
    elif $has_market; then
        # Market only: capped at 45
        echo "45"
    elif $has_customer; then
        # Customer only: capped at 45
        echo "45"
    else
        # No intelligence: capped at 30
        echo "30"
    fi
}

# --- Viability source label ---
get_viability_source() {
    local feat="$1"
    if [[ -f "$VIABILITY_CACHE" ]]; then
        local v
        v=$(jq -r --arg f "$feat" '.features[$f].viability // -1' "$VIABILITY_CACHE" 2>/dev/null)
        if [[ "$v" != "-1" && "$v" != "null" ]]; then
            echo "agents"
            return
        fi
    fi
    local has_market=false has_customer=false
    [[ -f "$MARKET_CONTEXT" ]] && has_market=true
    [[ -f "$CUSTOMER_INTEL" ]] && has_customer=true
    if $has_market || $has_customer; then
        echo "intelligence"
    else
        echo "capped"
    fi
}

# --- Read demand tier (tier 6) ---
# Priority: demand-cache.json > default unknown (capped at 20)
get_demand_score() {
    local feat="$1"
    if [[ -f "$DEMAND_CACHE" ]] && command -v jq &>/dev/null; then
        local ds
        ds=$(jq -r --arg f "$feat" '.features[$f].demand_score // -1' "$DEMAND_CACHE" 2>/dev/null)
        if [[ "$ds" != "-1" && "$ds" != "null" && -n "$ds" ]]; then
            echo "$ds"
            return
        fi
        # Check demand_tier for a fallback score
        local tier
        tier=$(jq -r --arg f "$feat" '.features[$f].demand_tier // "unknown"' "$DEMAND_CACHE" 2>/dev/null)
        case "$tier" in
            validated) echo "85" ;;
            observed) echo "65" ;;
            hypothesized) echo "40" ;;
            *) echo "20" ;;
        esac
        return
    fi
    echo "20"  # No demand data = capped at 20
}

get_demand_source() {
    local feat="$1"
    if [[ -f "$DEMAND_CACHE" ]] && command -v jq &>/dev/null; then
        local ds
        ds=$(jq -r --arg f "$feat" '.features[$f].demand_score // -1' "$DEMAND_CACHE" 2>/dev/null)
        if [[ "$ds" != "-1" && "$ds" != "null" && -n "$ds" ]]; then
            echo "scored"
            return
        fi
        local tier
        tier=$(jq -r --arg f "$feat" '.features[$f].demand_tier // empty' "$DEMAND_CACHE" 2>/dev/null)
        if [[ -n "$tier" ]]; then
            echo "tier-$tier"
            return
        fi
    fi
    echo "unknown"
}

# --- Compute unified score for a feature ---
compute_feature_score() {
    local feat="$1"
    local eval_scores
    eval_scores=$(get_eval_scores "$feat")
    local delivery craft ci
    delivery=$(echo "$eval_scores" | awk '{print $1}')
    craft=$(echo "$eval_scores" | awk '{print $2}')
    ci=$(echo "$eval_scores" | awk '{print $3}')
    [[ -z "$ci" || "$ci" == "null" ]] && ci=0

    local visual behavioral viability
    visual=$(get_visual_score)
    behavioral=$(get_behavioral_score)
    viability=$(get_viability_score "$feat")
    local viability_src
    viability_src=$(get_viability_source "$feat")

    local demand demand_src
    demand=$(get_demand_score "$feat")
    demand_src=$(get_demand_source "$feat")

    # Determine available tiers
    local has_visual=true has_behavioral=true
    [[ "$visual" == "-1" ]] && has_visual=false
    [[ "$behavioral" == "-1" ]] && has_behavioral=false

    # Count filled tiers for confidence badge
    local tier_count=2  # health + eval always present
    $has_visual && tier_count=$((tier_count + 1))
    $has_behavioral && tier_count=$((tier_count + 1))
    [[ "$viability_src" == "agents" ]] && tier_count=$((tier_count + 1))
    [[ "$demand_src" != "unknown" ]] && tier_count=$((tier_count + 1))

    local score
    if [[ "$demand_src" != "unknown" ]]; then
        # Demand data available
        if $has_visual && $has_behavioral; then
            # All tiers: d*35 + c*20 + visual*12 + behavioral*8 + viability*10 + demand*15
            score=$(( delivery * 35 / 100 + craft * 20 / 100 + visual * 12 / 100 + behavioral * 8 / 100 + viability * 10 / 100 + demand * 15 / 100 ))
        elif ! $has_visual && ! $has_behavioral; then
            # No visual/behavioral: d*45 + c*25 + viability*15 + demand*15
            score=$(( delivery * 45 / 100 + craft * 25 / 100 + viability * 15 / 100 + demand * 15 / 100 ))
        else
            # Partial: weighted average of what's available
            local total_weight=0 weighted_sum=0
            weighted_sum=$(( delivery * 35 + craft * 20 ))
            total_weight=55
            if $has_visual; then
                weighted_sum=$(( weighted_sum + visual * 12 ))
                total_weight=$(( total_weight + 12 ))
            fi
            if $has_behavioral; then
                weighted_sum=$(( weighted_sum + behavioral * 8 ))
                total_weight=$(( total_weight + 8 ))
            fi
            weighted_sum=$(( weighted_sum + viability * 10 + demand * 15 ))
            total_weight=$(( total_weight + 10 + 15 ))
            score=$(( weighted_sum / total_weight ))
        fi
    else
        # No demand data — redistribute: +10% to delivery, +5% to viability
        if $has_visual && $has_behavioral; then
            # d*45 + c*20 + visual*12 + behavioral*8 + viability*15
            score=$(( delivery * 45 / 100 + craft * 20 / 100 + visual * 12 / 100 + behavioral * 8 / 100 + viability * 15 / 100 ))
        elif ! $has_visual && ! $has_behavioral; then
            # d*55 + c*30 + viability*15
            score=$(( delivery * 55 / 100 + craft * 30 / 100 + viability * 15 / 100 ))
        else
            # Partial: weighted average of what's available
            local total_weight=0 weighted_sum=0
            weighted_sum=$(( delivery * 45 + craft * 20 ))
            total_weight=65
            if $has_visual; then
                weighted_sum=$(( weighted_sum + visual * 12 ))
                total_weight=$(( total_weight + 12 ))
            fi
            if $has_behavioral; then
                weighted_sum=$(( weighted_sum + behavioral * 8 ))
                total_weight=$(( total_weight + 8 ))
            fi
            weighted_sum=$(( weighted_sum + viability * 15 ))
            total_weight=$(( total_weight + 15 ))
            score=$(( weighted_sum / total_weight ))
        fi
    fi

    # Clamp
    [[ $score -gt 100 ]] && score=100
    [[ $score -lt 0 ]] && score=0

    # Confidence from tier count
    local confidence
    if [[ $tier_count -ge 6 ]]; then
        confidence="high"
    elif [[ $tier_count -ge 4 ]]; then
        confidence="medium"
    else
        confidence="low"
    fi

    # Output JSON
    local vis_out beh_out
    $has_visual && vis_out="$visual" || vis_out="null"
    $has_behavioral && beh_out="$behavioral" || beh_out="null"

    # Read top recommendation from eval cache if available
    local top_rec="null"
    if [[ "$_eval_cache_valid" == true ]]; then
        local rec_item
        rec_item=$(jq -r --arg f "$feat" '.[$f].recommendations.items[0] // empty' "$EVAL_CACHE" 2>/dev/null)
        if [[ -n "$rec_item" ]]; then
            top_rec=$(jq -c --arg f "$feat" '.[$f].recommendations.items[0]' "$EVAL_CACHE" 2>/dev/null)
        fi
    fi

    # Eval age and staleness
    local eval_age stale_flag
    eval_age=$(get_eval_age_days "$feat")
    if [[ "$eval_age" -gt 7 ]]; then
        stale_flag="true"
    else
        stale_flag="false"
    fi

    # Effective weight: halved when stale
    local raw_weight effective_weight
    raw_weight=$(get_feature_weight "$feat")
    if [[ "$stale_flag" == "true" ]]; then
        effective_weight=$(( (raw_weight + 1) / 2 ))  # ceiling division
    else
        effective_weight=$raw_weight
    fi

    echo "{\"feature\":\"$feat\",\"score\":$score,\"delivery\":$delivery,\"craft\":$craft,\"visual\":$vis_out,\"behavioral\":$beh_out,\"viability\":$viability,\"viability_source\":\"$viability_src\",\"demand\":$demand,\"demand_source\":\"$demand_src\",\"confidence\":\"$confidence\",\"tiers\":$tier_count,\"weight\":$raw_weight,\"effective_weight\":$effective_weight,\"confidence_interval\":$ci,\"top_recommendation\":$top_rec,\"eval_age_days\":$eval_age,\"stale\":$stale_flag}"
}

# --- Main ---
features=$(get_active_features)
if [[ -n "$TARGET_FEATURE" ]]; then
    features="$TARGET_FEATURE"
fi

# Collect results into arrays for both output modes
_feat_names=()
_feat_results=()
product_weighted_sum=0
product_total_weight=0
min_tiers=5
_max_eval_age=0

while IFS= read -r feat; do
    [[ -z "$feat" ]] && continue

    result=$(compute_feature_score "$feat")
    feat_score=$(echo "$result" | jq -r '.score')
    feat_weight=$(echo "$result" | jq -r '.effective_weight')
    feat_tiers=$(echo "$result" | jq -r '.tiers')

    _feat_names+=("$feat")
    _feat_results+=("$result")

    product_weighted_sum=$(( product_weighted_sum + feat_score * feat_weight ))
    product_total_weight=$(( product_total_weight + feat_weight ))
    [[ $feat_tiers -lt $min_tiers ]] && min_tiers=$feat_tiers
    # Track max eval age for staleness header
    _feat_age=$(echo "$result" | jq -r '.eval_age_days')
    [[ "$_feat_age" -gt "$_max_eval_age" ]] && _max_eval_age=$_feat_age
done <<< "$features"

# Product total
if [[ $product_total_weight -gt 0 ]]; then
    product_score=$(( product_weighted_sum / product_total_weight ))
else
    product_score=0
fi

# Product confidence from minimum tier count
product_confidence="high"
[[ $min_tiers -lt 6 ]] && product_confidence="medium"
[[ $min_tiers -lt 4 ]] && product_confidence="low"

# --- Read outside-in opportunity context ---
OUTSIDE_IN="$PROJECT_DIR/.claude/cache/outside-in.json"
_opp_journey_gaps=0
_opp_unmet_needs=0
_opp_top_signal=""
if [[ -f "$OUTSIDE_IN" ]] && command -v jq &>/dev/null; then
    _opp_journey_gaps=$(jq -r '.journey_gaps | length // 0' "$OUTSIDE_IN" 2>/dev/null || echo "0")
    _opp_unmet_needs=$(jq -r '.unmet_needs | length // 0' "$OUTSIDE_IN" 2>/dev/null || echo "0")
    _opp_top_signal=$(jq -r '(.market_opportunities // [])[0].signal // empty' "$OUTSIDE_IN" 2>/dev/null || true)
fi

# --- First-run guidance: no eval data yet ---
if [[ "$_eval_cache_empty" == true && "$OUTPUT_MODE" == "text" ]]; then
    echo ""
    echo "  No eval data yet. Run /eval to score your features."
    echo ""
    exit 0
elif [[ "$_eval_cache_empty" == true ]]; then
    echo "{\"synthesized_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"features\":{},\"product_score\":0,\"confidence\":\"none\",\"message\":\"No eval data yet. Run /eval to score your features.\",\"tiers_filled\":0,\"total_weight\":0,\"opportunity_context\":null}"
    exit 0
fi

if [[ "$OUTPUT_MODE" == "text" ]]; then
    # --- Formatted text output (voice.md compliant) ---
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_GREEN='\033[0;32m'
    _C_YELLOW='\033[1;33m'
    _C_RED='\033[0;31m'
    _C_NC='\033[0m'

    # Score bar helper (compact: 12 chars)
    _score_bar() {
        local s=${1:-0}
        local filled=$(( (s + 4) / 8 ))
        [[ $filled -gt 12 ]] && filled=12
        local empty=$((12 - filled))
        local color="$_C_RED"
        [[ $s -ge 50 ]] && color="$_C_YELLOW"
        [[ $s -ge 80 ]] && color="$_C_GREEN"
        local bar="" trail=""
        for ((_b=0; _b<filled; _b++)); do bar="${bar}█"; done
        for ((_b=0; _b<empty; _b++)); do trail="${trail}░"; done
        printf "${color}${bar}${_C_DIM}${trail}${_C_NC}"
    }

    # Big score bar (20 chars) for header
    _score_bar_lg() {
        local s=${1:-0}
        local filled=$(( (s + 2) / 5 ))
        [[ $filled -gt 20 ]] && filled=20
        local empty=$((20 - filled))
        local color="$_C_RED"
        [[ $s -ge 50 ]] && color="$_C_YELLOW"
        [[ $s -ge 80 ]] && color="$_C_GREEN"
        local bar="" trail=""
        for ((_b=0; _b<filled; _b++)); do bar="${bar}█"; done
        for ((_b=0; _b<empty; _b++)); do trail="${trail}░"; done
        printf "${color}${bar}${_C_DIM}${trail}${_C_NC}"
    }

    # Color a score value — right-aligned in 2 chars
    _color_s() {
        local s=${1:-0}
        if [[ $s -ge 80 ]]; then printf "${_C_GREEN}%2d${_C_NC}" "$s"
        elif [[ $s -ge 50 ]]; then printf "${_C_YELLOW}%2d${_C_NC}" "$s"
        else printf "${_C_RED}%2d${_C_NC}" "$s"; fi
    }

    # Tier fill badge
    _tier_badge() {
        local n=${1:-0} out=""
        for ((_t=0; _t<n; _t++)); do out="${out}●"; done
        for ((_t=n; _t<6; _t++)); do out="${out}○"; done
        echo "$out"
    }

    _SEP="${_C_DIM}  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${_C_NC}"

    # --- Header (dual-path: eval score + belief pass rate) ---
    echo ""
    echo -e "${_SEP}"
    echo -e "  ${_C_BOLD}${product_score}${_C_NC}${_C_DIM}/100${_C_NC}  $(_score_bar_lg $product_score)  ${_C_DIM}$(_tier_badge $min_tiers)${_C_NC}"
    # Dual-path line: beliefs + eval avg
    echo -e "  ${_C_DIM}beliefs: ${_belief_pass}/${_belief_total} (${_belief_score}%)  ·  eval: ${product_score} avg${_C_NC}"
    # Overall staleness from oldest eval cache
    if [[ "$_max_eval_age" -gt 7 ]]; then
        echo -e "  ${_C_YELLOW}⚠ eval data up to ${_max_eval_age}d old — run /eval to refresh${_C_NC}"
    elif [[ "$_max_eval_age" -gt 3 ]]; then
        echo -e "  ${_C_DIM}eval data up to ${_max_eval_age}d old${_C_NC}"
    fi
    echo -e "${_SEP}"
    echo ""

    # --- Formula line ---
    # Determine which formula variant is active based on available tiers
    _has_vis_global=false _has_beh_global=false
    _vis_global=$(get_visual_score)
    _beh_global=$(get_behavioral_score)
    [[ "$_vis_global" == "-1" ]] && _has_vis_global=false
    [[ "$_beh_global" == "-1" ]] && _has_beh_global=false

    # Detect global demand availability
    _has_dem_global=false
    # Check first feature for demand source (representative)
    if [[ ${#_feat_results[@]} -gt 0 ]]; then
        _dem_src_global=$(echo "${_feat_results[0]}" | jq -r '.demand_source')
        [[ "$_dem_src_global" != "unknown" ]] && _has_dem_global=true
    fi

    if $_has_vis_global && $_has_beh_global && $_has_dem_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×35% + c×20% + visual×12% + behavioral×8% + viability×10% + demand×15%"
    elif $_has_vis_global && $_has_beh_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×45% + c×20% + visual×12% + behavioral×8% + viability×15%  ${_C_DIM}(no demand — run /demand to unlock)${_C_NC}"
    elif ! $_has_vis_global && ! $_has_beh_global && $_has_dem_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×45% + c×25% + viability×15% + demand×15%  ${_C_DIM}(no visual/behavioral — run /taste to unlock)${_C_NC}"
    elif ! $_has_vis_global && ! $_has_beh_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×55% + c×30% + viability×15%  ${_C_DIM}(no visual/behavioral/demand — run /taste and /demand to unlock)${_C_NC}"
    elif $_has_vis_global && $_has_dem_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×35% + c×20% + visual×12% + viability×10% + demand×15%  ${_C_DIM}(no behavioral — run /taste flows to unlock)${_C_NC}"
    elif $_has_vis_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×45% + c×20% + visual×12% + viability×15%  ${_C_DIM}(no behavioral/demand — run /taste flows and /demand to unlock)${_C_NC}"
    elif $_has_beh_global && $_has_dem_global; then
        echo -e "  ${_C_DIM}formula${_C_NC}  d×35% + c×20% + behavioral×8% + viability×10% + demand×15%  ${_C_DIM}(no visual — run /taste to unlock)${_C_NC}"
    else
        echo -e "  ${_C_DIM}formula${_C_NC}  d×45% + c×20% + behavioral×8% + viability×15%  ${_C_DIM}(no visual/demand — run /taste and /demand to unlock)${_C_NC}"
    fi
    echo ""

    # --- Table header ---
    echo -e "  ${_C_DIM}                                    delivery  craft  viability  demand${_C_NC}"

    # --- Sort features worst to best + track biggest mover ---
    _bottleneck_feat="" _bottleneck_score=101
    _sorted_indices=()
    # Track weighted gap per dimension for "biggest mover" recommendation
    _best_mover_dim="" _best_mover_impact=0 _best_mover_action=""
    for ((_i=0; _i<${#_feat_names[@]}; _i++)); do
        _fs=$(echo "${_feat_results[$_i]}" | jq -r '.score')
        _sorted_indices+=("${_fs}:${_i}")
    done
    IFS=$'\n' _sorted_indices=($(sort -t: -k1 -n <<< "${_sorted_indices[*]}")); unset IFS

    # --- Table rows ---
    for _si in "${_sorted_indices[@]}"; do
        _i="${_si#*:}"
        _fn="${_feat_names[$_i]}"
        _fr="${_feat_results[$_i]}"
        _fs=$(echo "$_fr" | jq -r '.score')
        _fd=$(echo "$_fr" | jq -r '.delivery')
        _fc=$(echo "$_fr" | jq -r '.craft')
        _fv=$(echo "$_fr" | jq -r '.viability')
        _fvs=$(echo "$_fr" | jq -r '.viability_source')
        _fdem=$(echo "$_fr" | jq -r '.demand')
        _fdems=$(echo "$_fr" | jq -r '.demand_source')
        _fw=$(echo "$_fr" | jq -r '.weight')
        _few=$(echo "$_fr" | jq -r '.effective_weight')
        _fci=$(echo "$_fr" | jq -r '.confidence_interval')
        _fage=$(echo "$_fr" | jq -r '.eval_age_days')
        _fstale=$(echo "$_fr" | jq -r '.stale')

        if [[ "$_fs" -lt "$_bottleneck_score" ]]; then
            _bottleneck_score=$_fs
            _bottleneck_feat=$_fn
        fi

        # Viability suffix — explain source/cap reason
        _via_suf=""
        if [[ "$_fvs" == "capped" ]]; then
            _via_suf=" ${_C_RED}capped${_C_NC}"
        elif [[ "$_fvs" == "intelligence" ]]; then
            _via_suf=" ${_C_DIM}~intel${_C_NC}"
        fi

        # Weight dots: ● for each weight point
        _wdots=""
        for ((_w=0; _w<_fw; _w++)); do _wdots="${_wdots}●"; done

        # Confidence interval suffix
        _ci_suf=""
        if [[ "$_fci" -gt 0 ]]; then
            _ci_suf=" ${_C_DIM}±${_fci}${_C_NC}"
        fi

        # Stale tag and weight penalty indicator
        _stale_suf=""
        if [[ "$_fstale" == "true" ]]; then
            _stale_suf=" ${_C_YELLOW}(stale)${_C_NC}"
        fi

        # Row: name  score+bar  d  c  v  weight
        # Use fixed-width segments to keep alignment despite ANSI codes
        _name_pad="$(printf '%-12s' "$_fn")"
        echo -ne "  ${_C_BOLD}${_name_pad}${_C_NC} $(_color_s $_fs)${_ci_suf} $(_score_bar $_fs)"
        # Demand suffix — explain source
        _dem_suf=""
        if [[ "$_fdems" == "unknown" ]]; then
            _dem_suf=" ${_C_RED}none${_C_NC}"
        elif [[ "$_fdems" == tier-* ]]; then
            _dem_suf=" ${_C_DIM}~${_fdems#tier-}${_C_NC}"
        fi
        echo -ne "      $(_color_s $_fd)      $(_color_s $_fc)       $(_color_s $_fv)${_via_suf}      $(_color_s $_fdem)${_dem_suf}"
        # Staleness indicator
        _age_suf=""
        if [[ "$_fstale" == "true" ]]; then
            _age_suf="${_stale_suf}"
        elif [[ "$_fage" -gt 3 ]]; then
            _age_suf=" ${_C_DIM}(${_fage}d old)${_C_NC}"
        fi
        echo -e "  ${_C_DIM}${_wdots}${_C_NC}${_age_suf}"

        # --- Compute biggest mover for this feature ---
        # Impact = weight_pct × gap_from_100 for each dimension
        # Use the active formula weights to determine which dimension gains the most
        _dem_impact=0
        if $_has_dem_global && $_has_vis_global && $_has_beh_global; then
            _d_impact=$(( (100 - _fd) * 35 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 10 * _fw / 100 ))
            _vis_impact=$(( (100 - _vis_global) * 12 * _fw / 100 ))
            _beh_impact=$(( (100 - _beh_global) * 8 * _fw / 100 ))
            _dem_impact=$(( (100 - _fdem) * 15 * _fw / 100 ))
        elif $_has_dem_global && $_has_vis_global; then
            _d_impact=$(( (100 - _fd) * 35 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 10 * _fw / 100 ))
            _vis_impact=$(( (100 - _vis_global) * 12 * _fw / 100 ))
            _beh_impact=0
            _dem_impact=$(( (100 - _fdem) * 15 * _fw / 100 ))
        elif $_has_dem_global && $_has_beh_global; then
            _d_impact=$(( (100 - _fd) * 35 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 10 * _fw / 100 ))
            _vis_impact=0
            _beh_impact=$(( (100 - _beh_global) * 8 * _fw / 100 ))
            _dem_impact=$(( (100 - _fdem) * 15 * _fw / 100 ))
        elif $_has_dem_global; then
            _d_impact=$(( (100 - _fd) * 45 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 25 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 15 * _fw / 100 ))
            _vis_impact=0
            _beh_impact=0
            _dem_impact=$(( (100 - _fdem) * 15 * _fw / 100 ))
        elif $_has_vis_global && $_has_beh_global; then
            _d_impact=$(( (100 - _fd) * 45 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 15 * _fw / 100 ))
            _vis_impact=$(( (100 - _vis_global) * 12 * _fw / 100 ))
            _beh_impact=$(( (100 - _beh_global) * 8 * _fw / 100 ))
        elif $_has_vis_global; then
            _d_impact=$(( (100 - _fd) * 45 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 15 * _fw / 100 ))
            _vis_impact=$(( (100 - _vis_global) * 12 * _fw / 100 ))
            _beh_impact=0
        elif $_has_beh_global; then
            _d_impact=$(( (100 - _fd) * 45 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 20 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 15 * _fw / 100 ))
            _vis_impact=0
            _beh_impact=$(( (100 - _beh_global) * 8 * _fw / 100 ))
        else
            _d_impact=$(( (100 - _fd) * 55 * _fw / 100 ))
            _c_impact=$(( (100 - _fc) * 30 * _fw / 100 ))
            _v_impact=$(( (100 - _fv) * 15 * _fw / 100 ))
            _vis_impact=0
            _beh_impact=0
        fi

        if [[ $_d_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_d_impact
            _best_mover_dim="delivery"
            _best_mover_action="/eval ${_fn} — delivery at ${_fd}, weight ${_fw}"
        fi
        if [[ $_c_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_c_impact
            _best_mover_dim="craft"
            _best_mover_action="/eval ${_fn} — craft at ${_fc}, weight ${_fw}"
        fi
        if [[ $_v_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_v_impact
            _best_mover_dim="viability"
            _best_mover_action="/research ${_fn} — viability at ${_fv}, weight ${_fw}"
        fi
        if [[ $_vis_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_vis_impact
            _best_mover_dim="visual"
            _best_mover_action="/taste — visual at ${_vis_global}"
        fi
        if [[ $_beh_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_beh_impact
            _best_mover_dim="behavioral"
            _best_mover_action="/taste flows — behavioral at ${_beh_global}"
        fi
        if [[ $_dem_impact -gt $_best_mover_impact ]]; then
            _best_mover_impact=$_dem_impact
            _best_mover_dim="demand"
            _best_mover_action="/demand — demand at ${_fdem}"
        fi
    done

    echo ""

    # --- Viability explanation (if any feature has capped viability) ---
    _any_capped=false
    for ((_i=0; _i<${#_feat_results[@]}; _i++)); do
        _fvs_chk=$(echo "${_feat_results[$_i]}" | jq -r '.viability_source')
        [[ "$_fvs_chk" == "capped" ]] && _any_capped=true && break
    done
    if $_any_capped; then
        echo -e "  ${_C_YELLOW}viability capped at 30 — no market data. Run /research to unlock${_C_NC}"
        echo ""
    fi

    # --- Footer ---
    echo -e "${_SEP}"

    # Bottleneck
    if [[ -n "$_bottleneck_feat" ]]; then
        echo -e "  ${_C_DIM}bottleneck${_C_NC}  ${_C_BOLD}${_bottleneck_feat}${_C_NC} at $(_color_s $_bottleneck_score)  ${_C_DIM}· /plan ${_bottleneck_feat}${_C_NC}"
    fi

    # Biggest mover recommendation
    if [[ -n "$_best_mover_dim" ]]; then
        echo -e "  ${_C_DIM}best move${_C_NC}   improve ${_C_BOLD}${_best_mover_dim}${_C_NC}  ${_C_DIM}· ${_best_mover_action}${_C_NC}"
    fi

    # Opportunity context
    if [[ "$_opp_journey_gaps" -gt 0 || "$_opp_unmet_needs" -gt 0 ]]; then
        _opp_parts=""
        [[ "$_opp_journey_gaps" -gt 0 ]] && _opp_parts="${_opp_journey_gaps} journey gaps"
        if [[ "$_opp_unmet_needs" -gt 0 ]]; then
            [[ -n "$_opp_parts" ]] && _opp_parts="$_opp_parts · "
            _opp_parts="${_opp_parts}${_opp_unmet_needs} unmet needs"
        fi
        [[ -n "$_opp_top_signal" ]] && _opp_parts="$_opp_parts · ${_opp_top_signal}"
        echo -e "  ${_C_DIM}opportunity${_C_NC} ${_opp_parts}"
    fi

    echo -e "${_SEP}"
    echo ""
else
    # --- JSON output (default) ---
    echo "{"
    echo "  \"synthesized_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"features\": {"

    first=true
    for ((_i=0; _i<${#_feat_names[@]}; _i++)); do
        $first || echo ","
        first=false
        echo -n "    \"${_feat_names[$_i]}\": ${_feat_results[$_i]}"
    done

    echo ""
    echo "  },"
    echo "  \"product_score\": $product_score,"
    echo "  \"belief_score\": $_belief_score,"
    echo "  \"belief_pass\": $_belief_pass,"
    echo "  \"belief_total\": $_belief_total,"
    echo "  \"confidence\": \"$product_confidence\","
    echo "  \"tiers_filled\": $min_tiers,"
    echo "  \"total_weight\": $product_total_weight,"

    # Opportunity context from outside-in analysis
    if [[ -f "$OUTSIDE_IN" ]] && command -v jq &>/dev/null; then
        _opp_json=$(jq -c '{journey_gaps: (.journey_gaps | length), unmet_needs: (.unmet_needs | length), market_opportunities: (.market_opportunities | length)}' "$OUTSIDE_IN" 2>/dev/null)
        if [[ -n "$_opp_json" && "$_opp_json" != "null" ]]; then
            echo "  \"opportunity_context\": $_opp_json"
        else
            echo "  \"opportunity_context\": null"
        fi
    else
        echo "  \"opportunity_context\": null"
    fi
    echo "}"
fi
