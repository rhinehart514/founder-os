#!/usr/bin/env bash
set -uo pipefail

# data.sh — Visualize founder-os learning data
# Score trends, prediction accuracy, experiment stats.

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" 2>/dev/null || { echo "Cannot access $PROJECT_DIR"; exit 1; }

# Resolve FOUNDER_DIR
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _DATA_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_DATA_SOURCE" ]]; do
        _DATA_SOURCE="$(readlink "$_DATA_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_DATA_SOURCE")/.." && pwd)"
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Sparkline ---
# Takes a list of numbers, renders a sparkline
sparkline() {
    local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local vals=("$@")
    local min=999999 max=0

    for v in "${vals[@]}"; do
        [[ "$v" -lt "$min" ]] && min=$v
        [[ "$v" -gt "$max" ]] && max=$v
    done

    local range=$((max - min))
    [[ "$range" -eq 0 ]] && range=1

    local out=""
    for v in "${vals[@]}"; do
        local idx=$(( (v - min) * 7 / range ))
        [[ "$idx" -gt 7 ]] && idx=7
        [[ "$idx" -lt 0 ]] && idx=0
        out+="${chars[$idx]}"
    done
    echo "$out"
}

# --- Score History ---
print_scores() {
    local history_file=".claude/scores/history.tsv"

    if [[ ! -f "$history_file" ]]; then
        echo -e "  ${DIM}No score history yet. Run /score${NC}"
        return
    fi

    local total_runs=$(( $(wc -l < "$history_file" | tr -d ' ') - 1 ))

    if [[ "$total_runs" -lt 1 ]]; then
        echo -e "  ${DIM}No score history yet. Run /score${NC}"
        return
    fi

    echo -e "${BOLD}Score History${NC}  ${DIM}($total_runs runs)${NC}"
    echo ""

    # Get last 30 values for each dimension
    local max_show=30
    local show=$total_runs
    [[ "$show" -gt "$max_show" ]] && show=$max_show

    local structures=()
    local hygienes=()
    local timestamps=()

    while IFS=$'\t' read -r ts build struct hyg _; do
        structures+=("$struct")
        hygienes+=("$hyg")
        timestamps+=("$ts")
    done < <(tail -"$show" "$history_file")

    # Current values (macOS bash 3 compat — no negative indices)
    local count=${#structures[@]}
    local cur_struct="${structures[$((count - 1))]}"
    local cur_hyg="${hygienes[$((count - 1))]}"

    # First values in window
    local first_struct="${structures[0]}"
    local first_hyg="${hygienes[0]}"

    # Deltas
    local struct_delta=$((cur_struct - first_struct))
    local hyg_delta=$((cur_hyg - first_hyg))

    # Sparklines
    local struct_spark=$(sparkline "${structures[@]}")
    local hyg_spark=$(sparkline "${hygienes[@]}")

    # Format delta
    fmt_delta() {
        local d=$1
        if [[ "$d" -gt 0 ]]; then echo -e "${GREEN}+${d}${NC}"
        elif [[ "$d" -lt 0 ]]; then echo -e "${RED}${d}${NC}"
        else echo -e "${DIM}±0${NC}"
        fi
    }

    printf "  Structure  %s  %s  %b\n" "$struct_spark" "$cur_struct" "$(fmt_delta $struct_delta)"
    printf "  Hygiene    %s  %s  %b\n" "$hyg_spark" "$cur_hyg" "$(fmt_delta $hyg_delta)"

    echo ""

    # Time range
    local ts_count=${#timestamps[@]}
    local first_ts="${timestamps[0]}"
    local last_ts="${timestamps[$((ts_count - 1))]}"
    local first_date="${first_ts%%T*}"
    local last_date="${last_ts%%T*}"

    if [[ "$first_date" == "$last_date" ]]; then
        echo -e "  ${DIM}$first_date · $show runs${NC}"
    else
        echo -e "  ${DIM}$first_date → $last_date · $show runs${NC}"
    fi
}

# --- Predictions ---
print_predictions() {
    local pred_file="$HOME/.claude/knowledge/predictions.tsv"

    if [[ ! -f "$pred_file" ]]; then
        echo -e "  ${DIM}No predictions yet.${NC}"
        return
    fi

    local total=$(( $(wc -l < "$pred_file" | tr -d ' ') - 1 ))

    if [[ "$total" -lt 1 ]]; then
        echo -e "  ${DIM}No predictions yet.${NC}"
        return
    fi

    echo -e "${BOLD}Predictions${NC}  ${DIM}($total logged)${NC}"
    echo ""

    # Count correct/incorrect/partial
    local correct=0 incorrect=0 partial=0 pending=0
    while IFS=$'\t' read -r date agent pred evidence result corr update; do
        case "$corr" in
            yes)     ((correct++)) ;;
            no)      ((incorrect++)) ;;
            partial) ((partial++)) ;;
            *)       ((pending++)) ;;
        esac
    done < <(tail -n +2 "$pred_file")

    local evaluated=$((correct + incorrect + partial))

    if [[ "$evaluated" -gt 0 ]]; then
        local accuracy=$(( correct * 100 / evaluated ))

        # Accuracy color + calibration note
        local acc_color="$GREEN"
        local cal_note=""
        if [[ "$accuracy" -gt 90 ]]; then
            acc_color="$YELLOW"
            cal_note="  ${DIM}(too safe — not learning enough)${NC}"
        elif [[ "$accuracy" -lt 30 ]]; then
            acc_color="$RED"
            cal_note="  ${DIM}(model needs recalibration)${NC}"
        elif [[ "$accuracy" -ge 50 && "$accuracy" -le 70 ]]; then
            cal_note="  ${DIM}(well calibrated)${NC}"
        fi

        printf "  Accuracy   ${acc_color}%d%%${NC}%b\n" "$accuracy" "$cal_note"
        printf "  ${GREEN}✓${NC} %d correct  ${RED}✗${NC} %d wrong  ${YELLOW}~${NC} %d partial" "$correct" "$incorrect" "$partial"
        [[ "$pending" -gt 0 ]] && printf "  ${DIM}? %d pending${NC}" "$pending"
        echo ""
    else
        echo -e "  ${DIM}$pending predictions pending evaluation${NC}"
    fi

    # Show last 3 predictions
    echo ""
    echo -e "  ${DIM}Recent:${NC}"
    tail -3 "$pred_file" | while IFS=$'\t' read -r date agent pred evidence result corr update; do
        local icon="?"
        case "$corr" in
            yes)     icon="${GREEN}✓${NC}" ;;
            no)      icon="${RED}✗${NC}" ;;
            partial) icon="${YELLOW}~${NC}" ;;
            *)       icon="${DIM}?${NC}" ;;
        esac
        # Truncate prediction to 60 chars
        local short_pred="$pred"
        [[ "${#short_pred}" -gt 60 ]] && short_pred="${short_pred:0:57}..."
        printf "  %b %s  %b%s%b\n" "$icon" "$date" "$DIM" "$short_pred" "$NC"
    done
}

