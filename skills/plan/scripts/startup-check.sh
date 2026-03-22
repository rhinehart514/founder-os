#!/usr/bin/env bash
# startup-check.sh — Mechanically check the 8 startup failure modes.
# Usage: bash scripts/startup-check.sh [project-dir]
# Output: one section per triggered pattern with severity + intervention.
set -euo pipefail

PROJECT_DIR="${1:-.}"
NOW=$(date +%s)
TRIGGERED=0

echo "=== STARTUP PATTERN CHECK ==="
echo ""

# --- 1. Building Without a Named Person ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    USER_FIELD=$(grep -m1 'user:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*user: *//' | sed 's/"//g' || echo "")
    if [[ -z "$USER_FIELD" ]] || echo "$USER_FIELD" | grep -qiE '^(users|developers|teams|people|everyone)$'; then
        echo "CRITICAL: Building Without a Named Person"
        echo "  user field: \"$USER_FIELD\""
        echo "  intervention: Name one human being and their situation before writing more code."
        echo ""
        TRIGGERED=$((TRIGGERED + 1))
    fi
fi

# --- 2. Polishing Before Delivering ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    POLISH=$(jq -r 'to_entries[] | select(.value.craft_score != null and .value.delivery_score != null) | select((.value.craft_score | tonumber) > ((.value.delivery_score | tonumber) + 15)) | "\(.key): craft=\(.value.craft_score) delivery=\(.value.delivery_score)"' "$EVAL_CACHE" 2>/dev/null || echo "")
    if [[ -n "$POLISH" ]]; then
        echo "CRITICAL: Polishing Before Delivering"
        echo "$POLISH" | sed 's/^/  /'
        echo "  intervention: Ship the value, then polish."
        echo ""
        TRIGGERED=$((TRIGGERED + 1))
    fi
fi

# --- 3. Feature Sprawl ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    SPRAWL_COUNT=$(jq '[to_entries[] | select(.value.score != null) | select((.value.score | tonumber) >= 30 and (.value.score | tonumber) <= 60)] | length' "$EVAL_CACHE" 2>/dev/null || echo "0")
    if [[ "$SPRAWL_COUNT" -gt 3 ]]; then
        SEVERITY="WARNING"
        [[ "$SPRAWL_COUNT" -gt 5 ]] && SEVERITY="CRITICAL"
        echo "$SEVERITY: Feature Sprawl ($SPRAWL_COUNT features in 30-60 range)"
        jq -r 'to_entries[] | select(.value.score != null) | select((.value.score | tonumber) >= 30 and (.value.score | tonumber) <= 60) | "  \(.key): \(.value.score)"' "$EVAL_CACHE" 2>/dev/null
        echo "  intervention: Pick one. Finish it. Kill or defer the rest."
        echo ""
        TRIGGERED=$((TRIGGERED + 1))
    fi
fi

# --- 4. Prediction Starvation ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null || echo "0000-00-00")
    RECENT_PREDS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v d="$WEEK_AGO" '$1 >= d' | wc -l | tr -d ' ')
    if [[ "$RECENT_PREDS" -lt 3 ]]; then
        echo "WARNING: Prediction Starvation ($RECENT_PREDS predictions in 7 days)"
        echo "  intervention: The learning loop is starving. Every move needs a prediction."
        echo ""
        TRIGGERED=$((TRIGGERED + 1))
    fi
fi

# --- 5. Strategy Avoidance ---
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ ! -f "$STRATEGY" ]]; then
    echo "WARNING: Strategy Avoidance (no strategy.yml)"
    echo "  intervention: Run /strategy honest."
    echo ""
    TRIGGERED=$((TRIGGERED + 1))
