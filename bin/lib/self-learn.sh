# ============================================================
# LEARN (25 pts) — Does it compound?
# ============================================================
CURRENT_SYSTEM="learn"

# learning-velocity (5 pts): predictions per week
MIN_PER_WEEK=$(cfg self.min_predictions_per_week 3)
PRED_STALE_DAYS=$(cfg self.prediction_stale_days 7)

if [[ ! -f "$PRED_FILE" ]]; then
    check_warn "learning-velocity" "no predictions.tsv" 0 5
else
    CUTOFF_DATE=$(date -v-${PRED_STALE_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${PRED_STALE_DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
    if [[ -n "$CUTOFF_DATE" ]]; then
        RECENT_COUNT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v cutoff="$CUTOFF_DATE" '$1 >= cutoff { c++ } END { print c+0 }')
        if [[ "$RECENT_COUNT" -lt "$MIN_PER_WEEK" ]]; then
            check_warn "learning-velocity" "${RECENT_COUNT} predictions in last ${PRED_STALE_DAYS}d (minimum: ${MIN_PER_WEEK})" 2 5
        else
            check_pass "learning-velocity" "${RECENT_COUNT} predictions in last ${PRED_STALE_DAYS}d" 5
        fi
    else
        check_warn "learning-velocity" "could not compute date cutoff" 0 5
    fi
fi

# prediction-grading (4 pts): are predictions being graded?
if [[ ! -f "$PRED_FILE" ]]; then
    check_warn "prediction-grading" "no predictions.tsv" 0 4
else
    TOTAL_ROWS=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    TOTAL_GRADED_L=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
    if [[ "$TOTAL_ROWS" -eq 0 ]]; then
        check_warn "prediction-grading" "no predictions logged yet" 0 4
    elif [[ "$TOTAL_GRADED_L" -eq 0 ]]; then
        check_fail "prediction-grading" "0/$TOTAL_ROWS predictions graded — learning loop stalled" 4
    else
        grade_rate=$((TOTAL_GRADED_L * 100 / TOTAL_ROWS))
        if [[ "$grade_rate" -ge 50 ]]; then
            check_pass "prediction-grading" "$TOTAL_GRADED_L/$TOTAL_ROWS predictions graded (${grade_rate}%)" 4
        else
            check_warn "prediction-grading" "$TOTAL_GRADED_L/$TOTAL_ROWS predictions graded (${grade_rate}%)" 2 4
        fi
    fi
fi

# knowledge-freshness (4 pts): experiment-learnings.md age
KNOWLEDGE_STALE_DAYS=$(cfg self.knowledge_stale_days 14)

if [[ ! -f "$LEARNINGS" ]]; then
    check_fail "knowledge-freshness" "experiment-learnings.md not found" 4
else
    if [[ "$(uname)" == "Darwin" ]]; then
        MTIME=$(stat -f %m "$LEARNINGS" 2>/dev/null || echo 0)
    else
        MTIME=$(stat -c %Y "$LEARNINGS" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
    if [[ "$AGE_DAYS" -gt "$KNOWLEDGE_STALE_DAYS" ]]; then
        check_warn "knowledge-freshness" "experiment-learnings.md is ${AGE_DAYS}d old (threshold: ${KNOWLEDGE_STALE_DAYS}d)" 2 4
    else
        check_pass "knowledge-freshness" "experiment-learnings.md updated ${AGE_DAYS}d ago" 4
    fi
fi

# self-model-freshness (4 pts): mind/self.md age
SELF_STALE_DAYS=$(cfg self.self_stale_days 7)
SELF_FILE="$FOUNDER_DIR/mind/self.md"

if [[ ! -f "$SELF_FILE" ]]; then
    check_fail "self-model-freshness" "mind/self.md not found" 4
else
    if [[ "$(uname)" == "Darwin" ]]; then
        MTIME=$(stat -f %m "$SELF_FILE" 2>/dev/null || echo 0)
    else
        MTIME=$(stat -c %Y "$SELF_FILE" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
    if [[ "$AGE_DAYS" -gt "$SELF_STALE_DAYS" ]]; then
        check_warn "self-model-freshness" "mind/self.md is ${AGE_DAYS}d old (threshold: ${SELF_STALE_DAYS}d)" 2 4
    else
        check_pass "self-model-freshness" "mind/self.md updated ${AGE_DAYS}d ago" 4
    fi
fi

# grade-runs (4 pts): grade.sh executes and produces output
if [[ ! -f "$FOUNDER_DIR/bin/grade.sh" ]]; then
    check_fail "grade-runs" "grade.sh not found" 4
elif [[ ! -x "$FOUNDER_DIR/bin/grade.sh" ]]; then
    check_fail "grade-runs" "grade.sh not executable" 4
else
    if [[ -f "$PRED_FILE" ]]; then
        # Actually run grade.sh --quiet and check exit code
        if bash "$FOUNDER_DIR/bin/grade.sh" --quiet "$PRED_FILE" \
            "$PWD/.claude/scores/history.tsv" \
            "$PWD/.claude/cache/score-cache.json" 2>/dev/null; then
            check_pass "grade-runs" "grade.sh executes successfully" 4
        else
            check_warn "grade-runs" "grade.sh exited with error" 2 4
        fi
    else
        check_warn "grade-runs" "grade.sh exists but no predictions.tsv to grade" 2 4
    fi
fi

# prediction-trend (3 pts): is accuracy improving over time?
if [[ -f "$PRED_FILE" ]]; then
    TOTAL_GRADED_T=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
    if [[ "$TOTAL_GRADED_T" -ge 8 ]]; then
        # Compare first half vs second half accuracy
        HALF=$((TOTAL_GRADED_T / 2))
        FIRST_HALF_ACC=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++; if($6=="yes") y++; if($6=="partial") p++ } c<='"$HALF"' { } END { printf "%.2f", (y + p*0.5) / (c>0?c:1) }')
        SECOND_HALF_ACC=$(tail -n +2 "$PRED_FILE" | awk -F'\t' 'BEGIN{c=0;y=0;p=0;skip='"$HALF"'} $6 != "" { total++; if(total>skip) { c++; if($6=="yes") y++; if($6=="partial") p++ } } END { printf "%.2f", (y + p*0.5) / (c>0?c:1) }')
        if awk "BEGIN { exit !($SECOND_HALF_ACC >= $FIRST_HALF_ACC) }"; then
            check_pass "prediction-trend" "accuracy improving: ${FIRST_HALF_ACC} → ${SECOND_HALF_ACC}" 3
        else
            check_warn "prediction-trend" "accuracy declining: ${FIRST_HALF_ACC} → ${SECOND_HALF_ACC}" 1 3
        fi
    else
        check_warn "prediction-trend" "need 8+ graded predictions for trend (have ${TOTAL_GRADED_T})" 1 3
    fi
else
    check_warn "prediction-trend" "no predictions.tsv" 0 3
fi

# knowledge-velocity (3 pts): new entries being added recently?
if [[ -f "$LEARNINGS" ]]; then
    RECENT_CUTOFF=$(date -v-14d '+%Y-%m-%d' 2>/dev/null || date -d "14 days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
    if [[ -n "$RECENT_CUTOFF" ]]; then
        RECENT_ENTRIES=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$LEARNINGS" 2>/dev/null | \
            awk -v cutoff="$RECENT_CUTOFF" '$0 >= cutoff { c++ } END { print c+0 }')
        if [[ "$RECENT_ENTRIES" -ge 3 ]]; then
            check_pass "knowledge-velocity" "${RECENT_ENTRIES} knowledge entries from last 14d" 3
        elif [[ "$RECENT_ENTRIES" -ge 1 ]]; then
            check_warn "knowledge-velocity" "only ${RECENT_ENTRIES} entries from last 14d — model growth stalling" 1 3
        else
            check_fail "knowledge-velocity" "0 entries from last 14d — model is stagnant" 3
        fi
    else
        check_warn "knowledge-velocity" "could not compute date cutoff" 0 3
    fi
else
    check_fail "knowledge-velocity" "no experiment-learnings.md" 3
fi

# citation-rate (3 pts): do predictions cite evidence?
if [[ -f "$PRED_FILE" ]]; then
    TOTAL_PREDS=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    CITED_PREDS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$3 != "" && $3 != " " { c++ } END { print c+0 }')
    if [[ "$TOTAL_PREDS" -eq 0 ]]; then
        check_warn "citation-rate" "no predictions yet" 0 3
    else
        CITE_RATE=$((CITED_PREDS * 100 / TOTAL_PREDS))
        if [[ "$CITE_RATE" -ge 70 ]]; then
            check_pass "citation-rate" "${CITED_PREDS}/${TOTAL_PREDS} predictions cite evidence (${CITE_RATE}%)" 3
        elif [[ "$CITE_RATE" -ge 40 ]]; then
            check_warn "citation-rate" "${CITED_PREDS}/${TOTAL_PREDS} cite evidence (${CITE_RATE}%) — too many guesses" 1 3
        else
            check_fail "citation-rate" "${CITED_PREDS}/${TOTAL_PREDS} cite evidence (${CITE_RATE}%) — model not grounded" 3
        fi
    fi
else
    check_warn "citation-rate" "no predictions.tsv" 0 3
fi

# learning-loop-closure (4 pts): full loop — predictions exist → graded → knowledge updated
# This is the core logic check: does the learning loop actually close?
LOOP_STAGES=0
LOOP_TOTAL=4
# Stage 1: predictions exist
if [[ -f "$PRED_FILE" ]]; then
    PRED_ROWS=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    [[ "$PRED_ROWS" -gt 0 ]] && LOOP_STAGES=$((LOOP_STAGES + 1))
fi
# Stage 2: some predictions are graded
if [[ -f "$PRED_FILE" ]]; then
    GRADED_ROWS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
    [[ "$GRADED_ROWS" -gt 0 ]] && LOOP_STAGES=$((LOOP_STAGES + 1))
fi
# Stage 3: knowledge model has content (not just headers)
if [[ -f "$LEARNINGS" ]]; then
    KNOWLEDGE_ENTRIES=$(grep -c '^\s*-\s' "$LEARNINGS" 2>/dev/null || echo "0")
    [[ "$KNOWLEDGE_ENTRIES" -gt 0 ]] && LOOP_STAGES=$((LOOP_STAGES + 1))
fi
# Stage 4: model_update column has entries (grading → knowledge feedback)
if [[ -f "$PRED_FILE" ]]; then
    MODEL_UPDATES=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$7 != "" { c++ } END { print c+0 }')
    [[ "$MODEL_UPDATES" -gt 0 ]] && LOOP_STAGES=$((LOOP_STAGES + 1))
fi

if [[ "$LOOP_STAGES" -eq "$LOOP_TOTAL" ]]; then
    check_pass "learning-loop-closure" "full loop: predict→grade→update→knowledge (${LOOP_STAGES}/${LOOP_TOTAL})" 4
elif [[ "$LOOP_STAGES" -ge 2 ]]; then
    check_warn "learning-loop-closure" "loop partially closed: ${LOOP_STAGES}/${LOOP_TOTAL} stages active" $((LOOP_STAGES * 4 / LOOP_TOTAL)) 4
else
    check_fail "learning-loop-closure" "learning loop broken: only ${LOOP_STAGES}/${LOOP_TOTAL} stages active" 4
fi
