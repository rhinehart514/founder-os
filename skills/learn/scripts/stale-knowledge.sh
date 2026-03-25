#!/usr/bin/env bash
# Knowledge staleness scan for /retro
# Usage: bash scripts/stale-knowledge.sh [threshold_days]
# Wraps bin/detect-staleness.sh + adds prediction cross-reference
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
THRESHOLD="${1:-30}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"

echo "── knowledge staleness ──"

# Run core staleness detection
if [[ -f "$FOUNDER_DIR/bin/detect-staleness.sh" ]]; then
    bash "$FOUNDER_DIR/bin/detect-staleness.sh" "$LEARNINGS" "$THRESHOLD" 2>/dev/null
else
    echo "  bin/detect-staleness.sh not found — manual scan"
    if [[ -f "$LEARNINGS" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            FILE_AGE=$(( ($(date +%s) - $(stat -f %m "$LEARNINGS")) / 86400 ))
        else
            FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "$LEARNINGS")) / 86400 ))
        fi
        echo "  file_age_days: $FILE_AGE"
        if [[ "$FILE_AGE" -gt "$THRESHOLD" ]]; then
            echo "  status: stale"
        else
            echo "  status: fresh"
        fi
    else
        echo "  no experiment-learnings.md found"
        exit 0
    fi
fi

# Cross-reference: Dead ends that appear in recent predictions (zombies)
echo ""
echo "── zombie dead ends ──"
if [[ -f "$LEARNINGS" && -f "$PRED_FILE" ]]; then
    IN_DEAD=false
    ZOMBIE_COUNT=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^##.*[Dd]ead ]]; then
            IN_DEAD=true
            continue
        elif [[ "$line" =~ ^## ]]; then
            IN_DEAD=false
        fi
        if $IN_DEAD && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            # Extract key phrase (first 40 chars after the dash)
            PHRASE=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | cut -c1-40 | tr '[:upper:]' '[:lower:]')
            # Check if any word from the phrase appears in recent predictions
            FIRST_WORD=$(echo "$PHRASE" | awk '{print $1}' | sed 's/[^a-z0-9]//g')
            if [[ -n "$FIRST_WORD" && ${#FIRST_WORD} -gt 2 ]]; then
                HITS=$(tail -n +2 "$PRED_FILE" | awk -F'\t' -v w="$FIRST_WORD" 'tolower($3) ~ w { c++ } END { print c+0 }')
                if [[ "$HITS" -gt 0 ]]; then
                    echo "  ⚠ zombie: $line ($HITS recent prediction refs)"
                    ZOMBIE_COUNT=$((ZOMBIE_COUNT + 1))
                fi
            fi
        fi
    done < "$LEARNINGS"
    if [[ "$ZOMBIE_COUNT" -eq 0 ]]; then
        echo "  none — dead ends are staying dead"
    fi
else
    echo "  (missing files for cross-reference)"
fi

# Count per section
echo ""
echo "── section sizes ──"
if [[ -f "$LEARNINGS" ]]; then
    CURRENT=""
    COUNT=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\  ]]; then
            if [[ -n "$CURRENT" ]]; then
                echo "  $CURRENT: $COUNT"
            fi
            CURRENT=$(echo "$line" | sed 's/^## //')
            COUNT=0
        elif [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            COUNT=$((COUNT + 1))
        fi
    done < "$LEARNINGS"
    if [[ -n "$CURRENT" ]]; then
        echo "  $CURRENT: $COUNT"
    fi
fi
