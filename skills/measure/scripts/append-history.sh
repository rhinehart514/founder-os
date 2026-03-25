#!/usr/bin/env bash
# append-history.sh — Append taste eval results to taste-history.tsv.
# Reads taste-*.json reports and ensures all are represented in the TSV.
# Backfills missing entries from existing reports.
# Usage: bash scripts/append-history.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
REPORTS_DIR="$PROJECT_DIR/.claude/evals/reports"
HISTORY="$PROJECT_DIR/.claude/evals/taste-history.tsv"
HEADER="date\turl\toverall\thierarchy\tbreathing_room\tcontrast\tpolish\temotional_tone\tinformation_density\twayfinding\tdistinctiveness\tscroll_experience\tlayout_coherence\tinformation_architecture"

DIMS="hierarchy breathing_room contrast polish emotional_tone information_density wayfinding distinctiveness scroll_experience layout_coherence information_architecture"

# Ensure directories exist
mkdir -p "$PROJECT_DIR/.claude/evals/reports"
mkdir -p "$(dirname "$HISTORY")"

# Create TSV with header if missing or empty
if [[ ! -f "$HISTORY" ]] || [[ ! -s "$HISTORY" ]]; then
    printf '%b\n' "$HEADER" > "$HISTORY"
    echo "created taste-history.tsv"
elif ! head -1 "$HISTORY" | grep -q "^date"; then
    # Header missing — prepend it
    TMP=$(mktemp)
    printf '%b\n' "$HEADER" > "$TMP"
    cat "$HISTORY" >> "$TMP"
    mv "$TMP" "$HISTORY"
    echo "added missing header to taste-history.tsv"
fi

# Check for jq
if ! command -v jq &>/dev/null; then
    echo "error: jq required for JSON parsing"
    exit 1
fi

# Collect existing dates from TSV
EXISTING_DATES=""
if [[ -f "$HISTORY" ]]; then
    EXISTING_DATES=$(tail -n +2 "$HISTORY" | cut -f1 | sort -u)
fi

# Find all taste report JSON files
REPORTS=$(find "$REPORTS_DIR" -name "taste-*.json" -not -name "taste-market*" 2>/dev/null | sort)

if [[ -z "$REPORTS" ]]; then
    echo "no taste reports found in $REPORTS_DIR"
    exit 0
fi

ADDED=0
SKIPPED=0

for report in $REPORTS; do
    # Extract date from JSON
    REPORT_DATE=$(jq -r '.timestamp // empty' "$report" 2>/dev/null | cut -d'T' -f1)
    if [[ -z "$REPORT_DATE" ]]; then
        # Try to extract from filename (taste-YYYY-MM-DD.json)
        REPORT_DATE=$(basename "$report" .json | sed 's/^taste-//')
    fi

    if [[ -z "$REPORT_DATE" || "$REPORT_DATE" == "null" ]]; then
        echo "skipping $report — no date found"
        continue
    fi

    # Skip if already in TSV
    if echo "$EXISTING_DATES" | grep -qx "$REPORT_DATE" 2>/dev/null; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Extract scores
    URL=$(jq -r '.url // "unknown"' "$report" 2>/dev/null)
    OVERALL=$(jq -r '.overall // 0' "$report" 2>/dev/null)

    ROW="$REPORT_DATE\t$URL\t$OVERALL"
    for dim in $DIMS; do
        SCORE=$(jq -r ".dimensions.\"$dim\".score // 0" "$report" 2>/dev/null)
        ROW="$ROW\t$SCORE"
    done

    printf '%b\n' "$ROW" >> "$HISTORY"
    EXISTING_DATES="$EXISTING_DATES
$REPORT_DATE"
    ADDED=$((ADDED + 1))
    echo "added: $REPORT_DATE ($URL) overall=$OVERALL"
done

echo ""
echo "appended: $ADDED new · skipped: $SKIPPED existing"
TOTAL=$(tail -n +2 "$HISTORY" | wc -l | tr -d ' ')
echo "total evaluations in history: $TOTAL"
