#!/usr/bin/env bash
# compute-bottleneck.sh — Find the bottleneck feature (lowest weighted score).
# Used by: /eval, /go, /plan, /founder, /strategy
#
# Usage: bash bin/compute-bottleneck.sh [eval-cache.json] [founder.yml]
# Output (TSV): feature_name \t score \t weight \t weighted_score \t weakest_dimension
#
# Reads eval-cache.json for per-feature scores and founder.yml for weights.
# Bottleneck = active feature with lowest (score × weight) product.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EVAL_CACHE="${1:-$PROJECT_DIR/.claude/cache/eval-cache.json}"
FOUNDER_YML="${2:-$PROJECT_DIR/config/founder.yml}"

if [[ ! -f "$EVAL_CACHE" ]]; then
    echo "no eval cache" >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "python3 required" >&2
    exit 1
fi

python3 << 'PYEOF'
import json, sys, re

eval_cache_path = sys.argv[1] if len(sys.argv) > 1 else ""
founder_yml_path = sys.argv[2] if len(sys.argv) > 2 else ""

# Read eval cache
try:
    with open(eval_cache_path or "") as f:
        cache = json.load(f)
except:
    print("no eval cache", file=sys.stderr)
    sys.exit(1)

# Parse weights from founder.yml (simple grep — avoids YAML dependency)
weights = {}
if founder_yml_path:
    try:
        with open(founder_yml_path) as f:
            content = f.read()
        # Find features section, extract name: ... weight: N patterns
        in_features = False
        current_feature = None
        for line in content.split('\n'):
            if line.strip().startswith('features:'):
                in_features = True
                continue
            if in_features and not line.startswith(' ') and line.strip() and not line.strip().startswith('#'):
                in_features = False
                continue
            if in_features:
                # Feature name (2-space indent, no further indent)
                m = re.match(r'^  (\w[\w-]*):', line)
                if m:
                    current_feature = m.group(1)
                # Weight field
                m2 = re.match(r'^\s+weight:\s*(\d+)', line)
                if m2 and current_feature:
                    weights[current_feature] = int(m2.group(1))
                # Skip killed features
                m3 = re.match(r'^\s+status:\s*killed', line)
                if m3 and current_feature:
                    weights.pop(current_feature, None)
                    current_feature = None
    except:
        pass

# Compute bottleneck
results = []
for name, data in cache.items():
    if isinstance(data, dict):
        score = data.get('score', data.get('pass', 0))
        if isinstance(score, str):
            try: score = int(score)
            except: continue
        weight = weights.get(name, 1)
        weighted = score * weight

        # Find weakest dimension
        d = data.get('delivery_score', 0) or 0
        c = data.get('craft_score', 0) or 0
        v = data.get('viability_score', 0) or 0
        dims = {'delivery': d, 'craft': c, 'viability': v}
        weakest_dim = min(dims, key=dims.get) if any(dims.values()) else 'unknown'

        results.append((name, score, weight, weighted, weakest_dim))

if not results:
    print("no features scored", file=sys.stderr)
    sys.exit(1)

# Sort by weighted score ascending — first result is the bottleneck
results.sort(key=lambda x: x[3])

for name, score, weight, weighted, dim in results:
    print(f"{name}\t{score}\t{weight}\t{weighted}\t{dim}")
PYEOF
