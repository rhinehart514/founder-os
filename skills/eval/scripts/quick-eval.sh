#!/usr/bin/env bash
# Quick assertion eval — mechanical checks only, no LLM judge
# Usage: bash scripts/quick-eval.sh [feature]
# Output: pass/fail counts, per-feature breakdown if --by-feature
# Exit 0 always — eval is measurement, not a gate
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEATURE="${1:-}"

echo "── quick eval (mechanical only) ──"

if [[ -n "$FEATURE" ]]; then
    "$FOUNDER_DIR/bin/eval.sh" --no-llm --score --feature "$FEATURE" 2>/dev/null || {
        echo "  eval.sh failed for feature: $FEATURE"
        echo "  check: config/founder.yml has feature defined, code paths exist"
        exit 0
    }
else
    "$FOUNDER_DIR/bin/eval.sh" --no-llm --score 2>/dev/null || {
        echo "  eval.sh failed"
        echo "  check: config/founder.yml exists and has features defined"
        exit 0
    }
fi

# Show belief summary if beliefs.yml exists
BELIEFS="$FOUNDER_DIR/lens/product/eval/beliefs.yml"
if [[ -f "$BELIEFS" ]]; then
    TOTAL=$(grep -c "^  - " "$BELIEFS" 2>/dev/null || echo 0)
    echo ""
    echo "  beliefs file: $TOTAL assertions defined"
fi
