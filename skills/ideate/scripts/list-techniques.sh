#!/usr/bin/env bash
# list-techniques.sh — Dynamically lists all technique files in ideate/techniques/
# Used by /ideate to discover available creative thinking modes.
#
# Usage: bash skills/ideate/scripts/list-techniques.sh
# Output: one line per technique — "name | first-line description"
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TECHNIQUES_DIR="$SCRIPT_DIR/../techniques"

if [[ ! -d "$TECHNIQUES_DIR" ]]; then
    echo "No techniques directory found at $TECHNIQUES_DIR" >&2
    exit 1
fi

COUNT=0
for technique_file in "$TECHNIQUES_DIR"/*.md; do
    [[ ! -f "$technique_file" ]] && continue
    name=$(basename "$technique_file" .md)
    # Extract first non-empty, non-heading line as description
    desc=$(awk '/^[^#\n]/ && NF > 0 {print; exit}' "$technique_file" 2>/dev/null)
    [[ -z "$desc" ]] && desc="(no description)"
    echo "$name | $desc"
    COUNT=$((COUNT + 1))
done

echo ""
echo "$COUNT techniques available"
