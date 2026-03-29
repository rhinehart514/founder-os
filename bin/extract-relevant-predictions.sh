#!/usr/bin/env bash
# extract-relevant-predictions.sh — Find predictions relevant to a topic
# Usage: bash bin/extract-relevant-predictions.sh "keyword1 keyword2"
# Returns markdown of failed/partial predictions matching keywords.
set -euo pipefail

KEYWORDS="${1:-}"
[[ -z "$KEYWORDS" ]] && exit 0

PROJECT_DIR="$(pwd)"
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && exit 0

MATCHES=""
for word in $KEYWORDS; do
    [[ ${#word} -lt 3 ]] && continue
    # Find failed or partial predictions matching this keyword
    FOUND=$(tail -n +2 "$PRED_FILE" | grep -i "$word" | awk -F'\t' '$6 == "no" || $6 == "partial"' 2>/dev/null || true)
    if [[ -n "$FOUND" ]]; then
        MATCHES="${MATCHES}${FOUND}"$'\n'
    fi
done

# Deduplicate
UNIQUE=$(echo "$MATCHES" | sort -u | head -10)
[[ -z "$UNIQUE" ]] && exit 0

echo "### Failed/Partial Predictions"
echo ""
while IFS=$'\t' read -r dt agent pred ev res cor mu; do
    [[ -z "$dt" ]] && continue
    echo "- **$dt** ($cor): ${pred:0:80}"
    [[ -n "$mu" ]] && echo "  - Model update: ${mu:0:80}"
done <<< "$UNIQUE"
