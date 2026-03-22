#!/usr/bin/env bash
# system-pulse.sh — Full system status for /founder dashboard.
# Scans all project state, outputs structured key-value pairs.
# Zero context cost — only the output enters the conversation.
#
# Usage: bash skills/founder/scripts/system-pulse.sh [project-dir]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Check dependencies
source "$FOUNDER_DIR/bin/lib/check-deps.sh"
require_cmd jq "brew install jq"
require_cmd python3 "brew install python3"

echo "=== PORTFOLIO ==="
PORTFOLIO="$HOME/.founder-os/portfolio.yml"
if [[ -f "$PORTFOLIO" ]]; then
    TOTAL=$(grep -c '^\s*- name:' "$PORTFOLIO" 2>/dev/null || echo "0")
    ACTIVE=$(grep -c 'status: active' "$PORTFOLIO" 2>/dev/null || echo "0")
    KILLED=$(grep -c 'status: killed' "$PORTFOLIO" 2>/dev/null || echo "0")
    SHIPPED=$(grep -c 'status: shipped' "$PORTFOLIO" 2>/dev/null || echo "0")
    echo "total: $TOTAL"
    echo "active: $ACTIVE"
    echo "killed: $KILLED"
    echo "shipped: $SHIPPED"
else
    echo "portfolio: none"
fi
echo ""

echo "=== SCORE ==="
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    jq -r '"score: \(.score // "?")\nhealth: \(.health // "?")\nstructure: \(.structure // "?")\nhygiene: \(.hygiene // "?")"' "$SCORE_CACHE" 2>/dev/null || echo "score: (parse error)"
else
    echo "score: --"
fi
echo ""

echo "=== EVAL ==="
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    jq -r 'to_entries[] | select(.value.score != null) | "\(.key): \(.value.score) (d:\(.value.delivery_score // 0) c:\(.value.craft_score // 0) v:\(.value.viability_score // 0)) w:\(.value.weight // 1) delta:\(.value.delta // "none")"' "$EVAL_CACHE" 2>/dev/null || echo "(parse error)"
    echo ""
    # Product completion via shared script
    if [[ -x "$FOUNDER_DIR/bin/compute-completion.sh" ]]; then
        bash "$FOUNDER_DIR/bin/compute-completion.sh" "$EVAL_CACHE" "$PROJECT_DIR/config/founder.yml" "$PROJECT_DIR/.claude/plans/roadmap.yml" 2>/dev/null || true
    fi
else
    echo "eval: no cache"
fi
echo ""

echo "=== BOTTLENECK ==="
if [[ -x "$FOUNDER_DIR/bin/compute-bottleneck.sh" ]]; then
    BN=$(bash "$FOUNDER_DIR/bin/compute-bottleneck.sh" "$EVAL_CACHE" "$PROJECT_DIR/config/founder.yml" 2>/dev/null | head -1) || true
    if [[ -n "$BN" ]]; then
        echo "feature: $(echo "$BN" | cut -f1)"
        echo "score: $(echo "$BN" | cut -f2)"
        echo "weight: $(echo "$BN" | cut -f3)"
        echo "weakest_dim: $(echo "$BN" | cut -f5)"
    else
        echo "bottleneck: none computed"
    fi
else
    echo "bottleneck: script missing"
fi
echo ""

echo "=== ASSERTIONS ==="
BELIEFS="$PROJECT_DIR/lens/product/eval/beliefs.yml"
if [[ -f "$BELIEFS" ]]; then
    TOTAL=$(grep -c '^\s*- ' "$BELIEFS" 2>/dev/null || echo "0")
    echo "total: $TOTAL"
else
    echo "total: 0 (no beliefs.yml)"
fi
echo ""

