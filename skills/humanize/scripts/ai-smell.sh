#!/usr/bin/env bash
# ai-smell.sh — Mechanical detection of AI-generated code patterns.
# Scans changed files (or all files) for the 7 AI smells.
# Zero LLM cost — grep-based detection only.
# Usage: ai-smell.sh [project-dir] [--all]
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
SCAN_ALL=false
[[ "${2:-}" == "--all" ]] && SCAN_ALL=true

echo "── ai smell check ──"

# Get file list
if [[ "$SCAN_ALL" == true ]] || ! git -C "$PROJECT_DIR" rev-parse HEAD &>/dev/null; then
    FILES=$(find "$PROJECT_DIR" -maxdepth 5 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.sh" -o -name "*.go" -o -name "*.rs" \) -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" -not -path "*/.git/*" 2>/dev/null || true)
    echo "  mode: full scan"
else
    FILES=$(git -C "$PROJECT_DIR" diff --name-only HEAD~5 HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|sh|go|rs)$' || true)
    [[ -z "$FILES" ]] && FILES=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|sh|go|rs)$' || true)
    echo "  mode: recent changes"
fi

FILE_COUNT=$(echo "$FILES" | grep -c '.' 2>/dev/null || echo 0)
echo "  files: $FILE_COUNT"
echo ""

SMELL_1=0 SMELL_2=0 SMELL_3=0 SMELL_5=0 SMELL_7=0

# Helper: safe line count
_count() { grep -c "$1" "$2" 2>/dev/null | tr -d '[:space:]' || echo 0; }
_lines() { wc -l < "$1" 2>/dev/null | tr -d '[:space:]' || echo 0; }

# --- Smell 1: Over-abstraction ---
echo "  ▸ over-abstraction"
while IFS= read -r f; do
    [[ -z "$f" || ! -f "$PROJECT_DIR/$f" ]] && continue
    fp="$PROJECT_DIR/$f"
    n=$(_count 'interface\|abstract class' "$fp")
    if [[ "$n" -gt 2 ]] 2>/dev/null; then
        echo "    · $f: $n abstractions"
        SMELL_1=$((SMELL_1 + 1))
    fi
    bn=$(basename "$f")
    if echo "$bn" | grep -qiE '(utils|helpers|constants|types)\.(ts|js)$'; then
        lines=$(_lines "$fp")
        if [[ "$lines" -lt 30 ]] 2>/dev/null; then
            echo "    · $f: ${lines} lines — inline candidate"
            SMELL_1=$((SMELL_1 + 1))
        fi
    fi
done <<< "$FILES"
[[ $SMELL_1 -eq 0 ]] && echo "    none detected"

# --- Smell 2: Defensive paranoia ---
echo ""
echo "  ▸ defensive paranoia"
while IFS= read -r f; do
    [[ -z "$f" || ! -f "$PROJECT_DIR/$f" ]] && continue
    fp="$PROJECT_DIR/$f"
    catches=$(_count 'catch\s*(' "$fp")
    lines=$(_lines "$fp")
    if [[ "$lines" -gt 20 && "$catches" -gt 0 ]] 2>/dev/null; then
        ratio=$((lines / (catches + 1)))
        if [[ "$ratio" -lt 20 ]] 2>/dev/null; then
            echo "    · $f: try/catch every ${ratio} lines"
            SMELL_2=$((SMELL_2 + 1))
        fi
    fi
done <<< "$FILES"
[[ $SMELL_2 -eq 0 ]] && echo "    none detected"

# --- Smell 3: Documentation theater ---
echo ""
echo "  ▸ documentation theater"
while IFS= read -r f; do
    [[ -z "$f" || ! -f "$PROJECT_DIR/$f" ]] && continue
    fp="$PROJECT_DIR/$f"
    docs=$(_count '^\s*\*\s\|^\s*/\*\*\|@param\|@returns' "$fp")
    lines=$(_lines "$fp")
    if [[ "$lines" -gt 30 && "$docs" -gt 0 ]] 2>/dev/null; then
        ratio=$((docs * 100 / lines))
        if [[ "$ratio" -gt 25 ]] 2>/dev/null; then
            echo "    · $f: ${ratio}% documentation"
            SMELL_3=$((SMELL_3 + 1))
        fi
    fi
    restate=$(_count '// \(get\|set\|return\|loop\|check\|handle\|create\|update\|delete\|fetch\|init\)' "$fp")
    if [[ "$restate" -gt 3 ]] 2>/dev/null; then
        echo "    · $f: $restate restating comments"
        SMELL_3=$((SMELL_3 + 1))
    fi
done <<< "$FILES"
[[ $SMELL_3 -eq 0 ]] && echo "    none detected"

# --- Smell 5: Premature completeness ---
echo ""
echo "  ▸ premature completeness"
while IFS= read -r f; do
    [[ -z "$f" || ! -f "$PROJECT_DIR/$f" ]] && continue
    fp="$PROJECT_DIR/$f"
    cases=$(_count 'case \|default:' "$fp")
    if [[ "$cases" -gt 10 ]] 2>/dev/null; then
        echo "    · $f: $cases switch cases"
        SMELL_5=$((SMELL_5 + 1))
    fi
done <<< "$FILES"
[[ $SMELL_5 -eq 0 ]] && echo "    none detected"

# --- Smell 7: Name anxiety ---
echo ""
echo "  ▸ name anxiety"
while IFS= read -r f; do
    [[ -z "$f" || ! -f "$PROJECT_DIR/$f" ]] && continue
    fp="$PROJECT_DIR/$f"
    long_names=$(grep -oE '[A-Z][a-z]+([A-Z][a-z]+){3,}' "$fp" 2>/dev/null | sort -u | head -3)
    if [[ -n "$long_names" ]]; then
        count=$(echo "$long_names" | wc -l | tr -d '[:space:]')
        first=$(echo "$long_names" | head -1)
        echo "    · $f: $count verbose names (e.g., $first)"
        SMELL_7=$((SMELL_7 + 1))
    fi
    handlers=$(_count 'handle[A-Z]' "$fp")
    if [[ "$handlers" -gt 5 ]] 2>/dev/null; then
        echo "    · $f: $handlers handle* functions"
        SMELL_7=$((SMELL_7 + 1))
    fi
done <<< "$FILES"
[[ $SMELL_7 -eq 0 ]] && echo "    none detected"

# --- Summary ---
echo ""
TOTAL=$((SMELL_1 + SMELL_2 + SMELL_3 + SMELL_5 + SMELL_7))

echo "── summary ──"
printf "  over-abstraction:       %d\n" "$SMELL_1"
printf "  defensive paranoia:     %d\n" "$SMELL_2"
printf "  documentation theater:  %d\n" "$SMELL_3"
printf "  premature completeness: %d\n" "$SMELL_5"
printf "  name anxiety:           %d\n" "$SMELL_7"
echo "  ────────────────────"
printf "  total signals:          %d\n" "$TOTAL"

if [[ $TOTAL -eq 0 ]]; then
    echo "  verdict: human — ship it"
elif [[ $TOTAL -le 3 ]]; then
    echo "  verdict: mostly human — quick fixes"
elif [[ $TOTAL -le 8 ]]; then
    echo "  verdict: AI-adjacent — review flagged files"
else
    echo "  verdict: AI-built — needs a humanize pass"
fi
