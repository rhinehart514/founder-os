#!/usr/bin/env bash
# Persistent shipping history — survives plugin upgrades
# Uses ${CLAUDE_PLUGIN_DATA} for stable storage
# Usage: ship-log.sh [add|list|stats|last] [options]
set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/cache}"
LOG_FILE="$DATA_DIR/ship-log.jsonl"

# Ensure data dir exists
mkdir -p "$DATA_DIR"

CMD="${1:-list}"
shift || true

case "$CMD" in
    add)
        # ship-log.sh add --type release --version v9.0 --commit abc1234 --score 85 --features "scoring,commands"
        TYPE="deploy"
        VERSION=""
        COMMIT=""
        SCORE=""
        FEATURES=""
        TARGET=""
        PR=""
        TAG=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --type)     TYPE="$2"; shift 2 ;;
                --version)  VERSION="$2"; shift 2 ;;
                --commit)   COMMIT="$2"; shift 2 ;;
                --score)    SCORE="$2"; shift 2 ;;
                --features) FEATURES="$2"; shift 2 ;;
                --target)   TARGET="$2"; shift 2 ;;
                --pr)       PR="$2"; shift 2 ;;
                --tag)      TAG="$2"; shift 2 ;;
                *)          shift ;;
            esac
        done

        # Auto-detect what we can
        if [[ -z "$COMMIT" ]]; then
            COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        fi

        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Build JSON entry
        ENTRY=$(cat <<JSONEOF
{"timestamp":"$TIMESTAMP","type":"$TYPE","version":"$VERSION","commit":"$COMMIT","score":${SCORE:-null},"features":"$FEATURES","target":"$TARGET","pr":"$PR","tag":"$TAG"}
JSONEOF
)
        echo "$ENTRY" >> "$LOG_FILE"
        echo "  logged: $TYPE $VERSION ($COMMIT) at $TIMESTAMP"
        ;;

    list)
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "  no shipping history yet"
            exit 0
        fi

        echo "── ship history ──"
        echo ""

        # Show last 10 entries
        TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
        echo "  total ships: $TOTAL"
        echo ""

        if command -v jq &>/dev/null; then
            tail -10 "$LOG_FILE" | while IFS= read -r line; do
                TS=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
                TYPE=$(echo "$line" | jq -r '.type // ""' 2>/dev/null)
                VER=$(echo "$line" | jq -r '.version // ""' 2>/dev/null)
                COMMIT=$(echo "$line" | jq -r '.commit // ""' 2>/dev/null)
                SCORE=$(echo "$line" | jq -r '.score // "–"' 2>/dev/null)
                DATE=$(echo "$TS" | cut -c1-10)
                echo "  $DATE  $TYPE  $VER  $COMMIT  score:$SCORE"
            done
        else
            tail -10 "$LOG_FILE"
        fi
        ;;

    stats)
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "  no shipping history"
            exit 0
        fi

        echo "── ship stats ──"
        TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
        echo "  total ships: $TOTAL"

        if command -v jq &>/dev/null; then
            DEPLOYS=$(grep -c '"type":"deploy"' "$LOG_FILE" 2>/dev/null || echo 0)
            RELEASES=$(grep -c '"type":"release"' "$LOG_FILE" 2>/dev/null || echo 0)
            PRS=$(grep -c '"type":"pr"' "$LOG_FILE" 2>/dev/null || echo 0)
            HOTFIXES=$(grep -c '"type":"hotfix"' "$LOG_FILE" 2>/dev/null || echo 0)
            ROLLBACKS=$(grep -c '"type":"rollback"' "$LOG_FILE" 2>/dev/null || echo 0)

            echo "  deploys: $DEPLOYS · releases: $RELEASES · PRs: $PRS · hotfixes: $HOTFIXES · rollbacks: $ROLLBACKS"

            # Last ship
            LAST=$(tail -1 "$LOG_FILE" | jq -r '"\(.timestamp) \(.type) \(.version)"' 2>/dev/null || echo "unknown")
            echo "  last ship: $LAST"

            # Score trend (last 5 with scores)
            SCORES=$(grep -v '"score":null' "$LOG_FILE" | tail -5 | jq -r '.score' 2>/dev/null | tr '\n' ' ')
            if [[ -n "$SCORES" ]]; then
                echo "  score trend (last 5): $SCORES"
            fi
        fi
        ;;

    last)
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "  no shipping history"
            exit 0
        fi

        LAST=$(tail -1 "$LOG_FILE")
        if command -v jq &>/dev/null; then
            echo "$LAST" | jq .
        else
            echo "$LAST"
        fi
        ;;

    *)
        echo "Usage: ship-log.sh [add|list|stats|last]"
        echo "  add    — log a ship event (--type --version --commit --score --features --target --pr --tag)"
        echo "  list   — show recent shipping history"
        echo "  stats  — shipping statistics"
        echo "  last   — show last ship entry"
        exit 1
        ;;
esac
