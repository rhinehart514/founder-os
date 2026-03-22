#!/usr/bin/env bash
# bottleneck-report.sh — Formatted bottleneck report for /plan.
# Shows bottleneck feature, sub-score breakdown, completion, and delta trends.
# Usage: bash scripts/bottleneck-report.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== BOTTLENECK REPORT ==="
echo ""

# --- Primary bottleneck ---
_bn_err=$(mktemp)
RESULT=$("$FOUNDER_DIR/bin/compute-bottleneck.sh" 2>"$_bn_err") || true
_bn_stderr=$(cat "$_bn_err")
rm -f "$_bn_err"
if [[ -z "$RESULT" ]]; then
    if [[ "$_bn_stderr" == *"no eval cache"* || "$_bn_stderr" == *"no features scored"* ]]; then
        echo "  no eval data — run founder eval . first"
    elif [[ "$_bn_stderr" == *"python3 required"* ]]; then
        echo "  error: python3 not found — install python3 to compute bottleneck"
    elif [[ -n "$_bn_stderr" ]]; then
        echo "  error: compute-bottleneck.sh crashed:"
        echo "$_bn_stderr" | head -5 | sed 's/^/    /'
    else
        echo "  no eval data — run founder eval . first"
    fi
    echo "=== REPORT COMPLETE ==="
    exit 0
fi

# First line is the bottleneck
BOTTLENECK=$(echo "$RESULT" | head -1)
NAME=$(echo "$BOTTLENECK" | cut -f1)
SCORE=$(echo "$BOTTLENECK" | cut -f2)
WEIGHT=$(echo "$BOTTLENECK" | cut -f3)
DIM=$(echo "$BOTTLENECK" | cut -f5)

echo "▸ bottleneck: $NAME"
# Show what this feature delivers (from founder.yml)
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
if [[ -f "$FOUNDER_YML" ]]; then
    _bn_claim=$(awk "/^  ${NAME}:/{found=1;next} found && /delivers:/{gsub(/.*delivers: *\"?/,\"\"); gsub(/\"$/,\"\"); print; exit} found && /^  [a-z]/{exit}" "$FOUNDER_YML" 2>/dev/null)
    _bn_for=$(awk "/^  ${NAME}:/{found=1;next} found && /for:/{gsub(/.*for: *\"?/,\"\"); gsub(/\"$/,\"\"); print; exit} found && /^  [a-z]/{exit}" "$FOUNDER_YML" 2>/dev/null)
    [[ -n "$_bn_claim" ]] && echo "  delivers: $_bn_claim"
    [[ -n "$_bn_for" ]] && echo "  for: $_bn_for"
fi
echo "  score: $SCORE/100  weight: $WEIGHT  weakest: $DIM"
# Journey position from topology
TOPO_CACHE="$PROJECT_DIR/.claude/cache/topology.json"
if [[ -f "$TOPO_CACHE" ]] && command -v jq &>/dev/null; then
    JPOS=$(jq -r --arg f "$NAME" '.journey_positions[$f].position // "unknown"' "$TOPO_CACHE" 2>/dev/null)
    if [[ "$JPOS" != "unknown" ]]; then
        echo "  journey: $JPOS"
        if [[ "$JPOS" == "entry" ]]; then
            echo "  *** ENTRY FEATURE — blocks ALL downstream value. Fix delivery first. ***"
        elif [[ "$JPOS" == "core" ]]; then
            echo "  *** CORE FEATURE — other features depend on this. Reliability matters. ***"
        fi
    fi
fi
echo ""

