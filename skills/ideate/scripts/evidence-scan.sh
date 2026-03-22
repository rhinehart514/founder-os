#!/usr/bin/env bash
# evidence-scan.sh — Scans all project state for ideation evidence.
# Outputs structured JSON. Zero context cost — only output enters the conversation.
set -euo pipefail

PROJECT_DIR="${1:-.}"
FEATURE_FLAG=""
FEATURE_NAME=""
# Parse --feature flag
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --feature) FEATURE_NAME="$2"; FEATURE_FLAG="1"; shift 2 ;;
        *) shift ;;
    esac
done
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve FOUNDER_DIR — works in both plugin cache and repo root
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    # Walk up from scripts/ to skill root, then to repo root
    FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    # Verify — if bin/lib doesn't exist, try one more level
    [[ ! -d "$FOUNDER_DIR/bin" ]] && FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Check dependencies (soft — don't block if check-deps.sh missing)
if [[ -f "$FOUNDER_DIR/bin/lib/check-deps.sh" ]]; then
    source "$FOUNDER_DIR/bin/lib/check-deps.sh"
    require_cmd jq "brew install jq"
else
    command -v jq &>/dev/null || { echo "jq required: brew install jq" >&2; exit 1; }
fi

# --- Eval cache sub-scores ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "=== EVAL SCORES ==="
    jq -r 'to_entries[] | select(.value.score != null) | "\(.key): \(.value.score) (d:\(.value.delivery_score) c:\(.value.craft_score)) delta:\(.value.delta // "none")"' "$EVAL_CACHE" 2>/dev/null || echo "(parse error)"
    echo ""
    # Weakest feature
    WEAKEST=$(jq -r 'to_entries | map(select(.value.score != null)) | sort_by(.value.score) | .[0] | "\(.key) at \(.value.score)"' "$EVAL_CACHE" 2>/dev/null || echo "unknown")
    echo "BOTTLENECK: $WEAKEST"
    echo ""
fi

# --- Wrong predictions (highest signal) ---
PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    echo "=== WRONG PREDICTIONS (last 10) ==="
    tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" || $6 == "partial"' | tail -10 | while IFS=$'\t' read -r date pred evidence result correct update; do
        echo "  $date: $pred"
        [[ -n "$update" ]] && echo "    model update: $update"
    done
    WRONG_CT=$(tail -n +2 "$PRED_FILE" | awk -F'\t' '$6 == "no" || $6 == "partial"' | wc -l | tr -d ' ')
    echo "  ($WRONG_CT total wrong/partial predictions)"
    echo ""
fi

# --- Backlog clusters (3+ todos on same feature) ---
TODOS_FILE="$PROJECT_DIR/.claude/plans/todos.yml"
if [[ -f "$TODOS_FILE" ]]; then
    echo "=== BACKLOG CLUSTERS ==="
    { grep -E 'feature:|tag:' "$TODOS_FILE" 2>/dev/null || true; } | sed 's/.*: *//' | sort | uniq -c | sort -rn | head -5 | while read -r count tag; do
        [[ "$count" -ge 3 ]] && echo "  $tag: $count todos (cluster)"
        [[ "$count" -lt 3 ]] && echo "  $tag: $count todos"
    done
    echo ""
fi

# --- Thesis gaps (unproven evidence) ---
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
if [[ -f "$ROADMAP" ]]; then
    echo "=== UNPROVEN THESIS EVIDENCE ==="
    # Find current version's evidence items
    awk '/^  v[0-9]/{ver=$0} /evidence:/{if(ver ~ /status: active/ || ver ~ /status: testing/) in_ev=1; next} in_ev && /^    -/{print "  " $0; next} in_ev && /^  [^ ]/{in_ev=0}' "$ROADMAP" 2>/dev/null || echo "(parse error)"
    echo ""
fi

# --- Dead ends that might be worth retrying ---
LEARNINGS="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
[[ ! -f "$LEARNINGS" ]] && LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]]; then
    echo "=== DEAD ENDS ==="
    { awk '/^## Dead Ends/,/^## /{if(/^## / && !/Dead Ends/) exit; print}' "$LEARNINGS" 2>/dev/null || true; } | grep -E '^\s*-' | head -5 || true
    echo ""
    echo "=== UNKNOWN TERRITORY ==="
    { awk '/^## Unknown Territory/,/^## /{if(/^## / && !/Unknown/) exit; print}' "$LEARNINGS" 2>/dev/null || true; } | grep -E '^\s*-' | head -10 || true
    echo ""
