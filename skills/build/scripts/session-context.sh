#!/usr/bin/env bash
# session-context.sh — Scans ALL project state for /plan session context.
# Outputs structured summary. Zero context cost — only output enters the conversation.
# Usage: bash scripts/session-context.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Check dependencies
source "$FOUNDER_DIR/bin/lib/check-deps.sh"
require_cmd jq "brew install jq"
require_cmd python3 "brew install python3"

echo "=== SESSION CONTEXT ==="
echo "date: $(date +%Y-%m-%d)"
echo ""

# --- Score ---
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▸ score"
    SCORE=$(jq -r '.score // "?"' "$SCORE_CACHE" 2>/dev/null)
    HEALTH=$(jq -r '.health // "?"' "$SCORE_CACHE" 2>/dev/null)
    PASS=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null)
    TOTAL=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null)
    echo "  score: $SCORE  health: $HEALTH  assertions: $PASS/$TOTAL"
    echo ""
else
    echo "▸ score"
    echo "  (no score cache — run: founder score .)"
    echo ""
fi

# --- Eval cache (per-feature — with claims from founder.yml) ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▸ features"
    # Show each feature with its claim + score + top gap
    jq -r 'to_entries[] | select(.value.score != null) | "\(.key)\t\(.value.score)\t\(.value.delivery_score // "?")\t\(.value.craft_score // "?")\t\(.value.delta // "none")\t\(.value.gaps[0] // "")"' "$EVAL_CACHE" 2>/dev/null | while IFS=$'\t' read -r fname fscore fd fc fdelta fgap; do
        [[ -z "$fname" ]] && continue
        # Get delivers: claim from founder.yml
        _claim=""
        _weight=""
        if [[ -f "$FOUNDER_YML" ]]; then
            _claim=$(awk "/^  ${fname}:/{found=1;next} found && /delivers:/{gsub(/.*delivers: *\"?/,\"\"); gsub(/\"$/,\"\"); print; exit} found && /^  [a-z]/{exit}" "$FOUNDER_YML" 2>/dev/null)
            _weight=$(awk "/^  ${fname}:/{found=1;next} found && /weight:/{gsub(/.*weight: */,\"\"); print; exit} found && /^  [a-z]/{exit}" "$FOUNDER_YML" 2>/dev/null)
        fi
        echo "  ${fname}: ${fscore} (d:${fd} c:${fc}) w:${_weight:-1} delta:${fdelta}"
        [[ -n "$_claim" ]] && echo "    delivers: ${_claim:0:80}"
        [[ -n "$fgap" ]] && echo "    top gap: ${fgap:0:100}"
    done
    echo ""
else
    echo "▸ features"
    echo "  (no eval cache — run: /eval)"
    echo ""
fi

# --- Completion ---
if [[ -f "$FOUNDER_DIR/bin/compute-completion.sh" ]]; then
    echo "▸ completion"
    "$FOUNDER_DIR/bin/compute-completion.sh" 2>/dev/null | sed 's/^/  /' || echo "  (error)"
    echo ""
fi

# --- Bottleneck ---
if [[ -f "$FOUNDER_DIR/bin/compute-bottleneck.sh" ]]; then
    echo "▸ bottleneck"
    RESULT=$("$FOUNDER_DIR/bin/compute-bottleneck.sh" 2>/dev/null | head -1 || echo "")
    if [[ -n "$RESULT" ]]; then
        NAME=$(echo "$RESULT" | cut -f1)
        SCORE=$(echo "$RESULT" | cut -f2)
        WEIGHT=$(echo "$RESULT" | cut -f3)
        DIM=$(echo "$RESULT" | cut -f5)
        echo "  feature: $NAME  score: $SCORE  weight: $WEIGHT  weakest: $DIM"
    else
        echo "  no eval data"
    fi
    echo ""
fi

