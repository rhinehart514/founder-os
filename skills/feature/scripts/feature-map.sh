#!/usr/bin/env bash
# feature-map.sh — Show all features with scores, weights, dependencies, maturity.
# Reads eval-cache.json + founder.yml. Outputs structured text for Claude to format.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

# --- Feature list from founder.yml ---
if [[ ! -f "$FOUNDER_YML" ]]; then
    echo "ERROR: no config/founder.yml found"
    exit 1
fi

# Use python for reliable YAML+JSON parsing
python3 << PYEOF
import json, sys, os, re

founder_path = "$FOUNDER_YML"
eval_path = "$EVAL_CACHE"

# --- Parse founder.yml (lightweight, no pyyaml dependency) ---
features = {}
current_feature = None
in_features = False

with open(founder_path) as f:
    for line in f:
        stripped = line.rstrip()
        # Detect features: section
        if stripped == "features:":
            in_features = True
            continue
        if in_features:
            # New top-level section (not indented under features)
            if stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
                in_features = False
                continue
            # Feature name (2-space indent, ends with colon)
            m = re.match(r'^  ([a-zA-Z0-9_-]+):\s*$', stripped)
            if m:
                current_feature = m.group(1)
                features[current_feature] = {}
                continue
            # Feature fields (4-space indent)
            if current_feature:
                fm = re.match(r'^    ([a-zA-Z_-]+):\s*(.+)$', stripped)
                if fm:
                    key = fm.group(1)
                    val = fm.group(2).strip().strip('"').strip("'")
                    # Handle list values like depends_on: [scoring]
                    if val.startswith('[') and val.endswith(']'):
                        val = [v.strip().strip('"').strip("'") for v in val[1:-1].split(',') if v.strip()]
                    features[current_feature][key] = val

# --- Parse eval-cache.json ---
eval_data = {}
if os.path.exists(eval_path):
    try:
        with open(eval_path) as f:
            eval_data = json.load(f)
    except:
        pass

# --- Output ---
print("=== FEATURE MAP ===")
print("")

active_features = {k: v for k, v in features.items()
                   if v.get('status', 'active') in ('active', 'proven')}

if not active_features:
    print("  no active features defined")
    sys.exit(0)

# Sort by score (lowest first = bottleneck at top)
def get_score(name):
    e = eval_data.get(name, {})
    return e.get('score', 0) if isinstance(e, dict) else 0

sorted_features = sorted(active_features.keys(), key=get_score)

for name in sorted_features:
    f = active_features[name]
    e = eval_data.get(name, {})

    score = e.get('score', '--') if isinstance(e, dict) else '--'
    d_score = e.get('delivery_score', '--') if isinstance(e, dict) else '--'
    c_score = e.get('craft_score', '--') if isinstance(e, dict) else '--'
    v_score = e.get('viability_score', '--') if isinstance(e, dict) else '--'
    delta = e.get('delta', None) if isinstance(e, dict) else None

    weight = f.get('weight', '1')
    status = f.get('status', 'active')
    delivers = f.get('delivers', '?')
    target = f.get('for', '?')
    deps = f.get('depends_on', [])
    if isinstance(deps, str):
        deps = [deps]

    # Maturity from score
    mat = "no-data"
    if isinstance(score, (int, float)):
        s = int(score)
        if s >= 90: mat = "proven"
        elif s >= 70: mat = "polished"
        elif s >= 50: mat = "working"
        elif s >= 30: mat = "building"
        else: mat = "planned"

    # Delta display
    delta_str = ""
    if delta is not None and delta != "none":
        try:
            d = int(delta)
            if d > 3: delta_str = f" ↑{d}"
            elif d < -3: delta_str = f" ↓{abs(d)}"
            else: delta_str = " —"
        except:
            delta_str = ""

    # Dependency display
    dep_str = f" depends_on:[{','.join(deps)}]" if deps else ""

    print(f"FEATURE\t{name}\t{score}\tw:{weight}\t{mat}\t(d:{d_score} c:{c_score} v:{v_score}){delta_str}\t\"{delivers}\"\tfor:\"{target}\"{dep_str}")

# --- Bottleneck ---
print("")
# Bottleneck = lowest score among highest-weight active features
best_weight = 0
for name in active_features:
    w = int(active_features[name].get('weight', 1))
    if w > best_weight:
        best_weight = w

high_weight = [n for n in active_features if int(active_features[n].get('weight', 1)) >= best_weight]
bottleneck = None
bottleneck_score = 999
bottleneck_dim = ""

for name in high_weight:
    e = eval_data.get(name, {})
    if isinstance(e, dict) and e.get('score') is not None:
        s = e['score']
        if s < bottleneck_score:
            bottleneck_score = s
            bottleneck = name
            # Find weakest dimension
            dims = {'delivery': e.get('delivery_score', 999),
                    'craft': e.get('craft_score', 999),
                    'viability': e.get('viability_score', 999)}
            bottleneck_dim = min(dims, key=dims.get)

if bottleneck:
    print(f"BOTTLENECK\t{bottleneck}\t{bottleneck_score}\tw:{best_weight}\t{bottleneck_dim}")
else:
    print("BOTTLENECK\tnone\t--\t--\t--")

# --- Dependency warnings ---
# Check for blocked features (depends on something scoring <30)
print("")
for name in active_features:
    deps = active_features[name].get('depends_on', [])
    if isinstance(deps, str):
        deps = [deps]
    for dep in deps:
        dep_eval = eval_data.get(dep, {})
        dep_score = dep_eval.get('score', None) if isinstance(dep_eval, dict) else None
        if dep_score is not None and dep_score < 30:
            print(f"BLOCKED\t{name}\tby {dep} (score:{dep_score})")

PYEOF
