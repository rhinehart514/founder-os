#!/usr/bin/env bash
# intelligence-query.sh — Queries ALL accumulated intelligence sources.
# Run when the founder asks a question. Surfaces what founder-os already knows
# before doing fresh research.
#
# Usage: intelligence-query.sh [project-dir] [query-keywords...]
# Example: intelligence-query.sh . pricing competitors agents
set -uo pipefail

PROJECT_DIR="${1:-.}"
shift || true
QUERY="$*"

echo "=== ACCUMULATED INTELLIGENCE ==="
echo "query: $QUERY"
echo ""

# --- 1. Market context (structured competitor/market data) ---
MARKET="$PROJECT_DIR/.claude/cache/market-context.json"
if [[ -f "$MARKET" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        AGE=$(( ($(date +%s) - $(stat -f %m "$MARKET" 2>/dev/null || echo 0)) / 86400 ))
    else
        AGE=$(( ($(date +%s) - $(stat -c %Y "$MARKET" 2>/dev/null || echo 0)) / 86400 ))
    fi
    echo "▸ MARKET CONTEXT (${AGE}d old):"
    if command -v jq &>/dev/null; then
        # Show competitors
        COMPETITORS=$(jq -r '.competitors[]?.name // empty' "$MARKET" 2>/dev/null)
        [[ -n "$COMPETITORS" ]] && echo "  competitors: $COMPETITORS"
        # Show signals
        jq -r '.signals[]? // empty' "$MARKET" 2>/dev/null | head -5 | while IFS= read -r s; do
            echo "  signal: $s"
        done
        # Show gaps
        jq -r '.gaps[]? // empty' "$MARKET" 2>/dev/null | head -3 | while IFS= read -r g; do
            echo "  gap: $g"
        done
    else
        head -20 "$MARKET"
    fi
    echo ""
fi

# --- 2. Customer intelligence ---
CUST="$PROJECT_DIR/.claude/cache/customer-intel.json"
if [[ -f "$CUST" ]]; then
    echo "▸ CUSTOMER INTELLIGENCE:"
    if command -v jq &>/dev/null; then
        jq -r '.demand_signals[]? // empty' "$CUST" 2>/dev/null | head -5 | while IFS= read -r d; do
            echo "  demand: $d"
        done
        jq -r '.unmet_needs[]? // empty' "$CUST" 2>/dev/null | head -3 | while IFS= read -r u; do
            echo "  unmet: $u"
        done
        jq -r '.competitor_complaints[]? // empty' "$CUST" 2>/dev/null | head -3 | while IFS= read -r c; do
            echo "  complaint: $c"
        done
    fi
    echo ""
fi

# --- 3. Research log (past research sessions) ---
LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/data/founder-os}"
RESEARCH_LOG="$LOG_DIR/research-log.jsonl"
if [[ -f "$RESEARCH_LOG" ]]; then
    ENTRIES=$(wc -l < "$RESEARCH_LOG" | tr -d ' ')
    echo "▸ RESEARCH HISTORY ($ENTRIES entries):"
    # Show recent entries, filter by query if provided
    if [[ -n "$QUERY" ]]; then
        grep -i "$QUERY" "$RESEARCH_LOG" 2>/dev/null | tail -5 | while IFS= read -r line; do
            TOPIC=$(echo "$line" | sed -n 's/.*"topic":"\([^"]*\)".*/\1/p')
            CONF=$(echo "$line" | sed -n 's/.*"confidence":"\([^"]*\)".*/\1/p')
            DATE=$(echo "$line" | sed -n 's/.*"date":"\([^"]*\)".*/\1/p' | cut -d'T' -f1)
            echo "  $DATE: $TOPIC (confidence: $CONF)"
        done
    else
        tail -5 "$RESEARCH_LOG" | while IFS= read -r line; do
            TOPIC=$(echo "$line" | sed -n 's/.*"topic":"\([^"]*\)".*/\1/p')
            DATE=$(echo "$line" | sed -n 's/.*"date":"\([^"]*\)".*/\1/p' | cut -d'T' -f1)
            echo "  $DATE: $TOPIC"
        done
    fi
    echo ""
fi

# --- 4. Ideation history (past ideas and their fate) ---
IDEA_LOG="$LOG_DIR/ideation-log.jsonl"
if [[ -f "$IDEA_LOG" ]]; then
    TOTAL=$(wc -l < "$IDEA_LOG" | tr -d ' ')
    echo "▸ IDEATION HISTORY ($TOTAL entries):"
    if [[ -n "$QUERY" ]]; then
        grep -i "$QUERY" "$IDEA_LOG" 2>/dev/null | tail -5 | while IFS= read -r line; do
            ACTION=$(echo "$line" | sed -n 's/.*"action":"\([^"]*\)".*/\1/p')
            NAME=$(echo "$line" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
            echo "  $ACTION: $NAME"
        done
    else
        tail -5 "$IDEA_LOG" | while IFS= read -r line; do
            ACTION=$(echo "$line" | sed -n 's/.*"action":"\([^"]*\)".*/\1/p')
            NAME=$(echo "$line" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
            echo "  $ACTION: $NAME"
        done
    fi
    echo ""
fi

# --- 5. Experiment learnings (the knowledge model) ---
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    KNOWN=$(awk '/^## Known Patterns/,/^## /{if(/^## / && !/Known/) exit; if(/^\s*-\s*\*\*/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    UNCERTAIN=$(awk '/^## Uncertain Patterns/,/^## /{if(/^## / && !/Uncertain/) exit; if(/^\s*-\s*\*\*/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    UNKNOWN=$(awk '/^## Unknown Territory/,/^## /{if(/^## / && !/Unknown/) exit; if(/^\s*-/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    DEAD=$(awk '/^## Dead Ends/,/^## /{if(/^## / && !/Dead/) exit; if(/^\s*-\s*\*\*/) c++} END{print c+0}' "$LEARNINGS" 2>/dev/null)
    echo "▸ KNOWLEDGE MODEL: $KNOWN known, $UNCERTAIN uncertain, $UNKNOWN unknown, $DEAD dead ends"
    if [[ -n "$QUERY" ]]; then
        MATCHES=$(grep -i "$QUERY" "$LEARNINGS" 2>/dev/null | head -5)
        if [[ -n "$MATCHES" ]]; then
            echo "  matching '$QUERY':"
            echo "$MATCHES" | while IFS= read -r m; do echo "    $m"; done
        fi
    fi
    echo ""
fi

# --- 6. Predictions (what we've claimed and whether we were right) ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    TOTAL=$(tail -n +2 "$PRED_FILE" | wc -l | tr -d ' ')
    CORRECT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "yes"' | wc -l | tr -d ' ')
    WRONG=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no"' | wc -l | tr -d ' ')
    echo "▸ PREDICTIONS: $TOTAL total, $CORRECT correct, $WRONG wrong"
    if [[ -n "$QUERY" ]]; then
        MATCHES=$(grep -i "$QUERY" "$PRED_FILE" 2>/dev/null | head -3)
        if [[ -n "$MATCHES" ]]; then
            echo "  matching '$QUERY':"
            echo "$MATCHES" | while IFS=$'\t' read -r date pred evidence result correct update; do
                echo "    $date: $pred [${correct:-ungraded}]"
            done
        fi
    fi
    echo ""
fi

# --- 7. Strategy (current strategic position) ---
STRATEGY="$PROJECT_DIR/.claude/plans/strategy.yml"
if [[ -f "$STRATEGY" ]]; then
    echo "▸ STRATEGY:"
    grep -E 'stage:|bottleneck:|focus:' "$STRATEGY" 2>/dev/null | sed 's/^/  /'
    echo ""
fi

# --- 8. Documents folder (ideation docs, guides, research) ---
DOCS_DIR="$PROJECT_DIR/documents"
if [[ -d "$DOCS_DIR" ]]; then
    DOC_CT=$(find "$DOCS_DIR" -type f | wc -l | tr -d ' ')
    echo "▸ DOCUMENTS ($DOC_CT files):"
    find "$DOCS_DIR" -type f -name "*.md" | while IFS= read -r doc; do
        NAME=$(basename "$doc")
        if [[ -n "$QUERY" ]] && grep -qi "$QUERY" "$doc" 2>/dev/null; then
            echo "  * $NAME (MATCHES query)"
        else
            echo "  · $NAME"
        fi
    done
    echo ""
fi

# --- 9. Roadmap (proven theses = what we've learned) ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    PROVEN=$(grep -c 'status: proven' "$ROADMAP" 2>/dev/null || echo 0)
    ACTIVE=$(grep -c 'status: active' "$ROADMAP" 2>/dev/null || echo 0)
    echo "▸ ROADMAP: $PROVEN proven theses, $ACTIVE active"
    # Show proven theses as accumulated knowledge
    grep -B1 'status: proven' "$ROADMAP" 2>/dev/null | grep 'thesis:' | sed 's/.*thesis: */  ✓ /' | sed 's/"//g' | head -5
    echo ""
fi

echo "=== END INTELLIGENCE ==="
