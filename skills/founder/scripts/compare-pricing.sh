#!/bin/bash
# Compare pricing data from gtm-strategy.json against founder.yml pricing section
# Usage: bash scripts/compare-pricing.sh
# Output: pricing alignment report

set -euo pipefail

CACHE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/cache"
CONFIG="${CLAUDE_PROJECT_DIR:-.}/config/founder.yml"

echo "── pricing comparison ──"

# Check if pricing is set in founder.yml
if grep -q 'pricing:' "$CONFIG" 2>/dev/null; then
  echo "  founder.yml pricing:"
  grep -A5 'pricing:' "$CONFIG" | sed 's/^/    /'
else
  echo "  founder.yml: no pricing set"
fi

echo ""

# Check if gtm analysis exists
if [ -f "$CACHE_DIR/gtm-strategy.json" ]; then
  echo "  gtm analysis:"
  python3 -c "
import json, sys
try:
    d = json.load(open('$CACHE_DIR/gtm-strategy.json'))
    p = d.get('pricing', {})
    print(f'    model: {p.get(\"recommended_model\", \"none\")}')
    print(f'    price: {p.get(\"recommended_price\", \"none\")}')
    print(f'    metric: {p.get(\"value_metric\", \"none\")}')
    print(f'    competitors: {p.get(\"competitor_range\", \"none\")}')
    print(f'    analyzed: {d.get(\"analyzed_at\", \"unknown\")}')
except Exception as e:
    print(f'    error: {e}', file=sys.stderr)
" 2>&1
else
  echo "  gtm analysis: none (run /money price)"
fi

echo ""

# Check customer willingness-to-pay signals
if [ -f "$CACHE_DIR/customer-intel.json" ]; then
  echo "  customer pricing signals:"
  python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/customer-intel.json'))
    for t in d.get('themes', []):
        if any(w in t.get('theme','').lower() for w in ['price', 'cost', 'pay', 'free', 'expensive', 'cheap']):
            print(f'    · {t[\"theme\"]} ({t[\"signal_strength\"]})')
    if not any(any(w in t.get('theme','').lower() for w in ['price','cost','pay','free']) for t in d.get('themes',[])):
        print('    (no pricing-related themes found)')
except:
    print('    (parse error)')
" 2>&1
else
  echo "  customer signals: none (run /discover)"
fi
