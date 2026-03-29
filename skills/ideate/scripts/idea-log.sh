#!/usr/bin/env bash
# idea-log.sh — Append an idea to the persistent ideation log.
# Usage: idea-log.sh <action> [args]
#   idea-log.sh add "idea name" "evidence" "status"
#   idea-log.sh kill "idea name" "reason"
#   idea-log.sh list
#   idea-log.sh stats
set -euo pipefail

LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/data/founder-os}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ideation-log.jsonl"

ACTION="${1:-list}"
shift || true

case "$ACTION" in
    add)
        NAME="${1:-unnamed}"
        EVIDENCE="${2:-none}"
        STATUS="${3:-proposed}"
        DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        if command -v jq &>/dev/null; then
            jq -n --arg date "$DATE" --arg action "add" --arg name "$NAME" --arg evidence "$EVIDENCE" --arg status "$STATUS" \
                '{date:$date,action:$action,name:$name,evidence:$evidence,status:$status}' >> "$LOG_FILE"
        else
            echo "{\"date\":\"$DATE\",\"action\":\"add\",\"name\":\"$NAME\",\"evidence\":\"$EVIDENCE\",\"status\":\"$STATUS\"}" >> "$LOG_FILE"
        fi
        echo "Logged: $NAME ($STATUS)"
        ;;
    kill)
        NAME="${1:-unnamed}"
        REASON="${2:-no reason}"
        DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        if command -v jq &>/dev/null; then
            jq -n --arg date "$DATE" --arg action "kill" --arg name "$NAME" --arg reason "$REASON" \
                '{date:$date,action:$action,name:$name,reason:$reason}' >> "$LOG_FILE"
        else
            echo "{\"date\":\"$DATE\",\"action\":\"kill\",\"name\":\"$NAME\",\"reason\":\"$REASON\"}" >> "$LOG_FILE"
        fi
        echo "Killed: $NAME — $REASON"
        ;;
    commit)
        NAME="${1:-unnamed}"
        DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        if command -v jq &>/dev/null; then
            jq -n --arg date "$DATE" --arg action "commit" --arg name "$NAME" \
                '{date:$date,action:$action,name:$name}' >> "$LOG_FILE"
        else
            echo "{\"date\":\"$DATE\",\"action\":\"commit\",\"name\":\"$NAME\"}" >> "$LOG_FILE"
        fi
        echo "Committed: $NAME"
        ;;
    list)
        if [[ -f "$LOG_FILE" ]]; then
            echo "=== IDEATION HISTORY ==="
            tail -20 "$LOG_FILE" | while IFS= read -r line; do
                DATE=$(echo "$line" | sed -n 's/.*"date":"\([^"]*\)".*/\1/p' | cut -d'T' -f1)
                ACTION=$(echo "$line" | sed -n 's/.*"action":"\([^"]*\)".*/\1/p')
                NAME=$(echo "$line" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
                case "$ACTION" in
                    add) echo "  + $DATE $NAME" ;;
                    kill) echo "  x $DATE $NAME" ;;
                    commit) echo "  > $DATE $NAME" ;;
                esac
            done
        else
            echo "No ideation history yet."
        fi
        ;;
    stats)
        if [[ -f "$LOG_FILE" ]]; then
            TOTAL=$(grep -c '"add"' "$LOG_FILE" 2>/dev/null || echo 0)
            KILLED=$(grep -c '"kill"' "$LOG_FILE" 2>/dev/null || echo 0)
            COMMITTED=$(grep -c '"commit"' "$LOG_FILE" 2>/dev/null || echo 0)
            echo "Ideas proposed: $TOTAL"
            echo "Ideas killed: $KILLED"
            echo "Ideas committed: $COMMITTED"
            if [[ "$TOTAL" -gt 0 ]]; then
                KILL_RATE=$(( KILLED * 100 / TOTAL ))
                COMMIT_RATE=$(( COMMITTED * 100 / TOTAL ))
                echo "Kill rate: ${KILL_RATE}%"
                echo "Commit rate: ${COMMIT_RATE}%"
            fi
        else
            echo "No ideation history yet."
        fi
        ;;
esac
