#!/usr/bin/env bash
# Persistent research history log
# Uses CLAUDE_PLUGIN_DATA for cross-session persistence.
# Usage:
#   bash scripts/research-log.sh                  — show recent sessions
#   bash scripts/research-log.sh topic "auth"     — filter by topic
#   bash scripts/research-log.sh add "topic" "route" "findings_count" "key_finding"
#   bash scripts/research-log.sh stats            — show research patterns
#   bash scripts/research-log.sh repeats          — find over-researched topics
set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/data/research}"
mkdir -p "$DATA_DIR"
LOG="$DATA_DIR/research-log.json"

# Initialize if missing
if [[ ! -f "$LOG" ]]; then
    echo '{"sessions":[],"self_assessment":null}' > "$LOG"
fi

CMD="${1:-list}"

case "$CMD" in
    list)
        if ! command -v jq &>/dev/null; then
            echo "jq required"; exit 1
        fi
        TOTAL=$(jq '.sessions | length' "$LOG")
        echo "── research log ── ($TOTAL sessions)"
        echo ""
        jq -r '.sessions[-10:][] | "  \(.date // "?")  \(.topic // "?") (\(.route // "?"))\n          findings: \(.findings_count // 0) · key: \(.key_finding // "none")\n          confidence: \(.confidence // "unknown")"' "$LOG" 2>/dev/null || echo "  empty"
        ;;
    topic)
        QUERY="${2:-}"
        [[ -z "$QUERY" ]] && { echo "usage: research-log.sh topic <query>"; exit 1; }
        jq -r --arg q "$QUERY" '
            .sessions[]
            | select(.topic | ascii_downcase | contains($q | ascii_downcase))
            | "  \(.date) · \(.topic) (\(.route))\n    key: \(.key_finding // "none")\n    confidence: \(.confidence // "unknown")"
        ' "$LOG" 2>/dev/null || echo "  no matches"
        ;;
    add)
        TOPIC="${2:-}"
        ROUTE="${3:-free-form}"
        COUNT="${4:-0}"
        KEY="${5:-}"
        CONFIDENCE="${6:-medium}"
        [[ -z "$TOPIC" ]] && { echo "usage: research-log.sh add <topic> [route] [findings_count] [key_finding] [confidence]"; exit 1; }
        DATE=$(date +%Y-%m-%d)
        jq --arg d "$DATE" --arg t "$TOPIC" --arg r "$ROUTE" --argjson c "$COUNT" --arg k "$KEY" --arg conf "$CONFIDENCE" \
            '.sessions += [{"date":$d,"topic":$t,"route":$r,"findings_count":$c,"key_finding":$k,"confidence":$conf,"acted_on":false}]' \
            "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
        echo "  logged: $TOPIC ($ROUTE) — $COUNT findings"
        ;;
    stats)
        if ! command -v jq &>/dev/null; then
            echo "jq required"; exit 1
        fi
        TOTAL=$(jq '.sessions | length' "$LOG")
        echo "── research stats ──"
        echo "  total sessions: $TOTAL"
        echo ""
        echo "  by route:"
        jq -r '.sessions | group_by(.route) | .[] | "    \(.[0].route // "?"): \(length) sessions, avg \([.[].findings_count] | add / length | floor) findings"' "$LOG" 2>/dev/null || true
        echo ""
        echo "  by confidence:"
        jq -r '.sessions | group_by(.confidence) | .[] | "    \(.[0].confidence // "?"): \(length)"' "$LOG" 2>/dev/null || true
        echo ""
        ACTED=$(jq '[.sessions[] | select(.acted_on == true)] | length' "$LOG" 2>/dev/null || echo "0")
        echo "  research→action rate: $ACTED / $TOTAL"
        ;;
    repeats)
        echo "── repeated topics ──"
        jq -r '
            .sessions | group_by(.topic | ascii_downcase)
            | map(select(length >= 2))
            | sort_by(-length)
            | .[] | "  \(length)x  \(.[0].topic)  (last: \(.[-1].date))"
        ' "$LOG" 2>/dev/null || echo "  none"
        ;;
    *)
        echo "usage: research-log.sh [list|topic|add|stats|repeats]"
        ;;
esac