fi

# --- Taste eval (visual/behavioral evidence) ---
TASTE_DIR="$PROJECT_DIR/.claude/evals/reports"
LATEST_TASTE=$(ls -t "$TASTE_DIR"/taste-*.json 2>/dev/null | head -1)
if [[ -n "$LATEST_TASTE" ]] && command -v jq &>/dev/null; then
    echo "=== TASTE EVAL ==="
    TASTE_DATE=$(jq -r '.date // "unknown"' "$LATEST_TASTE" 2>/dev/null)
    TASTE_OVERALL=$(jq -r '.overall // "?"' "$LATEST_TASTE" 2>/dev/null)
    TASTE_SLOP=$(jq -r '.slop_verdict // "unknown"' "$LATEST_TASTE" 2>/dev/null)
    echo "  date: $TASTE_DATE  overall: $TASTE_OVERALL  slop: $TASTE_SLOP"

    # Weak dimensions (< 55)
    echo "  weak dimensions:"
    jq -r '.dimensions | to_entries[] | select(.value.score < 55) | "    \(.key): \(.value.score)"' "$LATEST_TASTE" 2>/dev/null || true

    # Top issues
    echo "  top issues:"
    jq -r '.top_issues[]? | "    · \(.issue)"' "$LATEST_TASTE" 2>/dev/null | head -3
    echo ""
fi

# --- Product intelligence from taste (product-user fit) ---
if [[ -n "$LATEST_TASTE" ]] && command -v jq &>/dev/null; then
    PI_COUNT=$(jq '[.product_intelligence.opportunities[]?] | length' "$LATEST_TASTE" 2>/dev/null || echo "0")
    if [[ "$PI_COUNT" -gt 0 ]]; then
        echo "=== PRODUCT INTELLIGENCE ==="
        # Strong signals first
        jq -r '.product_intelligence.opportunities[]? | select(.signal_strength == "strong") | "  [STRONG] \(.type): \(.element) — \(.finding)\n    → \(.opportunity)"' "$LATEST_TASTE" 2>/dev/null || true
        # Then moderate
        jq -r '.product_intelligence.opportunities[]? | select(.signal_strength == "moderate") | "  [moderate] \(.type): \(.element) — \(.finding)\n    → \(.opportunity)"' "$LATEST_TASTE" 2>/dev/null || true
        # Verdict
        PI_VERDICT=$(jq -r '.product_intelligence.verdict // empty' "$LATEST_TASTE" 2>/dev/null)
        [[ -n "$PI_VERDICT" ]] && echo "  verdict: $PI_VERDICT"
        echo ""
    fi
fi

LATEST_FLOWS=$(ls -t "$TASTE_DIR"/flows-*.json 2>/dev/null | head -1)
if [[ -n "$LATEST_FLOWS" ]] && command -v jq &>/dev/null; then
    echo "=== FLOWS AUDIT ==="
    UNFIXED=$(jq '[.issues[]? | select(.fixed != true)] | length' "$LATEST_FLOWS" 2>/dev/null || echo "?")
    BLOCKERS=$(jq '[.issues[]? | select(.severity == "blocker" and (.fixed != true))] | length' "$LATEST_FLOWS" 2>/dev/null || echo "?")
    echo "  unfixed issues: $UNFIXED (blockers: $BLOCKERS)"
    jq -r '.issues[]? | select(.fixed != true) | "    [\(.severity)] \(.issue)"' "$LATEST_FLOWS" 2>/dev/null | head -5
    echo ""
fi

# --- Stale features (no score movement in 14+ days) ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo "=== STALE FEATURES (same delta) ==="
    jq -r 'to_entries[] | select(.value.delta == "same") | "\(.key): score \(.value.score) — no movement"' "$EVAL_CACHE" 2>/dev/null
    echo ""
fi

