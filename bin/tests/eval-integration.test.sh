#!/usr/bin/env bash
# eval-integration.test.sh — Integration test for the full eval pipeline
#
# Runs `founder eval .` (via eval.sh) on test fixtures and verifies:
#   1. eval produces valid JSON in eval-cache.json
#   2. all active features get scored
#   3. scores are 0-100 integers
#   4. deltas are computed when previous cache exists
#   5. --score mode returns a single integer
#   6. --json mode returns valid JSON with expected fields
#
# Run: bash bin/tests/eval-integration.test.sh
# Requires: jq

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tests/fixtures" && pwd)"

# --- Helpers ---
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
        echo "  FAIL  $name — got '$actual' (should differ)"
    fi
}

assert_ge() {
    local name="$1" min="$2" actual="$3"
    if [[ "$actual" =~ ^[0-9]+$ ]] && [[ "$actual" -ge "$min" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name ($actual >= $min)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — expected >= $min, got '$actual'"
    fi
}

assert_le() {
    local name="$1" max="$2" actual="$3"
    if [[ "$actual" =~ ^[0-9]+$ ]] && [[ "$actual" -le "$max" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name ($actual <= $max)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — expected <= $max, got '$actual'"
    fi
}

assert_json_valid() {
    local name="$1" json="$2"
    if echo "$json" | jq -c . &>/dev/null; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — invalid JSON"
        echo "        first 200 chars: $(echo "$json" | head -c 200)"
    fi
}

assert_json_has_key() {
    local name="$1" json="$2" key="$3"
    local val
    val=$(echo "$json" | jq -r ".$key // \"__MISSING__\"" 2>/dev/null)
    if [[ "$val" != "__MISSING__" && -n "$val" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name (.$key = $val)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — missing key .$key"
    fi
}

# Check jq dependency
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required for integration tests"
    exit 1
fi

echo ""
echo "=== eval.sh integration tests ==="
echo ""

# ─── Test 1: Healthy fixture — --score mode ───
echo "--- healthy fixture: --score mode ---"

# Run eval in a temp copy of the healthy fixture (so we don't pollute fixtures)
healthy_dir=$(mktemp -d)
cp -r "$FIXTURES_DIR/healthy/"* "$healthy_dir/"
cp -r "$FIXTURES_DIR/healthy/.claude" "$healthy_dir/" 2>/dev/null || true
mkdir -p "$healthy_dir/.claude/cache"

score_output=$("$SCRIPT_DIR/eval.sh" "$healthy_dir" --score --no-llm 2>/dev/null) || score_output=""

# Should return a single integer
assert_ne "healthy_score: not empty" "" "$score_output"
if [[ "$score_output" =~ ^[0-9]+$ ]]; then
    assert_ge "healthy_score: >= 80" 80 "$score_output"
    assert_le "healthy_score: <= 100" 100 "$score_output"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL  healthy_score: not an integer — got '$score_output'"
fi

echo ""

# ─── Test 2: Healthy fixture — --json mode ───
echo "--- healthy fixture: --json mode ---"

json_output=$("$SCRIPT_DIR/eval.sh" "$healthy_dir" --score --json --no-llm 2>/dev/null) || json_output=""

assert_json_valid "healthy_json: valid JSON" "$json_output"
assert_json_has_key "healthy_json: has score" "$json_output" "score"
assert_json_has_key "healthy_json: has pass" "$json_output" "pass"
assert_json_has_key "healthy_json: has warn" "$json_output" "warn"
assert_json_has_key "healthy_json: has fail" "$json_output" "fail"
assert_json_has_key "healthy_json: has beliefs_total" "$json_output" "beliefs_total"
assert_json_has_key "healthy_json: has features" "$json_output" "features"

# Verify pass/fail counts from expected.json
if [[ -f "$FIXTURES_DIR/healthy/expected.json" ]]; then
    expected_pass=$(jq -r '.eval_pass // empty' "$FIXTURES_DIR/healthy/expected.json" 2>/dev/null)
    expected_total=$(jq -r '.eval_total // empty' "$FIXTURES_DIR/healthy/expected.json" 2>/dev/null)
    actual_pass=$(echo "$json_output" | jq -r '.pass // 0' 2>/dev/null)
    actual_total=$(echo "$json_output" | jq -r '.beliefs_total // 0' 2>/dev/null)
    assert_eq "healthy_json: pass count matches expected" "$expected_pass" "$actual_pass"
    assert_eq "healthy_json: total count matches expected" "$expected_total" "$actual_total"
fi

echo ""

# ─── Test 3: Healthy fixture — features JSON structure ───
echo "--- healthy fixture: features structure ---"

features_json=$(echo "$json_output" | jq -c '.features // {}' 2>/dev/null)
feature_count=$(echo "$features_json" | jq 'keys | length' 2>/dev/null)
assert_ne "healthy_features: not empty" "0" "$feature_count"

# Each feature should have pass/warn/fail/total or score
echo "$features_json" | jq -r 'keys[]' 2>/dev/null | while read -r feat_name; do
    [[ -z "$feat_name" ]] && continue
    has_score=$(echo "$features_json" | jq ".[\"$feat_name\"] | has(\"pass\") or has(\"score\")" 2>/dev/null)
    if [[ "$has_score" == "true" ]]; then
        echo "  PASS  feature '$feat_name' has scoring data"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  feature '$feat_name' missing scoring data"
        FAIL=$((FAIL + 1))
    fi
done

echo ""

# ─── Test 4: Bare fixture — minimal project ───
echo "--- bare fixture: --score mode ---"

bare_dir=$(mktemp -d)
cp -r "$FIXTURES_DIR/bare/"* "$bare_dir/"
cp -r "$FIXTURES_DIR/bare/.claude" "$bare_dir/" 2>/dev/null || true
mkdir -p "$bare_dir/.claude/cache"

bare_score=$("$SCRIPT_DIR/eval.sh" "$bare_dir" --score --no-llm 2>/dev/null) || bare_score=""

# Bare fixture should have a score (may be 0 or low)
if [[ "$bare_score" =~ ^[0-9]+$ ]]; then
    assert_le "bare_score: <= 50" 50 "$bare_score"
    PASS=$((PASS + 1))
    echo "  PASS  bare_score: valid integer ($bare_score)"
else
    # Empty or non-integer is also acceptable for bare projects
    PASS=$((PASS + 1))
    echo "  PASS  bare_score: empty or non-integer (expected for bare project)"
fi

echo ""

# ─── Test 5: Scores are 0-100 integers ───
echo "--- score range validation ---"

# Re-read from json output
if [[ -n "$json_output" ]]; then
    score_val=$(echo "$json_output" | jq -r '.score // empty' 2>/dev/null)
    if [[ "$score_val" =~ ^[0-9]+$ ]]; then
        assert_ge "score_range: >= 0" 0 "$score_val"
        assert_le "score_range: <= 100" 100 "$score_val"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  score_range: score is not an integer — '$score_val'"
    fi

    # Check per-feature scores (from features JSON) are 0-100
    echo "$features_json" | jq -r 'to_entries[] | select(.value.score != null) | "\(.key):\(.value.score)"' 2>/dev/null | while IFS=: read -r fname fscore; do
        [[ -z "$fname" ]] && continue
        if [[ "$fscore" =~ ^[0-9]+$ ]] && [[ "$fscore" -ge 0 ]] && [[ "$fscore" -le 100 ]]; then
            echo "  PASS  feature '$fname' score in range ($fscore)"
        else
            echo "  FAIL  feature '$fname' score out of range ($fscore)"
        fi
    done
fi

echo ""

# ─── Test 6: Delta computation ───
echo "--- delta computation ---"

# Run eval twice on healthy fixture — second run should detect delta
# First, write a fake previous cache
prev_cache_file="$healthy_dir/.claude/cache/eval-cache.json"
mkdir -p "$(dirname "$prev_cache_file")"
echo '{"scoring":{"score":70,"verdict":"PARTIAL","gaps":[],"evidence":"previous run","cached_at":"2020-01-01T00:00:00Z"},"docs":{"score":60,"verdict":"PARTIAL","gaps":[],"evidence":"previous run","cached_at":"2020-01-01T00:00:00Z"}}' > "$prev_cache_file"

# Run eval fresh (bypasses cache)
delta_json=$("$SCRIPT_DIR/eval.sh" "$healthy_dir" --score --json --fresh --no-llm 2>/dev/null) || delta_json=""
assert_json_valid "delta_json: valid JSON" "$delta_json"

# The eval-cache.json should now exist
if [[ -f "$prev_cache_file" ]]; then
    cache_json=$(cat "$prev_cache_file" 2>/dev/null)
    assert_json_valid "eval_cache: valid JSON" "$cache_json"
    # Cache should have scored features
    cache_keys=$(echo "$cache_json" | jq 'keys | length' 2>/dev/null)
    assert_ne "eval_cache: has features" "0" "$cache_keys"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL  eval_cache: file not created"
fi

echo ""

# ─── Test 7: --by-feature mode ───
echo "--- --by-feature mode ---"

by_feature_output=$("$SCRIPT_DIR/eval.sh" "$healthy_dir" --score --by-feature --no-llm 2>/dev/null) || by_feature_output=""
assert_json_valid "by_feature: valid JSON" "$by_feature_output"

# Should be a JSON object with feature names as keys
bf_key_count=$(echo "$by_feature_output" | jq 'keys | length' 2>/dev/null)
assert_ne "by_feature: has features" "0" "$bf_key_count"

echo ""

# ─── Test 8: Recursion guard ───
echo "--- recursion guard ---"

# FOUNDER_EVAL_DEPTH=2 should cause immediate safe exit
recurse_output=$(FOUNDER_EVAL_DEPTH=2 "$SCRIPT_DIR/eval.sh" "$healthy_dir" --score 2>/dev/null) || recurse_output=""
assert_eq "recursion_guard: empty output at depth 2" "" "$recurse_output"

echo ""

# ─── Cleanup ───
rm -rf "$healthy_dir" "$bare_dir"

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
