#!/usr/bin/env bash
set -uo pipefail

# bench.sh — Calibration check. Runs founder-os against frozen fixture repos,
# compares actual scores against expected ranges.
#
# Usage:
#   bench.sh              # visual output
#   bench.sh --json       # machine-readable

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _BENCH_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_BENCH_SOURCE" ]]; do
        _BENCH_SOURCE="$(readlink "$_BENCH_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_BENCH_SOURCE")/.." && pwd)"
fi

# --- Args ---
JSON_OUTPUT=false
for arg in "$@"; do
    case $arg in
        --json) JSON_OUTPUT=true ;;
    esac
done

# --- Colors ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

FIXTURE_DIR="$FOUNDER_DIR/tests/fixtures"
TOTAL=0
PASSED=0
RESULTS_JSON="["

if [[ "$JSON_OUTPUT" != "true" ]]; then
    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}founder bench${NC} ${DIM}— calibration check${NC}"
    echo ""
fi

for fixture in "$FIXTURE_DIR"/*/; do
    [[ ! -d "$fixture" ]] && continue
    name=$(basename "$fixture")
    expected_file="$fixture/expected.json"

    [[ ! -f "$expected_file" ]] && continue

    TOTAL=$((TOTAL + 1))

    # Read expected values
    exp_min=$(jq -r '.score_range[0]' "$expected_file" 2>/dev/null)
    exp_max=$(jq -r '.score_range[1]' "$expected_file" 2>/dev/null)
    exp_mode=$(jq -r '.scoring_mode' "$expected_file" 2>/dev/null)
    exp_eval_pass=$(jq -r '.eval_pass // "null"' "$expected_file" 2>/dev/null)
    exp_eval_total=$(jq -r '.eval_total // "null"' "$expected_file" 2>/dev/null)

    # Run score.sh against the fixture
    # Use --force to skip cache, --json for machine output
    score_json=$(cd "$fixture" && bash "$FOUNDER_DIR/bin/score.sh" . --json --force 2>/dev/null) || score_json=""


    actual_score=""
    actual_mode=""
    actual_eval_pass=""
    actual_eval_total=""

    if [[ -n "$score_json" ]] && command -v jq &>/dev/null; then
        actual_score=$(echo "$score_json" | jq -r '.score // -1' 2>/dev/null)
        actual_mode=$(echo "$score_json" | jq -r '.scoring_mode // "unknown"' 2>/dev/null)
        actual_eval_pass=$(echo "$score_json" | jq -r '.assertion_pass_count // 0' 2>/dev/null)
        actual_eval_total=$(echo "$score_json" | jq -r '.assertion_count // 0' 2>/dev/null)
    fi

    # Check if within expected range
    fixture_pass=true
    reason=""

    if [[ -z "$actual_score" || "$actual_score" == "-1" ]]; then
        fixture_pass=false
        reason="score.sh failed"
    elif [[ "$actual_score" -lt "$exp_min" || "$actual_score" -gt "$exp_max" ]]; then
        fixture_pass=false
        reason="score $actual_score outside [$exp_min, $exp_max]"
    fi

    # Check scoring mode matches
    if [[ "$exp_mode" != "null" && -n "$actual_mode" && "$actual_mode" != "$exp_mode" ]]; then
        fixture_pass=false
        reason="${reason:+$reason; }mode $actual_mode != expected $exp_mode"
    fi

    # Check eval pass count (only if expected is not null)
    if [[ "$exp_eval_pass" != "null" && -n "$actual_eval_pass" && "$actual_eval_pass" != "$exp_eval_pass" ]]; then
        fixture_pass=false
        reason="${reason:+$reason; }eval pass $actual_eval_pass != expected $exp_eval_pass"
    fi

    if [[ "$exp_eval_total" != "null" && -n "$actual_eval_total" && "$actual_eval_total" != "$exp_eval_total" ]]; then
        fixture_pass=false
        reason="${reason:+$reason; }eval total $actual_eval_total != expected $exp_eval_total"
    fi

    if $fixture_pass; then
        PASSED=$((PASSED + 1))
    fi

    # Output
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        range_str="${exp_min}-${exp_max}"
        if $fixture_pass; then
            echo -e "  ${GREEN}✓${NC} $(printf '%-12s' "$name") expected: $(printf '%-8s' "$range_str") actual: $(printf '%-4s' "$actual_score") ${DIM}${actual_mode}${NC}"
        else
            echo -e "  ${RED}✗${NC} $(printf '%-12s' "$name") expected: $(printf '%-8s' "$range_str") actual: $(printf '%-4s' "${actual_score:--}") ${RED}${reason}${NC}"
        fi
    fi

    # JSON result
    [[ "$TOTAL" -gt 1 ]] && RESULTS_JSON+=","
    RESULTS_JSON+="{\"fixture\":\"$name\",\"expected_min\":$exp_min,\"expected_max\":$exp_max,\"actual_score\":${actual_score:--1},\"actual_mode\":\"${actual_mode:-unknown}\",\"pass\":$($fixture_pass && echo true || echo false)${reason:+,\"reason\":\"$reason\"}}"

    # Clean up cache files created in fixture dirs
    rm -rf "$fixture/.claude/cache" "$fixture/.claude/scores" 2>/dev/null
done

RESULTS_JSON+="]"

# Calibration rate
calibration=0
[[ "$TOTAL" -gt 0 ]] && calibration=$((PASSED * 100 / TOTAL))

if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "{\"passed\":$PASSED,\"total\":$TOTAL,\"calibration\":$calibration,\"results\":$RESULTS_JSON}"
else
    echo ""
    if [[ "$PASSED" -eq "$TOTAL" ]]; then
        echo -e "  ${GREEN}Calibration: ${PASSED}/${TOTAL} (${calibration}%)${NC}"
    else
        echo -e "  ${YELLOW}Calibration: ${PASSED}/${TOTAL} (${calibration}%)${NC}"
    fi
    echo ""
fi
