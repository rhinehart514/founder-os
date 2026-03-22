#!/usr/bin/env bash
# Assertion statistics: counts by type, pass rate, coverage gaps, mechanical-vs-llm ratio
# Run standalone — outputs structured text at zero context cost
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Find beliefs.yml
BELIEFS=""
for bf in "$PROJECT_DIR/lens/product/eval/beliefs.yml" "$PROJECT_DIR/config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && BELIEFS="$bf" && break
done

echo "── assertion stats ──"
if [[ -z "$BELIEFS" ]]; then
    echo "  no beliefs.yml found"
    exit 0
fi

TOTAL=$(grep -c '^\s*- id:' "$BELIEFS" 2>/dev/null || echo "0")
echo "  total: $TOTAL"

# --- By type ---
echo ""
echo "  by type:"
MECHANICAL=0
LLM=0
for type in file_check content_check command_check score_check score_trend self_check bench_check assertion_trend session_continuity value_velocity; do
    COUNT=$(grep -c "type: $type" "$BELIEFS" 2>/dev/null || true)
    COUNT=${COUNT:-0}
    COUNT=$(echo "$COUNT" | tr -d '[:space:]')
    if [[ "$COUNT" -gt 0 ]]; then
        echo "    $type: $COUNT"
        MECHANICAL=$((MECHANICAL + COUNT))
    fi
done
for type in llm_judge feature_review; do
    COUNT=$(grep -c "type: $type" "$BELIEFS" 2>/dev/null || true)
    COUNT=${COUNT:-0}
    COUNT=$(echo "$COUNT" | tr -d '[:space:]')
    if [[ "$COUNT" -gt 0 ]]; then
        echo "    $type: $COUNT"
        LLM=$((LLM + COUNT))
    fi
done

# --- Ratio ---
echo ""
if [[ "$TOTAL" -gt 0 ]]; then
    MECH_PCT=$((MECHANICAL * 100 / TOTAL))
    LLM_PCT=$((LLM * 100 / TOTAL))
    echo "  mechanical/llm ratio: ${MECHANICAL}/${LLM} (${MECH_PCT}%/${LLM_PCT}%)"
    if [[ "$LLM_PCT" -gt 30 ]]; then
        echo "  ⚠ llm_judge > 30% — high variance risk. Convert some to mechanical types."
    fi
    if [[ "$LLM_PCT" -eq 0 && "$TOTAL" -gt 5 ]]; then
        echo "  ⚠ zero llm_judge — may be missing qualitative checks on craft/value."
    fi
fi

# --- By severity ---
echo ""
echo "  by severity:"
for sev in block warn info; do
    COUNT=$(grep -c "severity: $sev" "$BELIEFS" 2>/dev/null || true)
    COUNT=${COUNT:-0}
    COUNT=$(echo "$COUNT" | tr -d '[:space:]')
    [[ "$COUNT" -gt 0 ]] && echo "    $sev: $COUNT"
done

# --- By feature ---
echo ""
echo "  by feature:"
grep "feature:" "$BELIEFS" 2>/dev/null | sed 's/.*feature: *//' | sort | uniq -c | sort -rn | while read -r count feat; do
    echo "    $feat: $count"
done

# --- Coverage gaps (features in founder.yml with 0 assertions) ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    echo ""
    echo "  coverage gaps:"
    FEATURES_SECTION=false
    HAS_GAP=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.*) ]]; then
            FEAT_NAME="${BASH_REMATCH[1]}"
            FEAT_NAME=$(echo "$FEAT_NAME" | sed 's/^[[:space:]"]*//;s/[[:space:]"]*$//')
            FEAT_COUNT=$(grep -c "feature: $FEAT_NAME" "$BELIEFS" 2>/dev/null || true)
            FEAT_COUNT=${FEAT_COUNT:-0}
            FEAT_COUNT=$(echo "$FEAT_COUNT" | tr -d '[:space:]')
            if [[ "$FEAT_COUNT" -eq 0 ]]; then
                echo "    ⚠ $FEAT_NAME: 0 assertions"
                HAS_GAP=true
            fi
        fi
    done < <(grep "name:" "$FOUNDER_YML" 2>/dev/null || true)
    if [[ "$HAS_GAP" == "false" ]]; then
        echo "    ✓ all features have assertions"
    fi
fi

# --- Pass rate from last eval (if history exists) ---
HISTORY="$PROJECT_DIR/.claude/evals/assertion-history.tsv"
if [[ -f "$HISTORY" ]]; then
    echo ""
    LAST_RUN=$(tail -1 "$HISTORY" 2>/dev/null | cut -f1 || echo "")
    if [[ -n "$LAST_RUN" ]]; then
        LAST_TOTAL=$(grep -c "^$LAST_RUN" "$HISTORY" 2>/dev/null || echo "0")
        LAST_PASS=$(grep "^$LAST_RUN" "$HISTORY" 2>/dev/null | grep -c "pass" || echo "0")
        if [[ "$LAST_TOTAL" -gt 0 ]]; then
            RATE=$((LAST_PASS * 100 / LAST_TOTAL))
            echo "  last eval pass rate: ${LAST_PASS}/${LAST_TOTAL} (${RATE}%)"
        fi
    fi
fi