# --- Customer intel summary ---
CUST_INTEL="$PROJECT_DIR/.claude/cache/customer-intel.json"
if [[ -f "$CUST_INTEL" ]] && command -v jq &>/dev/null; then
    echo "=== CUSTOMER SIGNALS ==="
    jq -r '.demand_signals[]? // empty' "$CUST_INTEL" 2>/dev/null | head -5
    echo ""
fi

# --- Git activity (what's been worked on) ---
echo "=== RECENT WORK (last 20 commits) ==="
git -C "$PROJECT_DIR" log --oneline -20 2>/dev/null || echo "(not a git repo)"
echo ""

# --- Feature-focused deep scan (when --feature is set) ---
if [[ -n "$FEATURE_FLAG" && -n "$FEATURE_NAME" ]]; then
    echo "=== FEATURE DEEP SCAN: $FEATURE_NAME ==="

    # Per-feature eval sub-scores
    if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
        echo "  ▸ eval sub-scores"
        jq -r --arg f "$FEATURE_NAME" '
            to_entries[] | select(.key | ascii_downcase | contains($f | ascii_downcase)) |
            "    \(.key): score=\(.value.score) delivery=\(.value.delivery_score) craft=\(.value.craft_score) delta=\(.value.delta // "none")"
        ' "$EVAL_CACHE" 2>/dev/null || echo "    (no eval data for $FEATURE_NAME)"
        # Gaps if available
        jq -r --arg f "$FEATURE_NAME" '
            to_entries[] | select(.key | ascii_downcase | contains($f | ascii_downcase)) |
            .value.gaps[]? // empty | "    gap: \(.)"
        ' "$EVAL_CACHE" 2>/dev/null || true
    fi

    # Per-feature taste prescriptions
    if [[ -n "$LATEST_TASTE" ]] && command -v jq &>/dev/null; then
        echo "  ▸ taste prescriptions"
        jq -r '.dimensions | to_entries[] | select(.value.prescription != null) | "    \(.key) (\(.value.score)): rx: \(.value.prescription)"' "$LATEST_TASTE" 2>/dev/null || echo "    (no taste data)"
        echo "  ▸ taste top fixes"
        jq -r '.top_3_fixes[]? | "    \(.element) → \(.change) → \(.impact)"' "$LATEST_TASTE" 2>/dev/null || true
    fi

    # Per-feature flow issues
    if [[ -n "$LATEST_FLOWS" ]] && command -v jq &>/dev/null; then
        echo "  ▸ flow issues"
        jq -r '.issues[]? | select(.fixed != true) | "    [\(.severity)] \(.issue)"' "$LATEST_FLOWS" 2>/dev/null | head -10
        jq -r '.edge_cases | to_entries[] | select(.value.pass == false) | "    edge case: \(.key) — \(.value.detail)"' "$LATEST_FLOWS" 2>/dev/null || true
    fi

    # Per-feature backlog items
    if [[ -f "$TODOS_FILE" ]]; then
        echo "  ▸ backlog items"
        grep -B2 -A5 -i "$FEATURE_NAME" "$TODOS_FILE" 2>/dev/null | head -30 || echo "    (no backlog items)"
    fi

    # Per-feature predictions
    if [[ -f "$PRED_FILE" ]]; then
        echo "  ▸ predictions"
        grep -i "$FEATURE_NAME" "$PRED_FILE" 2>/dev/null | tail -5 || echo "    (no predictions)"
    fi

    # Per-feature git history
    echo "  ▸ recent commits"
    git -C "$PROJECT_DIR" log --oneline -10 --all --grep="$FEATURE_NAME" 2>/dev/null || echo "    (no commits)"

    # Per-feature assertions
    BELIEFS="$PROJECT_DIR/.claude/plans/beliefs.yml"
    [[ ! -f "$BELIEFS" ]] && BELIEFS="$PROJECT_DIR/config/beliefs.yml"
    if [[ -f "$BELIEFS" ]]; then
        echo "  ▸ assertions"
        grep -B1 -A3 -i "$FEATURE_NAME" "$BELIEFS" 2>/dev/null | head -20 || echo "    (no assertions)"
    fi

    echo ""
fi

echo "=== SCAN COMPLETE ==="
