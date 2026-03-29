#!/usr/bin/env bash
# session_start.sh — SessionStart hook (founder-os)
# Boot card: portfolio summary → project state, score, plan, staleness, predictions.
set -euo pipefail

PROJECT_DIR=$(pwd)
INPUT=$(cat)

# --- Resolve FOUNDER_DIR for config access ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SS_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SS_SOURCE" ]]; do _SS_SOURCE="$(readlink "$_SS_SOURCE")"; done
    _SS_DIR="$(cd "$(dirname "$_SS_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_SS_DIR/.." && pwd)"
fi
if [[ -f "$FOUNDER_DIR/bin/lib/config.sh" ]]; then
    source "$FOUNDER_DIR/bin/lib/config.sh"
fi
# --- Auto-configure statusline (one-time) ---
STATUSLINE_SRC="$FOUNDER_DIR/bin/statusline.sh"
STATUSLINE_DST="$HOME/.claude/statusline-command.sh"
if [[ -f "$STATUSLINE_SRC" ]] && [[ ! -f "$STATUSLINE_DST" ]]; then
    cp "$STATUSLINE_SRC" "$STATUSLINE_DST" 2>/dev/null || true
    chmod +x "$STATUSLINE_DST" 2>/dev/null || true
fi
if [[ -f "$STATUSLINE_SRC" ]] && [[ -f "$STATUSLINE_DST" ]]; then
    if [[ "$STATUSLINE_SRC" -nt "$STATUSLINE_DST" ]]; then
        cp "$STATUSLINE_SRC" "$STATUSLINE_DST" 2>/dev/null || true
    fi
fi

# --- world.md staleness check ---
WORLD_FILE="$PROJECT_DIR/mind/world.md"
WORLD_STALE_WARNING=""
if [[ -f "$WORLD_FILE" ]]; then
    WORLD_MTIME=$(stat -f %m "$WORLD_FILE" 2>/dev/null || stat -c %Y "$WORLD_FILE" 2>/dev/null || echo 0)
    WORLD_NOW=$(date +%s)
    WORLD_AGE_DAYS=$(( (WORLD_NOW - WORLD_MTIME) / 86400 ))
    if (( WORLD_AGE_DAYS > 30 )); then
        WORLD_STALE_WARNING="world.md last updated ${WORLD_AGE_DAYS} days ago. Run /learn market to refresh."
    fi
fi

if ! command -v jq &>/dev/null; then
    echo -e "  \033[1;33m⚠\033[0m jq not found — boot card degraded. Install: brew install jq" >&2
fi
SESSION_TYPE=$(echo "$INPUT" | jq -r '.type // "startup"' 2>/dev/null || echo "startup")

# Colors
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_CYAN='\033[0;36m'
C_NC='\033[0m'

SEP="  ${C_DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${C_NC}"

print_score_bar() {
    local score=${1:-0}
    local filled=$(( (score + 2) / 5 ))
    [[ $filled -gt 20 ]] && filled=20
    local empty=$((20 - filled))
    local color="$C_RED"
    [[ $score -ge 50 ]] && color="$C_YELLOW"
    [[ $score -ge 80 ]] && color="$C_GREEN"
    local bar="" trail=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do trail="${trail}░"; done
    printf "${color}${bar}${C_DIM}${trail}${C_NC}"
}

color_score() {
    local score=${1:-0}
    if [[ "$score" == "?" ]]; then printf "${C_DIM}?${C_NC}"
    elif [[ $score -ge 80 ]]; then printf "${C_GREEN}${score}${C_NC}"
    elif [[ $score -ge 50 ]]; then printf "${C_YELLOW}${score}${C_NC}"
    else printf "${C_RED}${score}${C_NC}"; fi
}

