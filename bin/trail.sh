#!/usr/bin/env bash
set -euo pipefail

# trail.sh — Render the evidence trail from multiple sources.
# Primary: .claude/sessions/*.yml (rich /go session data)
# Fallback: git log (activity), predictions.tsv (learning), eval-cache (scores)
# Session files are a bonus, not a requirement.

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
SESSIONS_DIR="$PROJECT_DIR/.claude/sessions"

# Colors
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_CYAN='\033[0;36m'
C_NC='\033[0m'

HAS_SESSIONS=false
if [[ -d "$SESSIONS_DIR" ]] && ls "$SESSIONS_DIR"/*.yml >/dev/null 2>&1; then
    HAS_SESSIONS=true
fi

# --- Aggregate session data (when available) ---
TOTAL_SESSIONS=0
TOTAL_MOVES=0
TOTAL_KEPT=0
TOTAL_REVERTED=0
SCORES=""
ACCURACIES=""
LEARNINGS=""

if $HAS_SESSIONS; then
    for session in "$SESSIONS_DIR"/*.yml; do
        [[ ! -f "$session" ]] && continue
        TOTAL_SESSIONS=$((TOTAL_SESSIONS + 1))

        # Parse simple YAML fields (top-level only, no nesting)
        moves=$(grep -m1 '^moves:' "$session" 2>/dev/null | sed 's/^moves:[[:space:]]*//' || echo "0")
        kept=$(grep -m1 '^kept:' "$session" 2>/dev/null | sed 's/^kept:[[:space:]]*//' || echo "0")
        reverted=$(grep -m1 '^reverted:' "$session" 2>/dev/null | sed 's/^reverted:[[:space:]]*//' || echo "0")
        score_after=$(grep -m1 '^score_after:' "$session" 2>/dev/null | sed 's/^score_after:[[:space:]]*//' || echo "")

        [[ "$moves" =~ ^[0-9]+$ ]] && TOTAL_MOVES=$((TOTAL_MOVES + moves))
        [[ "$kept" =~ ^[0-9]+$ ]] && TOTAL_KEPT=$((TOTAL_KEPT + kept))
        [[ "$reverted" =~ ^[0-9]+$ ]] && TOTAL_REVERTED=$((TOTAL_REVERTED + reverted))
        [[ -n "$score_after" && "$score_after" =~ ^[0-9]+$ ]] && SCORES="${SCORES:+$SCORES }$score_after"

        # Collect prediction accuracy per session (tr -d space fixes grep -c + pipefail)
        pred_correct=$(grep -c 'correct: yes' "$session" 2>/dev/null | tr -d '[:space:]' || echo "0")
        [[ -z "$pred_correct" ]] && pred_correct=0
        pred_partial=$(grep -c 'correct: partial' "$session" 2>/dev/null | tr -d '[:space:]' || echo "0")
        [[ -z "$pred_partial" ]] && pred_partial=0
        pred_total=$(grep -c 'correct:' "$session" 2>/dev/null | tr -d '[:space:]' || echo "0")
        [[ -z "$pred_total" ]] && pred_total=0
        if [[ "$pred_total" -gt 0 ]]; then
            effective=$(awk "BEGIN { printf \"%d\", $pred_correct + $pred_partial * 0.5 }")
            acc=$((effective * 100 / pred_total))
            ACCURACIES="${ACCURACIES:+$ACCURACIES }${acc}%"
        fi

        # Collect learnings
        in_learnings=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^learnings: ]]; then
                in_learnings=true
                continue
            fi
            if $in_learnings; then
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                    learning=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
                    LEARNINGS="${LEARNINGS}${learning}\n"
                else
                    in_learnings=false
                fi
            fi
        done < "$session"
    done
fi

# --- Fallback: derive activity from git log when no sessions ---
GIT_ACTIVITY=""
if ! $HAS_SESSIONS; then
    if cd "$PROJECT_DIR" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
        COMMIT_COUNT=$(git log --oneline --since="30 days ago" 2>/dev/null | wc -l | tr -d ' ')
        DAYS_ACTIVE=$(git log --format='%cd' --date=short --since="30 days ago" 2>/dev/null | sort -u | wc -l | tr -d ' ')
        LAST_COMMIT=$(git log -1 --format='%cd' --date=relative 2>/dev/null || echo "unknown")
        GIT_ACTIVITY="${COMMIT_COUNT} commits across ${DAYS_ACTIVE} days (last: ${LAST_COMMIT})"
    fi
