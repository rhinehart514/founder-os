#!/usr/bin/env bash
# assertion-gate.sh — Run assertions and report pass/fail with specifics.
# Usage: bash scripts/assertion-gate.sh [feature] [--diff]
# --diff: compare against last run and show regressions/progressions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve FOUNDER_DIR: env var > install-path > relative to script
if [[ -n "${FOUNDER_DIR:-}" && -d "$FOUNDER_DIR/bin" ]]; then
    : # use existing FOUNDER_DIR
elif [[ -f "$HOME/.config/founder-os/install-path" ]]; then
    FOUNDER_DIR="$(cat "$HOME/.config/founder-os/install-path")"
else
    FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
FEATURE=""
DIFF_MODE=false

for arg in "$@"; do
    case "$arg" in
        --diff) DIFF_MODE=true ;;
        *) FEATURE="$arg" ;;
    esac
done

# Store previous results for diff comparison
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/data/go}"
mkdir -p "$DATA_DIR"
PREV_FILE="$DATA_DIR/last-assertions.txt"

# Run eval in assertion-only mode
RESULT=$("$FOUNDER_DIR/bin/eval.sh" --no-llm --score ${FEATURE:+--feature "$FEATURE"} 2>/dev/null || echo "")

if [[ -z "$RESULT" ]]; then
    echo "ERROR: assertion check failed (eval.sh returned empty)"
    exit 1
fi

# Parse pass/fail counts
if command -v jq &>/dev/null; then
    PASS=$(echo "$RESULT" | jq -r '.assertion_pass_count // .pass // 0' 2>/dev/null || echo "0")
    TOTAL=$(echo "$RESULT" | jq -r '.assertion_count // .total // 0' 2>/dev/null || echo "0")
    FAILURES=$(echo "$RESULT" | jq -r '.failures // [] | .[] | "  FAIL: \(.name // .claim // "unknown") — \(.reason // "no reason")"' 2>/dev/null || echo "")
    PASSES=$(echo "$RESULT" | jq -r '.passes // [] | .[] | "\(.name // .claim // "unknown")"' 2>/dev/null || echo "")
else
    PASS="?"
    TOTAL="?"
    FAILURES=""
    PASSES=""
fi

FAIL=$((TOTAL - PASS))

# Output
echo "=== ASSERTIONS: $PASS/$TOTAL passing ==="

if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "FAILING ($FAIL):"
    if [[ -n "$FAILURES" ]]; then
        echo "$FAILURES"
    else
        # Fall back to beliefs.yml parsing
        BELIEFS="config/beliefs.yml"
        if [[ -f "$BELIEFS" ]]; then
            grep -B2 'status: fail' "$BELIEFS" 2>/dev/null | grep -E 'name:|claim:' | sed 's/^/  FAIL: /' | head -10
        fi
    fi
fi

# Diff mode: compare with previous run
if $DIFF_MODE && [[ -f "$PREV_FILE" ]]; then
    echo ""
    echo "CHANGES SINCE LAST CHECK:"
    PREV_PASS=$(head -1 "$PREV_FILE" 2>/dev/null || echo "0")
    DELTA=$((PASS - PREV_PASS))
    if [[ "$DELTA" -gt 0 ]]; then
        echo "  PROGRESSED: +$DELTA assertions now passing"
    elif [[ "$DELTA" -lt 0 ]]; then
        echo "  REGRESSED: $DELTA assertions stopped passing"
    else
        echo "  UNCHANGED: same pass count"
    fi
fi

# Save current state for next diff
echo "$PASS" > "$PREV_FILE"
echo "$TOTAL" >> "$PREV_FILE"

# Exit code: 0 if all pass, 1 if any fail
if [[ "$PASS" == "$TOTAL" && "$TOTAL" != "0" ]]; then
    echo ""
    echo "STATUS: ALL PASSING"
    exit 0
else
    echo ""
    echo "STATUS: $FAIL FAILING"
    exit 1
fi