# ========== PORTFOLIO SUMMARY ==========
PORTFOLIO_FILE="$HOME/.founder-os/portfolio.yml"
HAS_PORTFOLIO=false
if [[ -f "$PORTFOLIO_FILE" ]]; then
    HAS_PORTFOLIO=true
    _p_total=$(sed -n '/^ideas:/,/^[^ ]/p' "$PORTFOLIO_FILE" | grep -c "^  [a-z][a-z_-]*:$" 2>/dev/null || echo 0)
    _p_killed=$(grep -c "stage: killed" "$PORTFOLIO_FILE" 2>/dev/null || echo 0)
    _p_active=$((_p_total - _p_killed))
    _p_building=$(grep -c "stage: building" "$PORTFOLIO_FILE" 2>/dev/null || echo 0)
    _p_validating=$(grep -c "stage: validating" "$PORTFOLIO_FILE" 2>/dev/null || echo 0)
    _p_researching=$(grep -c "stage: researching" "$PORTFOLIO_FILE" 2>/dev/null || echo 0)
fi

# ========== PREDICTION ACCURACY ==========
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
PRED_DISPLAY=""
UNGRADED_COUNT=0
if [[ -f "$PRED_FILE" ]]; then
    PRED_COUNT=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    if (( PRED_COUNT > 0 )); then
        CORRECT=$(tail -n +2 "$PRED_FILE" | tail -10 | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        PARTIAL_CT=$(tail -n +2 "$PRED_FILE" | tail -10 | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
        FILLED=$(tail -n +2 "$PRED_FILE" | tail -10 | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
        UNGRADED_COUNT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { c++ } END { print c+0 }')
        if (( FILLED > 0 )); then
            EFFECTIVE=$(awk "BEGIN { printf \"%d\", $CORRECT + $PARTIAL_CT * 0.5 }")
            PRED_DISPLAY="${EFFECTIVE}/${FILLED} correct"
            [[ "$PARTIAL_CT" -gt 0 ]] && PRED_DISPLAY="${PRED_DISPLAY} (${PARTIAL_CT} partial)"
        else
            PRED_DISPLAY="${PRED_COUNT} logged, 0 graded"
        fi
    fi
fi

# ========== KNOWLEDGE PATTERNS ==========
LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
known=0; uncertain=0; dead=0
if [[ -f "$LEARNINGS" ]]; then
    known=$(grep -c "^- " <(sed -n '/^## Known/,/^## /p' "$LEARNINGS") 2>/dev/null || echo 0)
    uncertain=$(grep -c "^- " <(sed -n '/^## Uncertain/,/^## /p' "$LEARNINGS") 2>/dev/null || echo 0)
    dead=$(grep -c "^- " <(sed -n '/^## Dead/,/^## /p' "$LEARNINGS") 2>/dev/null || echo 0)
fi

# ========== PROJECT STATE ==========
PROJECT_NAME=""
if [[ -f "$PROJECT_DIR/config/founder.yml" ]]; then
    PROJECT_NAME=$(grep -m1 '^name:' "$PROJECT_DIR/config/founder.yml" 2>/dev/null | sed 's/^name: *//' || true)
fi
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME=$(basename "$PROJECT_DIR")

HAS_PROJECT=false
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$PROJECT_DIR/config/founder.yml" ]] || [[ -f "$SCORE_CACHE" ]]; then
    HAS_PROJECT=true
fi

# --- Score data ---
TOTAL="?"
SCORING_MODE=""
ASSERTION_COUNT=0
ASSERTION_PASS_COUNT=0
HEALTH_MIN="?"
TIER_FILL=""
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    TOTAL=$(jq -r '.score // "?"' "$SCORE_CACHE" 2>/dev/null || echo "?")
    SCORING_MODE=$(jq -r '.scoring_mode // "empty"' "$SCORE_CACHE" 2>/dev/null || echo "empty")
    ASSERTION_COUNT=$(jq -r '.assertion_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    ASSERTION_PASS_COUNT=$(jq -r '.assertion_pass_count // 0' "$SCORE_CACHE" 2>/dev/null || echo "0")
    HEALTH_MIN=$(jq -r '.health_min // "?"' "$SCORE_CACHE" 2>/dev/null || echo "?")

    _tf=1
    [[ -f "$PROJECT_DIR/.claude/cache/eval-cache.json" ]] && _tf=$((_tf + 1))
    ls "$PROJECT_DIR/.claude/evals/reports/taste-"*.json &>/dev/null && _tf=$((_tf + 1))
    ls "$PROJECT_DIR/.claude/evals/reports/flows-"*.json &>/dev/null && _tf=$((_tf + 1))
    [[ -f "$PROJECT_DIR/.claude/cache/viability-cache.json" ]] && _tf=$((_tf + 1))
    _tf_filled="" _tf_empty=""
    for ((_i=0; _i<_tf; _i++)); do _tf_filled="${_tf_filled}●"; done
    for ((_i=_tf; _i<5; _i++)); do _tf_empty="${_tf_empty}○"; done
    TIER_FILL="${_tf_filled}${_tf_empty}"
fi

# --- Active plan ---
PLAN_FILE=""
for p in "$PROJECT_DIR/.claude/plans/plan.yml" "$HOME/.claude/plans/plan.yml"; do
    if [[ -f "$p" ]]; then PLAN_FILE="$p"; break; fi
done
TASKS_REMAINING=0; NEXT_TASK=""; PLAN_STALE=""
if [[ -n "$PLAN_FILE" ]]; then
    TOTAL_TASKS=$(grep -c '- title:' "$PLAN_FILE" 2>/dev/null | tr -d ' \n' || true)
    DONE_TASKS=$(grep -c 'status: done' "$PLAN_FILE" 2>/dev/null | tr -d ' \n' || true)
    [[ -z "$TOTAL_TASKS" || ! "$TOTAL_TASKS" =~ ^[0-9]+$ ]] && TOTAL_TASKS=0
    [[ -z "$DONE_TASKS" || ! "$DONE_TASKS" =~ ^[0-9]+$ ]] && DONE_TASKS=0
    TASKS_REMAINING=$((TOTAL_TASKS - DONE_TASKS))
    NEXT_TASK=$(grep -B1 'status: todo' "$PLAN_FILE" 2>/dev/null | grep 'title:' | head -1 | sed 's/.*title: *//' || true)
    if [[ "$(uname)" == "Darwin" ]]; then
        PLAN_MTIME=$(stat -f %m "$PLAN_FILE" 2>/dev/null || echo 0)
    else
        PLAN_MTIME=$(stat -c %Y "$PLAN_FILE" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE_HOURS=$(( (NOW - PLAN_MTIME) / 3600 ))
    if (( AGE_HOURS > 24 )); then
        PLAN_STALE="(${AGE_HOURS}h old — consider /plan)"
    fi
fi

# --- Auto-grade predictions ---
GRADE_SUMMARY=""
if [[ -f "$PRED_FILE" ]] && [[ -f "$FOUNDER_DIR/bin/grade.sh" ]]; then
    HAS_UNGRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { c++ } END { print c+0 }')
    if [[ "$HAS_UNGRADED" -gt 0 ]]; then
        BEFORE_GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
        bash "$FOUNDER_DIR/bin/grade.sh" --quiet "$PRED_FILE" \
            "$PROJECT_DIR/.claude/scores/history.tsv" \
            "$PROJECT_DIR/.claude/cache/score-cache.json" 2>/dev/null || true
        AFTER_GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
        NEWLY_GRADED=$((AFTER_GRADED - BEFORE_GRADED))
        if [[ "$NEWLY_GRADED" -gt 0 && "$NEWLY_GRADED" -le "$AFTER_GRADED" ]]; then
            NEW_YES=$(tail -n +2 "$PRED_FILE" | tail -n "$NEWLY_GRADED" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
            NEW_NO=$(tail -n +2 "$PRED_FILE" | tail -n "$NEWLY_GRADED" | awk -F'\t' '$6 == "no" { c++ } END { print c+0 }')
            NEW_PARTIAL=$(tail -n +2 "$PRED_FILE" | tail -n "$NEWLY_GRADED" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
            GRADE_SUMMARY="Graded ${NEWLY_GRADED}: ${NEW_YES} correct, ${NEW_PARTIAL} partial, ${NEW_NO} wrong"
        fi
    fi
fi

# ========== OUTPUT ==========
echo ""
echo -e "${SEP}"
echo -e "  ${C_CYAN}◆${C_NC} ${C_BOLD}founder-os${C_NC}  ${C_DIM}·${C_NC}  ${PROJECT_NAME}"
echo -e "${SEP}"
echo ""

# --- Portfolio summary (always shown if portfolio exists) ---
if [[ "$HAS_PORTFOLIO" == true ]]; then
    _p_parts="${_p_active} active"
    [[ $_p_building -gt 0 ]] && _p_parts="${_p_parts}  ·  ${_p_building} building"
    [[ $_p_validating -gt 0 ]] && _p_parts="${_p_parts}  ·  ${_p_validating} validating"
    [[ $_p_researching -gt 0 ]] && _p_parts="${_p_parts}  ·  ${_p_researching} researching"
    [[ $_p_killed -gt 0 ]] && _p_parts="${_p_parts}  ·  ${_p_killed} killed"
    echo -e "  ${C_DIM}portfolio${C_NC}   ${_p_parts}"
fi

# --- Prediction accuracy ---
if [[ -n "$PRED_DISPLAY" ]]; then
    _patterns_part="${known} known  ·  ${uncertain} uncertain  ·  ${dead} dead ends"
    echo -e "  ${C_DIM}accuracy${C_NC}    ${PRED_DISPLAY}  ${C_DIM}·${C_NC}  ${C_DIM}target: 50-70%${C_NC}"
    echo -e "  ${C_DIM}patterns${C_NC}    ${_patterns_part}"
fi

# --- Project score (only if in a project) ---
if [[ "$HAS_PROJECT" == true ]] && [[ "$TOTAL" != "?" ]]; then
    SCORE_BAR=$(print_score_bar "$TOTAL")
    TIER_BADGE=""
    [[ -n "$TIER_FILL" ]] && TIER_BADGE="  ${C_DIM}${TIER_FILL}${C_NC}"
    echo -e "  ${C_DIM}score${C_NC}       ${C_BOLD}${TOTAL}${C_NC}${C_DIM}/100${C_NC}  ${SCORE_BAR}${TIER_BADGE}"

    if [[ "$SCORING_MODE" == "assertions" ]]; then
        _assert_pct=0
        [[ "$ASSERTION_COUNT" -gt 0 ]] && _assert_pct=$((ASSERTION_PASS_COUNT * 100 / ASSERTION_COUNT))
        echo -e "              ${C_DIM}assertions${C_NC} ${ASSERTION_PASS_COUNT}/${ASSERTION_COUNT} (${_assert_pct}%)  ${C_DIM}·${C_NC}  ${C_DIM}health${C_NC} $(color_score "$HEALTH_MIN")"

        # Show features with scores
        if command -v jq &>/dev/null && [[ -f "$SCORE_CACHE" ]]; then
            FEAT_LIST=$(jq -r '.features // {} | to_entries | sort_by(if .value.type == "generative" then .value.score else (.value.pass / (.value.total + 0.001) * 100) end) | .[:4] | .[] | if .value.type == "generative" then "\(.key)|\(.value.score)" else "\(.key)|\(.value.pass * 100 / (.value.total + 1) | floor)" end' "$SCORE_CACHE" 2>/dev/null || true)
            if [[ -n "$FEAT_LIST" ]]; then
                while IFS='|' read -r fname fscore; do
                    [[ -z "$fname" ]] && continue
                    _bfilled=$(( (fscore + 6) / 12 ))
                    [[ $_bfilled -gt 8 ]] && _bfilled=8
                    _bempty=$((8 - _bfilled))
                    _bcolor="$C_RED"; [[ "$fscore" -ge 50 ]] && _bcolor="$C_YELLOW"; [[ "$fscore" -ge 80 ]] && _bcolor="$C_GREEN"
                    _bbar="" _btrail=""
                    for ((_bb=0; _bb<_bfilled; _bb++)); do _bbar="${_bbar}█"; done
                    for ((_bb=0; _bb<_bempty; _bb++)); do _btrail="${_btrail}░"; done
                    printf "              ${C_BOLD}%-12s${C_NC} ${_bcolor}%2d${C_NC} ${_bcolor}${_bbar}${C_DIM}${_btrail}${C_NC}\n" "$fname" "$fscore"
                done <<< "$FEAT_LIST"
            fi
        fi
    elif [[ "$SCORING_MODE" == "onboarding" ]]; then
        echo -e "              ${C_DIM}onboarding${C_NC}  ${C_DIM}·${C_NC}  ${C_DIM}health${C_NC} $(color_score "$HEALTH_MIN")"
    else
        echo -e "              ${C_DIM}no value hypothesis${C_NC}  ${C_DIM}·${C_NC}  ${C_DIM}health${C_NC} $(color_score "$HEALTH_MIN")"
    fi
elif [[ "$HAS_PROJECT" == true ]]; then
    echo -e "  ${C_DIM}score${C_NC}       ${C_DIM}none yet — run /score${C_NC}"
fi

# Plan + next task
if [[ -n "$PLAN_FILE" && "$TASKS_REMAINING" -gt 0 ]]; then
    PLAN_LINE="  ${C_DIM}plan${C_NC}        ${TASKS_REMAINING} tasks"
    [[ -n "$PLAN_STALE" ]] && PLAN_LINE="${PLAN_LINE}  ${C_YELLOW}${PLAN_STALE}${C_NC}"
    [[ -n "$NEXT_TASK" ]] && PLAN_LINE="${PLAN_LINE}  ${C_DIM}·${C_NC}  ${C_GREEN}▸${C_NC} ${NEXT_TASK}"
    echo -e "$PLAN_LINE"
fi

# --- Maturity tier ---
if [[ -f "$FOUNDER_DIR/bin/maturity-tier.sh" ]] && [[ "$HAS_PROJECT" == true ]]; then
    TIER_OUTPUT=$(bash "$FOUNDER_DIR/bin/maturity-tier.sh" "$PROJECT_DIR" 2>/dev/null || true)
    TIER_LINE=$(echo "$TIER_OUTPUT" | grep '^tier:' | sed 's/tier: *//')
    TIER_FOCUS=$(echo "$TIER_OUTPUT" | grep '^focus:' | sed 's/focus: *//')
    TIER_SKILLS=$(echo "$TIER_OUTPUT" | grep '^skills:' | sed 's/skills: *//' | tr '|' ', ')
    if [[ -n "$TIER_LINE" ]]; then
        case "$TIER_LINE" in
            fix)        TIER_COLOR="$C_RED" ;;
            deepen)     TIER_COLOR="$C_YELLOW" ;;
            strengthen) TIER_COLOR="$C_YELLOW" ;;
            expand)     TIER_COLOR="$C_CYAN" ;;
            mature)     TIER_COLOR="$C_GREEN" ;;
            *)          TIER_COLOR="$C_DIM" ;;
        esac
        echo -e "  ${C_DIM}tier${C_NC}        ${TIER_COLOR}${TIER_LINE}${C_NC}  ${C_DIM}·${C_NC}  ${TIER_FOCUS}"
        echo -e "              ${C_DIM}→${C_NC} ${TIER_SKILLS}"
    fi
fi

# ========== DEMAND SUMMARY ==========
DEMAND_CACHE="$PROJECT_DIR/.claude/cache/demand-cache.json"
if [[ -f "$DEMAND_CACHE" ]] && command -v jq &>/dev/null; then
    _demand_feat_count=$(jq '.features | length' "$DEMAND_CACHE" 2>/dev/null || echo "0")
    if [[ "$_demand_feat_count" -gt 0 ]]; then
        echo ""
        # Job → Feature tree
        _job_lines=$(jq -r '
            .features | to_entries[] |
            .key as $feat |
            .value.jobs // [] | .[] |
            "\(.type // "?"): \(.statement // "unnamed") → \($feat) [\(.evidence_class // "inferred")]"
        ' "$DEMAND_CACHE" 2>/dev/null)

        if [[ -n "$_job_lines" ]]; then
            _job_count=$(echo "$_job_lines" | wc -l | tr -d ' ')
            echo -e "  ${C_DIM}demand${C_NC}      ${_job_count} jobs mapped"
            _first=true
            while IFS= read -r _jl; do
                if [[ "$_first" == true ]]; then
                    echo -e "              ${C_DIM}┌${C_NC} ${_jl}"
                    _first=false
                else
                    echo -e "              ${C_DIM}├${C_NC} ${_jl}"
                fi
            done <<< "$_job_lines"
        fi

        # Package summary
        _pkg_count=$(jq '[.features[].packages // [] | .[]] | length' "$DEMAND_CACHE" 2>/dev/null || echo "0")
        if [[ "$_pkg_count" -gt 0 ]]; then
            _pkg_names=$(jq -r '[.features[].packages // [] | .[].customer_name] | join(", ")' "$DEMAND_CACHE" 2>/dev/null)
            echo -e "  ${C_DIM}packages${C_NC}    ${_pkg_count}: ${_pkg_names}"
        fi

        # Evidence distribution
        _obs=$(jq '[.features[].evidence_summary.observed // 0] | add // 0' "$DEMAND_CACHE" 2>/dev/null || echo "0")
        _sta=$(jq '[.features[].evidence_summary.stated // 0] | add // 0' "$DEMAND_CACHE" 2>/dev/null || echo "0")
        _mkt=$(jq '[.features[].evidence_summary.market // 0] | add // 0' "$DEMAND_CACHE" 2>/dev/null || echo "0")
        _inf=$(jq '[.features[].evidence_summary.inferred // 0] | add // 0' "$DEMAND_CACHE" 2>/dev/null || echo "0")
        _total=$((_obs + _sta + _mkt + _inf))
        if [[ "$_total" -gt 0 ]]; then
            echo -e "  ${C_DIM}evidence${C_NC}    ${_obs} observed · ${_sta} stated · ${_mkt} market · ${_inf} inferred"
        fi
    fi
fi

# --- Alerts ---
if [[ -n "${WORLD_STALE_WARNING:-}" ]]; then
    echo ""
    echo -e "  ${C_YELLOW}⚠${C_NC} ${WORLD_STALE_WARNING}"
fi
if [[ $UNGRADED_COUNT -gt 0 ]]; then
    echo ""
    echo -e "  ${C_RED}●${C_NC} ${UNGRADED_COUNT} ungraded predictions — run /retro"
fi

# --- Self-awareness + product nudge ---
_SELF_CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -L "${BASH_SOURCE[0]}" ]] && _SELF_CHECKS_DIR="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" && pwd)"
SELF_REC=""
if [[ -f "$_SELF_CHECKS_DIR/lib/self-checks.sh" ]]; then
    source "$_SELF_CHECKS_DIR/lib/self-checks.sh"
