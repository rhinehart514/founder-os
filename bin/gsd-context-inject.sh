#!/usr/bin/env bash
# gsd-context-inject.sh — Append founder-os intelligence to GSD CONTEXT.md
# Usage: bash bin/gsd-context-inject.sh <context-md-path> [phase-keywords]
# Appends <founder_intelligence> block to CONTEXT.md's <code_context> section.
set -euo pipefail

CONTEXT_FILE="${1:-}"
PHASE_KEYWORDS="${2:-}"

if [[ -z "$CONTEXT_FILE" || ! -f "$CONTEXT_FILE" ]]; then
    echo "Usage: gsd-context-inject.sh <context-md-path> [phase-keywords]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"

# Build intelligence block
INTEL=""

# --- Bottleneck ---
if [[ -f "$SCRIPT_DIR/compute-bottleneck.sh" && -f "$EVAL_CACHE" ]]; then
    BN=$(bash "$SCRIPT_DIR/compute-bottleneck.sh" "$EVAL_CACHE" "$FOUNDER_YML" 2>/dev/null | head -1 || true)
    if [[ -n "$BN" ]]; then
        IFS=$'\t' read -r name score weight wscore dim <<< "$BN"
        INTEL="${INTEL}### Current Bottleneck\n"
        INTEL="${INTEL}Feature: $name at $score/100 (weight: $weight, weakest: $dim)\n\n"
    fi
fi

# --- Feature scores ---
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    FEAT_TABLE=$(jq -r 'to_entries | sort_by(.value.score) | .[:5][] | "| \(.key) | \(.value.score // "?") | \(.value.delivery_score // "?") | \(.value.craft_score // "?") | \(.value.delta // "?") |"' "$EVAL_CACHE" 2>/dev/null || true)
    if [[ -n "$FEAT_TABLE" ]]; then
        INTEL="${INTEL}### Feature Scores\n"
        INTEL="${INTEL}| Feature | Score | Delivery | Craft | Delta |\n"
        INTEL="${INTEL}|---------|-------|----------|-------|-------|\n"
        INTEL="${INTEL}${FEAT_TABLE}\n\n"
    fi
fi

# --- Failed predictions for this phase ---
if [[ -n "$PHASE_KEYWORDS" && -f "$SCRIPT_DIR/extract-relevant-predictions.sh" ]]; then
    PRED_INTEL=$(bash "$SCRIPT_DIR/extract-relevant-predictions.sh" "$PHASE_KEYWORDS" 2>/dev/null || true)
    if [[ -n "$PRED_INTEL" ]]; then
        INTEL="${INTEL}${PRED_INTEL}\n\n"
    fi
fi

# --- Vault search ---
if [[ -n "$PHASE_KEYWORDS" && -f "$SCRIPT_DIR/vault-query.sh" ]]; then
    VAULT_INTEL=$(bash "$SCRIPT_DIR/vault-query.sh" "$PHASE_KEYWORDS" 2>/dev/null | head -30 || true)
    if [[ -n "$VAULT_INTEL" ]]; then
        INTEL="${INTEL}### Vault Notes\n"
        INTEL="${INTEL}${VAULT_INTEL}\n\n"
    fi
fi

# --- Known patterns from experiment-learnings ---
for _lf in "$PROJECT_DIR/.claude/knowledge/experiment-learnings.md" "$HOME/.claude/knowledge/experiment-learnings.md"; do
    if [[ -f "$_lf" ]]; then
        KNOWN=$(sed -n '/^## Known/,/^## /p' "$_lf" 2>/dev/null | head -10 | grep -E '^\s*-' || true)
        if [[ -n "$KNOWN" ]]; then
            INTEL="${INTEL}### Known Patterns\n${KNOWN}\n\n"
        fi
        break
    fi
done

# Exit if nothing to inject
[[ -z "$INTEL" ]] && exit 0

# --- Append to CONTEXT.md ---
BLOCK=$(printf "\n<founder_intelligence>\n%b</founder_intelligence>\n" "$INTEL")

# Try to inject before </code_context> if it exists, otherwise append at end
if grep -q '</code_context>' "$CONTEXT_FILE" 2>/dev/null; then
    # Insert before closing tag
    sed -i '' "s|</code_context>|${BLOCK//$'\n'/\\n}\n</code_context>|" "$CONTEXT_FILE" 2>/dev/null || \
        echo "$BLOCK" >> "$CONTEXT_FILE"
else
    echo "$BLOCK" >> "$CONTEXT_FILE"
fi