else
    UPDATED=$(grep -m1 'last_updated:' "$STRATEGY" 2>/dev/null | sed 's/.*last_updated: *//' || echo "")
    if [[ -n "$UPDATED" ]]; then
        UPDATED_TS=$(date -j -f "%Y-%m-%d" "$UPDATED" +%s 2>/dev/null || date -d "$UPDATED" +%s 2>/dev/null || echo "0")
        AGE_DAYS=$(( (NOW - UPDATED_TS) / 86400 ))
        if [[ "$AGE_DAYS" -gt 14 ]]; then
            echo "WARNING: Strategy Avoidance (${AGE_DAYS} days stale)"
            echo "  intervention: No strategy in ${AGE_DAYS} days. Run /strategy honest."
            echo ""
            TRIGGERED=$((TRIGGERED + 1))
        fi
    fi
fi

# --- 6. Thesis Drift ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    # Check if any evidence items have moved recently
    EVIDENCE_DATES=$(grep -A2 'evidence_needed:' "$ROADMAP" 2>/dev/null | grep 'updated:' | sed 's/.*updated: *//' || echo "")
    if [[ -n "$EVIDENCE_DATES" ]]; then
        ALL_STALE=true
        while IFS= read -r edate; do
            [[ -z "$edate" ]] && continue
            ETS=$(date -j -f "%Y-%m-%d" "$edate" +%s 2>/dev/null || date -d "$edate" +%s 2>/dev/null || echo "0")
            EAGE=$(( (NOW - ETS) / 86400 ))
            [[ "$EAGE" -lt 14 ]] && ALL_STALE=false
        done <<< "$EVIDENCE_DATES"
        if $ALL_STALE; then
            echo "WARNING: Thesis Drift (evidence hasn't moved in 14+ days)"
            echo "  intervention: Either the thesis is wrong or you're avoiding it."
            echo ""
            TRIGGERED=$((TRIGGERED + 1))
        fi
    fi
fi

# --- 7. Revenue Avoidance ---
if [[ -f "$FOUNDER_YML" ]]; then
    HAS_PRICING=$(grep -c 'pricing:' "$FOUNDER_YML" 2>/dev/null | tr -d '[:space:]' || echo "0")
    if [[ "$HAS_PRICING" -eq 0 ]] && [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
        WORKING_COUNT=$(jq '[to_entries[] | select(.value.score != null) | select((.value.score | tonumber) >= 50)] | length' "$EVAL_CACHE" 2>/dev/null | tr -d '[:space:]' || echo "0")
        STAGE=$(grep -m1 'stage:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*stage: *//' || echo "mvp")
        if [[ "$WORKING_COUNT" -ge 3 ]]; then
            SEVERITY="WARNING"
            [[ "$STAGE" =~ growth|mature ]] && SEVERITY="CRITICAL"
            [[ "$STAGE" == "mvp" ]] && SEVERITY="" # skip at mvp
            if [[ -n "$SEVERITY" ]]; then
                echo "$SEVERITY: Revenue Avoidance ($WORKING_COUNT features scoring 50+ with no pricing)"
                echo "  intervention: Run /money price."
                echo ""
                TRIGGERED=$((TRIGGERED + 1))
            fi
        fi
    fi
fi

# --- 8. Burnout Signals ---
GIT_DIR="$PROJECT_DIR"
if git -C "$GIT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    CONSECUTIVE_HIGH=0
    for i in 0 1 2 3 4; do
        DAY_DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null || echo "")
        [[ -z "$DAY_DATE" ]] && continue
        COMMITS=$(git -C "$GIT_DIR" log --oneline --after="$DAY_DATE 00:00" --before="$DAY_DATE 23:59" 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$COMMITS" -gt 15 ]]; then
            CONSECUTIVE_HIGH=$((CONSECUTIVE_HIGH + 1))
        else
            break
        fi
    done
    if [[ "$CONSECUTIVE_HIGH" -ge 3 ]]; then
        echo "WARNING: Burnout Signals ($CONSECUTIVE_HIGH consecutive high-commit days)"
        echo "  intervention: Check if the work is moving the score."
        echo ""
        TRIGGERED=$((TRIGGERED + 1))
    fi
fi

# --- Summary ---
if [[ "$TRIGGERED" -eq 0 ]]; then
    echo "  no patterns triggered"
fi
echo ""
echo "triggered: $TRIGGERED"
echo "=== CHECK COMPLETE ==="
