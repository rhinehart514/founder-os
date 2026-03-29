#!/usr/bin/env bash
# kill-audit.sh — Find things that should be killed.
# Scans for stale todos, passing-but-useless assertions, features that aren't advancing.
set -euo pipefail

PROJECT_DIR="${1:-.}"
NOW=$(date +%s)

echo "=== KILL CANDIDATES ==="
echo ""

# --- Open todos (no date comparison — listed for manual review) ---
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS" ]]; then
    echo "▸ Open todos (age unknown — no date comparison):"
    # Note: no date parsing implemented; listing open items for manual review
    grep -B2 'status: todo\|status: captured' "$TODOS" 2>/dev/null | grep 'title:' | sed 's/.*title: */  /' | head -5
    echo ""
fi

# --- Always-passing assertions (low signal) ---
BELIEFS="$PROJECT_DIR/lens/product/eval/beliefs.yml"
[[ ! -f "$BELIEFS" ]] && BELIEFS="$PROJECT_DIR/config/evals/beliefs.yml"
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$BELIEFS" ]] && [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▸ Always-passing assertions (consider killing):"
    # file_check assertions that check for existence are low-signal
    grep -B1 'type: file_check' "$BELIEFS" 2>/dev/null | grep 'id:' | sed 's/.*id: */  /' | head -5
    echo ""
fi

# --- Features with no score movement ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▸ Stuck features (delta: same):"
    jq -r 'to_entries[] | select(.value.delta == "same" and .value.score != null) | "  \(.key): \(.value.score)/100 — no movement"' "$EVAL_CACHE" 2>/dev/null
    echo ""
fi

# --- Killed features (for reference — don't re-propose) ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    echo "▸ Already killed (don't re-propose):"
    grep -A1 'status: killed' "$FOUNDER_YML" 2>/dev/null | grep 'killed_reason:' | sed 's/.*killed_reason: */  /' | head -5
    echo ""
fi

echo "=== AUDIT COMPLETE ==="
