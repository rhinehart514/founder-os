#!/usr/bin/env bash
# Outputs competitor pricing data from market-context.json
# Usage: bash scripts/pricing-compare.sh
# Output: competitor pricing landscape for positioning decisions
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
CONFIG="$PROJECT_DIR/config/founder.yml"

echo "── pricing comparison ──"
echo ""

# Current pricing from founder.yml
echo "  your pricing:"
if grep -q 'pricing:' "$CONFIG" 2>/dev/null; then
    grep -A5 'pricing:' "$CONFIG" | sed 's/^/    /'
else
    echo "    not set"
fi
echo ""

# Competitor data from market-context.json
echo "  competitor pricing:"
if [ -f "$CACHE_DIR/market-context.json" ]; then
    python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/market-context.json'))
    competitors = d.get('competitors', d.get('landscape', {}).get('competitors', []))

    if isinstance(competitors, list):
        for c in competitors:
            name = c.get('name', 'unknown')
            pricing = c.get('pricing', c.get('price', 'unknown'))
            model = c.get('model', c.get('pricing_model', ''))
            diff = c.get('differentiation', c.get('positioning', ''))
            print(f'    {name}:')
            print(f'      pricing: {pricing}')
            if model:
                print(f'      model: {model}')
            if diff:
                print(f'      positioning: {diff[:80]}')
            print()
    elif isinstance(competitors, dict):
        for name, data in competitors.items():
            pricing = data.get('pricing', data.get('price', 'unknown'))
            model = data.get('model', '')
            print(f'    {name}: {pricing} ({model})')
    else:
        print('    unexpected format')

except Exception as e:
    print(f'    error: {e}')
" 2>&1
else
    echo "    no market data (run /strategy market)"
fi

echo ""

# GTM analysis pricing recommendation
echo "  gtm recommendation:"
if [ -f "$CACHE_DIR/gtm-strategy.json" ]; then
    python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/gtm-strategy.json'))
    p = d.get('pricing', {})
    print(f'    model: {p.get(\"recommended_model\", \"none\")}')
    print(f'    price: {p.get(\"recommended_price\", \"none\")}')
    print(f'    metric: {p.get(\"value_metric\", \"none\")}')
    print(f'    range: {p.get(\"competitor_range\", \"none\")}')
    print(f'    analyzed: {d.get(\"analyzed_at\", \"unknown\")}')
except Exception as e:
    print(f'    error: {e}')
" 2>&1
else
    echo "    none (run /money price)"
fi

echo ""

# Customer willingness-to-pay signals
echo "  customer signals:"
if [ -f "$CACHE_DIR/customer-intel.json" ]; then
    python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/customer-intel.json'))
    found = False
    for t in d.get('themes', []):
        theme = t.get('theme', '').lower()
        if any(w in theme for w in ['price', 'cost', 'pay', 'free', 'expensive', 'cheap', 'worth', 'value']):
            print(f'    · {t[\"theme\"]} (strength: {t.get(\"signal_strength\", \"?\")})')
            found = True
    if not found:
        print('    no pricing-related themes')
except:
    print('    parse error')
" 2>&1
else
    echo "    no customer data (run /discover)"
fi
