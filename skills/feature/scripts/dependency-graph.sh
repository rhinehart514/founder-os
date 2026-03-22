#!/usr/bin/env bash
# dependency-graph.sh — Show feature dependency chain, identify blocked features.
# Outputs: dependency tree, blocked features, orphans (no deps and not depended on).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

if [[ ! -f "$FOUNDER_YML" ]]; then
    echo "ERROR: no config/founder.yml"
    exit 1
fi

python3 << PYEOF
import json, re, os, sys

founder_path = "$FOUNDER_YML"
eval_path = "$EVAL_CACHE"

# --- Parse features from founder.yml ---
features = {}
current_feature = None
in_features = False

with open(founder_path) as f:
    for line in f:
        stripped = line.rstrip()
        if stripped == "features:":
            in_features = True
            continue
        if in_features:
            if stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
                in_features = False
                continue
            m = re.match(r'^  ([a-zA-Z0-9_-]+):\s*$', stripped)
            if m:
                current_feature = m.group(1)
                features[current_feature] = {'depends_on': [], 'status': 'active', 'weight': '1'}
                continue
            if current_feature:
                fm = re.match(r'^    ([a-zA-Z_-]+):\s*(.+)$', stripped)
                if fm:
                    key = fm.group(1)
                    val = fm.group(2).strip().strip('"').strip("'")
                    if key == 'depends_on':
                        val = [v.strip().strip('"').strip("'") for v in val.strip('[]').split(',') if v.strip()]
                    features[current_feature][key] = val

# Filter to active/proven
active = {k: v for k, v in features.items() if v.get('status', 'active') in ('active', 'proven')}

# --- Parse eval cache ---
eval_data = {}
if os.path.exists(eval_path):
    try:
        with open(eval_path) as f:
            eval_data = json.load(f)
    except:
        pass

print("=== DEPENDENCY GRAPH ===")
print("")

# --- Build adjacency ---
# Find roots (no dependencies)
roots = [n for n in active if not active[n].get('depends_on')]
has_dependents = set()
for n in active:
    deps = active[n].get('depends_on', [])
    if isinstance(deps, str):
        deps = [deps]
    for d in deps:
        has_dependents.add(d)

# --- Print tree ---
def print_tree(name, depth=0, visited=None):
    if visited is None:
        visited = set()
    if name in visited:
        print(f"{'  ' * depth}↻ {name} (cycle)")
        return
    visited.add(name)

    e = eval_data.get(name, {})
    score = e.get('score', '--') if isinstance(e, dict) else '--'
    weight = active.get(name, {}).get('weight', '?')

    # Maturity
    mat = "no-data"
    if isinstance(score, (int, float)):
        s = int(score)
        if s >= 90: mat = "proven"
        elif s >= 70: mat = "polished"
        elif s >= 50: mat = "working"
        elif s >= 30: mat = "building"
        else: mat = "planned"

    prefix = "  " * depth
    print(f"{prefix}{'└─ ' if depth > 0 else ''}{name}  score:{score}  w:{weight}  ({mat})")

    # Find children (features that depend on this one)
    children = [n for n in active if name in (active[n].get('depends_on') or [])]
    for child in sorted(children):
        print_tree(child, depth + 1, visited.copy())

print("TREE (root → dependents)")
if roots:
    for root in sorted(roots):
        print_tree(root)
        print("")
else:
    print("  (no root features — possible cycle)")
    print("")

# --- Blocked features ---
print("BLOCKED FEATURES")
blocked = []
for name in active:
    deps = active[name].get('depends_on', [])
    if isinstance(deps, str):
        deps = [deps]
    for dep in deps:
        dep_eval = eval_data.get(dep, {})
        dep_score = dep_eval.get('score', None) if isinstance(dep_eval, dict) else None
        if dep_score is not None and dep_score < 30:
            blocked.append((name, dep, dep_score))

if blocked:
    for name, dep, dep_score in blocked:
        print(f"  {name} blocked by {dep} (score:{dep_score} < 30)")
else:
    print("  (none)")
print("")

# --- Orphans (not depended on by anything, and no deps of their own) ---
print("ORPHANS (no dependency connections)")
orphans = [n for n in active if n not in has_dependents and not active[n].get('depends_on')]
if orphans:
    for o in sorted(orphans):
        e = eval_data.get(o, {})
        score = e.get('score', '--') if isinstance(e, dict) else '--'
        print(f"  {o}  score:{score}")
else:
    print("  (none)")
print("")

# --- Cycle detection ---
print("CYCLES")
def find_cycles():
    visited = set()
    path = []
    cycles = []

    def dfs(node):
        if node in path:
            cycle_start = path.index(node)
            cycles.append(path[cycle_start:] + [node])
            return
        if node in visited:
            return
        path.append(node)
        deps = active.get(node, {}).get('depends_on', [])
        if isinstance(deps, str):
            deps = [deps]
        for dep in deps:
            if dep in active:
                dfs(dep)
        path.pop()
        visited.add(node)

    for n in active:
        dfs(n)
    return cycles

cycles = find_cycles()
if cycles:
    for c in cycles:
        print(f"  {'→'.join(c)}")
else:
    print("  (none)")

PYEOF
