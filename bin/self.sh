#!/usr/bin/env bash
# self.sh — founder-os self-diagnostic
# 4 systems × 25 pts each = 100 pts total: Measure, Think, Act, Learn
set -euo pipefail

# --- Recursion guard ---
# score.sh calls self.sh, self.sh must never call score.sh/eval.sh back.
# This guard catches any future accidental cross-calls.
FOUNDER_SELF_DEPTH="${FOUNDER_SELF_DEPTH:-0}"
if [[ "$FOUNDER_SELF_DEPTH" -ge 2 ]]; then
    echo "50"  # safe fallback
    exit 0
fi
export FOUNDER_SELF_DEPTH=$((FOUNDER_SELF_DEPTH + 1))

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SELF_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SELF_SOURCE" ]]; do
        _SELF_SOURCE="$(readlink "$_SELF_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_SELF_SOURCE")/.." && pwd)"
fi

source "$FOUNDER_DIR/bin/lib/config.sh"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
TOP_ISSUE=""

# --- Per-system point tracking ---
MEASURE_PTS=0; MEASURE_MAX=0
THINK_PTS=0;   THINK_MAX=0
ACT_PTS=0;     ACT_MAX=0
LEARN_PTS=0;   LEARN_MAX=0

# Current system context (set before each check)
CURRENT_SYSTEM=""

# Collected check results for display mode
declare -a CHECK_RESULTS=()

add_pts() {
    local pts="$1" max="$2"
    case "$CURRENT_SYSTEM" in
        measure) MEASURE_PTS=$((MEASURE_PTS + pts)); MEASURE_MAX=$((MEASURE_MAX + max)) ;;
        think)   THINK_PTS=$((THINK_PTS + pts));     THINK_MAX=$((THINK_MAX + max)) ;;
        act)     ACT_PTS=$((ACT_PTS + pts));         ACT_MAX=$((ACT_MAX + max)) ;;
        learn)   LEARN_PTS=$((LEARN_PTS + pts));     LEARN_MAX=$((LEARN_MAX + max)) ;;
    esac
}

check_pass() {
    local name="$1" desc="$2" pts="${3:-0}"
    add_pts "$pts" "$pts"
    CHECK_RESULTS+=("pass|$CURRENT_SYSTEM|$name|$desc|$pts/$pts")
}

check_warn() {
    local name="$1" desc="$2" pts="${3:-0}" max="${4:-0}"
    add_pts "$pts" "$max"
    CHECK_RESULTS+=("warn|$CURRENT_SYSTEM|$name|$desc|$pts/$max")
    [[ -z "$TOP_ISSUE" ]] && TOP_ISSUE="$desc" || true
}

check_fail() {
    local name="$1" desc="$2" max="${3:-0}"
    add_pts 0 "$max"
    CHECK_RESULTS+=("fail|$CURRENT_SYSTEM|$name|$desc|0/$max")
    [[ -z "$TOP_ISSUE" ]] && TOP_ISSUE="$desc" || true
}

# --- Check for --eval, --score, --json modes ---
EVAL_MODE=false
SCORE_MODE=false
JSON_MODE=false
for arg in "$@"; do
    [[ "$arg" == "--eval" ]] && EVAL_MODE=true
    [[ "$arg" == "--score" ]] && SCORE_MODE=true
    [[ "$arg" == "--json" ]] && JSON_MODE=true
done

SILENT=$([[ "$EVAL_MODE" == "true" || "$SCORE_MODE" == "true" || "$JSON_MODE" == "true" ]] && echo true || echo false)

if [[ "$SILENT" != "true" ]]; then
    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}founder self${NC}  ${DIM}${TIMESTAMP}${NC}"
    echo ""
fi

# --- Run system checks ---
source "$FOUNDER_DIR/bin/lib/self-measure.sh"
source "$FOUNDER_DIR/bin/lib/self-think.sh"
source "$FOUNDER_DIR/bin/lib/self-act.sh"
source "$FOUNDER_DIR/bin/lib/self-learn.sh"