echo "=== PREDICTIONS ==="
PRED="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED" ]] && PRED="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED" ]]; then
    TOTAL=$(tail -n +2 "$PRED" | wc -l | tr -d ' ')
    GRADED=$(tail -n +2 "$PRED" | awk -F'\t' '$6 != ""' | wc -l | tr -d ' ')
    UNGRADED=$((TOTAL - GRADED))
    CORRECT=$(tail -n +2 "$PRED" | awk -F'\t' '$6 == "yes"' | wc -l | tr -d ' ')
    PARTIAL=$(tail -n +2 "$PRED" | awk -F'\t' '$6 == "partial"' | wc -l | tr -d ' ')
    WRONG=$(tail -n +2 "$PRED" | awk -F'\t' '$6 == "no"' | wc -l | tr -d ' ')
    if [[ "$GRADED" -gt 0 ]]; then
        # accuracy with partials at 0.5
        ACCURACY=$(python3 -c "print(round(($CORRECT + $PARTIAL * 0.5) / $GRADED * 100))" 2>/dev/null || echo "?")
    else
        ACCURACY="--"
    fi
    echo "total: $TOTAL"
    echo "graded: $GRADED"
    echo "ungraded: $UNGRADED"
    echo "accuracy: $ACCURACY%"
    # Last prediction date
    LAST_DATE=$(tail -1 "$PRED" | cut -f1)
    echo "last_prediction: $LAST_DATE"
    # Days since last prediction
    if [[ -n "$LAST_DATE" ]] && command -v python3 &>/dev/null; then
        DAYS_AGO=$(python3 -c "
from datetime import datetime, date
try:
    d = datetime.strptime('$LAST_DATE'.strip()[:10], '%Y-%m-%d').date()
    print((date.today() - d).days)
except: print('?')
" 2>/dev/null)
        echo "days_since_prediction: $DAYS_AGO"
    fi
else
    echo "predictions: none"
fi
echo ""

echo "=== PLAN ==="
PLAN="$PROJECT_DIR/.claude/plans/plan.yml"
if [[ -f "$PLAN" ]]; then
    TODO=$(grep -c 'status: todo' "$PLAN" 2>/dev/null || true)
    TODO="${TODO:-0}"
    TODO=$(echo "$TODO" | tr -d '[:space:]')
    DONE=$(grep -c 'status: done' "$PLAN" 2>/dev/null || true)
    DONE="${DONE:-0}"
    DONE=$(echo "$DONE" | tr -d '[:space:]')
    TOTAL=$((TODO + DONE))
    echo "tasks_remaining: $TODO"
    echo "tasks_done: $DONE"
    echo "tasks_total: $TOTAL"
    # Bottleneck feature from plan
    BN_FEAT=$(grep 'bottleneck_feature:' "$PLAN" 2>/dev/null | head -1 | sed 's/.*: *//' || true)
    [[ -n "$BN_FEAT" ]] && echo "plan_bottleneck: $BN_FEAT"
    # Plan freshness
    PLAN_MOD=$(stat -f %m "$PLAN" 2>/dev/null || stat -c %Y "$PLAN" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    PLAN_AGE_H=$(( (NOW - PLAN_MOD) / 3600 ))
    echo "plan_age_hours: $PLAN_AGE_H"
else
    echo "plan: none"
fi
echo ""

echo "=== STRATEGY ==="
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY" ]]; then
    STRAT_MOD=$(stat -f %m "$STRATEGY" 2>/dev/null || stat -c %Y "$STRATEGY" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    STRAT_AGE_D=$(( (NOW - STRAT_MOD) / 86400 ))
    echo "strategy_age_days: $STRAT_AGE_D"
    echo "strategy: present"
else
    echo "strategy: none"
fi
echo ""

echo "=== THESIS ==="
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    # Extract current version + thesis
    CURRENT_VER=$(grep -E '^\s+v[0-9]' "$ROADMAP" 2>/dev/null | head -1 | sed 's/://;s/^ *//' || true)
    echo "current_version: $CURRENT_VER"
    THESIS=$(grep 'thesis:' "$ROADMAP" 2>/dev/null | head -1 | sed 's/.*thesis: *//' | tr -d '"' || true)
    echo "thesis: $THESIS"
    # Evidence counts
    if command -v python3 &>/dev/null; then
        python3 -c "
import re
with open('$ROADMAP') as f:
    content = f.read()
# Simple count of evidence statuses
proven = len(re.findall(r'status:\s*proven', content))
partial = len(re.findall(r'status:\s*partial', content))
todo = len(re.findall(r'status:\s*todo', content))
disproven = len(re.findall(r'status:\s*disproven', content))
total = proven + partial + todo + disproven
print(f'evidence_proven: {proven}')
print(f'evidence_partial: {partial}')
print(f'evidence_todo: {todo}')
print(f'evidence_total: {total}')
" 2>/dev/null || true
    fi
else
    echo "roadmap: none"
fi
echo ""

echo "=== TODOS ==="
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS" ]]; then
    ACTIVE=$(grep -c 'status: active' "$TODOS" 2>/dev/null || true)
    ACTIVE="${ACTIVE:-0}"; ACTIVE=$(echo "$ACTIVE" | tr -d '[:space:]')
    BACKLOG=$(grep -c 'status: backlog' "$TODOS" 2>/dev/null || true)
    BACKLOG="${BACKLOG:-0}"; BACKLOG=$(echo "$BACKLOG" | tr -d '[:space:]')
    STALE=$(grep -c 'status: stale' "$TODOS" 2>/dev/null || true)
    STALE="${STALE:-0}"; STALE=$(echo "$STALE" | tr -d '[:space:]')
    DONE_T=$(grep -c 'status: done' "$TODOS" 2>/dev/null || true)
    DONE_T="${DONE_T:-0}"; DONE_T=$(echo "$DONE_T" | tr -d '[:space:]')
    echo "active: $ACTIVE"
    echo "backlog: $BACKLOG"
    echo "stale: $STALE"
    echo "done: $DONE_T"
else
    echo "todos: none"
fi
echo ""

echo "=== COHERENCE ==="
# Cross-skill alignment check: are strategy, eval, and plan pointing the same direction?
MISMATCHES=0

# 1. Strategy bottleneck vs eval bottleneck
STRAT_BN=""
if [[ -f "$PROJECT_DIR/.claude/plans/strategy.yml" ]]; then
    STRAT_BN=$(grep -m1 'bottleneck:' "$PROJECT_DIR/.claude/plans/strategy.yml" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' | tr -d '[:space:]' || true)
fi
EVAL_BN=""
if [[ -x "$FOUNDER_DIR/bin/compute-bottleneck.sh" ]] && [[ -f "$EVAL_CACHE" ]]; then
    EVAL_BN=$(bash "$FOUNDER_DIR/bin/compute-bottleneck.sh" "$EVAL_CACHE" "$PROJECT_DIR/config/founder.yml" 2>/dev/null | head -1 | cut -f1 | tr -d '[:space:]' || true)
fi
if [[ -n "$STRAT_BN" ]] && [[ -n "$EVAL_BN" ]] && [[ "$STRAT_BN" != "$EVAL_BN" ]]; then
    echo "mismatch: strategy_bottleneck=$STRAT_BN vs eval_bottleneck=$EVAL_BN"
    MISMATCHES=$((MISMATCHES + 1))
fi

# 2. Plan target vs eval bottleneck
PLAN_BN=""
if [[ -f "$PROJECT_DIR/.claude/plans/plan.yml" ]]; then
    PLAN_BN=$(grep -m1 'bottleneck:' "$PROJECT_DIR/.claude/plans/plan.yml" 2>/dev/null | sed 's/.*bottleneck: *//' | sed 's/"//g' | tr -d '[:space:]' || true)
fi
if [[ -n "$PLAN_BN" ]] && [[ -n "$EVAL_BN" ]] && [[ "$PLAN_BN" != "$EVAL_BN" ]]; then
    echo "mismatch: plan_targets=$PLAN_BN vs eval_bottleneck=$EVAL_BN"
    MISMATCHES=$((MISMATCHES + 1))
fi

# 3. Weakest feature has tasks?
if [[ -n "$EVAL_BN" ]] && [[ -f "$PROJECT_DIR/.claude/plans/todos.yml" ]]; then
    BN_TASKS=$(grep -c "$EVAL_BN" "$PROJECT_DIR/.claude/plans/todos.yml" 2>/dev/null || true)
    BN_TASKS="${BN_TASKS:-0}"; BN_TASKS=$(echo "$BN_TASKS" | tr -d '[:space:]')
    if [[ "$BN_TASKS" -eq 0 ]]; then
        echo "mismatch: weakest_feature=$EVAL_BN has 0 todos"
        MISMATCHES=$((MISMATCHES + 1))
    fi
fi

if [[ "$MISMATCHES" -eq 0 ]]; then
    echo "coherence: aligned"
else
    echo "coherence: $MISMATCHES mismatches"
fi
echo ""

echo "=== GIT ==="
git -C "$PROJECT_DIR" log --oneline -3 2>/dev/null || echo "(not a git repo)"
echo ""

echo "=== VERSION ==="
PLUGIN_JSON="$FOUNDER_DIR/.claude-plugin/plugin.json"
if [[ -f "$PLUGIN_JSON" ]] && command -v jq &>/dev/null; then
    jq -r '"version: \(.version // "?")\nname: \(.name // "?")"' "$PLUGIN_JSON" 2>/dev/null || echo "version: ?"
else
    echo "version: unknown"
fi
echo ""

echo "=== SKILLS ==="
SKILL_CT=$(find "$FOUNDER_DIR/skills" -name "SKILL.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
AGENT_CT=$(find "$FOUNDER_DIR/agents" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
echo "skills: $SKILL_CT"
echo "agents: $AGENT_CT"
echo ""

echo "=== PULSE COMPLETE ==="
