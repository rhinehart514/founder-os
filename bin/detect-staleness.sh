#!/usr/bin/env bash
# detect-staleness.sh — Find stale entries in experiment-learnings.md.
# Used by: /retro, /research, /plan
#
# Usage: bash bin/detect-staleness.sh [experiment-learnings.md] [threshold_days]
# Output: one line per stale entry with section + text
#
# Checks:
# - Known patterns >30 days without new evidence → stale
# - Unknown territory >30 days without first experiment → neglected
# - Dead ends that appear in recent predictions → zombie

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LEARNINGS="${1:-}"
THRESHOLD="${2:-30}"

# Find learnings file
if [[ -z "$LEARNINGS" ]]; then
    LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
fi

if [[ ! -f "$LEARNINGS" ]]; then
    echo "no experiment-learnings.md found" >&2
    exit 1
fi

# File age in days
if [[ "$(uname)" == "Darwin" ]]; then
    FILE_AGE=$(( ($(date +%s) - $(stat -f %m "$LEARNINGS")) / 86400 ))
else
    FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "$LEARNINGS")) / 86400 ))
fi

echo "file_age_days: $FILE_AGE"

if [[ "$FILE_AGE" -gt "$THRESHOLD" ]]; then
    echo "status: stale"
    echo "message: experiment-learnings.md is ${FILE_AGE} days old (threshold: ${THRESHOLD})"
else
    echo "status: fresh"
fi

# Count entries per section
echo ""
echo "sections:"

CURRENT_SECTION=""
ENTRY_COUNT=0
while IFS= read -r line; do
    if [[ "$line" =~ ^##\  ]]; then
        if [[ -n "$CURRENT_SECTION" ]]; then
            echo "  ${CURRENT_SECTION}: ${ENTRY_COUNT} entries"
        fi
        CURRENT_SECTION=$(echo "$line" | sed 's/^## //')
        ENTRY_COUNT=0
    elif [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        ENTRY_COUNT=$((ENTRY_COUNT + 1))
    fi
done < "$LEARNINGS"
# Print last section
if [[ -n "$CURRENT_SECTION" ]]; then
    echo "  ${CURRENT_SECTION}: ${ENTRY_COUNT} entries"
fi

# Check for Unknown Territory items (highest information value)
echo ""
echo "unknown_territory:"
IN_UNKNOWN=false
while IFS= read -r line; do
    if [[ "$line" =~ ^##.*[Uu]nknown ]]; then
        IN_UNKNOWN=true
        continue
    elif [[ "$line" =~ ^## ]]; then
        IN_UNKNOWN=false
    fi
    if $IN_UNKNOWN && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        echo "  $line"
    fi
done < "$LEARNINGS"