# --- Predictions (last 10 + accuracy) ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    echo "▸ predictions"
    TOTAL=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != ""' | wc -l | tr -d ' ')
    CORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes"' | wc -l | tr -d ' ')
    PARTIAL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "partial"' | wc -l | tr -d ' ')
    WRONG=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no"' | wc -l | tr -d ' ')
    UNGRADED=$((TOTAL - GRADED))
    if [[ "$GRADED" -gt 0 ]]; then
        # partial counts as 0.5
        ACC=$(python3 -c "print(round(($CORRECT + $PARTIAL * 0.5) / $GRADED * 100))" 2>/dev/null || echo "?")
        echo "  total: $TOTAL  graded: $GRADED  accuracy: ${ACC}%"
    else
        echo "  total: $TOTAL  graded: 0  accuracy: n/a"
    fi
    echo "  ungraded: $UNGRADED  correct: $CORRECT  partial: $PARTIAL  wrong: $WRONG"

    # Last 7 days count
    WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null || echo "0000-00-00")
    RECENT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$WEEK_AGO" '$1 >= d' | wc -l | tr -d ' ')
    echo "  last_7_days: $RECENT"

    # Recent wrong predictions (highest signal)
    WRONG_RECENT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" || $6 == "partial"' | tail -3)
    if [[ -n "$WRONG_RECENT" ]]; then
        echo "  recent wrong:"
        echo "$WRONG_RECENT" | while IFS=$'\t' read -r date pred evidence result correct update; do
            echo "    $date: $pred"
            [[ -n "$update" ]] && echo "      update: $update"
        done
    fi

    # --- Prediction intelligence: model weakness detection ---
    TWO_WEEKS_AGO=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d '14 days ago' +%Y-%m-%d 2>/dev/null || echo "0000-00-00")
    WRONG_14D=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$TWO_WEEKS_AGO" '$1 >= d && $6 == "no"' 2>/dev/null)
    WRONG_14D_COUNT=$(echo "$WRONG_14D" | grep -c '.' 2>/dev/null || echo "0")
    if [[ "$WRONG_14D_COUNT" -ge 2 ]]; then
        # Group wrong predictions by area (extract keywords)
        echo "  model_weaknesses:"
        echo "$WRONG_14D" | awk -F'\t' '{print $3}' | grep -oE '[a-zA-Z_-]{4,}' | \
            grep -viE '^(will|from|that|this|with|have|been|into|than|they|them|were|more|each|also|does|make|raise|drop|should|would|could|because|about|after|before|between|improve|increase|decrease|change|predict|prediction|target|score|eval|expect)$' | \
            sort | uniq -c | sort -rn | head -5 | while read -r cnt kw; do
            if [[ "$cnt" -ge 2 ]]; then
                echo "    ⚠ model wrong about '$kw' ($cnt times in 14d) — DO NOT trust assumptions about $kw"
            fi
        done
    fi

    # --- Dead ends check: block re-proposing failed approaches ---
    LEARNINGS_SC="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$LEARNINGS_SC" ]] && LEARNINGS_SC="$HOME/.claude/knowledge/experiment-learnings.md"
    if [[ -f "$LEARNINGS_SC" ]]; then
        DEAD_ENDS=$(awk '/^## Dead Ends/,0' "$LEARNINGS_SC" 2>/dev/null | grep '^\s*- \*\*' | head -5)
        if [[ -n "$DEAD_ENDS" ]]; then
            echo "  dead_ends (do NOT re-propose):"
            echo "$DEAD_ENDS" | while IFS= read -r de; do
                echo "    $de"
            done
        fi
    fi
    echo ""
else
    echo "▸ predictions"
    echo "  (no predictions — /go will start logging them)"
    echo ""
fi

# --- Strategy ---
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY" ]]; then
    echo "▸ strategy"
    STAGE=$(grep -m1 'stage:' "$STRATEGY" 2>/dev/null | sed 's/.*stage: *//' || echo "?")
    BOTTLENECK=$(grep -m1 'bottleneck:' "$STRATEGY" 2>/dev/null | sed 's/.*bottleneck: *//' || echo "?")
    UPDATED=$(grep -m1 'last_updated:' "$STRATEGY" 2>/dev/null | sed 's/.*last_updated: *//' || echo "?")
    echo "  stage: $STAGE  bottleneck: $BOTTLENECK  updated: $UPDATED"
    echo ""
else
    echo "▸ strategy"
    echo "  (no strategy — run: /strategy honest)"
    echo ""
fi

# --- Roadmap (current thesis) ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    echo "▸ roadmap"
    # Current version + thesis
    grep -m1 'version:' "$ROADMAP" 2>/dev/null | sed 's/^/  /' || true
    grep -m1 'thesis:' "$ROADMAP" 2>/dev/null | sed 's/^/  /' || true
    # Evidence items
    echo "  evidence:"
    grep -A1 'evidence_needed:' "$ROADMAP" 2>/dev/null | grep -E '^\s+-' | sed 's/^/  /' | head -8 || true
    echo ""
else
    echo "▸ roadmap"
    echo "  (no roadmap — run: /roadmap new)"
    echo ""
fi

# --- Todos ---
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS" ]]; then
    echo "▸ todos"
    TOTAL_TODOS=$(grep -c '- title:' "$TODOS" 2>/dev/null || true)
    TOTAL_TODOS="${TOTAL_TODOS:-0}"; TOTAL_TODOS="${TOTAL_TODOS// /}"
    DONE_TODOS=$(grep -c 'status: done' "$TODOS" 2>/dev/null || true)
    DONE_TODOS="${DONE_TODOS:-0}"; DONE_TODOS="${DONE_TODOS// /}"
    ACTIVE_TODOS=$(grep -cE 'status: (todo|captured)' "$TODOS" 2>/dev/null || true)
    ACTIVE_TODOS="${ACTIVE_TODOS:-0}"; ACTIVE_TODOS="${ACTIVE_TODOS// /}"
    echo "  total: $TOTAL_TODOS  done: $DONE_TODOS  active: $ACTIVE_TODOS"
    echo ""
else
    echo "▸ todos"
    echo "  (no backlog — run: /todo add \"your first task\")"
    echo ""
fi

