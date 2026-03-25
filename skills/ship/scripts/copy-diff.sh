#!/bin/bash
# Compare current copy against previous versions
# Reads from copy-history.json stored in plugin data dir
# Usage: bash scripts/copy-diff.sh [type]
# Output: shows what changed since last copy generation

set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/cache}"
HISTORY="$DATA_DIR/copy-history.json"
TYPE="${1:-all}"

echo "── copy history ──"

if [ ! -f "$HISTORY" ]; then
  echo "  no history yet. First /copy run will create it."
  exit 0
fi

python3 -c "
import json, sys

try:
    with open('$HISTORY') as f:
        history = json.load(f)

    entries = history.get('entries', [])
    if not entries:
        print('  no entries yet')
        sys.exit(0)

    type_filter = '$TYPE'
    if type_filter != 'all':
        entries = [e for e in entries if e.get('type') == type_filter]

    print(f'  {len(entries)} entries')
    print()

    # Show last 5
    for e in entries[-5:]:
        print(f'  {e.get(\"date\", \"?\")} · {e.get(\"type\", \"?\")}')
        headline = e.get('headline', e.get('preview', ''))[:60]
        if headline:
            print(f'    \"{headline}\"')

        quality = e.get('quality_gate', {})
        passed = sum(1 for v in quality.values() if v)
        total = len(quality)
        if total > 0:
            print(f'    quality: {passed}/{total} checks passed')
        print()

    # Show iteration count by type
    types = {}
    for e in history.get('entries', []):
        t = e.get('type', 'unknown')
        types[t] = types.get(t, 0) + 1

    print('  by type:')
    for t, count in sorted(types.items(), key=lambda x: -x[1]):
        print(f'    {t}: {count} iterations')

except Exception as e:
    print(f'  error: {e}', file=sys.stderr)
" 2>&1
