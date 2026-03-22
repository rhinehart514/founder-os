#!/usr/bin/env bash
# cross-validate.sh — Detect divergence between scoring tiers
# Usage: cross-validate.sh [project-dir] [--json]
#
# Reads score-cache.json (belief pass rate), eval-cache.json (generative scores),
# and latest taste report. Flags pairwise divergence >15 points.

set -uo pipefail

PROJECT_DIR="${1:-.}"
OUTPUT_MODE="text"
[[ "${2:-}" == "--json" ]] && OUTPUT_MODE="json"

SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
TASTE_DIR="$PROJECT_DIR/.claude/evals/reports"

# --- ANSI (text mode only) ---
_C_BOLD='\033[1m'
_C_DIM='\033[2m'
_C_YELLOW='\033[1;33m'
_C_NC='\033[0m'

# --- Read belief pass rate ---
belief_pct=-1
belief_pass=0
belief_total=0
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    belief_pass=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null)
    belief_total=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null)
    if [[ "$belief_total" -gt 0 ]]; then
        belief_pct=$(( belief_pass * 100 / belief_total ))
    fi
fi

# --- Read eval average ---
eval_avg=-1
eval_count=0
if [[ -f "$EVAL_CACHE" ]] && jq empty "$EVAL_CACHE" 2>/dev/null; then
    eval_data=$(jq -r '[to_entries[] | .value.score // 0] | if length > 0 then {avg: (add / length | floor), count: length} else {avg: -1, count: 0} end' "$EVAL_CACHE" 2>/dev/null)
    eval_avg=$(echo "$eval_data" | jq -r '.avg')
    eval_count=$(echo "$eval_data" | jq -r '.count')
fi

# --- Read latest taste score ---
taste_score=-1
taste_source=""
# Check CLI taste first, then web taste
cli_latest=$(ls -t "$TASTE_DIR"/cli-taste-*.json 2>/dev/null | head -1)
if [[ -n "$cli_latest" ]]; then
    _ts=$(jq -r '.overall // -1' "$cli_latest" 2>/dev/null)
    if [[ "$_ts" != "-1" && "$_ts" != "null" ]]; then
        taste_score=$_ts
        taste_source="cli"
    fi
fi
if [[ "$taste_score" == "-1" ]]; then
    web_latest=$(ls -t "$TASTE_DIR"/taste-*.json 2>/dev/null | head -1)
    if [[ -n "$web_latest" ]]; then
        _ts=$(jq -r '[.dimensions // {} | to_entries[] | .value.score // 0] | if length > 0 then (add / length | floor) else -1 end' "$web_latest" 2>/dev/null)
        if [[ "$_ts" != "-1" && "$_ts" != "null" ]]; then
            taste_score=$_ts
            taste_source="web"
        fi
    fi
fi

# --- Compute pairwise divergences ---
divergences=()

# Belief vs Eval
if [[ "$belief_pct" -ge 0 && "$eval_avg" -ge 0 ]]; then
    diff=$(( belief_pct - eval_avg ))
    [[ $diff -lt 0 ]] && diff=$(( -diff ))
    if [[ $diff -gt 15 ]]; then
        if [[ $belief_pct -gt $eval_avg ]]; then
            msg="belief-eval divergence: beliefs ${belief_pct}% but eval avg ${eval_avg} — assertions don't cover eval gaps"
        else
            msg="belief-eval divergence: beliefs ${belief_pct}% but eval avg ${eval_avg} — eval may be over-scoring"
        fi
        divergences+=("{\"pair\":\"belief-eval\",\"belief\":$belief_pct,\"eval\":$eval_avg,\"delta\":$diff,\"message\":\"$msg\"}")
    fi
fi

# Belief vs Taste
if [[ "$belief_pct" -ge 0 && "$taste_score" -ge 0 ]]; then
    diff=$(( belief_pct - taste_score ))
    [[ $diff -lt 0 ]] && diff=$(( -diff ))
    if [[ $diff -gt 15 ]]; then
        if [[ $belief_pct -gt $taste_score ]]; then
            msg="belief-taste divergence: beliefs ${belief_pct}% but taste ${taste_score} — code works but product surface weak"
        else
            msg="belief-taste divergence: beliefs ${belief_pct}% but taste ${taste_score} — surface quality exceeds code coverage"
        fi
        divergences+=("{\"pair\":\"belief-taste\",\"belief\":$belief_pct,\"taste\":$taste_score,\"delta\":$diff,\"message\":\"$msg\"}")
    fi
fi

# Eval vs Taste
if [[ "$eval_avg" -ge 0 && "$taste_score" -ge 0 ]]; then
    diff=$(( eval_avg - taste_score ))
    [[ $diff -lt 0 ]] && diff=$(( -diff ))
    if [[ $diff -gt 15 ]]; then
        if [[ $eval_avg -gt $taste_score ]]; then
            msg="eval-taste divergence: eval avg ${eval_avg} but taste ${taste_score} — code quality ahead of product surface"
        else
            msg="eval-taste divergence: eval avg ${eval_avg} but taste ${taste_score} — surface quality ahead of code"
        fi
        divergences+=("{\"pair\":\"eval-taste\",\"eval\":$eval_avg,\"taste\":$taste_score,\"delta\":$diff,\"message\":\"$msg\"}")
    fi
fi

# --- Output ---
if [[ "$OUTPUT_MODE" == "json" ]]; then
    echo "{"
    echo "  \"validated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"belief_pct\": $belief_pct,"
    echo "  \"belief_pass\": $belief_pass,"
    echo "  \"belief_total\": $belief_total,"
    echo "  \"eval_avg\": $eval_avg,"
    echo "  \"eval_features\": $eval_count,"
    echo "  \"taste_score\": $taste_score,"
    echo "  \"taste_source\": \"$taste_source\","
    echo -n "  \"divergences\": ["
    first=true
    for d in "${divergences[@]+"${divergences[@]}"}"; do
        $first || echo -n ","
        first=false
        echo -n "$d"
    done
    echo "],"
    echo "  \"healthy\": $([ ${#divergences[@]} -eq 0 ] && echo "true" || echo "false")"
    echo "}"
else
    # Human-readable output
    echo ""
    echo -e "${_C_DIM}cross-validation${_C_NC}"
    echo -e "${_C_DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${_C_NC}"

    # Show tier values
    [[ "$belief_pct" -ge 0 ]] && echo -e "  ${_C_DIM}beliefs${_C_NC}  ${_C_BOLD}${belief_pass}/${belief_total}${_C_NC} ${_C_DIM}(${belief_pct}%)${_C_NC}"
    [[ "$eval_avg" -ge 0 ]] && echo -e "  ${_C_DIM}eval${_C_NC}     ${_C_BOLD}${eval_avg}${_C_NC} ${_C_DIM}avg across ${eval_count} features${_C_NC}"
    [[ "$taste_score" -ge 0 ]] && echo -e "  ${_C_DIM}taste${_C_NC}    ${_C_BOLD}${taste_score}${_C_NC} ${_C_DIM}(${taste_source})${_C_NC}"
    echo ""

    if [[ ${#divergences[@]} -eq 0 ]]; then
        echo -e "  ${_C_DIM}no divergence >15 points — tiers aligned${_C_NC}"
    else
        for d in "${divergences[@]}"; do
            _msg=$(echo "$d" | jq -r '.message')
            echo -e "  ${_C_YELLOW}⚠${_C_NC} ${_msg}"
        done
    fi

    echo -e "${_C_DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${_C_NC}"
    echo ""
fi
