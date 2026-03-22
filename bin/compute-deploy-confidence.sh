#!/usr/bin/env bash
# compute-deploy-confidence.sh — Deploy confidence from assertions + history.
# Used by: /ship, /go
#
# Usage: bash bin/compute-deploy-confidence.sh [eval-cache.json] [deploy-history.json]
# Output:
#   confidence: 85
#   assertion_pass_rate: 90
#   deploy_success_rate: 100
#   last_3_deploys: success success success
#   verdict: ship

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SCORE_CACHE="${1:-$PROJECT_DIR/.claude/cache/score-cache.json}"
DEPLOY_HISTORY="${2:-$PROJECT_DIR/.claude/cache/deploy-history.json}"

# Assertion pass rate from score cache
PASS_RATE=0
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    PASS=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    TOTAL=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    if [[ "$TOTAL" -gt 0 ]]; then
        PASS_RATE=$(( PASS * 100 / TOTAL ))
    fi
fi

# Deploy success rate from last 3 deploys
DEPLOY_SUCCESS=100
LAST_3="none"
if [[ -f "$DEPLOY_HISTORY" ]] && command -v jq &>/dev/null; then
    LAST_3=$(jq -r '.deploys[-3:] | map(.status // "unknown") | join(" ")' "$DEPLOY_HISTORY" 2>/dev/null || echo "none")
    if [[ "$LAST_3" != "none" && -n "$LAST_3" ]]; then
        TOTAL_DEPLOYS=$(echo "$LAST_3" | wc -w | tr -d ' ')
        SUCCESS_DEPLOYS=$(echo "$LAST_3" | tr ' ' '\n' | grep -c 'success' || true)
        if [[ "$TOTAL_DEPLOYS" -gt 0 ]]; then
            DEPLOY_SUCCESS=$(( SUCCESS_DEPLOYS * 100 / TOTAL_DEPLOYS ))
        fi
    fi
fi

# Confidence = assertion_pass_rate × deploy_success_rate / 100
CONFIDENCE=$(( PASS_RATE * DEPLOY_SUCCESS / 100 ))

# Verdict
VERDICT="ship"
if [[ "$CONFIDENCE" -lt 50 ]]; then
    VERDICT="block"
elif [[ "$CONFIDENCE" -lt 75 ]]; then
    VERDICT="warn"
fi

echo "confidence: $CONFIDENCE"
echo "assertion_pass_rate: $PASS_RATE"
echo "deploy_success_rate: $DEPLOY_SUCCESS"
echo "last_3_deploys: $LAST_3"
echo "verdict: $VERDICT"
