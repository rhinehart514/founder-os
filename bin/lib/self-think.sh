# ============================================================
# THINK (25 pts) — Can it reason?
# ============================================================
CURRENT_SYSTEM="think"

# mind-integrity (5 pts): 4 mind files present + delivered
MIND_FILES=(identity.md thinking.md standards.md self.md)
MIND_MISSING=0
MIND_UNLINKED=0
for mf in "${MIND_FILES[@]}"; do
    if [[ ! -f "$FOUNDER_DIR/mind/$mf" ]]; then
        MIND_MISSING=$((MIND_MISSING + 1))
    fi
done
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # Plugin mode: mind files delivered via skills/founder-mind/SKILL.md
    if [[ ! -f "$FOUNDER_DIR/skills/founder-mind/SKILL.md" ]]; then
        MIND_UNLINKED=1
    fi
else
    # Legacy mode: check symlinks in rules/
    for mf in "${MIND_FILES[@]}"; do
        RULES_CHECK_DIR="$PWD/.claude/rules"
        [[ ! -d "$RULES_CHECK_DIR" ]] && RULES_CHECK_DIR="$HOME/.claude/rules"
        if [[ ! -L "$RULES_CHECK_DIR/$mf" ]] || [[ ! -f "$RULES_CHECK_DIR/$mf" ]]; then
            MIND_UNLINKED=$((MIND_UNLINKED + 1))
        fi
    done
fi
if [[ "$MIND_MISSING" -eq 0 && "$MIND_UNLINKED" -eq 0 ]]; then
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        check_pass "mind-integrity" "4 mind files present + SKILL.md delivers them" 5
    else
        check_pass "mind-integrity" "4 mind files present + symlinked" 5
    fi
elif [[ "$MIND_MISSING" -gt 0 ]]; then
    check_fail "mind-integrity" "$MIND_MISSING mind file(s) missing from mind/" 5
else
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        check_fail "mind-integrity" "skills/founder-mind/SKILL.md missing" 5
    else
        check_fail "mind-integrity" "$MIND_UNLINKED mind file(s) not symlinked in rules/" 5
    fi
fi

# strategy-ready (5 pts): strategy.yml has stage + bottleneck
STRATEGY_FILE=".claude/plans/strategy.yml"
if [[ -f "$STRATEGY_FILE" ]]; then
    has_stage=$(grep -c 'stage:' "$STRATEGY_FILE" 2>/dev/null) || has_stage=0
    has_bottleneck=$(grep -c 'bottleneck:' "$STRATEGY_FILE" 2>/dev/null) || has_bottleneck=0
    if [[ "$has_stage" -gt 0 && "$has_bottleneck" -gt 0 ]]; then
        check_pass "strategy-ready" "strategy has stage + bottleneck" 5
    else
        check_warn "strategy-ready" "strategy missing stage or bottleneck" 2 5
    fi
else
    check_fail "strategy-ready" "no strategy.yml — run /strategy" 5
fi

# knowledge-coverage (6 pts): all 4 zones populated
LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    has_known=$(grep -c '## Known' "$LEARNINGS" 2>/dev/null) || has_known=0
    has_uncertain=$(grep -c '## Uncertain' "$LEARNINGS" 2>/dev/null) || has_uncertain=0
    has_unknown=$(grep -c '## Unknown' "$LEARNINGS" 2>/dev/null) || has_unknown=0
    has_dead=$(grep -c '## Dead' "$LEARNINGS" 2>/dev/null) || has_dead=0
    zones=$((has_known + has_uncertain + has_unknown + has_dead))
    if [[ "$zones" -ge 4 ]]; then
        check_pass "knowledge-coverage" "all 4 zones populated (known/uncertain/unknown/dead)" 6
    elif [[ "$zones" -ge 2 ]]; then
        check_warn "knowledge-coverage" "$zones/4 knowledge zones populated" $((zones * 6 / 4)) 6
    else
        check_fail "knowledge-coverage" "knowledge model has $zones/4 zones — too thin to reason from" 6
    fi
else
    check_fail "knowledge-coverage" "no experiment-learnings.md" 6
fi

# prediction-accuracy (5 pts): calibrated 30-90%
PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
ACCURACY_FLOOR=$(cfg self.prediction_accuracy_floor 0.30)
ACCURACY_CEILING=$(cfg self.prediction_accuracy_ceiling 0.90)

if [[ ! -f "$PRED_FILE" ]]; then
    check_warn "prediction-accuracy" "no predictions.tsv found" 0 5
else
    TOTAL_GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
    if [[ "$TOTAL_GRADED" -lt 5 ]]; then
        check_warn "prediction-accuracy" "only $TOTAL_GRADED graded predictions (need 5+ for calibration)" 2 5
    else
        CORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        PARTIAL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
        # Partial credit: directionally right but off on magnitude counts as 0.5
        ACCURACY=$(awk "BEGIN { printf \"%.2f\", ($CORRECT + $PARTIAL * 0.5) / $TOTAL_GRADED }")
        if awk "BEGIN { exit !($ACCURACY < $ACCURACY_FLOOR) }"; then
            check_fail "prediction-accuracy" "accuracy ${ACCURACY} below floor ${ACCURACY_FLOOR} — model may be broken" 5
        elif awk "BEGIN { exit !($ACCURACY > $ACCURACY_CEILING) }"; then
            check_warn "prediction-accuracy" "accuracy ${ACCURACY} above ceiling ${ACCURACY_CEILING} — predictions may be too safe" 2 5
        else
            check_pass "prediction-accuracy" "accuracy ${ACCURACY} (${CORRECT}/${TOTAL_GRADED}) — well calibrated" 5
        fi
    fi
fi

# knowledge-entry-staleness (4 pts): individual knowledge entries checked for age
KNOWLEDGE_STALE_DAYS=$(cfg self.knowledge_stale_days 14)
if [[ -f "$LEARNINGS" ]]; then
    # Count dated entries and check for stale ones (dates embedded in entries like "2026-03-10")
    STALE_ENTRIES=0
    TOTAL_ENTRIES=0
    CUTOFF_DATE=$(date -v-${KNOWLEDGE_STALE_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${KNOWLEDGE_STALE_DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
    if [[ -n "$CUTOFF_DATE" ]]; then
        while IFS= read -r entry_date; do
            [[ -z "$entry_date" ]] && continue
            TOTAL_ENTRIES=$((TOTAL_ENTRIES + 1))
            if [[ "$entry_date" < "$CUTOFF_DATE" ]]; then
                STALE_ENTRIES=$((STALE_ENTRIES + 1))
            fi
        done < <(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$LEARNINGS" 2>/dev/null | sort -u)
    fi
    if [[ "$TOTAL_ENTRIES" -eq 0 ]]; then
        check_warn "knowledge-entry-staleness" "no dated entries in knowledge model — can't assess freshness" 2 4
    elif [[ "$STALE_ENTRIES" -gt "$((TOTAL_ENTRIES / 2))" ]]; then
        check_warn "knowledge-entry-staleness" "${STALE_ENTRIES}/${TOTAL_ENTRIES} dated entries older than ${KNOWLEDGE_STALE_DAYS}d" 1 4
    else
        check_pass "knowledge-entry-staleness" "${TOTAL_ENTRIES} dated entries, ${STALE_ENTRIES} stale" 4
    fi
else
    check_fail "knowledge-entry-staleness" "no experiment-learnings.md" 4
fi
