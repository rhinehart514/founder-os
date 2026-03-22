#!/usr/bin/env bash
# post_compact.sh — PostCompact hook (non-blocking)
# Re-injects state bar + active plan + resume instructions after compaction.
# DIFFERENT from pre_compact.sh: pre fires BEFORE compression, post fires AFTER.
# Outputs MORE context for recovery. Target: <100ms (pure file reads).

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(pwd)

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _PC_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_PC_SOURCE" ]]; do _PC_SOURCE="$(readlink "$_PC_SOURCE")"; done
    _PC_DIR="$(cd "$(dirname "$_PC_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_PC_DIR/.." && pwd)"
fi

# Colors
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_CYAN='\033[0;36m'
C_NC='\033[0m'

SEP="  ${C_DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${C_NC}"

echo ""
echo -e "${SEP}"
echo -e "  ${C_YELLOW}↻${C_NC} ${C_BOLD}Context compacted — recovery state${C_NC}"
echo -e "${SEP}"
echo ""

# --- 1. State bar: score, assertions, health ---
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    TOTAL=$(jq -r '.score // "?"' "$SCORE_CACHE" 2>/dev/null || echo "?")
    ASSERTION_COUNT=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    ASSERTION_PASS=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    HEALTH_MIN=$(jq -r '.health_min // "?"' "$SCORE_CACHE" 2>/dev/null || echo "?")

    echo -e "  ${C_DIM}score${C_NC}       ${C_BOLD}${TOTAL}${C_NC}${C_DIM}/100${C_NC}  ${C_DIM}·${C_NC}  assertions ${ASSERTION_PASS}/${ASSERTION_COUNT}  ${C_DIM}·${C_NC}  health ${HEALTH_MIN}"
else
    echo -e "  ${C_DIM}score${C_NC}       ${C_DIM}no cache yet — quality check runs after next code change${C_NC}"
fi

# --- 2. Active plan + next 2-3 tasks ---
PLAN_FILE=""
for p in "$PROJECT_DIR/.claude/plans/plan.yml" "$HOME/.claude/plans/plan.yml"; do
    if [[ -f "$p" ]]; then PLAN_FILE="$p"; break; fi
done

if [[ -n "$PLAN_FILE" ]]; then
    PLAN_NAME=$(grep -m1 'name:' "$PLAN_FILE" 2>/dev/null | sed 's/.*name: *//' | sed 's/"//g' || echo "unknown")
    TASKS_TODO=$(grep -c 'status: todo' "$PLAN_FILE" 2>/dev/null || true)
    TASKS_DONE=$(grep -c 'status: done' "$PLAN_FILE" 2>/dev/null || true)
    TASKS_TODO=${TASKS_TODO:-0}
    TASKS_DONE=${TASKS_DONE:-0}

    echo -e "  ${C_DIM}plan${C_NC}        \"${PLAN_NAME}\" — ${TASKS_DONE} done, ${TASKS_TODO} remaining"

    # Next 2-3 todo task titles
    NEXT_TASKS=$(grep -B1 'status: todo' "$PLAN_FILE" 2>/dev/null | grep 'title:' | head -3 | sed 's/.*title: *//' || true)
    if [[ -n "$NEXT_TASKS" ]]; then
        echo -e "  ${C_DIM}next${C_NC}        "
        while IFS= read -r task; do
            [[ -z "$task" ]] && continue
            echo -e "              ${C_GREEN}▸${C_NC} ${task}"
        done <<< "$NEXT_TASKS"
    fi
else
    echo -e "  ${C_DIM}plan${C_NC}        none active"
fi

# --- 3. Current bottleneck from strategy.yml ---
STRATEGY_FILE="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY_FILE" ]]; then
    BOTTLENECK=$(grep -m1 'bottleneck:' "$STRATEGY_FILE" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' || echo "unknown")
    echo -e "  ${C_DIM}bottleneck${C_NC}  ${BOTTLENECK}"
fi

# --- 4. Current thesis from roadmap.yml ---
ROADMAP_FILE="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP_FILE" ]]; then
    CURRENT_V=$(grep -m1 'current:' "$ROADMAP_FILE" 2>/dev/null | sed 's/.*current: *//' || echo "?")
    THESIS=$(grep -A2 "^  ${CURRENT_V}:" "$ROADMAP_FILE" 2>/dev/null | grep 'thesis:' | sed 's/.*thesis: *//' | sed 's/"//g' || echo "?")
    echo -e "  ${C_DIM}thesis${C_NC}      ${CURRENT_V}: \"${THESIS}\""
fi

echo ""

# --- 5. Re-read instructions ---
echo -e "  ${C_BOLD}Re-read these files:${C_NC}"
echo -e "    ${C_DIM}1.${C_NC} mind/thinking.md"
echo -e "    ${C_DIM}2.${C_NC} ~/.claude/knowledge/experiment-learnings.md"
echo -e "    ${C_DIM}3.${C_NC} .claude/plans/plan.yml"
echo -e "    ${C_DIM}4.${C_NC} .claude/plans/strategy.yml"
echo -e "    ${C_DIM}5.${C_NC} .claude/plans/roadmap.yml"
echo -e "    ${C_DIM}6.${C_NC} .claude/cache/eval-cache.json"
echo -e "    ${C_DIM}7.${C_NC} active tasks (TaskList)"
echo ""

# --- 6. Recovery hint ---
echo -e "  ${C_GREEN}▸${C_NC} Continue with the next task in the plan."
echo ""
