#!/usr/bin/env bash
# cofounder-opinion.sh — One opinionated recommendation per session.
# Not a dashboard line. A cofounder talking.
#
# Reads: eval-cache, strategy, plan, predictions, founder.yml
# Returns: COFOUNDER_OPINION (1-2 sentence recommendation with evidence)
#
# Required env: PROJECT_DIR, FOUNDER_DIR, C_BOLD, C_DIM, C_NC, C_RED, C_YELLOW, C_GREEN

COFOUNDER_OPINION=""

EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
STRATEGY_FILE="$PROJECT_DIR/.claude/plans/strategy.yml"
PLAN_FILE="$PROJECT_DIR/.claude/plans/plan.yml"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"

# Bail if no project config
[[ ! -f "$FOUNDER_YML" ]] && return 0 2>/dev/null || true

# --- Gather state ---

# Bottleneck feature: highest weight × lowest score
_bottleneck=""
_bottleneck_score=100
_bottleneck_weight=0
_strongest=""
_strongest_score=0

if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    # Read features with weights from founder.yml
    while IFS= read -r feat_name; do
        [[ -z "$feat_name" ]] && continue
        _w=$(grep -A5 "^  ${feat_name}:" "$FOUNDER_YML" 2>/dev/null | grep 'weight:' | head -1 | awk '{print $2}' || echo "1")
        [[ -z "$_w" || ! "$_w" =~ ^[0-9]+$ ]] && _w=1
        _s=$(jq -r --arg f "$feat_name" '.[$f].score // 0' "$EVAL_CACHE" 2>/dev/null || echo "0")
        [[ -z "$_s" || ! "$_s" =~ ^[0-9]+$ ]] && _s=0

        # Track bottleneck (lowest score, weight as tiebreaker)
        _impact=$(( (100 - _s) * _w ))
        _current_impact=$(( (100 - _bottleneck_score) * _bottleneck_weight ))
        if [[ "$_impact" -gt "$_current_impact" ]]; then
            _bottleneck="$feat_name"
            _bottleneck_score="$_s"
            _bottleneck_weight="$_w"
        fi

        # Track strongest
        if [[ "$_s" -gt "$_strongest_score" ]]; then
            _strongest="$feat_name"
            _strongest_score="$_s"
        fi
    done < <(jq -r 'keys[]' "$EVAL_CACHE" 2>/dev/null)
fi

# Top gap from eval-cache for bottleneck feature
_top_gap=""
if [[ -n "$_bottleneck" && -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    _top_gap=$(jq -r --arg f "$_bottleneck" '.[$f].gaps[0] // empty' "$EVAL_CACHE" 2>/dev/null | head -c 120)
fi

# Last wrong prediction (what did we get wrong?)
_last_wrong=""
if [[ -f "$PRED_FILE" ]]; then
    _last_wrong=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" { p=$3 } END { if(p) print substr(p, 1, 80) }')
fi

# Plan alignment: is the current plan targeting the bottleneck?
_plan_aligned=true
if [[ -n "$_bottleneck" && -f "$PLAN_FILE" ]]; then
    if ! grep -qi "$_bottleneck" "$PLAN_FILE" 2>/dev/null; then
        _plan_aligned=false
    fi
fi

# Strategy age
_strat_age_days=0
if [[ -f "$STRATEGY_FILE" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        _st_mt=$(stat -f %m "$STRATEGY_FILE" 2>/dev/null || echo 0)
    else
        _st_mt=$(stat -c %Y "$STRATEGY_FILE" 2>/dev/null || echo 0)
    fi
    _strat_age_days=$(( ($(date +%s) - _st_mt) / 86400 ))
fi

# Recent commit activity on bottleneck feature code paths
_recent_bottleneck_commits=0
if [[ -n "$_bottleneck" && -f "$FOUNDER_YML" ]]; then
    _code_paths=$(grep -A10 "^  ${_bottleneck}:" "$FOUNDER_YML" 2>/dev/null | grep 'code:' | head -1 | sed 's/.*\[//;s/\].*//;s/"//g;s/,/ /g' || true)
    for _cp in $_code_paths; do
        [[ ! -e "$PROJECT_DIR/$_cp" ]] && continue
        _cc=$(git -C "$PROJECT_DIR" log --oneline --since="3 days ago" -- "$_cp" 2>/dev/null | wc -l | tr -d ' ')
        _recent_bottleneck_commits=$((_recent_bottleneck_commits + _cc))
    done
fi

# --- Form opinion ---

# Priority 1: Plan is not aligned with bottleneck
if [[ "$_plan_aligned" == false && -n "$_bottleneck" && "$_bottleneck_score" -lt 70 ]]; then
    COFOUNDER_OPINION="${C_RED}●${C_NC} Plan doesn't mention ${C_BOLD}${_bottleneck}${C_NC} but it's the bottleneck (${_bottleneck_score}, w:${_bottleneck_weight})."
    [[ -n "$_top_gap" ]] && COFOUNDER_OPINION="${COFOUNDER_OPINION}\n              ${C_DIM}gap: ${_top_gap:0:100}${C_NC}"
    return 0 2>/dev/null || true
fi

# Priority 2: Working on strongest feature while bottleneck is broken
if [[ "$_recent_bottleneck_commits" -eq 0 && -n "$_bottleneck" && "$_bottleneck_score" -lt 60 && -n "$_strongest" && "$_strongest" != "$_bottleneck" ]]; then
    COFOUNDER_OPINION="${C_YELLOW}●${C_NC} ${C_BOLD}${_bottleneck}${C_NC} is at ${_bottleneck_score} with 0 commits in 3 days. ${_strongest} is already at ${_strongest_score} — work where it matters."
    return 0 2>/dev/null || true
fi

# Priority 3: Strategy is stale and score is plateauing
if [[ "$_strat_age_days" -gt 7 ]]; then
    COFOUNDER_OPINION="${C_YELLOW}●${C_NC} Strategy is ${_strat_age_days}d old. Are you still solving the right problem?"
    return 0 2>/dev/null || true
fi

# Priority 4: Bottleneck with specific gap
if [[ -n "$_bottleneck" && "$_bottleneck_score" -lt 70 && -n "$_top_gap" ]]; then
    COFOUNDER_OPINION="${C_GREEN}▸${C_NC} ${C_BOLD}${_bottleneck}${C_NC} (${_bottleneck_score}) is the bottleneck. ${_top_gap:0:100}"
    return 0 2>/dev/null || true
fi

# Priority 5: Everything is healthy — push for the next level
if [[ -n "$_bottleneck" && "$_bottleneck_score" -ge 70 ]]; then
    COFOUNDER_OPINION="${C_GREEN}▸${C_NC} Lowest feature is ${C_BOLD}${_bottleneck}${C_NC} at ${_bottleneck_score}. Consider /strategy to check if you're building the right thing."
    return 0 2>/dev/null || true
fi

# Priority 6: No eval data — suggest starting
if [[ -z "$_bottleneck" ]]; then
    COFOUNDER_OPINION="${C_DIM}No eval data. Run /eval to see where you stand.${C_NC}"
fi
