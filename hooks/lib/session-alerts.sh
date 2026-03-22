# Learning velocity — show trajectory, not just current state
if [[ -f "$PRED_FILE" ]]; then
    # Count patterns learned this week (entries in experiment-learnings.md modified recently)
    LEARNINGS_FILE="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$LEARNINGS_FILE" ]] && LEARNINGS_FILE="$HOME/.claude/knowledge/experiment-learnings.md"
    PATTERNS_LEARNED=""
    if [[ -f "$LEARNINGS_FILE" ]]; then
        PATTERN_COUNT=$(grep -c '^\s*-\s' "$LEARNINGS_FILE" 2>/dev/null || echo "0")
        PATTERNS_LEARNED="${PATTERN_COUNT} patterns"
    fi

    # Compute accuracy trend: compare last 5 graded vs previous 5 graded
    GRADED_ALL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != ""' 2>/dev/null)
    GRADED_TOTAL=$(echo "$GRADED_ALL" | grep -c '.' 2>/dev/null || echo "0")
    if [[ "$GRADED_TOTAL" -ge 6 ]]; then
        # Recent 5
        RECENT_CORRECT=$(echo "$GRADED_ALL" | tail -5 | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        RECENT_PARTIAL=$(echo "$GRADED_ALL" | tail -5 | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
        RECENT_EFF=$(awk "BEGIN { printf \"%d\", ($RECENT_CORRECT + $RECENT_PARTIAL * 0.5) * 100 / 5 }")
        # Previous 5
        PREV_CORRECT=$(echo "$GRADED_ALL" | tail -10 | head -5 | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        PREV_PARTIAL=$(echo "$GRADED_ALL" | tail -10 | head -5 | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
        PREV_EFF=$(awk "BEGIN { printf \"%d\", ($PREV_CORRECT + $PREV_PARTIAL * 0.5) * 100 / 5 }")
        TREND_ARROW=""
        if [[ "$RECENT_EFF" -gt "$PREV_EFF" ]]; then
            TREND_ARROW="${C_GREEN}↑${C_NC} ${C_DIM}from ${PREV_EFF}%${C_NC}"
        elif [[ "$RECENT_EFF" -lt "$PREV_EFF" ]]; then
            TREND_ARROW="${C_RED}↓${C_NC} ${C_DIM}from ${PREV_EFF}%${C_NC}"
        fi
        # Calibration context: 50-70% = well-calibrated
        _cal_hint=""
        if [[ "$RECENT_EFF" -ge 50 && "$RECENT_EFF" -le 70 ]]; then
            _cal_hint="  ${C_DIM}(target: 50-70%)${C_NC}"
        elif [[ "$RECENT_EFF" -gt 70 ]]; then
            _cal_hint="  ${C_DIM}(>70% — predictions may be too safe)${C_NC}"
        elif [[ "$RECENT_EFF" -lt 50 ]]; then
            _cal_hint="  ${C_DIM}(<50% — model needs updating)${C_NC}"
        fi
        VELOCITY_LINE="  ${C_DIM}learning${C_NC}    ${RECENT_EFF}% accurate${_cal_hint}${TREND_ARROW:+ ${TREND_ARROW}}"
        [[ -n "$PATTERNS_LEARNED" ]] && VELOCITY_LINE="${VELOCITY_LINE}  ${C_DIM}·${C_NC}  ${PATTERNS_LEARNED}"
        echo -e "$VELOCITY_LINE"
    fi
fi

# --- Learning signals: surface wrong predictions as actionable intelligence ---
if [[ -f "$PRED_FILE" ]]; then
    WEEK_AGO_LS=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null || echo "0000-00-00")

    # Wrong predictions in last 7 days — suggest /plan target the weak area
    WRONG_7D=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$WEEK_AGO_LS" '$1 >= d && $6 == "no"' 2>/dev/null)
    WRONG_7D_COUNT=$(echo "$WRONG_7D" | grep -c '.' 2>/dev/null || echo "0")
    if [[ "$WRONG_7D_COUNT" -gt 0 ]]; then
        # Extract areas from wrong predictions (first 4+ char keyword)
        WRONG_AREAS=$(echo "$WRONG_7D" | awk -F'\t' '{print $3}' | grep -oE '[a-zA-Z_-]{4,}' | \
            grep -viE '^(will|from|that|this|with|have|been|into|than|they|them|were|more|each|also|does|make|raise|drop|should|would|could|because|about|after|before|between|improve|increase|decrease|change|predict|prediction|target|score|eval|expect)$' | \
            sort | uniq -c | sort -rn | head -3 | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
        if [[ -n "$WRONG_AREAS" ]]; then
            echo -e "  ${C_RED}●${C_NC} ${WRONG_7D_COUNT} wrong prediction(s) this week in: ${WRONG_AREAS}"
            echo -e "    ${C_DIM}→ /plan should target these areas — the model is wrong here${C_NC}"
            HAS_ALERTS=true

            # Write wrong-prediction areas to cache so /plan can read them
            local wrong_cache_dir="$PROJECT_DIR/.claude/cache"
            [[ ! -d "$wrong_cache_dir" ]] && wrong_cache_dir="$HOME/.claude/cache"
            mkdir -p "$wrong_cache_dir" 2>/dev/null
            echo "$WRONG_AREAS" > "$wrong_cache_dir/wrong-prediction-areas.txt"
        fi
    fi

    # Dead ends relevant to current bottleneck — warn before rebuilding
    LEARNINGS_LS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$LEARNINGS_LS" ]] && LEARNINGS_LS="$HOME/.claude/knowledge/experiment-learnings.md"
    if [[ -f "$LEARNINGS_LS" && -n "${NEXT_TASK:-}" ]]; then
        # Extract first keyword from next task
        TASK_KW=$(echo "$NEXT_TASK" | grep -oE '[a-zA-Z_-]{4,}' | head -1)
        if [[ -n "$TASK_KW" ]]; then
            DEAD_MATCH=$(awk '/^## Dead Ends/,0' "$LEARNINGS_LS" 2>/dev/null | grep -i "$TASK_KW" | head -1)
            if [[ -n "$DEAD_MATCH" ]]; then
                echo -e "  ${C_YELLOW}⚠${C_NC} Dead end near next task: ${DEAD_MATCH:0:70}"
                HAS_ALERTS=true
            fi
        fi
    fi
fi

# Experiment results stats
RESULTS_TSV="$PROJECT_DIR/.claude/experiments/results.tsv"
if [[ -f "$RESULTS_TSV" ]]; then
    EXP_TOTAL=$(tail -n +2 "$RESULTS_TSV" | wc -l | tr -d ' ')
    if [[ "$EXP_TOTAL" -gt 0 ]]; then
        EXP_KEPT=$(tail -n +2 "$RESULTS_TSV" | awk -F'\t' '$7 == "kept"' | wc -l | tr -d ' ')
        EXP_DISCARDED=$(tail -n +2 "$RESULTS_TSV" | awk -F'\t' '$7 == "discarded"' | wc -l | tr -d ' ')
        EXP_CRASHED=$(tail -n +2 "$RESULTS_TSV" | awk -F'\t' '$7 == "crashed"' | wc -l | tr -d ' ')
        EXP_DECIDABLE=$((EXP_KEPT + EXP_DISCARDED))
        EXP_KEEP_RATE=""
        if [[ "$EXP_DECIDABLE" -gt 0 ]]; then
            EXP_KEEP_RATE="  ${C_DIM}·${C_NC}  $(( EXP_KEPT * 100 / EXP_DECIDABLE ))% kept"
        fi
        EXP_LINE="${EXP_TOTAL} total${EXP_KEEP_RATE}"
        if [[ "$EXP_CRASHED" -gt 0 ]]; then
            EXP_LINE="${EXP_LINE}  ${C_DIM}·${C_NC}  ${C_RED}${EXP_CRASHED} crashed${C_NC}"
        fi
        echo -e "  ${C_DIM}experiments${C_NC} ${EXP_LINE}"
    fi
fi

echo ""

# Alerts — blockers first, then warnings
HAS_ALERTS=false

if [[ -n "$INTEGRITY_WARNINGS" ]]; then
    echo -e "  ${C_RED}●${C_NC} $(echo "$INTEGRITY_WARNINGS" | head -1)"
    HAS_ALERTS=true
fi

if [[ -n "$GRADE_SUMMARY" ]]; then
    echo -e "  ${C_GREEN}✓${C_NC} ${GRADE_SUMMARY}"
    # When predictions were graded, prompt consolidation of learnings
    echo -e "    ${C_DIM}→ consolidate: update experiment-learnings.md with graded predictions${C_NC}"
    HAS_ALERTS=true
fi

if (( UNGRADED_COUNT > 0 )); then
    # Show examples of ungraded predictions to make manual grading easier
    UNGRADED_EXAMPLES=""
    if [[ -f "$PRED_FILE" ]]; then
        UNGRADED_EXAMPLES=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "" { print $3 }' | head -2)
    fi
    echo -e "  ${C_RED}●${C_NC} ${UNGRADED_COUNT} ungraded predictions — run /retro"
    if [[ -n "$UNGRADED_EXAMPLES" ]]; then
        while IFS= read -r ue; do
            [[ -n "$ue" ]] && echo -e "    ${C_DIM}· ${ue:0:70}${C_NC}"
        done <<< "$UNGRADED_EXAMPLES"
    fi
    HAS_ALERTS=true
fi

[[ -n "$STRATEGY_STALE" ]] && { echo -e "  ${C_YELLOW}⚠${C_NC} ${STRATEGY_STALE}"; HAS_ALERTS=true; }
[[ -n "$AGENT_EXP_DISPLAY" ]] && { echo -e "  ${C_YELLOW}⚠${C_NC} ${AGENT_EXP_DISPLAY}"; HAS_ALERTS=true; }

[[ "$HAS_ALERTS" == true ]] && echo ""
