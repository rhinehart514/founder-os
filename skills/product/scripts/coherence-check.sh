#!/usr/bin/env bash
# coherence-check.sh — Checks that README, features, assertions, thesis, and narrative align.
# Finds contradictions between what the product claims and what it delivers.
set -euo pipefail

PROJECT_DIR="${1:-.}"

FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
BELIEFS="$PROJECT_DIR/config/beliefs.yml"
NARRATIVE="$PROJECT_DIR/.claude/cache/narrative.yml"
README="$PROJECT_DIR/README.md"

DISCONNECTS=0
CHECKS=0

echo "=== COHERENCE CHECK ==="
echo ""

# --- 1. README vs Features ---
echo "▾ README vs FEATURES"
CHECKS=$((CHECKS + 1))
if [[ -f "$README" ]] && [[ -f "$FOUNDER_YML" ]]; then
    # Extract feature names from founder.yml
    FEATURES=$(grep -E '^\s+-\s+name:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*name:\s*//' | tr -d '"' || true)
    if [[ -n "$FEATURES" ]]; then
        MISSING=""
        while IFS= read -r feat; do
            feat_clean=$(echo "$feat" | tr -d ' ')
            if ! grep -qi "$feat_clean" "$README" 2>/dev/null; then
                MISSING="$MISSING  MISSING in README: $feat_clean\n"
            fi
        done <<< "$FEATURES"
        if [[ -n "$MISSING" ]]; then
            echo -e "$MISSING"
            echo "  DISCONNECT: README doesn't mention all defined features"
            DISCONNECTS=$((DISCONNECTS + 1))
        else
            echo "  OK: all features mentioned in README"
        fi
    else
        echo "  (no features in founder.yml)"
    fi
else
    echo "  SKIP: missing README or founder.yml"
fi
echo ""

# --- 2. Features vs Assertions ---
echo "▾ FEATURES vs ASSERTIONS"
CHECKS=$((CHECKS + 1))
if [[ -f "$FOUNDER_YML" ]] && [[ -f "$BELIEFS" ]]; then
    FEATURES=$(grep -E '^\s+-\s+name:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*name:\s*//' | tr -d '"' || true)
    if [[ -n "$FEATURES" ]]; then
        UNCOVERED=""
        while IFS= read -r feat; do
            feat_clean=$(echo "$feat" | tr -d ' ')
            if ! grep -qi "$feat_clean" "$BELIEFS" 2>/dev/null; then
                UNCOVERED="$UNCOVERED  NO ASSERTIONS: $feat_clean\n"
            fi
        done <<< "$FEATURES"
        if [[ -n "$UNCOVERED" ]]; then
            echo -e "$UNCOVERED"
            echo "  DISCONNECT: features exist without assertions to verify them"
            DISCONNECTS=$((DISCONNECTS + 1))
        else
            echo "  OK: all features have assertions"
        fi
    fi
else
    echo "  SKIP: missing founder.yml or beliefs.yml"
fi
echo ""

# --- 3. Eval scores vs Thesis claims ---
echo "▾ EVAL SCORES vs THESIS"
CHECKS=$((CHECKS + 1))
if [[ -f "$EVAL_CACHE" ]] && [[ -f "$ROADMAP" ]] && command -v jq &>/dev/null; then
    # Get active thesis description
    THESIS=$(awk '/status: active/,/^  v[0-9]/{print}' "$ROADMAP" 2>/dev/null | head -5)
    echo "  thesis: $(echo "$THESIS" | grep 'description:' | sed 's/.*description:\s*//' | head -1)"

    # Check if any high-weight features are low-scoring
    LOW_HIGH=$(jq -r 'to_entries[] | select(.value.score != null and .value.score < 50 and (.value.weight // 3) >= 4) |
      "  HIGH-WEIGHT LOW-SCORE: \(.key) weight:\(.value.weight // 3) score:\(.value.score)"' "$EVAL_CACHE" 2>/dev/null)
    if [[ -n "$LOW_HIGH" ]]; then
        echo "$LOW_HIGH"
        echo "  DISCONNECT: thesis depends on features that aren't delivering"
        DISCONNECTS=$((DISCONNECTS + 1))
    else
        echo "  OK: high-weight features are scoring adequately"
    fi
else
    echo "  SKIP: missing eval-cache or roadmap"
fi
echo ""

# --- 4. Narrative vs Reality ---
echo "▾ NARRATIVE vs EVIDENCE"
CHECKS=$((CHECKS + 1))
if [[ -f "$NARRATIVE" ]] && [[ -f "$ROADMAP" ]]; then
    echo "  narrative: present"
    # Check if narrative references things that roadmap shows as unproven
    UNPROVEN=$(awk '/evidence:/{found=1; next} found && /proven: false|status: untested/{print "  UNPROVEN: " $0; next} found && /^[a-z]/{found=0}' "$ROADMAP" 2>/dev/null || true)
    if [[ -n "$UNPROVEN" ]]; then
        echo "$UNPROVEN"
        echo "  CHECK: ensure narrative doesn't claim things that evidence hasn't proven"
        DISCONNECTS=$((DISCONNECTS + 1))
    else
        echo "  OK: no unproven evidence items found"
    fi
else
    if [[ ! -f "$NARRATIVE" ]]; then
        echo "  (no narrative.yml — run /roadmap narrative to generate)"
    fi
fi
echo ""

# --- 5. Hypothesis vs Features ---
echo "▾ HYPOTHESIS vs FEATURES"
CHECKS=$((CHECKS + 1))
if [[ -f "$FOUNDER_YML" ]]; then
    HYPOTHESIS=$(grep -E '^\s+hypothesis:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*hypothesis:\s*//' || true)
    FEAT_COUNT=$(grep -c -E '^\s+-\s+name:' "$FOUNDER_YML" 2>/dev/null | tail -1 || echo "0")
    FEAT_COUNT=$(echo "$FEAT_COUNT" | tr -d '[:space:]')
    if [[ -n "$HYPOTHESIS" ]]; then
        echo "  hypothesis: $HYPOTHESIS"
        echo "  features: $FEAT_COUNT defined"
        if [[ "$FEAT_COUNT" -eq 0 ]]; then
            echo "  DISCONNECT: hypothesis exists but no features to deliver it"
            DISCONNECTS=$((DISCONNECTS + 1))
        fi
    else
        echo "  DISCONNECT: no hypothesis — features exist without a reason"
        DISCONNECTS=$((DISCONNECTS + 1))
    fi
fi
echo ""

# --- 6. Claim verification (do features deliver what they claim?) ---
echo "▾ CLAIM vs REALITY"
CHECKS=$((CHECKS + 1))
CLAIM_CACHE="$PROJECT_DIR/.claude/cache/claim-verify.json"
CLAIM_SCRIPT="$(cd "$(dirname "$0")/../../shared" 2>/dev/null && pwd)/claim-verify.sh"
# Read from cache if <1 hour old, otherwise re-run
CLAIM_RESULT=""
if [[ -f "$CLAIM_CACHE" ]]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f%m "$CLAIM_CACHE" 2>/dev/null || stat -c%Y "$CLAIM_CACHE" 2>/dev/null || echo "0") ))
    if [[ "$CACHE_AGE" -lt 3600 ]]; then
        CLAIM_RESULT=$(cat "$CLAIM_CACHE" 2>/dev/null)
    fi
