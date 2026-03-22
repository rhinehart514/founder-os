#!/usr/bin/env bash
# pre_compact.sh — PreCompact hook
# Fires before context compression. Saves critical state so the model
# can reconstruct its working context after compaction.
# Must be fast (<200ms). Output is injected into the compacted context.
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
C_CYAN='\033[0;36m'
C_NC='\033[0m'

echo ""
echo -e "${C_CYAN}◆${C_NC} ${C_BOLD}context compacted${C_NC} — rebuild from:"
echo ""

# 1. Active plan
if [[ -f "$PROJECT_DIR/.claude/plans/plan.yml" ]]; then
    PLAN_NAME=$(grep -m1 'name:' "$PROJECT_DIR/.claude/plans/plan.yml" 2>/dev/null | sed 's/.*name: *//' | sed 's/"//g' || echo "unknown")
    TASKS_TODO=$(grep -c 'status: todo' "$PROJECT_DIR/.claude/plans/plan.yml" 2>/dev/null || true)
    TASKS_DONE=$(grep -c 'status: done' "$PROJECT_DIR/.claude/plans/plan.yml" 2>/dev/null || true)
    TASKS_TODO=${TASKS_TODO:-0}
    TASKS_DONE=${TASKS_DONE:-0}
    echo -e "  ${C_DIM}plan${C_NC}     \"${PLAN_NAME}\" — ${TASKS_DONE} done, ${TASKS_TODO} remaining"
else
    echo -e "  ${C_DIM}plan${C_NC}     none"
fi

# 2. Score + worst feature
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    SCORE=$(jq -r '.score // "?"' "$SCORE_CACHE" 2>/dev/null)
    WORST=$(jq -r '.features // {} | to_entries | sort_by(if .value.type == "generative" then .value.score else (.value.pass / (.value.total + 0.001) * 100) end) | .[0] | .key // "none"' "$SCORE_CACHE" 2>/dev/null || echo "none")
    WORST_SCORE=$(jq -r '.features // {} | to_entries | sort_by(if .value.type == "generative" then .value.score else (.value.pass / (.value.total + 0.001) * 100) end) | .[0] | if .value.type == "generative" then .value.score else (.value.pass * 100 / (.value.total + 1) | floor) end // "?"' "$SCORE_CACHE" 2>/dev/null || echo "?")
    echo -e "  ${C_DIM}score${C_NC}    ${SCORE}/100 — worst: ${WORST} (${WORST_SCORE})"
fi

# 3. Current bottleneck from strategy
if [[ -f "$PROJECT_DIR/.claude/plans/strategy.yml" ]]; then
    BOTTLENECK=$(grep -m1 'bottleneck:' "$PROJECT_DIR/.claude/plans/strategy.yml" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' || echo "unknown")
    echo -e "  ${C_DIM}bottleneck${C_NC} ${BOTTLENECK}"
fi

# 4. Current thesis
if [[ -f "$PROJECT_DIR/.claude/plans/roadmap.yml" ]]; then
    CURRENT_V=$(grep -m1 'current:' "$PROJECT_DIR/.claude/plans/roadmap.yml" 2>/dev/null | sed 's/.*current: *//' || echo "?")
    THESIS=$(grep -A2 "^  ${CURRENT_V}:" "$PROJECT_DIR/.claude/plans/roadmap.yml" 2>/dev/null | grep 'thesis:' | sed 's/.*thesis: *//' | sed 's/"//g' || echo "?")
    echo -e "  ${C_DIM}thesis${C_NC}   ${CURRENT_V}: \"${THESIS}\""
fi

# 5. Re-read instructions
echo ""
echo -e "  ${C_DIM}re-read:${C_NC}"
echo -e "    1. mind/thinking.md"
echo -e "    2. ~/.claude/knowledge/experiment-learnings.md"
echo -e "    3. .claude/plans/plan.yml"
echo -e "    4. active tasks (TaskList)"
echo ""
