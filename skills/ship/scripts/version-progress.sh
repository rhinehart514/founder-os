#!/usr/bin/env bash
# version-progress.sh — Current version thesis, evidence status, completion %
# Run this to get a quick snapshot of where the current version stands.
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"

echo "── version progress ──"

if [[ ! -f "$ROADMAP" ]]; then
    echo "  no roadmap.yml found at $ROADMAP"
    echo "  run /roadmap new to create one"
    exit 0
fi

# Current version
CURRENT=$(grep -m1 '^current:' "$ROADMAP" 2>/dev/null | sed 's/^current: *//' | tr -d ' ' || echo "?")
echo "  version: $CURRENT"

# Thesis
THESIS=$(awk "/^  ${CURRENT}:/{found=1} found && /thesis:/{print; exit}" "$ROADMAP" 2>/dev/null | sed 's/.*thesis: *//' | sed 's/"//g' || echo "?")
echo "  thesis: \"$THESIS\""

# Status
STATUS=$(awk "/^  ${CURRENT}:/{found=1} found && /status:/{print; exit}" "$ROADMAP" 2>/dev/null | sed 's/.*status: *//' || echo "?")
echo "  status: $STATUS"

# Evidence items
echo ""
echo "  ▾ evidence"
PROVEN=0
TOTAL=0
IN_CURRENT=0
IN_EVIDENCE=0

while IFS= read -r line; do
    # Detect we're in the current version block
    if echo "$line" | grep -qE "^  ${CURRENT}:"; then
        IN_CURRENT=1
        IN_EVIDENCE=0
        continue
    fi
    # Detect we left the current version (next version starts)
    if [[ $IN_CURRENT -eq 1 ]] && echo "$line" | grep -qE '^  v[0-9]'; then
        break
    fi
    # Detect evidence_needed section
    if [[ $IN_CURRENT -eq 1 ]] && echo "$line" | grep -q 'evidence_needed:'; then
        IN_EVIDENCE=1
        continue
    fi
    # Parse evidence items
    if [[ $IN_EVIDENCE -eq 1 ]]; then
        # New evidence item (starts with - id:)
        if echo "$line" | grep -qE '^\s+- id:'; then
            TOTAL=$((TOTAL + 1))
            EV_ID=$(echo "$line" | sed 's/.*id: *//')
        fi
        if echo "$line" | grep -q 'question:'; then
            EV_Q=$(echo "$line" | sed 's/.*question: *//' | sed 's/"//g')
        fi
        if echo "$line" | grep -q 'status:'; then
            EV_STATUS=$(echo "$line" | sed 's/.*status: *//')
            case "$EV_STATUS" in
                proven) ICON="✓"; PROVEN=$((PROVEN + 1)) ;;
                partial) ICON="~" ;;
                disproven) ICON="✗" ;;
                *) ICON="·" ;;
            esac
            echo "    $ICON $EV_ID: $EV_Q ($EV_STATUS)"
        fi
        # Exit evidence block when we hit a non-indented line
        if echo "$line" | grep -qE '^  [a-z]' && ! echo "$line" | grep -qE '^\s{4,}'; then
            IN_EVIDENCE=0
        fi
    fi
done < "$ROADMAP"

# Completion
echo ""
if [[ $TOTAL -gt 0 ]]; then
    EVIDENCE_PCT=$((PROVEN * 100 / TOTAL))
    echo "  evidence: $PROVEN/$TOTAL ($EVIDENCE_PCT%)"
else
    echo "  evidence: no evidence_needed items found"
fi

# Try compute-completion.sh if available
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPLETION_SCRIPT="$FOUNDER_DIR/bin/compute-completion.sh"
if [[ -x "$COMPLETION_SCRIPT" ]]; then
    COMPLETION=$("$COMPLETION_SCRIPT" 2>/dev/null | grep "version_completion" | awk '{print $2}' || echo "")
    [[ -n "$COMPLETION" ]] && echo "  version completion: ${COMPLETION}%"
fi

# Days since version started (use proven date of previous version or first commit)
echo ""
echo "── end progress ──"
