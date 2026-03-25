#!/usr/bin/env bash
# gsd-measure-wrap.sh — Pre/post measurement wrapper for GSD execution
# Usage:
#   bash bin/gsd-measure-wrap.sh --pre [project-dir]    # capture baseline
#   bash bin/gsd-measure-wrap.sh --post [project-dir]   # compare against baseline
#   bash bin/gsd-measure-wrap.sh --verify <verification-md> [project-dir]  # augment VERIFICATION.md
set -euo pipefail

MODE="${1:-}"
shift || true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$MODE" in
    --pre)
        PROJECT_DIR="${1:-$(pwd)}"
        CACHE_DIR="$PROJECT_DIR/.claude/cache"
        mkdir -p "$CACHE_DIR"

        # Capture score baseline
        if [[ -f "$SCRIPT_DIR/score.sh" ]]; then
            bash "$SCRIPT_DIR/score.sh" "$PROJECT_DIR" --json --quiet > "$CACHE_DIR/gsd-pre-score.json" 2>/dev/null || \
                echo '{}' > "$CACHE_DIR/gsd-pre-score.json"
        fi

        # Capture assertion baseline
        GATE_SCRIPT="$SCRIPT_DIR/../skills/build/scripts/assertion-gate.sh"
        if [[ -f "$GATE_SCRIPT" ]]; then
            RESULT=$(bash "$GATE_SCRIPT" 2>/dev/null || true)
            PASS=$(echo "$RESULT" | grep -oP '\d+(?=/\d+ passing)' | head -1 || echo "0")
            TOTAL=$(echo "$RESULT" | grep -oP '(?<=/)(\d+)(?= passing)' | head -1 || echo "0")
            echo "{\"pass\": $PASS, \"total\": $TOTAL}" > "$CACHE_DIR/gsd-pre-assertions.json"
        fi

        # Copy eval-cache snapshot
        [[ -f "$CACHE_DIR/eval-cache.json" ]] && cp "$CACHE_DIR/eval-cache.json" "$CACHE_DIR/gsd-pre-eval.json"

        # Record git SHA
        GIT_SHA=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
        echo "{\"sha\": \"$GIT_SHA\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$CACHE_DIR/gsd-pre-git.json"

        echo "Baseline captured: score, assertions, eval, git SHA"
        ;;

    --post)
        PROJECT_DIR="${1:-$(pwd)}"
        CACHE_DIR="$PROJECT_DIR/.claude/cache"

        [[ ! -f "$CACHE_DIR/gsd-pre-score.json" ]] && { echo "No baseline found. Run --pre first." >&2; exit 1; }

        # Get current score
        CURRENT_SCORE=""
        if [[ -f "$CACHE_DIR/score-cache.json" ]] && command -v jq &>/dev/null; then
            CURRENT_SCORE=$(jq -r '.score // 0' "$CACHE_DIR/score-cache.json" 2>/dev/null || echo "0")
        fi

        # Get pre score
        PRE_SCORE=""
        if command -v jq &>/dev/null; then
            PRE_SCORE=$(jq -r '.score // 0' "$CACHE_DIR/gsd-pre-score.json" 2>/dev/null || echo "0")
        fi

        # Get current assertions
        CURRENT_PASS=0 CURRENT_TOTAL=0
        if [[ -f "$CACHE_DIR/score-cache.json" ]] && command -v jq &>/dev/null; then
            CURRENT_PASS=$(jq -r '.assertion_pass_count // 0' "$CACHE_DIR/score-cache.json" 2>/dev/null || echo "0")
            CURRENT_TOTAL=$(jq -r '.assertion_count // 0' "$CACHE_DIR/score-cache.json" 2>/dev/null || echo "0")
        fi

        # Get pre assertions
        PRE_PASS=0 PRE_TOTAL=0
        if [[ -f "$CACHE_DIR/gsd-pre-assertions.json" ]] && command -v jq &>/dev/null; then
            PRE_PASS=$(jq -r '.pass // 0' "$CACHE_DIR/gsd-pre-assertions.json" 2>/dev/null || echo "0")
            PRE_TOTAL=$(jq -r '.total // 0' "$CACHE_DIR/gsd-pre-assertions.json" 2>/dev/null || echo "0")
        fi

        # Compute deltas
        SCORE_DELTA=0
        [[ -n "$CURRENT_SCORE" && -n "$PRE_SCORE" ]] && SCORE_DELTA=$((CURRENT_SCORE - PRE_SCORE))
        ASSERT_DELTA=$((CURRENT_PASS - PRE_PASS))

        # Determine status
        STATUS="stable"
        EXIT_CODE=0
        if [[ "$ASSERT_DELTA" -lt 0 ]]; then
            STATUS="assertion_regression"
            EXIT_CODE=1
        elif [[ "$SCORE_DELTA" -lt -5 ]]; then
            STATUS="score_regression"
            EXIT_CODE=2
        elif [[ "$SCORE_DELTA" -gt 0 || "$ASSERT_DELTA" -gt 0 ]]; then
            STATUS="improved"
        fi

        # Write report
        cat > "$CACHE_DIR/gsd-execution-report.json" << REPORT_EOF
{
  "status": "$STATUS",
  "score_before": $PRE_SCORE,
  "score_after": ${CURRENT_SCORE:-0},
  "score_delta": $SCORE_DELTA,
  "assertions_before": "$PRE_PASS/$PRE_TOTAL",
  "assertions_after": "$CURRENT_PASS/$CURRENT_TOTAL",
  "assertion_delta": $ASSERT_DELTA,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
REPORT_EOF

        echo "Execution report: $STATUS (score: ${PRE_SCORE}→${CURRENT_SCORE}, assertions: ${PRE_PASS}→${CURRENT_PASS})"
        exit $EXIT_CODE
        ;;

    --verify)
        VERIFY_FILE="${1:-}"
        PROJECT_DIR="${2:-$(pwd)}"
        CACHE_DIR="$PROJECT_DIR/.claude/cache"

        [[ -z "$VERIFY_FILE" || ! -f "$VERIFY_FILE" ]] && { echo "Usage: --verify <verification-md>" >&2; exit 1; }
        [[ ! -f "$CACHE_DIR/gsd-execution-report.json" ]] && { echo "No execution report found." >&2; exit 0; }

        if command -v jq &>/dev/null; then
            STATUS=$(jq -r '.status' "$CACHE_DIR/gsd-execution-report.json")
            S_BEFORE=$(jq -r '.score_before' "$CACHE_DIR/gsd-execution-report.json")
            S_AFTER=$(jq -r '.score_after' "$CACHE_DIR/gsd-execution-report.json")
            S_DELTA=$(jq -r '.score_delta' "$CACHE_DIR/gsd-execution-report.json")
            A_BEFORE=$(jq -r '.assertions_before' "$CACHE_DIR/gsd-execution-report.json")
            A_AFTER=$(jq -r '.assertions_after' "$CACHE_DIR/gsd-execution-report.json")
            A_DELTA=$(jq -r '.assertion_delta' "$CACHE_DIR/gsd-execution-report.json")

            cat >> "$VERIFY_FILE" << VERIFY_EOF

## Score Impact (founder-os)

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Score | $S_BEFORE | $S_AFTER | $S_DELTA |
| Assertions | $A_BEFORE | $A_AFTER | $A_DELTA |

**Status:** $STATUS
VERIFY_EOF

            if [[ "$STATUS" == "assertion_regression" || "$STATUS" == "score_regression" ]]; then
                echo "score_regression: true" >> "$VERIFY_FILE"
            fi
        fi

        echo "VERIFICATION.md augmented with score impact"
        ;;

    *)
        echo "Usage: gsd-measure-wrap.sh --pre|--post|--verify [args]" >&2
        exit 1
        ;;
esac
