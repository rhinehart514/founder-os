#!/usr/bin/env bash
# assumption-audit.sh — Extracts assumptions from value hypothesis, checks evidence.
# Outputs which assumptions are proven, tested, or untested.
set -euo pipefail

PROJECT_DIR="${1:-.}"

FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
PREDICTIONS="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PREDICTIONS" ]] && PREDICTIONS="$HOME/.claude/knowledge/predictions.tsv"
CUST_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"

echo "=== ASSUMPTION AUDIT ==="
echo ""

# --- Extract hypothesis ---
if [[ -f "$FOUNDER_YML" ]]; then
    echo "▾ VALUE HYPOTHESIS"
    grep -E '^\s+hypothesis:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*hypothesis:\s*/  /' || echo "  (none defined)"
    echo ""
    echo "▾ TARGET USER"
    grep -E '^\s+user:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*user:\s*/  /' || echo "  (none defined — CRITICAL: building for nobody)"
    echo ""
    echo "▾ SIGNALS"
    awk '/^\s+signals:/,/^[a-z]/{if(/^[a-z]/) exit; if(/name:/) print "  " $0}' "$FOUNDER_YML" 2>/dev/null || echo "  (no signals — how do you know if it works?)"
    echo ""
else
    echo "  NO founder.yml — product has no value hypothesis"
    echo "  This is the #1 problem. Run /onboard to define one."
    echo ""
fi

# --- Check what evidence exists ---
echo "▾ EVIDENCE SOURCES"
EVIDENCE_COUNT=0

if [[ -f "$EVAL_CACHE" ]]; then
    FEAT_CT=$(jq 'length' "$EVAL_CACHE" 2>/dev/null || echo "0")
    echo "  eval-cache: $FEAT_CT features scored"
    EVIDENCE_COUNT=$((EVIDENCE_COUNT + 1))
else
    echo "  eval-cache: MISSING — no feature scoring data"
fi

if [[ -f "$PREDICTIONS" ]]; then
    PRED_CT=$(tail -n +2 "$PREDICTIONS" 2>/dev/null | wc -l | tr -d ' ')
    WRONG_CT=$(tail -n +2 "$PREDICTIONS" 2>/dev/null | awk -F'\t' '$6 == "no" || $6 == "partial"' | wc -l | tr -d ' ')
    echo "  predictions: $PRED_CT total, $WRONG_CT wrong/partial"
    EVIDENCE_COUNT=$((EVIDENCE_COUNT + 1))
else
    echo "  predictions: MISSING — learning loop not running"
fi

if [[ -f "$LEARNINGS" ]]; then
    KNOWN_CT=$(awk '/^## Known Patterns/,/^## /{if(/^## / && !/Known/) exit; if(/^\s*-/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    UNKNOWN_CT=$(awk '/^## Unknown Territory/,/^## /{if(/^## / && !/Unknown/) exit; if(/^\s*-/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    echo "  learnings: $KNOWN_CT known patterns, $UNKNOWN_CT unknowns"
    EVIDENCE_COUNT=$((EVIDENCE_COUNT + 1))
else
    echo "  learnings: MISSING — no knowledge model"
fi

if [[ -f "$CUST_INTEL" ]]; then
    echo "  customer-intel: present"
    EVIDENCE_COUNT=$((EVIDENCE_COUNT + 1))
else
    echo "  customer-intel: MISSING — no external signal"
fi

echo ""
echo "▾ EVIDENCE DENSITY: $EVIDENCE_COUNT/4 sources available"
if [[ $EVIDENCE_COUNT -lt 2 ]]; then
    echo "  LOW — most assumptions will be untested. Run /research or /discover."
fi
echo ""

# --- Extract implicit assumptions from features ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▾ FEATURE-LEVEL ASSUMPTIONS"
    jq -r 'to_entries[] | select(.value.score != null) |
      "  \(.key) (\(.value.score)/100): " +
      if .value.score < 30 then "UNTESTED — this feature is a pure assumption"
      elif .value.score < 50 then "BUILDING — partially tested, still risky"
      elif .value.score < 70 then "WORKING — evidence exists but not proven"
      elif .value.score < 90 then "POLISHED — well-supported"
      else "PROVEN — strong evidence"
      end' "$EVAL_CACHE" 2>/dev/null
    echo ""

    # Count by evidence level
    UNTESTED=$(jq '[to_entries[] | select(.value.score != null and .value.score < 30)] | length' "$EVAL_CACHE" 2>/dev/null || echo "0")
    PROVEN=$(jq '[to_entries[] | select(.value.score != null and .value.score >= 70)] | length' "$EVAL_CACHE" 2>/dev/null || echo "0")
    TOTAL=$(jq '[to_entries[] | select(.value.score != null)] | length' "$EVAL_CACHE" 2>/dev/null || echo "0")
    echo "  SUMMARY: $PROVEN/$TOTAL proven, $UNTESTED/$TOTAL untested"
fi

echo ""

# --- Wrong predictions reveal wrong assumptions ---
if [[ -f "$PREDICTIONS" ]]; then
    WRONG=$(tail -n +2 "$PREDICTIONS" | awk -F'\t' '$6 == "no" || $6 == "partial"' | tail -5)
    if [[ -n "$WRONG" ]]; then
        echo "▾ WRONG PREDICTIONS (assumptions that were disproven)"
        echo "$WRONG" | while IFS=$'\t' read -r date pred evidence result correct update; do
            echo "  $date: $pred"
            [[ -n "$update" ]] && echo "    → $update"
        done
        echo ""
    fi
fi

echo "=== AUDIT COMPLETE ==="