elif [[ -f "$FOUNDER_DIR/hooks/lib/self-checks.sh" ]]; then
    source "$FOUNDER_DIR/hooks/lib/self-checks.sh"
fi
[[ -n "${SELF_REC:-}" ]] && echo -e "  ${C_DIM}⚙${C_NC} ${SELF_REC#\[self\] }"

if [[ -f "$_SELF_CHECKS_DIR/lib/product-nudge.sh" ]]; then
    source "$_SELF_CHECKS_DIR/lib/product-nudge.sh"
elif [[ -f "$FOUNDER_DIR/hooks/lib/product-nudge.sh" ]]; then
    source "$FOUNDER_DIR/hooks/lib/product-nudge.sh"
fi
[[ -n "${PRODUCT_LINES:-}" ]] && echo -e "  ${PRODUCT_LINES}"

if [[ -f "$_SELF_CHECKS_DIR/lib/cofounder-opinion.sh" ]]; then
    source "$_SELF_CHECKS_DIR/lib/cofounder-opinion.sh"
elif [[ -f "$FOUNDER_DIR/hooks/lib/cofounder-opinion.sh" ]]; then
    source "$FOUNDER_DIR/hooks/lib/cofounder-opinion.sh"
fi
[[ -n "${COFOUNDER_OPINION:-}" ]] && echo "" && echo -e "  ${COFOUNDER_OPINION}"

echo -e "${SEP}"
echo ""

# --- GSD Priority Injection (refresh .claude/rules/founder-priorities.md) ---
if [[ -f "$FOUNDER_DIR/bin/gsd-priority-inject.sh" ]]; then
    bash "$FOUNDER_DIR/bin/gsd-priority-inject.sh" "$PROJECT_DIR" 2>/dev/null || true
fi

# --- Compaction recovery ---
if [[ "$SESSION_TYPE" == "compact" ]]; then
    echo ""
    echo -e "  ${C_YELLOW}↻${C_NC} ${C_BOLD}Context compacted.${C_NC} Re-read:"
    echo -e "    ${C_DIM}1.${C_NC} mind/thinking.md"
    echo -e "    ${C_DIM}2.${C_NC} ~/.claude/knowledge/experiment-learnings.md"
    echo -e "    ${C_DIM}3.${C_NC} .claude/plans/plan.yml"
fi
