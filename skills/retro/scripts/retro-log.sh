#!/usr/bin/env bash
# Persistent retro session log
# Usage:
#   bash scripts/retro-log.sh add "graded 3, pruned 1, accuracy 63%"
#   bash scripts/retro-log.sh list [count]
#   bash scripts/retro-log.sh stats
#   bash scripts/retro-log.sh last
#
# Stores in ${CLAUDE_PLUGIN_DATA}/retro-log.tsv for cross-session persistence.
# Falls back to .claude/cache/retro-log.tsv if no plugin data dir.
set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-.claude/cache}"
mkdir -p "$DATA_DIR"
LOG_FILE="$DATA_DIR/retro-log.tsv"

# Init if missing
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "date\troute\tgraded\tpruned\taccuracy\tmodel_updates\tnotes" > "$LOG_FILE"
fi

ACTION="${1:-list}"
shift || true

case "$ACTION" in
    add)
        # Args: route graded pruned accuracy model_updates "notes"
        ROUTE="${1:-full}"
        GRADED="${2:-0}"
        PRUNED="${3:-0}"
        ACCURACY="${4:-?}"
        MODEL_UPDATES="${5:-0}"
        NOTES="${6:-}"
        DATE=$(date +%Y-%m-%d)
        echo -e "$DATE\t$ROUTE\t$GRADED\t$PRUNED\t$ACCURACY\t$MODEL_UPDATES\t$NOTES" >> "$LOG_FILE"
        echo "logged: $DATE $ROUTE (graded:$GRADED pruned:$PRUNED acc:$ACCURACY)"
        ;;

    list)
        COUNT="${1:-10}"
        echo "── retro sessions (last $COUNT) ──"
        echo ""
        tail -n +2 "$LOG_FILE" | tail -"$COUNT" | awk -F'\t' '{
            printf "  %s  %-10s  graded:%-3s pruned:%-3s acc:%-4s updates:%-3s %s\n", $1, $2, $3, $4, $5, $6, $7
        }'
        TOTAL=$(tail -n +2 "$LOG_FILE" | wc -l | tr -d ' ')
        echo ""
        echo "  total retro sessions: $TOTAL"
        ;;

    stats)
        echo "── retro frequency ──"
        TOTAL=$(tail -n +2 "$LOG_FILE" | wc -l | tr -d ' ')
        echo "  total sessions: $TOTAL"

        if [[ "$TOTAL" -gt 0 ]]; then
            # Last retro date
            LAST=$(tail -1 "$LOG_FILE" | awk -F'\t' '{print $1}')
            echo "  last retro: $LAST"

            # Average graded per session
            AVG_GRADED=$(tail -n +2 "$LOG_FILE" | awk -F'\t' '{ s += $3; c++ } END { if(c>0) printf "%.1f", s/c; else print 0 }')
            echo "  avg graded/session: $AVG_GRADED"

            # Average accuracy
            AVG_ACC=$(tail -n +2 "$LOG_FILE" | awk -F'\t' '$5 != "?" { s += $5; c++ } END { if(c>0) printf "%.0f%%", s/c; else print "?" }')
            echo "  avg accuracy: $AVG_ACC"

            # Sessions per week (last 4 weeks)
            for WEEKS_AGO in 0 1 2 3; do
                SINCE=$(date -v-$((WEEKS_AGO + 1))w +%Y-%m-%d 2>/dev/null || date -d "$((WEEKS_AGO + 1)) weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
                UNTIL=$(date -v-${WEEKS_AGO}w +%Y-%m-%d 2>/dev/null || date -d "$WEEKS_AGO weeks ago" +%Y-%m-%d 2>/dev/null || echo "")
                if [[ -n "$SINCE" && -n "$UNTIL" ]]; then
                    COUNT=$(tail -n +2 "$LOG_FILE" | awk -F'\t' -v s="$SINCE" -v u="$UNTIL" '$1 >= s && $1 < u { c++ } END { print c+0 }')
                    if [[ "$WEEKS_AGO" -eq 0 ]]; then
                        LABEL="this week"
                    else
                        LABEL="${WEEKS_AGO}w ago"
                    fi
                    echo "  $LABEL: $COUNT sessions"
                fi
            done
        fi
        ;;

    last)
        echo "── last retro ──"
        tail -1 "$LOG_FILE" | awk -F'\t' '{
            printf "  date: %s\n  route: %s\n  graded: %s\n  pruned: %s\n  accuracy: %s\n  model_updates: %s\n  notes: %s\n", $1, $2, $3, $4, $5, $6, $7
        }'
        ;;

    *)
        echo "usage: retro-log.sh [add|list|stats|last]"
        exit 1
        ;;
esac
