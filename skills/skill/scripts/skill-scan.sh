#!/usr/bin/env bash
# Lists all skills with file counts, descriptions, last modified
# Usage: bash scripts/skill-scan.sh
# Output: formatted skill inventory table
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SKILLS_DIR="$PROJECT_DIR/skills"

echo "── skill scan ──"
echo ""
printf "  %-16s %5s %3s %3s %3s  %-8s %-12s  %s\n" "skill" "lines" "scr" "ref" "tpl" "tier" "modified" "description"
printf "  %-16s %5s %3s %3s %3s  %-8s %-12s  %s\n" "─────" "─────" "───" "───" "───" "────────" "────────────" "───────────"

TOTAL=0
RICH=0
BASIC=0
BARE=0

for d in "$SKILLS_DIR"/*/; do
    [[ ! -f "$d/SKILL.md" ]] && continue
    NAME=$(basename "$d")
    TOTAL=$((TOTAL + 1))

    # Line count
    LINES=$(wc -l < "$d/SKILL.md" | tr -d ' ')

    # File counts by type
    SCRIPTS=$(find "$d" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    REFS=$(find "$d" -path "*/references/*" -type f 2>/dev/null | wc -l | tr -d ' ')
    TMPLS=$(find "$d" -path "*/templates/*" -type f 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_FILES=$(find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Gotchas indicator
    HAS_GOTCHAS=$([[ -f "$d/gotchas.md" ]] && echo "G" || echo "·")

    # Tier classification
    if [[ "$TOTAL_FILES" -ge 6 && "$SCRIPTS" -ge 1 ]]; then
        TIER="rich"
        RICH=$((RICH + 1))
    elif [[ "$TOTAL_FILES" -ge 3 ]]; then
        TIER="basic"
        BASIC=$((BASIC + 1))
    else
        TIER="bare"
        BARE=$((BARE + 1))
    fi

    # Last modified (portable: works on macOS + Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" "$d/SKILL.md" 2>/dev/null || echo "unknown")
    else
        MODIFIED=$(stat -c "%y" "$d/SKILL.md" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    fi

    # Extract description from frontmatter
    DESC=$(grep '^description:' "$d/SKILL.md" 2>/dev/null | head -1 | sed 's/^description: *"//;s/"$//' | cut -c1-50)

    printf "  %-16s %5s %3s %3s %3s  %-8s %-12s  %s\n" "$NAME" "$LINES" "$SCRIPTS" "$REFS" "$TMPLS" "$TIER$HAS_GOTCHAS" "$MODIFIED" "$DESC"
done

echo ""
echo "  total: $TOTAL skills (rich: $RICH, basic: $BASIC, bare: $BARE)"
