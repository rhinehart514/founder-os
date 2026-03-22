#!/usr/bin/env bash
# subagent_start.sh — SubagentStart hook (non-blocking)
# Injects role-specific context before agent starts.
# Target: <50ms (pure file reads).

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(pwd)

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SA_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SA_SOURCE" ]]; do _SA_SOURCE="$(readlink "$_SA_SOURCE")"; done
    _SA_DIR="$(cd "$(dirname "$_SA_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_SA_DIR/.." && pwd)"
fi

# Colors
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_CYAN='\033[0;36m'
C_NC='\033[0m'

# --- Parse agent type from input ---
AGENT_TYPE=""
if command -v jq &>/dev/null; then
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null || echo "")
else
    AGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"agent_type"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

[[ -z "$AGENT_TYPE" ]] && exit 0

case "$AGENT_TYPE" in
    *builder*)
        # Output design system + bottleneck
        if [[ -f "$PROJECT_DIR/.claude/design-system.md" ]]; then
            echo -e "${C_DIM}--- design system ---${C_NC}"
            cat "$PROJECT_DIR/.claude/design-system.md"
            echo ""
        fi
        STRATEGY_FILE="$PROJECT_DIR/.claude/plans/strategy.yml"
        if [[ -f "$STRATEGY_FILE" ]]; then
            BOTTLENECK=$(grep -m1 'bottleneck:' "$STRATEGY_FILE" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' || true)
            [[ -n "$BOTTLENECK" ]] && echo -e "${C_DIM}bottleneck:${C_NC} ${BOTTLENECK}"
        fi
        ;;

    *evaluator*)
        # Output baseline scores from eval-cache.json
        EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
        if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
            echo -e "${C_DIM}--- eval baseline ---${C_NC}"
            jq -r 'to_entries[] | "\(.key): \(.value.score // .value.pass // "?")"' "$EVAL_CACHE" 2>/dev/null | head -20 || true
            echo ""
        fi
        ;;

    *reviewer*)
        # Output UX checklist summary
        UX_CHECKLIST="$FOUNDER_DIR/lens/product/mind/product-standards.md"
        if [[ -f "$UX_CHECKLIST" ]]; then
            echo -e "${C_DIM}--- UX checklist ---${C_NC}"
            # Extract just the numbered items
            grep -E '^\d+\.' "$UX_CHECKLIST" 2>/dev/null | head -10 || true
            echo ""
        fi
        ;;

    *explorer*|*market*)
        # Output Unknown Territory section from experiment-learnings.md
        LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
        [[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
        if [[ -f "$LEARNINGS" ]]; then
            echo -e "${C_DIM}--- unknown territory ---${C_NC}"
            # Extract from "Unknown Territory" heading to next heading
            sed -n '/^## Unknown Territory/,/^## /{/^## Unknown Territory/d;/^## /d;p;}' "$LEARNINGS" 2>/dev/null | head -20 || true
            echo ""
        fi
        ;;

    *)
        # No additional context for other agent types
        ;;
esac