# --- Sub-score detail for bottleneck ---
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    D=$(jq -r ".[\"$NAME\"].delivery_score // \"?\"" "$EVAL_CACHE" 2>/dev/null)
    C=$(jq -r ".[\"$NAME\"].craft_score // \"?\"" "$EVAL_CACHE" 2>/dev/null)
    V=$(jq -r ".[\"$NAME\"].viability_score // \"?\"" "$EVAL_CACHE" 2>/dev/null)
    DELTA=$(jq -r ".[\"$NAME\"].delta // \"none\"" "$EVAL_CACHE" 2>/dev/null)
    echo "  sub-scores: delivery=$D  craft=$C  viability=$V  delta=$DELTA"

    # Diagnosis: which dimension is dragging?
    if [[ "$D" != "?" && "$C" != "?" && "$V" != "?" ]]; then
        if [[ "$D" -lt "$C" && "$D" -lt "$V" ]] 2>/dev/null; then
            echo "  diagnosis: delivery dragging — feature exists but doesn't deliver real value"
            echo "  action: complete the implementation, not polish"
        elif [[ "$C" -lt "$D" && "$C" -lt "$V" ]] 2>/dev/null; then
            echo "  diagnosis: craft dragging — delivers value but is fragile or rough"
            echo "  action: error handling, edge cases, polish"
        elif [[ "$V" -lt "$D" && "$V" -lt "$C" ]] 2>/dev/null; then
            echo "  diagnosis: viability dragging — works but lacks differentiation"
            echo "  action: competitive positioning, novelty, market fit"
        fi
    fi
    echo ""
fi

# --- All features ranked (with claims) ---
echo "▸ all features (worst first)"
echo "$RESULT" | while IFS=$'\t' read -r fname fscore fweight fweighted fdim; do
    _f_claim=""
    if [[ -f "$FOUNDER_YML" ]]; then
        _f_claim=$(awk "/^  ${fname}:/{found=1;next} found && /delivers:/{gsub(/.*delivers: *\"?/,\"\"); gsub(/\"$/,\"\"); print; exit} found && /^  [a-z]/{exit}" "$FOUNDER_YML" 2>/dev/null)
    fi
    _f_jpos=""
    if [[ -f "$TOPO_CACHE" ]] && command -v jq &>/dev/null; then
        _f_jpos=$(jq -r --arg f "$fname" '.journey_positions[$f].position // ""' "$TOPO_CACHE" 2>/dev/null)
    fi
    _jlabel=""
    [[ -n "$_f_jpos" ]] && _jlabel=" [$_f_jpos]"
    if [[ -n "$_f_claim" ]]; then
        echo "  $fname: $fscore (w:$fweight)$_jlabel — ${_f_claim:0:60}"
    else
        echo "  $fname: $fscore (w:$fweight, weakest:$fdim)$_jlabel"
    fi
done
echo ""

# --- Completion ---
_comp_err=$(mktemp)
COMPLETION=$("$FOUNDER_DIR/bin/compute-completion.sh" 2>"$_comp_err") || true
_comp_stderr=$(cat "$_comp_err")
rm -f "$_comp_err"
if [[ -n "$_comp_stderr" && -z "$COMPLETION" ]]; then
    echo "▸ completion"
    echo "  error: compute-completion.sh failed: $(echo "$_comp_stderr" | head -1)"
    echo ""
fi
if [[ -n "$COMPLETION" ]]; then
    echo "▸ completion"
    echo "$COMPLETION" | sed 's/^/  /'
    echo ""

    # Version >80% check
    VERSION_PCT=$(echo "$COMPLETION" | grep 'version_completion:' | sed 's/.*: //')
    if [[ -n "$VERSION_PCT" ]] && [[ "$VERSION_PCT" -gt 80 ]] 2>/dev/null; then
        echo "  *** VERSION COMPLETION >80% — consider /roadmap bump ***"
        echo ""
    fi
fi

# --- Delta trends ---
DELTAS="$PROJECT_DIR/.claude/cache/eval-deltas.json"
if [[ -f "$DELTAS" ]] && command -v jq &>/dev/null; then
    echo "▸ delta trends"
    jq -r 'to_entries[] | select(.value != null) | "\(.key): \(.value)"' "$DELTAS" 2>/dev/null | sed 's/^/  /' | head -10
    echo ""

    # Features trending worse get priority flag
    WORSE=$(jq -r 'to_entries[] | select(.value == "worse") | .key' "$DELTAS" 2>/dev/null || echo "")
    if [[ -n "$WORSE" ]]; then
        echo "  *** REGRESSION: $(echo $WORSE | tr '\n' ', ') trending worse ***"
        echo ""
    fi
fi

echo "=== REPORT COMPLETE ==="