# --- Research (recent findings) ---
RESEARCH="$HOME/.claude/cache/last-research.yml"
if [[ -f "$RESEARCH" ]]; then
    echo "▸ research"
    TOPIC=$(grep -m1 'topic:' "$RESEARCH" 2>/dev/null | sed 's/.*topic: *//' || echo "?")
    RDATE=$(grep -m1 'date:' "$RESEARCH" 2>/dev/null | sed 's/.*date: *//' || echo "?")
    echo "  topic: $TOPIC  date: $RDATE"
    # Suggested tasks
    grep -A5 'suggested_tasks:' "$RESEARCH" 2>/dev/null | grep -E '^\s+-' | sed 's/^/  /' | head -3 || true
    echo ""
fi

# --- Git (recent work) ---
echo "▸ git (last 10)"
git -C "$PROJECT_DIR" log --oneline -10 2>/dev/null || echo "  (not a git repo)"
echo ""

# --- Knowledge model (actionable patterns for /plan) ---
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    echo "▸ knowledge model"
    if [[ -f "$FOUNDER_DIR/bin/detect-staleness.sh" ]]; then
        "$FOUNDER_DIR/bin/detect-staleness.sh" "$LEARNINGS" 2>/dev/null | sed 's/^/  /' || echo "  (error)"
    else
        if [[ "$(uname)" == "Darwin" ]]; then
            AGE=$(( ($(date +%s) - $(stat -f %m "$LEARNINGS")) / 86400 ))
        else
            AGE=$(( ($(date +%s) - $(stat -c %Y "$LEARNINGS")) / 86400 ))
        fi
        echo "  age: ${AGE} days"
    fi

    echo ""
else
    echo "▸ knowledge model"
    echo "  (no learnings file — /onboard or /go will create one)"
    echo ""
fi

# --- Maturity tier ---
if [[ -f "$FOUNDER_DIR/bin/maturity-tier.sh" ]]; then
    echo "▸ maturity tier"
    bash "$FOUNDER_DIR/bin/maturity-tier.sh" "$PROJECT_DIR" 2>/dev/null | grep -v '===' | sed 's/^/  /' || echo "  (error)"
    echo ""
fi

# --- Topology ---
# --- Product value ---
VALUE_SCRIPT="$FOUNDER_DIR/skills/shared/product-value.sh"
VALUE_CACHE="$PROJECT_DIR/.claude/cache/product-value.json"
if [[ -f "$VALUE_SCRIPT" ]] && [[ ! -f "$VALUE_CACHE" ]]; then
    bash "$VALUE_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
fi
if [[ -f "$VALUE_CACHE" ]] && command -v jq &>/dev/null; then
    echo "▸ product value"
    CORE_COUNT=$(jq -r '.stats.core_count // 0' "$VALUE_CACHE" 2>/dev/null)
    AUTH_COUNT=$(jq -r '.stats.auth_gated_count // 0' "$VALUE_CACHE" 2>/dev/null)
    INFRA_COUNT=$(jq -r '.stats.infrastructure_count // 0' "$VALUE_CACHE" 2>/dev/null)
    AVG_CORE=$(jq -r '.stats.avg_core_value // 0' "$VALUE_CACHE" 2>/dev/null)
    echo "  core: $CORE_COUNT  auth-gated: $AUTH_COUNT  infrastructure: $INFRA_COUNT  avg_core_value: $AVG_CORE"
    echo "  value loop:"
    jq -r '.value_loop[:5][] | "    \(.)"' "$VALUE_CACHE" 2>/dev/null
    echo ""
fi

# --- Topology ---
TOPO_SCRIPT="$FOUNDER_DIR/skills/shared/product-topology.sh"
if [[ -f "$TOPO_SCRIPT" ]]; then
    echo "▸ topology"
    TOPO=$(bash "$TOPO_SCRIPT" "$PROJECT_DIR" 2>/dev/null)
    if [[ -n "$TOPO" ]] && command -v jq &>/dev/null; then
        PTYPE=$(echo "$TOPO" | jq -r '.product_type // "unknown"')
        SCOUNT=$(echo "$TOPO" | jq -r '.stats.surface_count // 0')
        OCOUNT=$(echo "$TOPO" | jq -r '.stats.orphan_count // 0')
        DCOUNT=$(echo "$TOPO" | jq -r '.stats.dead_end_count // 0')
        CRIT_DATA=$(echo "$TOPO" | jq -r '.stats.critical_data_count // 0')
        echo "  product_type: $PTYPE  surfaces: $SCOUNT  orphans: $OCOUNT  dead_ends: $DCOUNT"
        # Journey positions for active features
        echo "$TOPO" | jq -r '.journey_positions | to_entries[] | "  \(.key): \(.value.position) (w:\(.value.weight))"' 2>/dev/null
        # Critical data flows (high-risk: many readers, few writers)
        if [[ "$CRIT_DATA" -gt 0 ]]; then
            echo "  critical_data ($CRIT_DATA files with many consumers):"
            echo "$TOPO" | jq -r '.critical_data | to_entries[] | select(.value.risk == "high") | "    \(.key): \(.value.consumers) consumers, \(.value.producers) producers"' 2>/dev/null | head -5
        fi
    else
        echo "  (topology generation failed)"
    fi
    echo ""
fi

echo "=== CONTEXT COMPLETE ==="
