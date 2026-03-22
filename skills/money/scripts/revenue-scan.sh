#!/usr/bin/env bash
# Reads pricing config, calculates MRR/ARR estimates, runway
# Usage: bash scripts/revenue-scan.sh
# Output: structured financial snapshot from project state
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
CONFIG="$PROJECT_DIR/config/founder.yml"

echo "── revenue scan ──"
echo ""

# 1. Pricing from founder.yml
echo "  pricing:"
if grep -q 'pricing:' "$CONFIG" 2>/dev/null; then
    MODEL=$(grep -A10 'pricing:' "$CONFIG" 2>/dev/null | grep 'model:' | head -1 | sed 's/.*model: *//' | tr -d '"' || echo "none")
    PRICE=$(grep -A10 'pricing:' "$CONFIG" 2>/dev/null | grep 'price:' | head -1 | sed 's/.*price: *//' | tr -d '"' || echo "0")
    METRIC=$(grep -A10 'pricing:' "$CONFIG" 2>/dev/null | grep 'metric:' | head -1 | sed 's/.*metric: *//' | tr -d '"' || echo "none")
    echo "    model: $MODEL"
    echo "    price: $PRICE"
    echo "    metric: $METRIC"
else
    echo "    not set (run /money price)"
    MODEL="none"
    PRICE="0"
fi

echo ""

# 2. Feature maturity from eval-cache (only count features 50+)
echo "  product maturity:"
if [ -f "$CACHE_DIR/eval-cache.json" ]; then
    python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/eval-cache.json'))
    features = d.get('features', {})
    total = len(features)
    mature = sum(1 for f in features.values() if f.get('score', 0) >= 50)
    avg = sum(f.get('score', 0) for f in features.values()) / max(total, 1)
    print(f'    features: {total} total, {mature} at 50+ (GTM-ready)')
    print(f'    avg score: {avg:.0f}')
except Exception as e:
    print(f'    error: {e}')
" 2>&1
else
    echo "    no eval data (run founder eval .)"
fi

echo ""

# 3. MRR/ARR estimates
echo "  revenue estimates:"
if [ -f "$CACHE_DIR/gtm-strategy.json" ]; then
    python3 -c "
import json, re
try:
    d = json.load(open('$CACHE_DIR/gtm-strategy.json'))
    p = d.get('pricing', {})
    price_str = str(p.get('recommended_price', '0'))
    nums = re.findall(r'[\d.]+', price_str)
    price = float(nums[0]) if nums else 0

    r = d.get('runway', {})
    burn_str = str(r.get('monthly_burn_estimate', '0'))
    burn_nums = re.findall(r'[\d.]+', burn_str)
    burn = float(burn_nums[0]) if burn_nums else 0

    if price > 0:
        print(f'    price/user: \${price:.0f}/mo')
        for n in [1, 5, 10, 25, 50, 100]:
            mrr = n * price
            arr = mrr * 12
            net = mrr - burn
            marker = '✓' if net >= 0 else '·'
            print(f'    {marker} {n:>3} users: MRR \${mrr:>6,.0f}  ARR \${arr:>8,.0f}  net \${net:>+7,.0f}/mo')
    else:
        print('    no price set — estimates unavailable')

    if burn > 0:
        print(f'    monthly burn: \${burn:,.0f}')
        if price > 0:
            breakeven = int(-(-burn // price))
            print(f'    breakeven: {breakeven} users')
    else:
        print('    burn: unknown')

except Exception as e:
    print(f'    error: {e}')
" 2>&1
else
    echo "    no gtm data (run /money model)"
fi

echo ""

# 4. Money history
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$CACHE_DIR}"
HISTORY="$DATA_DIR/money-history.json"
if [ -f "$HISTORY" ]; then
    ENTRIES=$(python3 -c "import json; print(len(json.load(open('$HISTORY')).get('entries', [])))" 2>/dev/null || echo "0")
    LAST=$(python3 -c "import json; e=json.load(open('$HISTORY')).get('entries',[]); print(e[-1]['date'] if e else 'none')" 2>/dev/null || echo "unknown")
    echo "  history: $ENTRIES entries, last: $LAST"
else
    echo "  history: none yet"
fi
