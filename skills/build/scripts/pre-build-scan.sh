#!/usr/bin/env bash
# pre-build-scan.sh — Full project state scan before entering the /go loop.
# Outputs structured sections. Zero context cost — only output enters conversation.
# Usage: bash scripts/pre-build-scan.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve FOUNDER_DIR: env var > install-path > relative to script
if [[ -n "${FOUNDER_DIR:-}" && -d "$FOUNDER_DIR/bin" ]]; then
    : # use existing FOUNDER_DIR
elif [[ -f "$HOME/.config/founder-os/install-path" ]]; then
    FOUNDER_DIR="$(cat "$HOME/.config/founder-os/install-path")"
else
    FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Check dependencies (graceful if check-deps.sh missing in plugin cache)
if [[ -f "$FOUNDER_DIR/bin/lib/check-deps.sh" ]]; then
    source "$FOUNDER_DIR/bin/lib/check-deps.sh"
    require_cmd jq "brew install jq"
else
    command -v jq &>/dev/null || { echo "jq required: brew install jq"; exit 1; }
fi

# --- Current score ---
echo "=== CURRENT SCORE ==="
if [[ -f "$FOUNDER_DIR/bin/score.sh" ]]; then
    bash "$FOUNDER_DIR/bin/score.sh" "$PROJECT_DIR" 2>/dev/null | tail -5 || echo "(score.sh failed)"
else
    echo "(no score.sh found)"
fi
echo ""

# --- Eval cache: per-feature scores ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "=== FEATURE SCORES ==="
    jq -r 'to_entries[] | select(.value.score != null) | "\(.key): \(.value.score) (d:\(.value.delivery_score // "?") c:\(.value.craft_score // "?") v:\(.value.viability_score // "?")) delta:\(.value.delta // "none")"' "$EVAL_CACHE" 2>/dev/null || echo "(parse error)"
    echo ""
    WEAKEST=$(jq -r 'to_entries | map(select(.value.score != null)) | sort_by(.value.score) | .[0] | "\(.key) at \(.value.score)"' "$EVAL_CACHE" 2>/dev/null || echo "unknown")
    echo "BOTTLENECK: $WEAKEST"
    echo ""
fi

# --- Failing assertions ---
echo "=== ASSERTION STATUS ==="
bash "$SCRIPT_DIR/assertion-gate.sh" 2>/dev/null || echo "(assertion check failed)"
echo ""

# Detailed failures from beliefs
BELIEFS="$PROJECT_DIR/config/beliefs.yml"
if [[ -f "$BELIEFS" ]]; then
    FAIL_COUNT=$(grep -c 'status: fail' "$BELIEFS" 2>/dev/null || echo "0")
    if [[ "$FAIL_COUNT" -gt 0 ]]; then
        echo "FAILING ($FAIL_COUNT):"
        grep -B2 'status: fail' "$BELIEFS" 2>/dev/null | grep -E 'name:|claim:' | sed 's/^  /  /' | head -20
    fi
    echo ""
fi

# --- Plan tasks ---
PLAN="$PROJECT_DIR/.claude/plans/plan.yml"
if [[ -f "$PLAN" ]]; then
    echo "=== PLAN TASKS ==="
    grep -E 'title:|status:' "$PLAN" 2>/dev/null | paste - - | head -10
    echo ""
fi

# --- Active todos (promoted = founder priority) ---
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS" ]]; then
    echo "=== PROMOTED TODOS ==="
    # Find promoted/active items
    grep -B1 -A3 'promoted: true\|priority: high' "$TODOS" 2>/dev/null | head -20 || echo "(none promoted)"
    echo ""
fi

# --- Strategy ---
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY" ]]; then
    echo "=== STRATEGY ==="
    grep -E 'bottleneck:|stage:|focus:' "$STRATEGY" 2>/dev/null | head -5
    echo ""
fi

# --- Recent predictions (last 5) ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    echo "=== RECENT PREDICTIONS (last 5) ==="
    tail -5 "$PRED_FILE" | while IFS=$'\t' read -r date pred evidence result correct update; do
        STATUS="${correct:-ungraded}"
        echo "  [$STATUS] $pred"
        [[ -n "${update:-}" ]] && echo "    model: $update"
    done
    # Accuracy
    TOTAL=$(tail -n +2 "$PRED_FILE" | grep -c -E '\t(yes|no|partial)\t' || echo "0")
    CORRECT=$(tail -n +2 "$PRED_FILE" | grep -c -E '\tyes\t' || echo "0")
    echo "  accuracy: $CORRECT/$TOTAL graded"
    echo ""
fi

# --- Experiment learnings: dead ends + unknown territory ---
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    echo "=== DEAD ENDS (avoid these) ==="
    awk '/^## Dead Ends/,/^## /{if(/^## / && !/Dead Ends/) exit; print}' "$LEARNINGS" 2>/dev/null | grep -E '^\s*-' | head -5
    echo ""
    echo "=== UNKNOWN TERRITORY (highest learning value) ==="
    awk '/^## Unknown Territory/,/^## /{if(/^## / && !/Unknown/) exit; print}' "$LEARNINGS" 2>/dev/null | grep -E '^\s*-' | head -5
    echo ""
fi

# --- Roadmap thesis ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    echo "=== CURRENT THESIS ==="
    grep -E 'thesis:|version:' "$ROADMAP" 2>/dev/null | head -3
    echo ""
fi

# --- Git state ---
echo "=== GIT STATE ==="
git -C "$PROJECT_DIR" status --short 2>/dev/null | head -10 || echo "(not a git repo)"
DIRTY=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[[ "$DIRTY" -gt 0 ]] && echo "WARNING: $DIRTY uncommitted changes — stash before building"
echo ""

# --- Plateau check ---
echo "=== PLATEAU STATUS ==="
bash "$SCRIPT_DIR/plateau-check.sh" 2>/dev/null || echo "(plateau check unavailable)"
echo ""

echo "=== SCAN COMPLETE ==="
