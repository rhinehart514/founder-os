#!/usr/bin/env bash
# self-checks.sh — Self-awareness checks for session boot card.
# Extracted from session_start.sh to reduce file size.
# Returns a single recommendation string via SELF_REC variable.
#
# Required env: PROJECT_DIR, FOUNDER_DIR, PRED_FILE, C_DIM, C_NC
# Required function: cfg()

SELF_REC=""

# 1. Hooks broken?
HOOKS_BROKEN_COUNT=0
if [[ -f "$PROJECT_DIR/.claude/settings.json" ]] && command -v jq &>/dev/null; then
    while IFS= read -r hook_cmd; do
        [[ -z "$hook_cmd" ]] && continue
        [[ ! -f "$hook_cmd" ]] && HOOKS_BROKEN_COUNT=$((HOOKS_BROKEN_COUNT + 1))
    done < <(jq -r '.. | .command? // empty' "$PROJECT_DIR/.claude/settings.json" 2>/dev/null)
else
    for hook in "$HOME/.claude/hooks/"*.sh; do
        [[ ! -f "$hook" ]] && continue
        if [[ -L "$hook" ]]; then
            target=$(readlink "$hook" 2>/dev/null)
            [[ ! -f "$target" ]] && HOOKS_BROKEN_COUNT=$((HOOKS_BROKEN_COUNT + 1))
        fi
    done
fi
if [[ "$HOOKS_BROKEN_COUNT" -gt 0 ]]; then
    SELF_REC="[self] $HOOKS_BROKEN_COUNT broken hook(s) — check hooks.json"
fi

# 2. Mind files missing?
if [[ -z "$SELF_REC" ]]; then
    MIND_MISSING_COUNT=0
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        if [[ ! -f "$FOUNDER_DIR/skills/founder-mind/SKILL.md" ]]; then
            MIND_MISSING_COUNT=1
        fi
    else
        RULES_DIR="$PROJECT_DIR/.claude/rules"
        [[ ! -d "$RULES_DIR" ]] && RULES_DIR="$HOME/.claude/rules"
        for mf in identity.md thinking.md standards.md self.md; do
            if [[ ! -L "$RULES_DIR/$mf" ]] || [[ ! -f "$RULES_DIR/$mf" ]]; then
                MIND_MISSING_COUNT=$((MIND_MISSING_COUNT + 1))
            fi
        done
    fi
    if [[ "$MIND_MISSING_COUNT" -gt 0 ]]; then
        SELF_REC="[self] $MIND_MISSING_COUNT mind file(s) not loaded — check plugin installation"
    fi
fi

# 3. Prediction accuracy out of range?
if [[ -z "$SELF_REC" && -f "$PRED_FILE" ]]; then
    GRADED=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" { c++ } END { print c+0 }')
    if [[ "$GRADED" -ge 5 ]]; then
        PCORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        FLOOR=$(cfg self.prediction_accuracy_floor 0.30)
        CEILING=$(cfg self.prediction_accuracy_ceiling 0.90)
        ACC=$(awk "BEGIN { printf \"%.2f\", $PCORRECT / $GRADED }")
        if awk "BEGIN { exit !($ACC < $FLOOR) }"; then
            SELF_REC="[self] prediction accuracy ${ACC} — model may be miscalibrated"
        elif awk "BEGIN { exit !($ACC > $CEILING) }"; then
            SELF_REC="[self] prediction accuracy ${ACC} — predictions may be too safe"
        fi
    fi
fi

# 4. No predictions recently?
if [[ -z "$SELF_REC" ]]; then
    STALE_DAYS=$(cfg self.prediction_stale_days 7)
    if [[ -f "$PRED_FILE" ]]; then
        CUTOFF=$(date -v-${STALE_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${STALE_DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
        if [[ -n "$CUTOFF" ]]; then
            RECENT_PREDS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v cutoff="$CUTOFF" '$1 >= cutoff { c++ } END { print c+0 }')
            MIN_PREDS=$(cfg self.min_predictions_per_week 3)
            if [[ "$RECENT_PREDS" -lt "$MIN_PREDS" ]]; then
                SELF_REC="[self] ${RECENT_PREDS} predictions in ${STALE_DAYS}d — learning loop stalled"
            fi
        fi
    else
        SELF_REC="[self] no predictions.tsv — learning loop not started"
    fi
fi

# 5. Knowledge model stale?
if [[ -z "$SELF_REC" ]]; then
    KN_STALE=$(cfg self.knowledge_stale_days 14)
    LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
    if [[ -f "$LEARNINGS" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            KN_MTIME=$(stat -f %m "$LEARNINGS" 2>/dev/null || echo 0)
        else
            KN_MTIME=$(stat -c %Y "$LEARNINGS" 2>/dev/null || echo 0)
        fi
        KN_AGE=$(( ($(date +%s) - KN_MTIME) / 86400 ))
        if [[ "$KN_AGE" -gt "$KN_STALE" ]]; then
            SELF_REC="[self] knowledge model ${KN_AGE}d old — consider /research"
        fi
    fi
fi
