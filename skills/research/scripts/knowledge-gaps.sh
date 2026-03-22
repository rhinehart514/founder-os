#!/usr/bin/env bash
# Reads experiment-learnings.md, counts unknowns, ranks by information value
# Cross-references with eval-cache.json and founder.yml for bottleneck relevance
# Usage: bash scripts/knowledge-gaps.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
GLOBAL_LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

# Find learnings file (project-local takes priority)
if [[ -f "$LEARNINGS" ]]; then
    SRC="$LEARNINGS"
elif [[ -f "$GLOBAL_LEARNINGS" ]]; then
    SRC="$GLOBAL_LEARNINGS"
else
    echo "no experiment-learnings.md found"
    exit 0
fi

echo "── knowledge gaps ──"
echo "  source: $SRC"
echo ""

# Extract Unknown Territory section
UNKNOWNS=$(sed -n '/^## Unknown Territory/,/^## /p' "$SRC" | grep -E '^\s*-' | sed 's/^[[:space:]]*- //' || true)
UNKNOWN_COUNT=$(echo "$UNKNOWNS" | grep -c '[^ ]' 2>/dev/null || echo "0")
echo "  unknowns: $UNKNOWN_COUNT"

# Extract Uncertain Patterns section
UNCERTAIN=$(sed -n '/^## Uncertain Patterns/,/^## /p' "$SRC" | grep -E '^\s*-' | sed 's/^[[:space:]]*- //' || true)
UNCERTAIN_COUNT=$(echo "$UNCERTAIN" | grep -c '[^ ]' 2>/dev/null || echo "0")
echo "  uncertain: $UNCERTAIN_COUNT"

# Extract Known Patterns count
KNOWN_COUNT=$(sed -n '/^## Known Patterns/,/^## /p' "$SRC" | grep -cE '^\s*-' 2>/dev/null || echo "0")
echo "  known: $KNOWN_COUNT"

# Extract Dead Ends count
DEAD_COUNT=$(sed -n '/^## Dead Ends/,/^## /p' "$SRC" | grep -cE '^\s*-' 2>/dev/null || echo "0")
echo "  dead_ends: $DEAD_COUNT"
echo ""

# Get bottleneck feature if eval-cache exists
BOTTLENECK=""
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    # Find lowest-scoring highest-weight feature
    BOTTLENECK=$(jq -r '
        .features // {} | to_entries
        | sort_by(-(.value.weight // 1))
        | sort_by(.value.score // 100)
        | .[0].key // ""
    ' "$EVAL_CACHE" 2>/dev/null || echo "")
    if [[ -n "$BOTTLENECK" ]]; then
        SCORE=$(jq -r ".features.\"$BOTTLENECK\".score // \"?\"" "$EVAL_CACHE" 2>/dev/null || echo "?")
        WEIGHT=$(jq -r ".features.\"$BOTTLENECK\".weight // \"?\"" "$EVAL_CACHE" 2>/dev/null || echo "?")
        echo "  bottleneck: $BOTTLENECK (score:$SCORE weight:$WEIGHT)"
        echo ""
    fi
fi

# Print unknowns ranked
if [[ "$UNKNOWN_COUNT" -gt 0 ]]; then
    echo "  ── unknown territory (highest info value) ──"
    echo "$UNKNOWNS" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        # Check if this unknown relates to the bottleneck
        if [[ -n "$BOTTLENECK" ]] && echo "$line" | grep -qi "$BOTTLENECK"; then
            echo "  HIGH  $line  [bottleneck-related]"
        else
            echo "  MED   $line"
        fi
    done
    echo ""
fi

if [[ "$UNCERTAIN_COUNT" -gt 0 ]]; then
    echo "  ── uncertain patterns (needs confirmation) ──"
    echo "$UNCERTAIN" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        echo "  LOW   $line"
    done
    echo ""
fi

# Staleness check on learnings file
if [[ -f "$SRC" ]]; then
    DAYS_OLD=$(( ($(date +%s) - $(stat -f %m "$SRC" 2>/dev/null || stat -c %Y "$SRC" 2>/dev/null || echo "0")) / 86400 ))
    if [[ "$DAYS_OLD" -gt 7 ]]; then
        echo "  WARNING: learnings file is ${DAYS_OLD} days old — may be stale"
    fi
fi
