#!/usr/bin/env bash
# feature-health.sh — Per-feature health: score trend, assertion pass rate, todo count, last touched.
# Usage: feature-health.sh [feature-name] [project-dir]
set -euo pipefail

FEATURE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${2:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

if [[ -z "$FEATURE" ]]; then
    echo "Usage: feature-health.sh <feature-name> [project-dir]"
    exit 1
fi

EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
BELIEFS="$PROJECT_DIR/beliefs.yml"
TODOS="$PROJECT_DIR/.claude/plans/todos.yml"
RUBRIC="$PROJECT_DIR/.claude/cache/rubrics/${FEATURE}.json"

echo "=== FEATURE HEALTH: $FEATURE ==="
echo ""

# --- Eval scores ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    ENTRY=$(jq -r --arg f "$FEATURE" '.[$f] // empty' "$EVAL_CACHE" 2>/dev/null)
    if [[ -n "$ENTRY" ]]; then
        echo "SCORES"
        echo "$ENTRY" | jq -r '"  score: \(.score // "--")"'
        echo "$ENTRY" | jq -r '"  delivery: \(.delivery_score // "--")"'
        echo "$ENTRY" | jq -r '"  craft: \(.craft_score // "--")"'
        echo "$ENTRY" | jq -r '"  viability: \(.viability_score // "--")"'
        echo "$ENTRY" | jq -r '"  delta: \(.delta // "--")"'
        # Weakest dimension
        echo "$ENTRY" | jq -r '
            [["delivery", (.delivery_score // 999)],
             ["craft", (.craft_score // 999)],
             ["viability", (.viability_score // 999)]]
            | sort_by(.[1]) | .[0]
            | "  weakest: \(.[0]) (\(.[1]))"'
    else
        echo "SCORES"
        echo "  no eval data — run: founder eval . --feature $FEATURE --fresh"
    fi
else
    echo "SCORES"
    echo "  no eval cache"
fi
echo ""

# --- Assertion pass rate ---
echo "ASSERTIONS"
if [[ -f "$BELIEFS" ]]; then
    # Count assertions tagged with this feature
    TOTAL=$(grep -c "feature:.*$FEATURE" "$BELIEFS" 2>/dev/null || echo "0")
    if [[ "$TOTAL" -gt 0 ]]; then
        # Run eval for this feature's assertions
        PASS_OUTPUT=$(cd "$PROJECT_DIR" && bash bin/eval.sh 2>/dev/null | grep -c "^PASS" || echo "0")
        echo "  $TOTAL assertions found (run founder eval . for pass/fail breakdown)"
    else
        echo "  0 assertions tagged with feature:$FEATURE"
        echo "  suggestion: run /assert to add beliefs for this feature"
    fi
else
    echo "  no beliefs.yml — run /assert to create"
fi
echo ""

# --- Todo count ---
echo "TODOS"
if [[ -f "$TODOS" ]]; then
    TODO_COUNT=$(grep -c "$FEATURE" "$TODOS" 2>/dev/null || true)
    TODO_COUNT=${TODO_COUNT:-0}
    TODO_COUNT=$(echo "$TODO_COUNT" | tr -d '[:space:]')
    DONE_COUNT=$(grep -A2 "$FEATURE" "$TODOS" 2>/dev/null | grep -c "status: done" 2>/dev/null || true)
    DONE_COUNT=${DONE_COUNT:-0}
    DONE_COUNT=$(echo "$DONE_COUNT" | tr -d '[:space:]')
    ACTIVE_COUNT=$(( ${TODO_COUNT:-0} - ${DONE_COUNT:-0} ))
    echo "  $ACTIVE_COUNT active todos mentioning $FEATURE ($DONE_COUNT done)"
else
    echo "  no todos.yml"
fi
echo ""

# --- Last touched (git) ---
echo "LAST TOUCHED"
# Get code paths from founder.yml
CODE_PATHS=$(python3 -c "
import re
in_feature = False
with open('$FOUNDER_YML') as f:
    for line in f:
        s = line.rstrip()
        if s.strip() == '$FEATURE:':
            in_feature = True
            continue
        if in_feature:
            if s.startswith('    code:'):
                # Extract paths from [\"path1\", \"path2\"]
                paths = re.findall(r'\"([^\"]+)\"', s)
                for p in paths:
                    print(p)
                break
            if s and not s.startswith('    ') and not s.startswith('#'):
                break
" 2>/dev/null || echo "")

if [[ -n "$CODE_PATHS" ]]; then
    LATEST=""
    while IFS= read -r codepath; do
        if [[ -e "$PROJECT_DIR/$codepath" ]]; then
            LAST_COMMIT=$(cd "$PROJECT_DIR" && git log -1 --format="%ar|%s" -- "$codepath" 2>/dev/null || echo "")
            if [[ -n "$LAST_COMMIT" ]]; then
                echo "  $codepath: $LAST_COMMIT"
                LATEST="$LAST_COMMIT"
            fi
        fi
    done <<< "$CODE_PATHS"
    if [[ -z "$LATEST" ]]; then
        echo "  no git history for code paths"
    fi
else
    echo "  no code paths defined in founder.yml"
fi
echo ""

# --- Rubric (if exists) ---
if [[ -f "$RUBRIC" ]]; then
    echo "RUBRIC"
    jq -r 'to_entries[] | "  \(.key): \(.value)"' "$RUBRIC" 2>/dev/null || echo "  (parse error)"
    echo ""
fi

# --- Dependencies ---
echo "DEPENDENCIES"
DEPS=$(python3 -c "
import re
in_feature = False
with open('$FOUNDER_YML') as f:
    for line in f:
        s = line.rstrip()
        if s.strip() == '$FEATURE:':
            in_feature = True
            continue
        if in_feature:
            if 'depends_on:' in s:
                deps = re.findall(r'[a-zA-Z0-9_-]+', s.split('depends_on:')[1])
                for d in deps:
                    print(d)
                break
            if s and not s.startswith('    ') and not s.startswith('#'):
                break
" 2>/dev/null || echo "")

if [[ -n "$DEPS" ]]; then
    echo "  depends on: $DEPS"
else
    echo "  depends on: (none)"
fi

# Find reverse deps (who depends on this feature)
REVERSE_DEPS=$(grep -B5 "depends_on:.*$FEATURE" "$FOUNDER_YML" 2>/dev/null | grep -oP '^\s{2}([a-zA-Z0-9_-]+):' | sed 's/://;s/^ *//' || echo "")
if [[ -n "$REVERSE_DEPS" ]]; then
    echo "  depended on by: $REVERSE_DEPS"
else
    echo "  depended on by: (none)"
fi
