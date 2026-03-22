#!/usr/bin/env bash
# Structured competitor/market data template
# Outputs JSON format for market-context.json
# Usage:
#   bash scripts/market-scan.sh init              — create empty market-context.json
#   bash scripts/market-scan.sh show              — display current market context
#   bash scripts/market-scan.sh add-competitor     — print competitor entry template
#   bash scripts/market-scan.sh add-signal         — print market signal template
#   bash scripts/market-scan.sh age               — check staleness of market data
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MARKET_FILE="$PROJECT_DIR/.claude/cache/market-context.json"

CMD="${1:-show}"

case "$CMD" in
    init)
        mkdir -p "$(dirname "$MARKET_FILE")"
        if [[ -f "$MARKET_FILE" ]]; then
            echo "market-context.json already exists ($(jq '.competitors | length' "$MARKET_FILE" 2>/dev/null || echo "?") competitors)"
            exit 0
        fi
        cat > "$MARKET_FILE" <<'JSON'
{
  "updated": "",
  "domain": "",
  "competitors": [],
  "market_signals": [],
  "gaps": [],
  "positioning": {
    "our_approach": "",
    "differentiation": "",
    "risk": ""
  }
}
JSON
        echo "created: $MARKET_FILE"
        ;;
    show)
        if [[ ! -f "$MARKET_FILE" ]]; then
            echo "no market-context.json — run 'market-scan.sh init' or '/research market'"
            exit 0
        fi
        echo "── market context ──"
        jq -r '
            "  updated: \(.updated // "never")",
            "  domain: \(.domain // "unset")",
            "  competitors: \(.competitors | length)",
            "",
            (.competitors[]? | "    \(.name // "?") — \(.category // "?") · \(.stage // "?") · \(.pricing // "?")\n      approach: \(.approach // "?")\n      strength: \(.strength // "?")\n      weakness: \(.weakness // "?")"),
            "",
            "  signals: \(.market_signals | length)",
            (.market_signals[]? | "    [\(.date // "?")] \(.signal // "?") (confidence: \(.confidence // "?"))"),
            "",
            "  gaps: \(.gaps | length)",
            (.gaps[]? | "    \(.gap // "?") — evidence: \(.evidence // "none")"),
            "",
            "  positioning:",
            "    ours: \(.positioning.our_approach // "unset")",
            "    diff: \(.positioning.differentiation // "unset")",
            "    risk: \(.positioning.risk // "unset")"
        ' "$MARKET_FILE" 2>/dev/null
        ;;
    add-competitor)
        cat <<'TEMPLATE'
── competitor entry template ──
Add to market-context.json .competitors[]:

{
  "name": "",
  "url": "",
  "category": "direct|adjacent|substitute",
  "stage": "pre-revenue|early|growth|mature",
  "pricing": "free|freemium|paid ($X/mo)|enterprise",
  "approach": "1-sentence: how they solve the problem",
  "strength": "their best advantage",
  "weakness": "their biggest gap",
  "evidence": "how you know this (URL, screenshot, user report)",
  "last_checked": "YYYY-MM-DD"
}
TEMPLATE
        ;;
    add-signal)
        cat <<'TEMPLATE'
── market signal template ──
Add to market-context.json .market_signals[]:

{
  "date": "YYYY-MM-DD",
  "signal": "what happened",
  "source": "URL or description",
  "source_tier": "T1|T2|T3|T4|T5",
  "confidence": "high|medium|low",
  "implication": "what this means for us"
}
TEMPLATE
        ;;
    age)
        if [[ ! -f "$MARKET_FILE" ]]; then
            echo "no market-context.json"
            exit 0
        fi
        UPDATED=$(jq -r '.updated // "never"' "$MARKET_FILE" 2>/dev/null)
        if [[ "$UPDATED" == "never" || -z "$UPDATED" ]]; then
            echo "  market data: never updated"
        else
            DAYS=$(( ($(date +%s) - $(date -j -f "%Y-%m-%d" "$UPDATED" +%s 2>/dev/null || echo "0")) / 86400 ))
            echo "  market data: $DAYS days old (updated: $UPDATED)"
            if [[ "$DAYS" -gt 14 ]]; then
                echo "  WARNING: stale — run /research market to refresh"
            fi
        fi
        COMP_COUNT=$(jq '.competitors | length' "$MARKET_FILE" 2>/dev/null || echo "0")
        echo "  competitors tracked: $COMP_COUNT"
        ;;
    *)
        echo "usage: market-scan.sh [init|show|add-competitor|add-signal|age]"
        ;;
esac
