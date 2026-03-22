#!/usr/bin/env bash
# compute-completion.sh — Calculate product completion % and version completion %.
# Used by: /plan, /founder, /roadmap
#
# Usage: bash bin/compute-completion.sh [eval-cache.json] [founder.yml] [roadmap.yml]
# Output:
#   product_completion: 62
#   version_completion: 45
#   features_scored: 5
#   total_weight: 22

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EVAL_CACHE="${1:-$PROJECT_DIR/.claude/cache/eval-cache.json}"
FOUNDER_YML="${2:-$PROJECT_DIR/config/founder.yml}"
ROADMAP_YML="${3:-$PROJECT_DIR/.claude/plans/roadmap.yml}"

if ! command -v python3 &>/dev/null; then
    echo "python3 required for completion computation" >&2
    exit 1
fi

if [[ ! -f "$EVAL_CACHE" ]]; then
    echo "no eval cache" >&2
    exit 1
fi

python3 << 'PYEOF'
import json, sys, re

eval_path = sys.argv[1] if len(sys.argv) > 1 else ""
founder_path = sys.argv[2] if len(sys.argv) > 2 else ""
roadmap_path = sys.argv[3] if len(sys.argv) > 3 else ""

# Read eval cache
cache = {}
try:
    with open(eval_path) as f:
        cache = json.load(f)
except:
    pass

# Parse weights from founder.yml
weights = {}
if founder_path:
    try:
        with open(founder_path) as f:
            content = f.read()
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
                m = re.match(r'^  (\w[\w-]*):', line)
                if m:
                    current_feature = m.group(1)
                m2 = re.match(r'^\s+weight:\s*(\d+)', line)
                if m2 and current_feature:
                    weights[current_feature] = int(m2.group(1))
                m3 = re.match(r'^\s+status:\s*killed', line)
                if m3 and current_feature:
                    weights.pop(current_feature, None)
                    current_feature = None
    except:
        pass

# Product completion = sum(eval_score × weight) / sum(weight × 100)
total_weighted_score = 0
total_weight = 0
features_scored = 0
for name, w in weights.items():
    data = cache.get(name, {})
    if isinstance(data, dict):
        score = data.get('score', 0)
        if isinstance(score, str):
            try: score = int(score)
            except: score = 0
        total_weighted_score += score * w
        total_weight += w * 100
        if score > 0:
            features_scored += 1

product_completion = round(total_weighted_score / total_weight * 100) if total_weight > 0 else 0

# Version completion from roadmap.yml
version_completion = 0
if roadmap_path:
    try:
        with open(roadmap_path) as f:
            content = f.read()
        # Count evidence items and their status
        evidence_total = 0
        evidence_done = 0
        for line in content.split('\n'):
            if 'status:' in line and ('proven' in line or 'partial' in line or 'todo' in line or 'disproven' in line):
                evidence_total += 1
                if 'proven' in line:
                    evidence_done += 1
                elif 'partial' in line:
                    evidence_done += 0.5
        version_completion = round(evidence_done / evidence_total * 100) if evidence_total > 0 else 0
    except:
        pass

print(f"product_completion: {product_completion}")
print(f"version_completion: {version_completion}")
print(f"features_scored: {features_scored}")
print(f"total_weight: {sum(weights.values())}")
PYEOF