fi

# --- Fallback: score trajectory from history.tsv ---
if [[ -z "$SCORES" ]]; then
    HISTORY_FILE="$PROJECT_DIR/.claude/scores/history.tsv"
    if [[ -f "$HISTORY_FILE" ]]; then
        # Extract up to 8 score snapshots (min of build, structure, hygiene) spaced across history
        TOTAL_ROWS=$(tail -n +2 "$HISTORY_FILE" | wc -l | tr -d ' ')
        if [[ "$TOTAL_ROWS" -gt 0 ]]; then
            STEP=$(( TOTAL_ROWS / 8 ))
            [[ "$STEP" -lt 1 ]] && STEP=1
            SCORES=$(tail -n +2 "$HISTORY_FILE" | awk -F'\t' -v step="$STEP" '
                NR % step == 0 || NR == 1 {
                    s = $2 + 0
                    if ($3+0 < s) s = $3 + 0
                    # hygiene is $6 for 7-col format, $5 for 6-col
                    h = (NF >= 7) ? $6 + 0 : $5 + 0
                    if (h > 0 && h < s) s = h
                    printf "%d ", s
                }
            ')
            # Always include the last row
            LAST_SCORE=$(tail -1 "$HISTORY_FILE" | awk -F'\t' '{
                s = $2 + 0
                if ($3+0 < s) s = $3 + 0
                h = (NF >= 7) ? $6 + 0 : $5 + 0
                if (h > 0 && h < s) s = h
                printf "%d", s
            }')
            SCORES="${SCORES}${LAST_SCORE}"
        fi
    fi
fi

# --- Fallback: score from eval-cache ---
if [[ -z "$SCORES" ]]; then
    EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
    if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
        CURRENT_SCORE=$(jq -r '.score // empty' "$EVAL_CACHE" 2>/dev/null)
        [[ -n "$CURRENT_SCORE" ]] && SCORES="$CURRENT_SCORE"
    fi
fi

# --- Keep rate ---
DECIDABLE=$((TOTAL_KEPT + TOTAL_REVERTED))
KEEP_RATE=""
if [[ "$DECIDABLE" -gt 0 ]]; then
    KEEP_RATE="$((TOTAL_KEPT * 100 / DECIDABLE))%"
fi

# --- Output ---
echo ""
if $HAS_SESSIONS; then
    echo -e "  ${C_CYAN}◆${C_NC} ${C_BOLD}trail${C_NC} — ${TOTAL_SESSIONS} sessions, ${TOTAL_MOVES} moves${KEEP_RATE:+, ${KEEP_RATE} kept}"
elif [[ -n "$GIT_ACTIVITY" ]]; then
    echo -e "  ${C_CYAN}◆${C_NC} ${C_BOLD}trail${C_NC} — ${GIT_ACTIVITY}"
else
    echo -e "  ${C_CYAN}◆${C_NC} ${C_BOLD}trail${C_NC}"
fi
echo ""

# Score trajectory (cap to last 20 data points)
if [[ -n "$SCORES" ]]; then
    # Convert to array and truncate if needed
    SCORE_ARR=($SCORES)
    SCORE_COUNT=${#SCORE_ARR[@]}
    MAX_POINTS=20
    TRUNCATED=false
    if [[ "$SCORE_COUNT" -gt "$MAX_POINTS" ]]; then
        SCORE_ARR=("${SCORE_ARR[@]: -$MAX_POINTS}")
        TRUNCATED=true
    fi

    SCORE_LINE="  ${C_DIM}score${C_NC}     "
    if $TRUNCATED; then
        SCORE_LINE="${SCORE_LINE}${C_DIM}...${C_NC} "
    fi
    FIRST=true
    for s in "${SCORE_ARR[@]}"; do
        if $FIRST; then
            SCORE_LINE="${SCORE_LINE}${s}"
            FIRST=false
        else
            SCORE_LINE="${SCORE_LINE} ${C_DIM}───${C_NC} ${s}"
        fi
    done
    echo -e "$SCORE_LINE"
fi

# Prediction accuracy trajectory
if [[ -n "$ACCURACIES" ]]; then
    ACC_LINE="  ${C_DIM}accuracy${C_NC}  "
    FIRST=true
    for a in $ACCURACIES; do
        if $FIRST; then
            ACC_LINE="${ACC_LINE}${a}"
            FIRST=false
        else
            ACC_LINE="${ACC_LINE}  ${a}"
        fi
    done
    echo -e "$ACC_LINE"
fi

echo ""

# Top learnings (last 5, deduplicated) — from sessions or model_update column in predictions.tsv
# Extracts causal mechanisms (X→Y because Z) from model_update text
if [[ -z "$LEARNINGS" ]]; then
    PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
    # Only fall back to global predictions if running from within founder-os itself
    if [[ ! -f "$PRED_FILE" ]]; then
        if [[ -f "$PROJECT_DIR/config/founder.yml" ]]; then
            PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
        else
            PRED_FILE=""
        fi
    fi
    if [[ -n "$PRED_FILE" && -f "$PRED_FILE" ]]; then
        # Extract non-empty model_update entries (column 7) from graded predictions
        # Then distill to causal mechanism: find sentences with →, because, discovered, confirmed, etc.
        LEARNINGS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$7 != "" && $6 != "" { print $7 }' | tail -10 | sort -u | tail -5 | while IFS= read -r l; do
            [[ -z "$l" ]] && continue
            # Try to extract a mechanism sentence (contains causal markers)
            mechanism=""
            # First priority: sentences with → (explicit causal notation)
            mechanism=$(echo "$l" | sed 's/\. /\n/g' | grep -m1 '→' 2>/dev/null || true)
            # Second: sentences with "because" or "since"
            if [[ -z "$mechanism" ]]; then
                mechanism=$(echo "$l" | sed 's/\. /\n/g' | grep -im1 'because\|since\|causes\|leads to' 2>/dev/null || true)
            fi
            # Third: sentences with "discovered", "confirmed", "proved", "validated"
            if [[ -z "$mechanism" ]]; then
                mechanism=$(echo "$l" | sed 's/\. /\n/g' | grep -im1 'discover\|confirm\|prove\|validat\|must be\|always\|never' 2>/dev/null || true)
            fi
            # Fallback: first sentence only (not the whole blob)
            if [[ -z "$mechanism" ]]; then
                mechanism=$(echo "$l" | sed 's/\. .*/\./')
            fi
            # Trim whitespace
            mechanism=$(echo "$mechanism" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            echo "${mechanism}\n"
        done)
    fi
fi

if [[ -n "$LEARNINGS" ]]; then
    echo -e "  ${C_DIM}▾ mechanisms learned${C_NC}"
    echo -e "$LEARNINGS" | grep -v '^$' | sort -u | tail -5 | while IFS= read -r l; do
        [[ -n "$l" ]] && echo -e "    ${C_DIM}·${C_NC} ${l}"
    done
    echo ""
fi

# --- Prediction vs outcome: show what changed (last 3 graded predictions) ---
if [[ -z "${PRED_FILE:-}" ]]; then
    PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
    if [[ ! -f "$PRED_FILE" && -f "$PROJECT_DIR/config/founder.yml" ]]; then
        PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
    elif [[ ! -f "$PRED_FILE" ]]; then
        PRED_FILE=""
    fi
fi

if [[ -n "$PRED_FILE" && -f "$PRED_FILE" ]]; then
    # Show last 3 graded predictions with predicted vs actual
    DIFFS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$5 != "" && $6 != "" {
        pred = $3
        result = $5
        grade = $6
        # Truncate prediction to first clause
        gsub(/[—,].*/, "", pred)
        # Truncate result to first clause
        gsub(/[—,].*/, "", result)
        # Trim to 55 chars
        if (length(pred) > 55) pred = substr(pred, 1, 52) "..."
        if (length(result) > 55) result = substr(result, 1, 52) "..."
        # Symbol by grade
        sym = "·"
        if (grade == "yes") sym = "✓"
        else if (grade == "no") sym = "✗"
        else if (grade == "partial") sym = "◐"
        printf "%s|%s|%s\n", sym, pred, result
    }' | tail -3)

    if [[ -n "$DIFFS" ]]; then
        echo -e "  ${C_DIM}▾ predicted vs actual${C_NC}"
        while IFS='|' read -r sym pred result; do
            [[ -z "$sym" ]] && continue
            case "$sym" in
                "✓") color="$C_GREEN" ;;
                "✗") color="$C_RED" ;;
                "◐") color="$C_YELLOW" ;;
                *) color="$C_DIM" ;;
            esac
            echo -e "    ${color}${sym}${C_NC} ${C_DIM}predicted:${C_NC} ${pred}"
            echo -e "      ${C_DIM}actual:${C_NC}    ${result}"
        done <<< "$DIFFS"
        echo ""
    fi
