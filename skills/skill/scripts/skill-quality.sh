#!/usr/bin/env bash
# Grades each skill for folder completeness
# Checks: gotchas.md, scripts/, references/, templates/
# Usage: bash scripts/skill-quality.sh
# Output: per-skill completeness report with letter grades
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SKILLS_DIR="$PROJECT_DIR/skills"

echo "── skill quality ──"
echo ""
printf "  %-16s %-5s %-8s %-7s %-5s %-5s  %s\n" "skill" "grade" "gotchas" "scripts" "refs" "tmpls" "missing"
printf "  %-16s %-5s %-8s %-7s %-5s %-5s  %s\n" "─────" "─────" "───────" "───────" "─────" "─────" "───────"

TOTAL=0
A_COUNT=0
B_COUNT=0
C_COUNT=0
F_COUNT=0

for d in "$SKILLS_DIR"/*/; do
    [[ ! -f "$d/SKILL.md" ]] && continue
    NAME=$(basename "$d")

    # Skip context skills (no folder expectations)
    if [[ "$NAME" == "founder-mind" || "$NAME" == "product-lens" ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))
    SCORE=0
    MISSING=""

    # Check gotchas.md (2 points)
    if [[ -f "$d/gotchas.md" ]]; then
        GOTCHAS_LINES=$(wc -l < "$d/gotchas.md" | tr -d ' ')
        if [[ "$GOTCHAS_LINES" -ge 5 ]]; then
            HAS_GOTCHAS="✓ ${GOTCHAS_LINES}L"
            SCORE=$((SCORE + 2))
        else
            HAS_GOTCHAS="⚠ thin"
            SCORE=$((SCORE + 1))
            MISSING="${MISSING}gotchas-thin "
        fi
    else
        HAS_GOTCHAS="✗"
        MISSING="${MISSING}gotchas "
    fi

    # Check scripts/ (2 points)
    SCRIPT_COUNT=$(find "$d" -path "*/scripts/*" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$SCRIPT_COUNT" -ge 2 ]]; then
        HAS_SCRIPTS="✓ ${SCRIPT_COUNT}"
        SCORE=$((SCORE + 2))
    elif [[ "$SCRIPT_COUNT" -ge 1 ]]; then
        HAS_SCRIPTS="· ${SCRIPT_COUNT}"
        SCORE=$((SCORE + 1))
        MISSING="${MISSING}more-scripts "
    else
        HAS_SCRIPTS="✗"
        MISSING="${MISSING}scripts "
    fi

    # Check references/ (2 points)
    REF_COUNT=$(find "$d" -path "*/references/*" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$REF_COUNT" -ge 2 ]]; then
        HAS_REFS="✓ ${REF_COUNT}"
        SCORE=$((SCORE + 2))
    elif [[ "$REF_COUNT" -ge 1 ]]; then
        HAS_REFS="· ${REF_COUNT}"
        SCORE=$((SCORE + 1))
        MISSING="${MISSING}more-refs "
    else
        HAS_REFS="✗"
        MISSING="${MISSING}references "
    fi

    # Check templates/ (2 points)
    TMPL_COUNT=$(find "$d" -path "*/templates/*" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$TMPL_COUNT" -ge 1 ]]; then
        HAS_TMPLS="✓ ${TMPL_COUNT}"
        SCORE=$((SCORE + 2))
    else
        HAS_TMPLS="✗"
        MISSING="${MISSING}templates "
    fi

    # Grade: A=7-8, B=5-6, C=3-4, F=0-2
    if [[ "$SCORE" -ge 7 ]]; then
        GRADE="A"
        A_COUNT=$((A_COUNT + 1))
    elif [[ "$SCORE" -ge 5 ]]; then
        GRADE="B"
        B_COUNT=$((B_COUNT + 1))
    elif [[ "$SCORE" -ge 3 ]]; then
        GRADE="C"
        C_COUNT=$((C_COUNT + 1))
    else
        GRADE="F"
        F_COUNT=$((F_COUNT + 1))
    fi

    # Trim trailing space from MISSING
    MISSING=$(echo "$MISSING" | sed 's/ *$//')

    printf "  %-16s %-5s %-8s %-7s %-5s %-5s  %s\n" "$NAME" "$GRADE" "$HAS_GOTCHAS" "$HAS_SCRIPTS" "$HAS_REFS" "$HAS_TMPLS" "$MISSING"
done

echo ""
echo "  $TOTAL skills graded: A=$A_COUNT B=$B_COUNT C=$C_COUNT F=$F_COUNT"
echo "  A = gotchas + scripts + references + templates (full folder)"
echo "  F = missing 3+ components (bare file)"
