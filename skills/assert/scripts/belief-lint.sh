#!/usr/bin/env bash
# Lint beliefs.yml: syntax issues, duplicate ids, missing fields, mechanical-vs-llm ratio
# Run standalone — outputs structured warnings
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

BELIEFS=""
for bf in "$PROJECT_DIR/lens/product/eval/beliefs.yml" "$PROJECT_DIR/config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && BELIEFS="$bf" && break
done

echo "── belief lint ──"
if [[ -z "$BELIEFS" ]]; then
    echo "  no beliefs.yml found"
    exit 0
fi

ISSUES=0

# --- Duplicate IDs ---
echo ""
echo "  checking duplicate ids..."
DUPES=$(grep '^\s*- id:' "$BELIEFS" | sed 's/.*- id: *//' | sort | uniq -d)
if [[ -n "$DUPES" ]]; then
    echo "$DUPES" | while read -r dup; do
        echo "    ✗ duplicate id: $dup"
        ISSUES=$((ISSUES + 1))
    done
else
    echo "    ✓ no duplicates"
fi

# --- Missing required fields ---
echo ""
echo "  checking required fields..."
# Extract each belief block and check for id, type, feature, severity
CURRENT_ID=""
MISSING_TYPE=0
MISSING_FEATURE=0
MISSING_SEVERITY=0
IN_BELIEF=false

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]id:[[:space:]]*(.*) ]]; then
        # Check previous block
        if [[ -n "$CURRENT_ID" ]]; then
            [[ "$HAS_TYPE" == "false" ]] && echo "    ✗ $CURRENT_ID: missing type" && MISSING_TYPE=$((MISSING_TYPE + 1))
            [[ "$HAS_FEATURE" == "false" ]] && echo "    ✗ $CURRENT_ID: missing feature" && MISSING_FEATURE=$((MISSING_FEATURE + 1))
            [[ "$HAS_SEVERITY" == "false" ]] && echo "    ✗ $CURRENT_ID: missing severity" && MISSING_SEVERITY=$((MISSING_SEVERITY + 1))
        fi
        CURRENT_ID="${BASH_REMATCH[1]}"
        CURRENT_ID=$(echo "$CURRENT_ID" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        HAS_TYPE=false
        HAS_FEATURE=false
        HAS_SEVERITY=false
    elif [[ "$line" =~ ^[[:space:]]+type: ]]; then
        HAS_TYPE=true
    elif [[ "$line" =~ ^[[:space:]]+feature: ]]; then
        HAS_FEATURE=true
    elif [[ "$line" =~ ^[[:space:]]+severity: ]]; then
        HAS_SEVERITY=true
    fi
done < "$BELIEFS"

# Check last block
if [[ -n "$CURRENT_ID" ]]; then
    [[ "$HAS_TYPE" == "false" ]] && echo "    ✗ $CURRENT_ID: missing type" && MISSING_TYPE=$((MISSING_TYPE + 1))
    [[ "$HAS_FEATURE" == "false" ]] && echo "    ✗ $CURRENT_ID: missing feature" && MISSING_FEATURE=$((MISSING_FEATURE + 1))
    [[ "$HAS_SEVERITY" == "false" ]] && echo "    ✗ $CURRENT_ID: missing severity" && MISSING_SEVERITY=$((MISSING_SEVERITY + 1))
fi

TOTAL_MISSING=$((MISSING_TYPE + MISSING_FEATURE + MISSING_SEVERITY))
if [[ "$TOTAL_MISSING" -eq 0 ]]; then
    echo "    ✓ all beliefs have id, type, feature, severity"
fi

# --- Mechanical vs LLM ratio ---
echo ""
echo "  checking type balance..."
TOTAL=$(grep -c '^\s*- id:' "$BELIEFS" 2>/dev/null || echo "0")
LLM_COUNT=0
for type in llm_judge feature_review; do
    C=$(grep -c "type: $type" "$BELIEFS" 2>/dev/null || echo "0")
    LLM_COUNT=$((LLM_COUNT + C))
done
MECHANICAL_COUNT=$((TOTAL - LLM_COUNT))

if [[ "$TOTAL" -gt 0 ]]; then
    LLM_PCT=$((LLM_COUNT * 100 / TOTAL))
    echo "    mechanical: $MECHANICAL_COUNT · llm: $LLM_COUNT (${LLM_PCT}% llm)"
    if [[ "$LLM_PCT" -gt 40 ]]; then
        echo "    ⚠ llm_judge ratio > 40% — results will be noisy. Target: <20%"
        ISSUES=$((ISSUES + 1))
    elif [[ "$LLM_PCT" -gt 20 ]]; then
        echo "    · llm_judge ratio > 20% — consider converting some to mechanical"
    else
        echo "    ✓ healthy mechanical/llm ratio"
    fi
fi

# --- Beliefs with no 'belief:' text (description missing) ---
echo ""
echo "  checking belief text..."
NO_BELIEF=0
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]id:[[:space:]]*(.*) ]]; then
        CUR_ID="${BASH_REMATCH[1]}"
        CUR_ID=$(echo "$CUR_ID" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        HAS_BELIEF=false
    elif [[ "$line" =~ ^[[:space:]]+belief: ]]; then
        HAS_BELIEF=true
    elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]id: ]]; then
        if [[ -n "${CUR_ID:-}" && "${HAS_BELIEF:-true}" == "false" ]]; then
            echo "    ✗ $CUR_ID: no belief text"
            NO_BELIEF=$((NO_BELIEF + 1))
        fi
    fi
done < "$BELIEFS"

if [[ "$NO_BELIEF" -eq 0 ]]; then
    echo "    ✓ all beliefs have description text"
fi

# --- Summary ---
DUPE_COUNT=0
if [[ -n "$DUPES" ]]; then
    DUPE_COUNT=$(echo "$DUPES" | wc -l | tr -d '[:space:]')
fi
TOTAL_ISSUES=$((DUPE_COUNT + TOTAL_MISSING + NO_BELIEF))
echo ""
if [[ "$TOTAL_ISSUES" -eq 0 ]]; then
    echo "  lint: ✓ clean ($TOTAL beliefs)"
else
    echo "  lint: $TOTAL_ISSUES issue(s) found"
fi
