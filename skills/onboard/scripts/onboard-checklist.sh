#!/usr/bin/env bash
# Check what's already been set up by founder-os.
# Outputs a checklist of setup state — helps /onboard decide what to create vs skip.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "── onboard checklist ──"
echo ""

SETUP_COUNT=0
TOTAL_CHECKS=8

# 1. founder.yml
if [[ -f "$PROJECT_DIR/config/founder.yml" ]]; then
    echo "  ✓ config/founder.yml exists"
    # Check if it has real content or just template
    if grep -q 'hypothesis: ""' "$PROJECT_DIR/config/founder.yml" 2>/dev/null; then
        echo "    · hypothesis is empty (template only)"
    else
        echo "    ✓ hypothesis populated"
        SETUP_COUNT=$((SETUP_COUNT + 1))
    fi
    # Check features
    FEATURE_COUNT=$(grep -c "^  [a-z]" "$PROJECT_DIR/config/founder.yml" 2>/dev/null || echo 0)
    if [[ "$FEATURE_COUNT" -gt 0 ]]; then
        echo "    ✓ $FEATURE_COUNT features defined"
        SETUP_COUNT=$((SETUP_COUNT + 1))
    else
        echo "    · no features defined"
    fi
else
    echo "  · config/founder.yml (missing)"
fi

# 2. beliefs.yml
if [[ -f "$PROJECT_DIR/beliefs.yml" ]]; then
    BELIEF_COUNT=$(grep -c "^  - claim:" "$PROJECT_DIR/beliefs.yml" 2>/dev/null || echo 0)
    echo "  ✓ beliefs.yml — $BELIEF_COUNT assertions"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · beliefs.yml (missing)"
fi

# 3. Predictions
PRED_FILE=""
[[ -f "$PROJECT_DIR/.claude/knowledge/predictions.tsv" ]] && PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ -z "$PRED_FILE" && -f "$HOME/.claude/knowledge/predictions.tsv" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -n "$PRED_FILE" ]]; then
    PRED_COUNT=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    echo "  ✓ predictions.tsv — $PRED_COUNT predictions logged"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · predictions.tsv (missing)"
fi

# 4. Experiment learnings
LEARN_FILE=""
[[ -f "$PROJECT_DIR/.claude/knowledge/experiment-learnings.md" ]] && LEARN_FILE="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ -z "$LEARN_FILE" && -f "$HOME/.claude/knowledge/experiment-learnings.md" ]] && LEARN_FILE="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -n "$LEARN_FILE" ]]; then
    echo "  ✓ experiment-learnings.md"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · experiment-learnings.md (missing)"
fi

# 5. Strategy
if [[ -f "$PROJECT_DIR/.claude/plans/strategy.yml" ]]; then
    echo "  ✓ strategy.yml"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · strategy.yml (missing)"
fi

# 6. Roadmap
if [[ -f "$PROJECT_DIR/.claude/plans/roadmap.yml" ]]; then
    echo "  ✓ roadmap.yml"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · roadmap.yml (missing)"
fi

# 7. Eval cache
if [[ -f "$PROJECT_DIR/.claude/cache/eval-cache.json" ]]; then
    echo "  ✓ eval-cache.json (scores cached)"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · eval-cache.json (no cached scores)"
fi

# 8. Score history
if [[ -f "$PROJECT_DIR/.claude/scores/history.tsv" ]]; then
    SCORE_COUNT=$(tail -n +2 "$PROJECT_DIR/.claude/scores/history.tsv" 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ score history — $SCORE_COUNT entries"
    SETUP_COUNT=$((SETUP_COUNT + 1))
else
    echo "  · score history (no scores yet)"
fi

echo ""
echo "  setup: $SETUP_COUNT/$TOTAL_CHECKS complete"

if [[ "$SETUP_COUNT" -ge 6 ]]; then
    echo "  status: fully initialized — use --force to regenerate"
elif [[ "$SETUP_COUNT" -ge 3 ]]; then
    echo "  status: partially initialized — will fill gaps"
else
    echo "  status: fresh project — full onboard needed"
fi
