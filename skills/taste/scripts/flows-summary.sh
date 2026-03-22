#!/usr/bin/env bash
# flows-summary.sh — Reads past flow audit reports, shows issue trends.
# Like dimension-summary.sh but for flows mode.
# Usage: bash scripts/flows-summary.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
REPORTS_DIR="$PROJECT_DIR/.claude/evals/reports"

echo "── flows summary ──"

# Find flow reports
FLOW_REPORTS=$(ls -t "$REPORTS_DIR"/flows-*.json 2>/dev/null || true)
if [[ -z "$FLOW_REPORTS" ]]; then
    echo "  no flow audits yet"
    echo "  run: /taste <url> flows"
    exit 0
fi

REPORT_COUNT=$(echo "$FLOW_REPORTS" | wc -l | tr -d ' ')
echo "  audits: $REPORT_COUNT"

# Latest report
LATEST=$(echo "$FLOW_REPORTS" | head -1)
if ! command -v jq &>/dev/null; then
    echo "  (jq required for detailed summary)"
    exit 0
fi

LATEST_DATE=$(jq -r '.timestamp // "unknown"' "$LATEST" 2>/dev/null | cut -c1-10)
LATEST_URL=$(jq -r '.url // "unknown"' "$LATEST" 2>/dev/null)
echo "  latest: $LATEST_DATE  $LATEST_URL"
echo ""

# Issue counts
BLOCKERS=$(jq -r '.summary.blockers // 0' "$LATEST" 2>/dev/null)
MAJOR=$(jq -r '.summary.major // 0' "$LATEST" 2>/dev/null)
MINOR=$(jq -r '.summary.minor // 0' "$LATEST" 2>/dev/null)
POLISH=$(jq -r '.summary.polish // 0' "$LATEST" 2>/dev/null)
CORE_FLOW=$(jq -r '.summary.core_flow_complete // "unknown"' "$LATEST" 2>/dev/null)
VERDICT=$(jq -r '.summary.verdict // "no verdict"' "$LATEST" 2>/dev/null)

echo "  ▸ issues"
[[ "$BLOCKERS" != "0" ]] && echo "    blockers: $BLOCKERS"
[[ "$MAJOR" != "0" ]] && echo "    major: $MAJOR"
[[ "$MINOR" != "0" ]] && echo "    minor: $MINOR"
[[ "$POLISH" != "0" ]] && echo "    polish: $POLISH"
TOTAL_ISSUES=$((BLOCKERS + MAJOR + MINOR + POLISH))
[[ "$TOTAL_ISSUES" -eq 0 ]] && echo "    none found"
echo ""

echo "  ▸ core flow: $CORE_FLOW"
echo "  ▸ verdict: $VERDICT"

# Fix priority
FIX_COUNT=$(jq '.fix_priority | length' "$LATEST" 2>/dev/null || echo 0)
if [[ "$FIX_COUNT" -gt 0 ]]; then
    echo ""
    echo "  ▸ top fixes"
    jq -r '.fix_priority[:3][] | "    [\(.severity)] \(.element) — \(.problem)"' "$LATEST" 2>/dev/null || true
fi

# Trend (compare with previous report)
if [[ "$REPORT_COUNT" -gt 1 ]]; then
    PREV=$(echo "$FLOW_REPORTS" | sed -n '2p')
    PREV_TOTAL=$(jq -r '[.summary.blockers, .summary.major, .summary.minor, .summary.polish] | add // 0' "$PREV" 2>/dev/null || echo "0")
    echo ""
    if [[ "$TOTAL_ISSUES" -lt "$PREV_TOTAL" ]]; then
        DELTA=$((PREV_TOTAL - TOTAL_ISSUES))
        echo "  trend: improving ($DELTA fewer issues)"
    elif [[ "$TOTAL_ISSUES" -gt "$PREV_TOTAL" ]]; then
        DELTA=$((TOTAL_ISSUES - PREV_TOTAL))
        echo "  trend: regressing ($DELTA more issues)"
    else
        echo "  trend: flat ($TOTAL_ISSUES issues unchanged)"
    fi
fi

# Mechanical check results
MECHANICAL=$(jq '.mechanical // {}' "$LATEST" 2>/dev/null)
if [[ "$MECHANICAL" != "{}" && "$MECHANICAL" != "null" ]]; then
    echo ""
    echo "  ▸ mechanical"
    CONSOLE_ERRORS=$(echo "$MECHANICAL" | jq -r '.console_errors // 0')
    FAILED_REQ=$(echo "$MECHANICAL" | jq -r '.failed_requests // 0')
    SMALL_TARGETS=$(echo "$MECHANICAL" | jq -r '.undersized_targets // 0')
    UNLABELED=$(echo "$MECHANICAL" | jq -r '.unlabeled_inputs // 0')
    [[ "$CONSOLE_ERRORS" != "0" ]] && echo "    console errors: $CONSOLE_ERRORS"
    [[ "$FAILED_REQ" != "0" ]] && echo "    failed requests: $FAILED_REQ"
    [[ "$SMALL_TARGETS" != "0" ]] && echo "    undersized targets: $SMALL_TARGETS"
    [[ "$UNLABELED" != "0" ]] && echo "    unlabeled inputs: $UNLABELED"
    ALL_CLEAN=true
    [[ "$CONSOLE_ERRORS" != "0" || "$FAILED_REQ" != "0" || "$SMALL_TARGETS" != "0" || "$UNLABELED" != "0" ]] && ALL_CLEAN=false
    $ALL_CLEAN && echo "    all clean"
fi