# --- Experiments ---
print_experiments() {
    local exp_file
    # Check both locations
    if [[ -f ".claude/brains/experiment-log.md" ]]; then
        exp_file=".claude/brains/experiment-log.md"
    elif [[ -f "$HOME/.claude/knowledge/experiment-learnings.md" ]]; then
        exp_file="$HOME/.claude/knowledge/experiment-learnings.md"
    else
        echo -e "  ${DIM}No experiment data yet.${NC}"
        return
    fi

    echo -e "${BOLD}Experiments${NC}"
    echo ""

    # Count kept/discarded from experiment-log.md
    if [[ -f ".claude/brains/experiment-log.md" ]]; then
        local kept=$(grep -ci 'kept' ".claude/brains/experiment-log.md" 2>/dev/null || echo 0)
        local discarded=$(grep -ci 'discard' ".claude/brains/experiment-log.md" 2>/dev/null || echo 0)
        local exp_total=$((kept + discarded))

        if [[ "$exp_total" -gt 0 ]]; then
            local keep_rate=$((kept * 100 / exp_total))
            local bar_kept=$((kept * 20 / exp_total))
            local bar_disc=$((20 - bar_kept))

            local bar=""
            for ((b=0; b<bar_kept; b++)); do bar+="█"; done
            for ((b=0; b<bar_disc; b++)); do bar+="░"; done

            printf "  Keep rate  ${GREEN}%s${NC}${DIM}%s${NC}  %d%%  ${DIM}(%d kept / %d total)${NC}\n" \
                "${bar:0:$bar_kept}" "${bar:$bar_kept}" "$keep_rate" "$kept" "$exp_total"
        else
            echo -e "  ${DIM}No experiments recorded yet.${NC}"
        fi
    fi

    # Count patterns from learnings
    if [[ -f "$HOME/.claude/knowledge/experiment-learnings.md" ]]; then
        local known=$(grep -c '^\- \*\*' "$HOME/.claude/knowledge/experiment-learnings.md" 2>/dev/null || echo 0)
        local dead=$(grep -ci 'dead end\|confirmed fail' "$HOME/.claude/knowledge/experiment-learnings.md" 2>/dev/null || echo 0)
        echo ""
        printf "  ${GREEN}%d${NC} known patterns  ${RED}%d${NC} dead ends\n" "$known" "$dead"
    fi
}

# --- Beliefs ---
print_beliefs() {
    local beliefs_file
    # Try project-local first, then founder-os default
    if [[ -f "lens/product/eval/beliefs.yml" ]]; then
        beliefs_file="lens/product/eval/beliefs.yml"
    elif [[ -f "config/evals/beliefs.yml" ]]; then
        beliefs_file="config/evals/beliefs.yml"
    elif [[ -f "$FOUNDER_DIR/lens/product/eval/beliefs.yml" ]]; then
        beliefs_file="$FOUNDER_DIR/lens/product/eval/beliefs.yml"
    elif [[ -f "$FOUNDER_DIR/config/evals/beliefs.yml" ]]; then
        beliefs_file="$FOUNDER_DIR/config/evals/beliefs.yml"
    else
        return
    fi

    local belief_count
    belief_count=$(grep -c '^\- id:' "$beliefs_file" 2>/dev/null) || belief_count=0
    local block_count
    block_count=$(grep -c 'severity: block' "$beliefs_file" 2>/dev/null) || block_count=0
    local warn_count
    warn_count=$(grep -c 'severity: warn' "$beliefs_file" 2>/dev/null) || warn_count=0

    if [[ "$belief_count" -gt 0 ]]; then
        echo -e "${BOLD}Beliefs${NC}  ${DIM}($belief_count active)${NC}"
        echo ""
        printf "  ${RED}%d${NC} blocking  ${YELLOW}%d${NC} warning\n" "$block_count" "$warn_count"
    fi
}

# ============================================================
# MAIN
# ============================================================
echo ""
echo -e "  ${CYAN}◆${NC} ${BOLD}founder data${NC}"
echo ""

print_scores
echo ""

print_predictions
echo ""

print_experiments
echo ""

print_beliefs
echo ""