fi
if [[ -z "$CLAIM_RESULT" && -f "$CLAIM_SCRIPT" ]]; then
    CLAIM_RESULT=$(bash "$CLAIM_SCRIPT" "$PROJECT_DIR" 2>/dev/null)
fi
if [[ -n "$CLAIM_RESULT" ]] && command -v jq &>/dev/null; then
    OVERALL_PCT=$(echo "$CLAIM_RESULT" | jq -r '.overall_pass_rate // 0')
    echo "  overall claim delivery: ${OVERALL_PCT}%"

    # Show features with gaps
    GAPS=$(echo "$CLAIM_RESULT" | jq -r '.features | to_entries[] | select(.value.verdict == "gap" or .value.verdict == "broken") | "  \(.value.verdict | ascii_upcase): \(.key) — \(.value.claim)"' 2>/dev/null)
    if [[ -n "$GAPS" ]]; then
        echo "$GAPS"
        echo "  DISCONNECT: features exist that don't deliver their claims"
        DISCONNECTS=$((DISCONNECTS + 1))
    else
        echo "  OK: all features delivering on claims (${OVERALL_PCT}%+)"
    fi
else
    echo "  SKIP: no claim data (run claim-verify.sh to populate)"
fi
echo ""

# --- 7. Topology coherence (features ↔ surfaces) ---
echo "▾ TOPOLOGY COHERENCE"
CHECKS=$((CHECKS + 1))
TOPO_CACHE="$PROJECT_DIR/.claude/cache/topology.json"
if [[ -f "$TOPO_CACHE" ]] && command -v jq &>/dev/null; then
    ORPHAN_COUNT=$(jq -r '.stats.orphan_count // 0' "$TOPO_CACHE" 2>/dev/null)
    DEAD_END_COUNT=$(jq -r '.stats.dead_end_count // 0' "$TOPO_CACHE" 2>/dev/null)

    # Features with no surfaces (not reachable)
    NO_SURFACE=$(jq -r '.journey_positions | to_entries[] | select(.value.surfaces == 0) | .key' "$TOPO_CACHE" 2>/dev/null)
    if [[ -n "$NO_SURFACE" ]]; then
        echo "  FEATURES WITH NO SURFACES:"
        echo "$NO_SURFACE" | while IFS= read -r f; do
            echo "    $f — defined in founder.yml but not bound to any skill or CLI command"
        done
        DISCONNECTS=$((DISCONNECTS + 1))
    fi

    # Orphan skills (no skill leads to them)
    ORPHAN_SKILLS=$(jq -r '[.orphans[] | select(startswith("skill/"))] | join(", ")' "$TOPO_CACHE" 2>/dev/null)
    if [[ -n "$ORPHAN_SKILLS" && "$ORPHAN_SKILLS" != "" ]]; then
        echo "  ORPHAN SKILLS (nothing leads to them): $ORPHAN_SKILLS"
    fi

    if [[ "$ORPHAN_COUNT" -gt 5 ]]; then
        echo "  DISCONNECT: $ORPHAN_COUNT orphan surfaces — product has navigation gaps"
        DISCONNECTS=$((DISCONNECTS + 1))
    else
        echo "  OK: topology shows $ORPHAN_COUNT orphans, $DEAD_END_COUNT dead ends"
    fi
else
    echo "  SKIP: no topology.json — run: bash skills/shared/product-topology.sh ."
fi
echo ""

# --- Summary ---
echo "=== COHERENCE SUMMARY ==="
echo "  checks: $CHECKS"
echo "  disconnects: $DISCONNECTS"
if [[ $DISCONNECTS -eq 0 ]]; then
    echo "  status: COHERENT — claims align with evidence"
elif [[ $DISCONNECTS -le 2 ]]; then
    echo "  status: MINOR GAPS — some claims outpace evidence"
else
    echo "  status: INCOHERENT — product says one thing and does another"
fi
echo ""
echo "=== CHECK COMPLETE ==="
