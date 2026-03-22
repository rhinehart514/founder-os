#!/bin/bash
# Quick runway calculator from gtm-strategy.json
# Usage: bash scripts/runway-calc.sh [monthly_burn]
# If no argument, reads from gtm-strategy.json
# Output: breakeven analysis

set -euo pipefail

CACHE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/cache"
MONTHLY_BURN="${1:-0}"

echo "── runway calculator ──"

if [ "$MONTHLY_BURN" -eq 0 ] 2>/dev/null && [ -f "$CACHE_DIR/gtm-strategy.json" ]; then
  MONTHLY_BURN=$(python3 -c "
import json
try:
    d = json.load(open('$CACHE_DIR/gtm-strategy.json'))
    r = d.get('runway', {})
    burn = r.get('monthly_burn_estimate', '0')
    # Extract number from string like '$500' or '500'
    import re
    nums = re.findall(r'[\d.]+', str(burn))
    print(int(float(nums[0])) if nums else 0)
except:
    print(0)
" 2>&1)
fi

if [ "$MONTHLY_BURN" -eq 0 ] 2>/dev/null; then
  echo "  no burn data. Usage: bash scripts/runway-calc.sh 500"
  exit 0
fi

echo "  monthly burn: \$$MONTHLY_BURN"

# Read pricing if available
if [ -f "$CACHE_DIR/gtm-strategy.json" ]; then
  python3 -c "
import json, re
d = json.load(open('$CACHE_DIR/gtm-strategy.json'))
p = d.get('pricing', {})
price_str = p.get('recommended_price', '0')
nums = re.findall(r'[\d.]+', str(price_str))
price = float(nums[0]) if nums else 0

burn = $MONTHLY_BURN

if price > 0:
    breakeven_users = -(-burn // int(price))  # ceiling division
    print(f'  price/user: \${price:.0f}/mo')
    print(f'  breakeven: {breakeven_users} users')
    print()
    for users in [1, 5, 10, 25, 50, 100]:
        revenue = users * price
        net = revenue - burn
        status = '✓' if net >= 0 else '·'
        print(f'  {status} {users:>3} users → \${revenue:>6.0f}/mo → net \${net:>+7.0f}')
else:
    print('  no pricing data. Run /money price first.')
" 2>&1
else
  echo "  no gtm data. Run /money first."
fi