fi

# --- Knowledge model growth ---
LEARNINGS_FILE="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
if [[ ! -f "$LEARNINGS_FILE" && -f "$PROJECT_DIR/config/founder.yml" ]]; then
    LEARNINGS_FILE="$HOME/.claude/knowledge/experiment-learnings.md"
elif [[ ! -f "$LEARNINGS_FILE" ]]; then
    LEARNINGS_FILE=""
fi

if [[ -n "$LEARNINGS_FILE" && -f "$LEARNINGS_FILE" ]]; then
    KNOWN_CT=$(awk '/^## Known Patterns/,/^## /' "$LEARNINGS_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
    [[ -z "$KNOWN_CT" || ! "$KNOWN_CT" =~ ^[0-9]+$ ]] && KNOWN_CT=0
    UNCERTAIN_CT=$(awk '/^## Uncertain Patterns/,/^## /' "$LEARNINGS_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
    [[ -z "$UNCERTAIN_CT" || ! "$UNCERTAIN_CT" =~ ^[0-9]+$ ]] && UNCERTAIN_CT=0
    UNKNOWN_CT=$(awk '/^## Unknown Territory/,/^## /' "$LEARNINGS_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
    [[ -z "$UNKNOWN_CT" || ! "$UNKNOWN_CT" =~ ^[0-9]+$ ]] && UNKNOWN_CT=0
    DEAD_CT=$(awk '/^## Dead Ends/,/^## /' "$LEARNINGS_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
    [[ -z "$DEAD_CT" || ! "$DEAD_CT" =~ ^[0-9]+$ ]] && DEAD_CT=0

    echo -e "  ${C_DIM}▾ knowledge model${C_NC}"
    echo -e "    ${C_GREEN}known${C_NC} ${KNOWN_CT}  ${C_YELLOW}uncertain${C_NC} ${UNCERTAIN_CT}  ${C_DIM}unknown${C_NC} ${UNKNOWN_CT}  ${C_RED}dead ends${C_NC} ${DEAD_CT}"
    echo ""
fi

# --- Prediction accuracy trend across sessions ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
# Only fall back to global if this is a founder-managed project
if [[ ! -f "$PRED_FILE" && -f "$PROJECT_DIR/config/founder.yml" ]]; then
    PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
elif [[ ! -f "$PRED_FILE" ]]; then
    PRED_FILE=""
fi

if [[ -n "$PRED_FILE" && -f "$PRED_FILE" ]]; then
    # Exclude "prefilled" and "needs_target" and "expired" from accuracy — only real grades count
    GRADED_ALL=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 != "" && $6 != "prefilled" && $6 != "needs_target" && $6 != "expired"' 2>/dev/null)
    GRADED_TOTAL=$(echo "$GRADED_ALL" | grep -c '.' 2>/dev/null || echo "0")
    if [[ "$GRADED_TOTAL" -ge 3 ]]; then
        CORRECT_CT=$(echo "$GRADED_ALL" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
        PARTIAL_CT=$(echo "$GRADED_ALL" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
        EFFECTIVE=$(awk "BEGIN { printf \"%d\", ($CORRECT_CT + $PARTIAL_CT * 0.5) * 100 / $GRADED_TOTAL }")
        echo -e "  ${C_DIM}▾ prediction accuracy${C_NC}"
        echo -e "    ${C_BOLD}${EFFECTIVE}%${C_NC} overall (${GRADED_TOTAL} graded)  ${C_DIM}·${C_NC}  ${CORRECT_CT} correct, ${PARTIAL_CT} partial"

        # Show trend: compare last 10 predictions vs overall, plus trajectory arrow
        if [[ "$GRADED_TOTAL" -ge 6 ]]; then
            # Recent window: last 10 graded (or all if <10)
            RECENT_WINDOW=10
            if [[ "$GRADED_TOTAL" -lt "$RECENT_WINDOW" ]]; then
                RECENT_WINDOW="$GRADED_TOTAL"
            fi
            RECENT_CORRECT=$(echo "$GRADED_ALL" | tail -"$RECENT_WINDOW" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
            RECENT_PARTIAL=$(echo "$GRADED_ALL" | tail -"$RECENT_WINDOW" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
            RECENT_EFF=$(awk "BEGIN { printf \"%d\", ($RECENT_CORRECT + $RECENT_PARTIAL * 0.5) * 100 / $RECENT_WINDOW }")

            # Earlier window: everything before the last 10
            EARLIER_CT=$((GRADED_TOTAL - RECENT_WINDOW))
            if [[ "$EARLIER_CT" -gt 0 ]]; then
                EARLIER_CORRECT=$(echo "$GRADED_ALL" | head -"$EARLIER_CT" | awk -F'\t' '$6 == "yes" { c++ } END { print c+0 }')
                EARLIER_PARTIAL=$(echo "$GRADED_ALL" | head -"$EARLIER_CT" | awk -F'\t' '$6 == "partial" { c++ } END { print c+0 }')
                EARLIER_EFF=$(awk "BEGIN { printf \"%d\", ($EARLIER_CORRECT + $EARLIER_PARTIAL * 0.5) * 100 / $EARLIER_CT }")

                DELTA=$((RECENT_EFF - EARLIER_EFF))
                if [[ "$DELTA" -gt 5 ]]; then
                    echo -e "    ${C_GREEN}↑${C_NC} ${C_BOLD}${EFFECTIVE}%${C_NC} ${C_DIM}(last ${RECENT_WINDOW}: ${RECENT_EFF}%, prior: ${EARLIER_EFF}%)${C_NC}"
                elif [[ "$DELTA" -lt -5 ]]; then
                    echo -e "    ${C_RED}↓${C_NC} ${C_BOLD}${EFFECTIVE}%${C_NC} ${C_DIM}(last ${RECENT_WINDOW}: ${RECENT_EFF}%, prior: ${EARLIER_EFF}%)${C_NC}"
                else
                    echo -e "    ${C_DIM}→${C_NC} ${C_BOLD}${EFFECTIVE}%${C_NC} ${C_DIM}(stable — last ${RECENT_WINDOW}: ${RECENT_EFF}%, prior: ${EARLIER_EFF}%)${C_NC}"
                fi
                # Set for next-action logic
                LATE_EFF="$RECENT_EFF"
                EARLY_EFF="$EARLIER_EFF"
            else
                echo -e "    ${C_DIM}→${C_NC} ${C_BOLD}${EFFECTIVE}%${C_NC} ${C_DIM}(${RECENT_WINDOW} predictions — need more for trend)${C_NC}"
            fi
        fi

        # Actionable recommendation based on accuracy data
        if [[ "$EFFECTIVE" -lt 50 ]]; then
            echo -e "    ${C_YELLOW}▸${C_NC} Model needs calibration — run /retro to diagnose"
        elif [[ "$EFFECTIVE" -gt 80 ]]; then
            echo -e "    ${C_YELLOW}▸${C_NC} Predictions may be too safe — explore Unknown Territory"
        fi
        # Check for recent decline: last-10 accuracy >10 points below overall
        if [[ -n "${LATE_EFF:-}" && "$LATE_EFF" -lt $((EFFECTIVE - 10)) ]]; then
            echo -e "    ${C_YELLOW}▸${C_NC} Recent accuracy declining — run /retro stale"
        fi

        echo ""
    fi
fi

# --- Next action suggestion ---
_trail_declining=false
_trail_empty_model=false

# Check if accuracy is declining (reuse LATE_EFF/EARLY_EFF if set)
if [[ -n "${LATE_EFF:-}" && -n "${EARLY_EFF:-}" && "$LATE_EFF" -lt "$EARLY_EFF" ]]; then
    _trail_declining=true
fi

# Check if knowledge model is empty
if [[ "${KNOWN_CT:-0}" -eq 0 && "${UNCERTAIN_CT:-0}" -eq 0 ]]; then
    _trail_empty_model=true
fi

if $_trail_declining; then
    echo -e "  ${C_GREEN}▸${C_NC} ${C_DIM}/retro to review and recalibrate${C_NC}"
elif $_trail_empty_model; then
    echo -e "  ${C_GREEN}▸${C_NC} ${C_DIM}predictions need grading — run /retro${C_NC}"
else
    echo -e "  ${C_GREEN}▸${C_NC} ${C_DIM}/plan to pick the next move${C_NC}"
fi
echo ""
