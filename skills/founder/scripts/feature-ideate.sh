#!/usr/bin/env bash
# feature-ideate.sh — Gathers all context for a specific feature's improvement.
# Outputs structured evidence at zero context cost. Used by /feature [name] ideate.
# Usage: feature-ideate.sh [project-dir] [feature-name]
set -euo pipefail

PROJECT_DIR="${1:-.}"
FEATURE_NAME="${2:-}"

if [[ -z "$FEATURE_NAME" ]]; then
    echo "Usage: feature-ideate.sh [project-dir] [feature-name]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve FOUNDER_DIR
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    [[ ! -d "$FOUNDER_DIR/bin" ]] && FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Check jq
command -v jq &>/dev/null || { echo "jq required: brew install jq" >&2; exit 1; }

echo "◆ feature ideate context — $FEATURE_NAME"
echo ""

# --- Feature definition from founder.yml ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    echo "=== FEATURE DEFINITION ==="
    # Extract feature block (works for simple YAML)
    awk -v feat="$FEATURE_NAME" '
        /^  [a-zA-Z]/ { if (match($0, feat)) { in_feat=1 } else { in_feat=0 } }
        in_feat { print "  " $0 }
    ' "$FOUNDER_YML" 2>/dev/null || echo "  (not found in founder.yml)"
    echo ""
fi

# --- Eval sub-scores ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]]; then
    echo "=== EVAL SUB-SCORES ==="
    jq -r --arg f "$FEATURE_NAME" '
        to_entries[] | select(.key | ascii_downcase | contains($f | ascii_downcase)) |
        "  \(.key): score=\(.value.score) delivery=\(.value.delivery_score) craft=\(.value.craft_score) viability=\(.value.viability_score // "n/a") delta=\(.value.delta // "none")"
    ' "$EVAL_CACHE" 2>/dev/null || echo "  (no eval data)"

    # Gaps
    GAPS=$(jq -r --arg f "$FEATURE_NAME" '
        to_entries[] | select(.key | ascii_downcase | contains($f | ascii_downcase)) |
        .value.gaps[]? // empty
    ' "$EVAL_CACHE" 2>/dev/null || true)
    if [[ -n "$GAPS" ]]; then
        echo "  gaps:"
        echo "$GAPS" | while read -r gap; do echo "    · $gap"; done
    fi

    # Verdict
    jq -r --arg f "$FEATURE_NAME" '
        to_entries[] | select(.key | ascii_downcase | contains($f | ascii_downcase)) |
        .value.verdict[]? // empty | "  verdict: \(.)"
    ' "$EVAL_CACHE" 2>/dev/null || true
    echo ""
fi

# --- Rubric ---
RUBRIC="$PROJECT_DIR/.claude/cache/rubrics/$FEATURE_NAME.json"
if [[ -f "$RUBRIC" ]]; then
    echo "=== RUBRIC ==="
    jq -r 'to_entries[] | "  \(.key): \(.value)"' "$RUBRIC" 2>/dev/null || echo "  (parse error)"
    echo ""
fi

# --- Taste prescriptions ---
TASTE_DIR="$PROJECT_DIR/.claude/evals/reports"
LATEST_TASTE=$(ls -t "$TASTE_DIR"/taste-*.json 2>/dev/null | head -1)
if [[ -n "${LATEST_TASTE:-}" ]]; then
    echo "=== TASTE DATA ==="
    TASTE_DATE=$(jq -r '.date // "unknown"' "$LATEST_TASTE" 2>/dev/null)
    TASTE_OVERALL=$(jq -r '.overall // "?"' "$LATEST_TASTE" 2>/dev/null)
    echo "  date: $TASTE_DATE  overall: $TASTE_OVERALL"

    # Weak dimensions
    echo "  weak dimensions (< 55):"
    jq -r '.dimensions | to_entries[] | select(.value.score < 55) | "    \(.key): \(.value.score) — rx: \(.value.prescription // "none")"' "$LATEST_TASTE" 2>/dev/null || true

    # Top fixes
    echo "  top fixes:"
    jq -r '.top_3_fixes[]? | "    \(.element) → \(.change) → \(.impact)"' "$LATEST_TASTE" 2>/dev/null || true

    # Top issues
    echo "  top issues:"
    jq -r '.top_issues[]? | "    · \(.issue)"' "$LATEST_TASTE" 2>/dev/null | head -5
    echo ""
fi

# --- Flow issues ---
LATEST_FLOWS=$(ls -t "$TASTE_DIR"/flows-*.json 2>/dev/null | head -1)
if [[ -n "${LATEST_FLOWS:-}" ]]; then
    echo "=== FLOW ISSUES ==="
    UNFIXED=$(jq '[.issues[]? | select(.fixed != true)] | length' "$LATEST_FLOWS" 2>/dev/null || echo "?")
    echo "  unfixed: $UNFIXED"
    jq -r '.issues[]? | select(.fixed != true) | "    [\(.severity)] \(.issue)"' "$LATEST_FLOWS" 2>/dev/null | head -10
    echo ""
fi

# --- Customer intel ---
CUST_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
if [[ -f "$CUST_INTEL" ]]; then
    echo "=== CUSTOMER SIGNALS ==="
    jq -r '.demand_signals[]? // empty' "$CUST_INTEL" 2>/dev/null | head -5
    jq -r '.pain_points[]? // empty' "$CUST_INTEL" 2>/dev/null | head -5
    echo ""
fi

# --- Market context ---
MARKET="$PROJECT_DIR/.claude/cache/market-context.json"
if [[ -f "$MARKET" ]]; then
    echo "=== MARKET CONTEXT ==="
    jq -r '.competitors[]? | "  \(.name): \(.strength // "n/a")"' "$MARKET" 2>/dev/null | head -5
    echo ""
fi

# --- Feature-specific research cache ---
FEAT_RESEARCH="$PROJECT_DIR/.claude/cache/feature-research-$FEATURE_NAME.json"
if [[ -f "$FEAT_RESEARCH" ]]; then
    echo "=== PAST FEATURE RESEARCH ==="
    jq -r '.' "$FEAT_RESEARCH" 2>/dev/null | head -30
    echo ""
fi

# --- Backlog items for this feature ---
TODOS_FILE="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS_FILE" ]]; then
    echo "=== BACKLOG ITEMS ==="
    grep -B2 -A5 -i "$FEATURE_NAME" "$TODOS_FILE" 2>/dev/null | head -30 || echo "  (none)"
    echo ""
