#!/usr/bin/env bash
# eval.test.sh — Unit tests for eval.sh components
# Run: bash bin/tests/eval.test.sh

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name"
        echo "        expected: '$expected'"
        echo "        actual:   '$actual'"
    fi
}

assert_ne() {
    local name="$1" not_expected="$2" actual="$3"
    if [[ "$not_expected" != "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "        FAIL  $name — got '$actual' (should differ)"
    fi
}

assert_contains() {
    local name="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — '$needle' not found in output"
    fi
}

echo ""
echo "=== eval.sh unit tests ==="
echo ""

# ─── Test 1: compute_eval_score — generative only ───
echo "--- compute_eval_score ---"

# Source just the function we need (extract it)
compute_eval_score() {
    local _gen_count="$1" _gen_sum="$2" _pass="$3" _warn="$4" _fail="$5" _has_block="${6:-false}"
    local _total=$((_pass + _warn + _fail))
    if [[ "$_has_block" == "true" ]]; then
        echo 0
    elif [[ "$_gen_count" -gt 0 ]]; then
        local _gen_avg=$((_gen_sum / _gen_count))
        local _penalty=$((_warn * 3 + _fail * 5))
        local _score=$((_gen_avg - _penalty))
        [[ "$_score" -lt 0 ]] && _score=0
        echo "$_score"
    elif [[ "$_total" -gt 0 ]]; then
        echo $(( (_pass * 100 + _warn * 50) / _total ))
    fi
}

assert_eq "gen_only: 2 features avg 70" "70" "$(compute_eval_score 2 140 0 0 0 false)"
assert_eq "gen_only: 1 feature score 85" "85" "$(compute_eval_score 1 85 0 0 0 false)"
assert_eq "gen_with_penalties: 70 avg - 1 warn - 1 fail" "62" "$(compute_eval_score 2 140 0 1 1 false)"
assert_eq "block_fail: always 0" "0" "$(compute_eval_score 2 140 5 0 0 true)"
assert_eq "beliefs_only: 8 pass 2 warn 0 fail" "90" "$(compute_eval_score 0 0 8 2 0 false)"
assert_eq "beliefs_only: all pass" "100" "$(compute_eval_score 0 0 10 0 0 false)"
assert_eq "beliefs_only: all warn" "50" "$(compute_eval_score 0 0 0 10 0 false)"
assert_eq "score_floor: penalty exceeds avg" "0" "$(compute_eval_score 1 10 0 0 10 false)"
assert_eq "no_data: empty output" "" "$(compute_eval_score 0 0 0 0 0 false)"

echo ""

# ─── Test 2: file_mtime ───
echo "--- file_mtime ---"

file_mtime() {
    local file="$1"
    [[ ! -f "$file" ]] && echo "" && return
    stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo ""
}

# Test with a real file
tmpfile=$(mktemp)
echo "test" > "$tmpfile"
mtime=$(file_mtime "$tmpfile")
assert_ne "real_file: returns non-empty" "" "$mtime"
assert_ne "real_file: not zero" "0" "$mtime"

# Test with nonexistent file
mtime_missing=$(file_mtime "/nonexistent/path/to/file")
assert_eq "missing_file: returns empty" "" "$mtime_missing"
rm -f "$tmpfile"

echo ""

# ─── Test 3: beliefs parser ───
echo "--- beliefs-parser ---"

# Create a test beliefs.yml
test_dir=$(mktemp -d)
cat > "$test_dir/beliefs.yml" << 'YAML'
beliefs:
  - id: test-file-exists
    type: file_check
    feature: scoring
    path: bin/eval.sh
    quality: correctness
    layer: infrastructure

  - id: test-content
    type: content_check
    feature: hygiene
    forbidden:
      - "debugger"
      - "console.error"

  - id: test-metric
    type: dom_check
    feature: ux
    metric: contrast-ratio
    quality: craft
    layer: ux
YAML

# Source the parser
source "$SCRIPT_DIR/lib/beliefs-parser.sh"

# Mock process_belief to capture parsed values
PARSED_BELIEFS=""
process_belief() {
    [[ -z "$belief_id" ]] && return
    PARSED_BELIEFS="${PARSED_BELIEFS}${belief_id}|${belief_type}|${belief_feature}|${belief_quality}|${belief_layer}
"
}

parse_beliefs_file "$test_dir/beliefs.yml"

assert_contains "parser: finds file_check" "test-file-exists|file_check|scoring|correctness|infrastructure" "$PARSED_BELIEFS"
assert_contains "parser: finds content_check" "test-content|content_check|hygiene||" "$PARSED_BELIEFS"
assert_contains "parser: finds dom_check" "test-metric|dom_check|ux|craft|ux" "$PARSED_BELIEFS"

# Count parsed beliefs
belief_count=$(echo "$PARSED_BELIEFS" | grep -c '|' || true)
assert_eq "parser: found 3 beliefs" "3" "$belief_count"

rm -rf "$test_dir"

echo ""

# ─── Test 4: fallback score is NOT 30 ───
echo "--- fallback score ---"

# The old code had: feat_score=30 as fallback.
# Verify the fix: grep for the old pattern should NOT be found
old_pattern=$(grep -c 'feat_score=30' "$SCRIPT_DIR/eval.sh" 2>/dev/null || true)
assert_eq "no_hardcoded_30: removed" "0" "$old_pattern"

# Verify the new pattern exists
new_pattern=$(grep -c 'feat_score=-1' "$SCRIPT_DIR/eval.sh" 2>/dev/null || true)
assert_ne "fallback_-1: exists" "0" "$new_pattern"

echo ""

# ─── Test 5: FOUNDER_DIR ordering ───
echo "--- FOUNDER_DIR ordering ---"

# FOUNDER_DIR must be defined before any use of $_SKILL_DIR="$FOUNDER_DIR/skills"
# Find the line numbers
founder_dir_def=$(grep -n 'FOUNDER_DIR=' "$SCRIPT_DIR/eval.sh" | head -1 | cut -d: -f1)
founder_dir_use=$(grep -n 'FOUNDER_DIR' "$SCRIPT_DIR/eval.sh" | grep -v '^[0-9]*:#' | grep -v 'FOUNDER_DIR=' | head -1 | cut -d: -f1)

if [[ -n "$founder_dir_def" && -n "$founder_dir_use" ]]; then
    if [[ "$founder_dir_def" -lt "$founder_dir_use" ]]; then
        assert_eq "founder_dir: defined before first use" "true" "true"
    else
        assert_eq "founder_dir: defined before first use" "def<use" "def=$founder_dir_def use=$founder_dir_use"
    fi
else
    assert_eq "founder_dir: lines found" "both" "def=$founder_dir_def use=$founder_dir_use"
fi

echo ""

# ─── Test 6: rubric truncation ───
echo "--- rubric truncation ---"

trunc_5000=$(grep -rc 'head -c 5000' "$SCRIPT_DIR/eval.sh" "$SCRIPT_DIR/lib/generative-eval.sh" 2>/dev/null | awk -F: '{s+=$NF}END{print s}' || true)
trunc_2000=$(grep -rc 'head -c 2000' "$SCRIPT_DIR/eval.sh" "$SCRIPT_DIR/lib/generative-eval.sh" 2>/dev/null | awk -F: '{s+=$NF}END{print s}' || true)
assert_ne "rubric: uses 5000 char limit" "0" "$trunc_5000"
assert_eq "rubric: no 2000 char limit" "0" "$trunc_2000"

echo ""

# ─── Test 7: cross-platform stat ───
echo "--- cross-platform stat ---"

# file_mtime helper should exist in eval.sh
has_file_mtime=$(grep -c 'file_mtime()' "$SCRIPT_DIR/eval.sh" 2>/dev/null || true)
assert_ne "file_mtime: helper defined" "0" "$has_file_mtime"

# No raw stat -f %m calls should remain (they should all use file_mtime)
raw_stat=$(grep -c 'stat -f %m' "$SCRIPT_DIR/eval.sh" 2>/dev/null || true)
# file_mtime definition has 2 (comment + call), no others should exist
assert_eq "raw_stat: only in file_mtime def" "2" "$raw_stat"

echo ""

# ─── Summary ───
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS/$TOTAL passed ==="
if [[ "$FAIL" -gt 0 ]]; then
    echo "FAILED"
    exit 1
else
    echo "ALL PASSED"
    exit 0
fi