# ============================================================
# Compute system scores (normalize to 25 pts each)
# ============================================================
normalize() {
    local pts="$1" max="$2"
    if [[ "$max" -eq 0 ]]; then echo 0; return; fi
    echo $(( pts * 25 / max ))
}

MEASURE_SCORE=$(normalize "$MEASURE_PTS" "$MEASURE_MAX")
THINK_SCORE=$(normalize "$THINK_PTS" "$THINK_MAX")
ACT_SCORE=$(normalize "$ACT_PTS" "$ACT_MAX")
LEARN_SCORE=$(normalize "$LEARN_PTS" "$LEARN_MAX")
TOTAL_SCORE=$((MEASURE_SCORE + THINK_SCORE + ACT_SCORE + LEARN_SCORE))

# === --score mode: output 0-100 ===
if [[ "$SCORE_MODE" == "true" ]]; then
    echo "$TOTAL_SCORE"
    exit 0
fi

# === --json mode: output system breakdown ===
if [[ "$JSON_MODE" == "true" ]]; then
    echo "{\"measure\":$MEASURE_SCORE,\"think\":$THINK_SCORE,\"act\":$ACT_SCORE,\"learn\":$LEARN_SCORE,\"total\":$TOTAL_SCORE}"
    exit 0
fi

# === --eval mode: machine-readable output for eval.sh ===
if [[ "$EVAL_MODE" == "true" ]]; then
    PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
    CAL_STATUS="HEALTHY"
    CAL_DETAIL="score ${TOTAL_SCORE}/100 (M:${MEASURE_SCORE} T:${THINK_SCORE} A:${ACT_SCORE} L:${LEARN_SCORE})"
    if [[ -f "$PRED_FILE" ]]; then
        TOTAL_GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
        if [[ "$TOTAL_GRADED" -ge 5 ]]; then
            CORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
            PARTIAL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
            # Partial credit: directionally right counts as 0.5
            ACCURACY=$(awk "BEGIN { printf \"%.2f\", ($CORRECT + $PARTIAL * 0.5) / $TOTAL_GRADED }")
            FLOOR=$(cfg self.prediction_accuracy_floor 0.30)
            CEILING=$(cfg self.prediction_accuracy_ceiling 0.90)
            if awk "BEGIN { exit !($ACCURACY < $FLOOR) }"; then
                CAL_STATUS="BROKEN"
            elif awk "BEGIN { exit !($ACCURACY > $CEILING) }"; then
                CAL_STATUS="TOO_SAFE"
            fi
            CAL_DETAIL="accuracy ${ACCURACY} (${CORRECT}+${PARTIAL}p/${TOTAL_GRADED}), ${CAL_DETAIL}"
        else
            CAL_STATUS="INSUFFICIENT"
            CAL_DETAIL="only ${TOTAL_GRADED} graded predictions (need 5+)"
        fi
    else
        CAL_STATUS="INSUFFICIENT"
        CAL_DETAIL="no predictions.tsv found"
    fi

    if [[ "$CAL_STATUS" == "HEALTHY" || "$CAL_STATUS" == "INSUFFICIENT" ]]; then
        echo "calibration:pass:${CAL_STATUS} — ${CAL_DETAIL}"
    else
        echo "calibration:fail:${CAL_STATUS} — ${CAL_DETAIL}"
    fi

    # Remaining metrics: only safe to run outside the scoring pipeline.
    # When called from eval.sh (FOUNDER_EVAL_DEPTH > 0), skip to avoid recursion.
    if [[ "${FOUNDER_EVAL_DEPTH:-0}" -eq 0 ]]; then
        # score-runs: does founder score . --quiet produce a number?
        score_out=$("$FOUNDER_DIR/bin/score.sh" . --quiet --force 2>/dev/null) || score_out=""
        if [[ -n "$score_out" && "$score_out" =~ ^[0-9]+$ ]]; then
            echo "score-runs:pass:founder score produces $score_out"
        else
            echo "score-runs:fail:founder score did not produce a number"
        fi

        # eval-runs: does founder eval . exit without crash?
        if "$FOUNDER_DIR/bin/eval.sh" . >/dev/null 2>&1; then
            echo "eval-runs:pass:founder eval exits cleanly"
        else
            echo "eval-runs:fail:founder eval crashed"
        fi

        # tests-pass: does founder test exit 0?
        if "$FOUNDER_DIR/bin/founder" test >/dev/null 2>&1; then
            echo "tests-pass:pass:founder test exits 0"
        else
            echo "tests-pass:fail:founder test failed"
        fi
    else
        # Inside scoring pipeline — check existence instead of execution
        [[ -f "$FOUNDER_DIR/bin/score.sh" ]] && echo "score-runs:pass:score.sh exists" || echo "score-runs:fail:score.sh missing"
        [[ -f "$FOUNDER_DIR/bin/eval.sh" ]] && echo "eval-runs:pass:eval.sh exists" || echo "eval-runs:fail:eval.sh missing"
        [[ -d "$FOUNDER_DIR/tests" ]] && echo "tests-pass:pass:tests/ exists" || echo "tests-pass:fail:tests/ missing"
    fi

    # value-hypothesis-defined: does founder.yml have value: section?
    if [[ -f "$FOUNDER_DIR/config/founder.yml" ]] && grep -q '^value:' "$FOUNDER_DIR/config/founder.yml" 2>/dev/null; then
        echo "value-hypothesis-defined:pass:founder.yml has value: section"
    else
        echo "value-hypothesis-defined:fail:founder.yml missing value: section"
    fi

    # predictions-logged: does predictions.tsv have entries?
    _pred="$HOME/.claude/knowledge/predictions.tsv"
    if [[ -f "$_pred" ]]; then
        _pcount=$(tail -n +2 "$_pred" | wc -l | tr -d ' ')
        if [[ "$_pcount" -gt 0 ]]; then
            echo "predictions-logged:pass:${_pcount} predictions logged"
        else
            echo "predictions-logged:fail:predictions.tsv exists but empty"
        fi
    else
        echo "predictions-logged:fail:no predictions.tsv"
    fi

    # help-works: does founder help produce output?
    _help_out=$("$FOUNDER_DIR/bin/founder" help 2>&1) || true
    if echo "$_help_out" | grep -q 'founder'; then
        echo "help-works:pass:founder help produces output"
    else
        echo "help-works:fail:founder help produced no output"
    fi

    # skills-have-descriptions: every SKILL.md in skills/ has description: in frontmatter
    _skill_dir="$FOUNDER_DIR/skills"
    _cmd_total=0; _cmd_ok=0
    if [[ -d "$_skill_dir" ]]; then
        for _cf in "$_skill_dir"/*/SKILL.md; do
            [[ ! -f "$_cf" ]] && continue
            _cmd_total=$((_cmd_total + 1))
            if head -5 "$_cf" | grep -q 'description:'; then
                _cmd_ok=$((_cmd_ok + 1))
            fi
        done
    fi
    if [[ "$_cmd_total" -eq 0 ]]; then
        echo "skills-have-descriptions:fail:no skill files"
    elif [[ "$_cmd_ok" -eq "$_cmd_total" ]]; then
        echo "skills-have-descriptions:pass:${_cmd_ok}/${_cmd_total} have descriptions"
    else
        echo "skills-have-descriptions:fail:$((_cmd_total - _cmd_ok))/${_cmd_total} missing description"
    fi

    # install-exists: install.sh exists and is executable
    if [[ -x "$FOUNDER_DIR/install.sh" ]]; then
        echo "install-exists:pass:install.sh exists and is executable"
    elif [[ -f "$FOUNDER_DIR/install.sh" ]]; then
        echo "install-exists:fail:install.sh exists but not executable"
    else
        echo "install-exists:fail:install.sh missing"
    fi

    # readme-exists: README.md exists with content
    if [[ -f "$FOUNDER_DIR/README.md" ]]; then
        _rlines=$(wc -l < "$FOUNDER_DIR/README.md" | tr -d ' ')
        if [[ "$_rlines" -gt 10 ]]; then
            echo "readme-exists:pass:README.md exists (${_rlines} lines)"
        else
            echo "readme-exists:fail:README.md exists but too short (${_rlines} lines)"
        fi
    else
        echo "readme-exists:fail:README.md missing"
    fi

    # readme-has-commands: README mentions slash commands
    if [[ -f "$FOUNDER_DIR/README.md" ]] && grep -q '/plan\|/go\|/assert\|/feature' "$FOUNDER_DIR/README.md" 2>/dev/null; then
        echo "readme-has-commands:pass:README documents slash commands"
    else
        echo "readme-has-commands:fail:README doesn't mention slash commands"
    fi

    # readme-has-scoring: README explains scoring
    if [[ -f "$FOUNDER_DIR/README.md" ]] && grep -q 'assertion pass rate\|scoring' "$FOUNDER_DIR/README.md" 2>/dev/null; then
        echo "readme-has-scoring:pass:README explains scoring"
    else
        echo "readme-has-scoring:fail:README doesn't explain scoring"
    fi

    exit 0
fi

# === Display mode: grouped by system with subtotals ===

sys_color() {
    local pts="$1"
    if [[ "$pts" -ge 20 ]]; then echo "$GREEN"
    elif [[ "$pts" -ge 12 ]]; then echo "$YELLOW"
    else echo "$RED"
    fi
}

render_system() {
    local sys_name="$1" sys_key="$2" sys_score="$3"
    local color
    color=$(sys_color "$sys_score")
    echo -e "  ${BOLD}${sys_name}${NC} ${color}${sys_score}/25${NC}"

    for entry in "${CHECK_RESULTS[@]}"; do
        local status sys name desc pts
        IFS='|' read -r status sys name desc pts <<< "$entry"
        [[ "$sys" != "$sys_key" ]] && continue
        case "$status" in
            pass) printf "    ${GREEN}✓${NC} %-22s ${DIM}%s${NC}\n" "$name" "$desc" ;;
            warn) printf "    ${YELLOW}⚠${NC} %-22s ${YELLOW}%s${NC}\n" "$name" "$desc" ;;
            fail) printf "    ${RED}✗${NC} %-22s ${RED}%s${NC}\n" "$name" "$desc" ;;
        esac
    done
    echo ""
}

render_system "Measure" "measure" "$MEASURE_SCORE"
render_system "Think"   "think"   "$THINK_SCORE"
render_system "Act"     "act"     "$ACT_SCORE"
render_system "Learn"   "learn"   "$LEARN_SCORE"

# Overall
overall_color=$(sys_color "$((TOTAL_SCORE / 4))")
echo -e "  ${BOLD}Total: ${overall_color}${TOTAL_SCORE}/100${NC}"

if [[ -n "$TOP_ISSUE" ]]; then
    echo -e "  ${DIM}→${NC} $TOP_ISSUE"
fi
echo ""

# Weakest system
weakest_score=$MEASURE_SCORE; weakest_name="Measure"
[[ "$THINK_SCORE" -lt "$weakest_score" ]] && weakest_score=$THINK_SCORE && weakest_name="Think"
[[ "$ACT_SCORE" -lt "$weakest_score" ]] && weakest_score=$ACT_SCORE && weakest_name="Act"
[[ "$LEARN_SCORE" -lt "$weakest_score" ]] && weakest_score=$LEARN_SCORE && weakest_name="Learn"

if [[ "$weakest_score" -lt 20 ]]; then
    echo -e "  ${DIM}weakest system: ${BOLD}${weakest_name}${NC} ${DIM}(${weakest_score}/25)${NC}"
    echo ""
fi

exit 0
