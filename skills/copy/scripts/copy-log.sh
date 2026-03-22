#!/usr/bin/env bash
# Persistent copy history — what was written, when, for what purpose
# Usage:
#   bash scripts/copy-log.sh add "landing" "headline text" "preview text"
#   bash scripts/copy-log.sh list [type]
#   bash scripts/copy-log.sh stats
# Storage: ${CLAUDE_PLUGIN_DATA}/copy-history.json (persistent across upgrades)
set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/cache}"
HISTORY="$DATA_DIR/copy-history.json"

# Initialize if missing
if [ ! -f "$HISTORY" ]; then
    mkdir -p "$DATA_DIR"
    echo '{"entries": []}' > "$HISTORY"
fi

ACTION="${1:-stats}"

case "$ACTION" in
    add)
        TYPE="${2:-unknown}"
        HEADLINE="${3:-}"
        PREVIEW="${4:-}"
        DATE=$(date +%Y-%m-%d)

        python3 -c "
import json, sys

with open('$HISTORY') as f:
    data = json.load(f)

data['entries'].append({
    'date': '$DATE',
    'type': '$TYPE',
    'headline': '''${HEADLINE//\'/\\\'}''',
    'preview': '''${PREVIEW//\'/\\\'}'''[:60],
    'quality_gate': {}
})

with open('$HISTORY', 'w') as f:
    json.dump(data, f, indent=2)

print(f'  logged: {\"$TYPE\"} copy ({\"$DATE\"})')
" 2>&1
        ;;

    list)
        TYPE_FILTER="${2:-all}"
        echo "── copy history ──"
        echo ""
        python3 -c "
import json, sys

with open('$HISTORY') as f:
    data = json.load(f)

entries = data.get('entries', [])
if not entries:
    print('  no entries yet')
    sys.exit(0)

type_filter = '$TYPE_FILTER'
if type_filter != 'all':
    entries = [e for e in entries if e.get('type') == type_filter]

print(f'  {len(entries)} entries' + (f' (type: {type_filter})' if type_filter != 'all' else ''))
print()

for e in entries[-10:]:
    date = e.get('date', '?')
    etype = e.get('type', '?')
    headline = e.get('headline', '')[:50]
    print(f'  {date} · {etype}')
    if headline:
        print(f'    \"{headline}\"')
    print()
" 2>&1
        ;;

    stats)
        echo "── copy stats ──"
        echo ""
        python3 -c "
import json, sys

with open('$HISTORY') as f:
    data = json.load(f)

entries = data.get('entries', [])
if not entries:
    print('  no copy generated yet')
    sys.exit(0)

# Count by type
types = {}
for e in entries:
    t = e.get('type', 'unknown')
    types[t] = types.get(t, 0) + 1

print(f'  total: {len(entries)} pieces of copy')
print()
print('  by type:')
for t, count in sorted(types.items(), key=lambda x: -x[1]):
    print(f'    {t}: {count}')

# Last entry
last = entries[-1]
print()
print(f'  last: {last.get(\"date\", \"?\")} · {last.get(\"type\", \"?\")}')
headline = last.get('headline', '')[:50]
if headline:
    print(f'    \"{headline}\"')

# Quality gate stats
gated = [e for e in entries if e.get('quality_gate')]
if gated:
    all_checks = sum(len(e['quality_gate']) for e in gated)
    all_passed = sum(sum(1 for v in e['quality_gate'].values() if v) for e in gated)
    print(f'  quality: {all_passed}/{all_checks} checks passed across {len(gated)} gated entries')
" 2>&1
        ;;

    *)
        echo "Usage: copy-log.sh [add|list|stats] [args...]"
        echo "  add <type> <headline> <preview>  — log new copy"
        echo "  list [type]                       — show history"
        echo "  stats                             — summary statistics"
        exit 1
        ;;
esac