fi

# --- Predictions about this feature ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    echo "=== PREDICTIONS ==="
    grep -i "$FEATURE_NAME" "$PRED_FILE" 2>/dev/null | tail -5 || echo "  (none)"
    echo ""
fi

# --- Past ideation for this feature ---
IDEA_LOG="${CLAUDE_PLUGIN_DATA:-$PROJECT_DIR/.claude/cache}/ideation-log.jsonl"
if [[ -f "$IDEA_LOG" ]]; then
    echo "=== PAST IDEAS ==="
    grep -i "$FEATURE_NAME" "$IDEA_LOG" 2>/dev/null | tail -5 || echo "  (none)"
    echo ""
fi

# --- Assertions for this feature ---
BELIEFS="$PROJECT_DIR/.claude/plans/beliefs.yml"
[[ ! -f "$BELIEFS" ]] && BELIEFS="$PROJECT_DIR/config/beliefs.yml"
if [[ -f "$BELIEFS" ]]; then
    echo "=== ASSERTIONS ==="
    grep -B1 -A3 -i "$FEATURE_NAME" "$BELIEFS" 2>/dev/null | head -20 || echo "  (none)"
    echo ""
fi

# --- Dead ends related to this feature ---
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    DEAD=$(awk '/^## Dead Ends/,/^## /{if(/^## / && !/Dead Ends/) exit; print}' "$LEARNINGS" 2>/dev/null | grep -i "$FEATURE_NAME" || true)
    if [[ -n "$DEAD" ]]; then
        echo "=== DEAD ENDS (this feature) ==="
        echo "$DEAD"
        echo ""
    fi
fi

# --- Recent commits touching this feature ---
echo "=== RECENT COMMITS ==="
# Get code paths from founder.yml
if [[ -f "$FOUNDER_YML" ]]; then
    CODE_PATHS=$(awk -v feat="$FEATURE_NAME" '
        /^  [a-zA-Z]/ { if (match($0, feat)) in_feat=1; else in_feat=0 }
        in_feat && /code:/ { gsub(/.*code: *\[?/, ""); gsub(/\].*/, ""); gsub(/"/, ""); gsub(/, */, "\n"); print }
    ' "$FOUNDER_YML" 2>/dev/null || true)

    if [[ -n "$CODE_PATHS" ]]; then
        echo "$CODE_PATHS" | while read -r path; do
            [[ -z "$path" ]] && continue
            git -C "$PROJECT_DIR" log --oneline -5 -- "$path" 2>/dev/null || true
        done | sort -u | head -10
    else
        git -C "$PROJECT_DIR" log --oneline -5 --all --grep="$FEATURE_NAME" 2>/dev/null || echo "  (no commits)"
    fi
else
    git -C "$PROJECT_DIR" log --oneline -5 --all --grep="$FEATURE_NAME" 2>/dev/null || echo "  (no commits)"
fi
echo ""

echo "=== SCAN COMPLETE ==="
