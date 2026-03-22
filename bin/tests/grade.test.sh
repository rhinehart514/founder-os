#!/usr/bin/env bash
# grade.test.sh — Tests for bin/grade.sh parse_claim, grading logic, and consolidation.
#
# Usage: bash bin/tests/grade.test.sh
#
# Tests source grade.sh functions in isolation using temp fixtures.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRADE_SH="$SCRIPT_DIR/../grade.sh"
PASS=0
FAIL=0
TOTAL=0

# Colors (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} $test_name"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} $test_name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_contains() {
    local test_name="$1" needle="$2" haystack="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "$haystack" == *"$needle"* ]]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} $test_name"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} $test_name"
        echo "    expected to contain: $needle"
        echo "    actual: $haystack"
    fi
}

# ---- Source grade.sh functions (we need to stub out the main execution) ----
# Extract just the functions by sourcing in a subshell with traps
extract_functions() {
    # Create a modified version that only defines functions (skip main execution)
    local tmp_funcs
    tmp_funcs=$(mktemp)

    # Extract function definitions and skip main execution code.
    # We keep everything except: set -uo pipefail, variable defaults, the main while loop,
    # the mv/rm at the end, and the direct calls to consolidate/detect.
    awk '
    /^set -uo pipefail/ { next }
    /^QUIET=/ { next }
    /^if \[\[.*--quiet/ { skip=1; next }
    skip && /^fi$/ { skip=0; next }
    skip { next }
    /^SCRIPT_DIR=/ { next }
    /^PROJECT_DIR=.*SCRIPT_DIR/ { next }
    /^PRED_FILE=.*1:-/ { next }
    /^HISTORY_FILE=.*2:-/ { next }
    /^CACHE_FILE=.*3:-/ { next }
    /^if \[\[.*PRED_FILE/ { skip=1; next }
    /^UNGRADED=/ { skip=1; next }
    /^\$QUIET/ { next }
    # Skip the main processing loop (TEMP_FILE through done < "$PRED_FILE")
    /^TEMP_FILE=\$\(mktemp\)/ { in_main=1; next }
    in_main && /^done < "\$PRED_FILE"/ { in_main=0; next }
    in_main { next }
    # Skip the atomic write block and direct function calls at the end
    /^if \[\[ "\$GRADED_COUNT"/ { skip=1; next }
    /^consolidate_knowledge$/ { next }
    /^detect_stale_entries$/ { next }
    {print}
    ' "$GRADE_SH" > "$tmp_funcs"

    # Source it
    source "$tmp_funcs"
    rm -f "$tmp_funcs"
}

# Set up temp dirs
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# ================================================================
echo "== parse_claim tests =="
# ================================================================

# Source functions
QUIET=true
PRED_FILE="$TEMP_DIR/predictions.tsv"
HISTORY_FILE="$TEMP_DIR/history.tsv"
CACHE_FILE="$TEMP_DIR/score-cache.json"
PROJECT_DIR="$TEMP_DIR"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GRADED_COUNT=0
extract_functions

# --- Tier 1: Numeric patterns ---

result=$(parse_claim "raise learning from 62 to 75")
assert_eq "raise X from N to M" "raise|learning|62|75" "$result"

result=$(parse_claim "will raise score from 30 to 50")
assert_eq "will raise X from N to M" "raise|score|30|50" "$result"

result=$(parse_claim "learning from 62 to 75 because we fixed grading")
assert_eq "X from N to M with because clause" "raise|learning|62|75" "$result"

result=$(parse_claim "learning eval from 50 to 70")
assert_eq "eval_target X eval to N" "eval_target|learning||70" "$result"

result=$(parse_claim "learning will score 75")
assert_eq "eval_target X will score N" "eval_target|learning||75" "$result"

result=$(parse_claim "learning will reach 80")
assert_eq "numeric_target X will reach N" "numeric_target|learning||80" "$result"

result=$(parse_claim "56 assertions will pass")
assert_eq "N assertions will pass" "assertion_count|||56" "$result"

result=$(parse_claim "score stays at 90")
assert_eq "score_target score at N" "score_target|score||90" "$result"

# --- Tier 2: Verb patterns ---

result=$(parse_claim "grade.sh will work after refactor")
assert_eq "X will work" "will_work|grade.sh||" "$result"

result=$(parse_claim "consolidation will fail on empty files")
assert_eq "X will fail" "will_fail|consolidation||" "$result"

result=$(parse_claim "will drop after removing features")
assert_eq "will drop (no subject)" "drop|||" "$result"

result=$(parse_claim "will improve with better patterns")
assert_eq "will improve (no subject)" "raise|||" "$result"

# --- Tier 3: Filesystem ---

result=$(parse_claim "file bin/grade.sh exists")
assert_eq "file X exists" "exists|bin/grade.sh||" "$result"

# --- Tier 4: Directional (3+ char feature names) ---

result=$(parse_claim "learning improve after fixes")
assert_eq "directional_up learning" "directional_up|learning||" "$result"

result=$(parse_claim "quality decline without tests")
assert_eq "directional_down quality" "directional_down|quality||" "$result"

# Short words should NOT match as feature names in directional patterns
result=$(parse_claim "it will improve")
# "it" is 2 chars, should not match directional_up — falls through to "will improve" = raise
assert_eq "short word not captured as feature" "raise|||" "$result"

# "X will improve" should match directional_up when X is 3+ chars
result=$(parse_claim "learning will improve after fixes")
assert_eq "directional_up with will" "directional_up|learning||" "$result"

# --- Because clause handling ---

result=$(parse_claim "consolidation will work because we fixed zone routing")
assert_eq "because stripped, will_work matched" "will_work|consolidation||" "$result"

result=$(parse_claim "this will get better because of refactoring")
# "this" is short, stripped "because", "will get" doesn't match specific patterns → causal_bool
assert_contains "causal fallback" "causal" "$result"

# ================================================================
echo ""
echo "== history bisection tests =="
# ================================================================

# Re-source with a fresh history file
cat > "$HISTORY_FILE" << 'HIST'
timestamp	build	structure	product	capabilities	hygiene	project_type
2026-03-09T03:50:58Z	100	100	32	0	95	unknown
2026-03-12T10:00:00Z	100	90	50	60	90	cli
2026-03-15T12:00:00Z	100	75	70	80	85	cli
2026-03-17T18:00:00Z	100	65	80	93	80	cli
HIST

# Score at 2026-03-09: min(100, 100, 95) = 95
result=$(find_score_at_date "2026-03-09")
assert_eq "bisect: exact date match (first row)" "95" "$result"

# Score at 2026-03-13 (between rows 2 and 3): should find row 2, min(100, 90, 90) = 90
result=$(find_score_at_date "2026-03-13")
assert_eq "bisect: between rows finds earlier" "90" "$result"

# Score at 2026-03-17 (exact last row date): min(100, 65, 80) = 65
result=$(find_score_at_date "2026-03-17")
assert_eq "bisect: exact last row" "65" "$result"

# Score at 2026-03-16 (between rows 3 and 4): row 3, min(100, 75, 85) = 75
result=$(find_score_at_date "2026-03-16")
assert_eq "bisect: picks closest before date" "75" "$result"

# Score before any history: should return empty (no rows before target)
result=$(find_score_at_date "2026-03-01")
assert_eq "bisect: before all history returns empty" "" "$result"

# ================================================================
echo ""
echo "== directional grading tests =="
# ================================================================

# Test directional_up grading with history bisection
# "quality improve" triggers directional_up with feature="quality"
# get_feature_score("quality") will fail, get_total_score will be used

echo '{"score": 85}' > "$CACHE_FILE"

# grade_prediction for "quality improve" — current total=85, baseline at 2026-03-12=90
# This should be NO because 85 < 90
result=$(grade_prediction "quality improve" "2026-03-12")
assert_contains "directional_up: score dropped, grade NO" "NO" "$result"

# baseline at 2026-03-09=95, current=85 → NO
result=$(grade_prediction "quality improve" "2026-03-09")
assert_contains "directional_up: score lower than old baseline" "NO" "$result"

# Now set current score higher than any baseline
echo '{"score": 96}' > "$CACHE_FILE"
result=$(grade_prediction "quality improve" "2026-03-15")
assert_contains "directional_up: score above baseline" "YES" "$result"

# ================================================================
echo ""
echo "== eval target grading tests =="
# ================================================================

# Set up eval-cache with feature scores
cat > "$CACHE_FILE" << 'JSON'
{
    "learning": {"score": 72},
    "commands": {"score": 85},
    "score": 70
}
JSON

result=$(grade_prediction "learning will score 75" "2026-03-15")
assert_contains "eval_target: 72 vs target 75 (within 75%)" "PARTIAL" "$result"

result=$(grade_prediction "commands will score 80" "2026-03-15")
assert_contains "eval_target: 85 >= 80" "YES" "$result"

# 72 vs target 95: 75% of 95 = 71.25, so 72 >= 71.25 → PARTIAL
result=$(grade_prediction "learning will score 95" "2026-03-15")
assert_contains "eval_target: 72 within 75% of 95" "PARTIAL" "$result"

# 72 vs target 100: 75% of 100 = 75, so 72 < 75 → NO
result=$(grade_prediction "learning will score 100" "2026-03-15")
assert_contains "eval_target: 72 below 75% of 100" "NO" "$result"

# ================================================================
echo ""
echo "== consolidation zone tests =="
# ================================================================

# Create a minimal experiment-learnings.md
mkdir -p "$TEMP_DIR/.claude/knowledge"
cat > "$TEMP_DIR/.claude/knowledge/experiment-learnings.md" << 'MD'
# Experiment Learnings

## Known Patterns (3+ experiments, high confidence)

- Pattern about grading confirmed multiple times

## Uncertain Patterns (1-2 experiments, test again)

- Something uncertain about grading

## Unknown Territory (0 experiments, highest information value)

- Untested area

## Dead Ends (confirmed failures)

- Failed grading approach X
MD

# Create predictions with graded results
cat > "$PRED_FILE" << 'TSV'
date	agent	prediction	evidence	result	correct	model_update
2026-03-18	builder	grading accuracy improved	past patterns	Confirmed: accuracy up	yes	Grading accuracy improvement confirmed by test
2026-03-18	builder	grading will fail on edge cases	hypothesis	Failed: edge cases handled	no	Grading edge case handling works contrary to expectation
TSV

# Re-source with project dir pointing to temp
PROJECT_DIR="$TEMP_DIR"
extract_functions

# Run consolidation
consolidate_knowledge 2>/dev/null

# Check that the yes-graded entry went to Uncertain (not enough prior matches for Known)
UNCERTAIN_SECTION=$(awk '/^## Uncertain Patterns/,/^## Unknown Territory/' "$TEMP_DIR/.claude/knowledge/experiment-learnings.md")
assert_contains "yes-graded goes to Uncertain (first occurrence)" "Grading accuracy improvement" "$UNCERTAIN_SECTION"

# Check that the no-graded entry went to Dead Ends (existing dead-end entry matches "grading")
DEAD_SECTION=$(awk '/^## Dead Ends/,0' "$TEMP_DIR/.claude/knowledge/experiment-learnings.md")
assert_contains "no-graded with existing dead-end goes to Dead Ends" "Grading edge case handling" "$DEAD_SECTION"

# Check that nothing was inserted into Known (not enough matches)
KNOWN_SECTION=$(awk '/^## Known Patterns/,/^## Uncertain Patterns/' "$TEMP_DIR/.claude/knowledge/experiment-learnings.md")
TOTAL=$((TOTAL + 1))
if [[ "$KNOWN_SECTION" != *"Auto-graded"* ]]; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} no auto-graded entries in Known Patterns"
else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} no auto-graded entries in Known Patterns"
    echo "    Known section contains Auto-graded entries (should not)"
fi

# ================================================================
echo ""
echo "== qualitative grading tests (v9.4.1) =="
# ================================================================

# These test the 3 new pattern types end-to-end via grade_prediction.
# parse_claim alternation captures are unreliable in bash 3.2 sourced context,
# so we test grade_prediction which runs as a complete function call.

# Set up history + cache for qualitative grading
cat > "$HISTORY_FILE" << 'HIST'
timestamp	build	structure	product	capabilities	hygiene	project_type
2026-03-09T03:50:58Z	100	100	32	0	95	unknown
2026-03-12T10:00:00Z	100	90	50	60	90	cli
2026-03-15T12:00:00Z	100	75	70	80	85	cli
2026-03-17T18:00:00Z	100	65	80	93	80	cli
HIST

# Cache with score 85 and 89% assertion pass rate
cat > "$CACHE_FILE" << 'JSON'
{
    "learning": {"score": 72, "delivery_score": 70, "craft_score": 78, "viability_score": 62},
    "commands": {"score": 85},
    "score": 85,
    "assertion_pass_count": 50,
    "assertion_total_count": 56
}
JSON

# Re-source functions with updated fixtures
extract_functions

# --- "will be [adjective]" pattern: checks score delta ---

# "output will be better" — baseline at 2026-03-12=90, current=85 → score dropped → NO
result=$(grade_prediction "output will be better after this change" "2026-03-12")
assert_contains "qualitative_up: score dropped → NO" "NO" "$result"

# "output will be better" — baseline at 2026-03-15=75, current=85 → improved by 10 → YES
result=$(grade_prediction "output will be better after this change" "2026-03-15")
assert_contains "qualitative_up: score improved → YES" "YES" "$result"

# --- "should [verb]" pattern: checks assertion pass rate ---

# "grading should work" — pass rate 89% → YES (≥85%)
result=$(grade_prediction "grading should work on qualitative predictions" "2026-03-15")
assert_contains "should_verb: 89% pass rate → YES" "YES" "$result"

# Lower assertion rate → PARTIAL
echo '{"score": 85, "assertion_pass_count": 40, "assertion_total_count": 56}' > "$CACHE_FILE"
extract_functions
result=$(grade_prediction "this should pass all tests" "2026-03-15")
assert_contains "should_verb: 71% pass rate → PARTIAL" "PARTIAL" "$result"

# Very low pass rate → NO
echo '{"score": 85, "assertion_pass_count": 20, "assertion_total_count": 56}' > "$CACHE_FILE"
extract_functions
result=$(grade_prediction "this should pass all tests" "2026-03-15")
assert_contains "should_verb: 35% pass rate → NO" "NO" "$result"

# Restore cache for remaining tests
cat > "$CACHE_FILE" << 'JSON'
{
    "score": 85,
    "assertion_pass_count": 50,
    "assertion_total_count": 56
}
JSON
extract_functions

# --- "expect [noun]" pattern: checks score delta ---

# "expect improvement" — baseline at 2026-03-15=75, current=85 → +10 → YES
result=$(grade_prediction "I expect improvement in the score" "2026-03-15")
assert_contains "expect_up: score improved by 10 → YES" "YES" "$result"

# "expect regression" — baseline at 2026-03-15=75, current=85 → went up → NO
result=$(grade_prediction "expect regression after removing features" "2026-03-15")
assert_contains "expect_down: score went up → NO" "NO" "$result"

# "expect stability" — baseline at 2026-03-17=65, current=85 → delta 20 → NO (not stable)
result=$(grade_prediction "expect stability in the score" "2026-03-17")
assert_contains "expect_stable: delta 20 → NO" "NO" "$result"

# ================================================================
echo ""
echo "== Results =="
echo "$PASS/$TOTAL passed, $FAIL failed"
# ================================================================

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
