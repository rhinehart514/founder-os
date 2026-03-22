#!/usr/bin/env bash
# build-log.sh — Persistent build session log across conversations.
# Uses CLAUDE_PLUGIN_DATA for cross-session persistence.
# Usage:
#   bash scripts/build-log.sh add <json-data>   — append a session entry
#   bash scripts/build-log.sh list [N]           — show last N sessions (default 5)
#   bash scripts/build-log.sh stats              — session statistics
#   bash scripts/build-log.sh streak             — current keep/revert streak
set -euo pipefail

COMMAND="${1:-list}"
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/data/go}"
LOG_FILE="$DATA_DIR/build-sessions.jsonl"

mkdir -p "$DATA_DIR"
touch "$LOG_FILE"

case "$COMMAND" in
    add)
        shift
        # Expects JSON on stdin or as argument
        if [[ $# -gt 0 ]]; then
            INPUT="$*"
        else
            INPUT=$(cat)
        fi
        # Add timestamp if not present
        if echo "$INPUT" | jq -e '.timestamp' &>/dev/null; then
            echo "$INPUT" >> "$LOG_FILE"
        else
            echo "$INPUT" | jq -c ". + {timestamp: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG_FILE" 2>/dev/null || echo "$INPUT" >> "$LOG_FILE"
        fi
        echo "session logged to $LOG_FILE"
        ;;

    list)
        N="${2:-5}"
        TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
        if [[ "$TOTAL" -eq 0 ]]; then
            echo "no build sessions recorded yet"
            exit 0
        fi
        echo "=== LAST $N BUILD SESSIONS (of $TOTAL total) ==="
        tail -n "$N" "$LOG_FILE" | while IFS= read -r line; do
            if command -v jq &>/dev/null; then
                TS=$(echo "$line" | jq -r '.timestamp // "?"')
                SCOPE=$(echo "$line" | jq -r '.scope // "?"')
                MOVES=$(echo "$line" | jq -r '.moves // "?"')
                KEPT=$(echo "$line" | jq -r '.kept // "?"')
                REVERTED=$(echo "$line" | jq -r '.reverted // "?"')
                SCORE_B=$(echo "$line" | jq -r '.score_before // "?"')
                SCORE_A=$(echo "$line" | jq -r '.score_after // "?"')
                PRED_ACC=$(echo "$line" | jq -r '.prediction_accuracy // "?"')
                echo "  $TS | $SCOPE | moves:$MOVES kept:$KEPT rev:$REVERTED | score:$SCORE_B->$SCORE_A | pred:$PRED_ACC"
            else
                echo "  $line"
            fi
        done
        echo ""
        ;;

    stats)
        TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
        if [[ "$TOTAL" -eq 0 ]]; then
            echo "no sessions recorded"
            exit 0
        fi
        echo "=== BUILD SESSION STATS ==="
        echo "total sessions: $TOTAL"
        if command -v jq &>/dev/null; then
            # Aggregate stats
            TOTAL_MOVES=$(jq -s '[.[].moves // 0] | add' "$LOG_FILE" 2>/dev/null || echo "?")
            TOTAL_KEPT=$(jq -s '[.[].kept // 0] | add' "$LOG_FILE" 2>/dev/null || echo "?")
            TOTAL_REVERTED=$(jq -s '[.[].reverted // 0] | add' "$LOG_FILE" 2>/dev/null || echo "?")
            echo "total moves: $TOTAL_MOVES (kept: $TOTAL_KEPT, reverted: $TOTAL_REVERTED)"
            if [[ "$TOTAL_MOVES" != "?" && "$TOTAL_MOVES" -gt 0 ]]; then
                KEEP_RATE=$((TOTAL_KEPT * 100 / TOTAL_MOVES))
                echo "keep rate: ${KEEP_RATE}%"
            fi
            # Average score delta
            AVG_DELTA=$(jq -s '[.[] | select(.score_before != null and .score_after != null) | (.score_after - .score_before)] | if length > 0 then (add / length | floor) else 0 end' "$LOG_FILE" 2>/dev/null || echo "?")
            echo "avg score delta per session: $AVG_DELTA"
        fi
        echo ""
        ;;

    streak)
        if [[ ! -s "$LOG_FILE" ]]; then
            echo "no sessions recorded"
            exit 0
        fi
        # Count consecutive sessions with positive delta
        echo "=== CURRENT STREAK ==="
        STREAK=0
        STREAK_TYPE=""
        tac "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            DELTA=$(echo "$line" | jq -r '(.score_after // 0) - (.score_before // 0)' 2>/dev/null || echo "0")
            if [[ "$STREAK_TYPE" == "" ]]; then
                if [[ "$DELTA" -gt 0 ]]; then
                    STREAK_TYPE="improving"
                elif [[ "$DELTA" -eq 0 ]]; then
                    STREAK_TYPE="flat"
                else
                    STREAK_TYPE="declining"
                fi
                STREAK=1
            elif [[ "$STREAK_TYPE" == "improving" && "$DELTA" -gt 0 ]]; then
                STREAK=$((STREAK + 1))
            elif [[ "$STREAK_TYPE" == "flat" && "$DELTA" -eq 0 ]]; then
                STREAK=$((STREAK + 1))
            elif [[ "$STREAK_TYPE" == "declining" && "$DELTA" -lt 0 ]]; then
                STREAK=$((STREAK + 1))
            else
                break
            fi
            echo "$STREAK_TYPE streak: $STREAK sessions"
        done | tail -1
        echo ""
        ;;

    *)
        echo "Usage: build-log.sh {add|list|stats|streak} [args]"
        exit 1
        ;;
esac
