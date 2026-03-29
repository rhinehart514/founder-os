#!/usr/bin/env bash
# vault-sync.sh — Sync founder-os knowledge artifacts into Obsidian vault
# Usage: bash bin/vault-sync.sh [project-dir]
# One-way sync: founder-os → vault. Runs on hooks.
#
# Structure:
#   vault/Knowledge/          ← global (learnings, predictions, patterns)
#   vault/Projects/[name]/    ← per-project (scores, plans, research, sessions)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# --- Resolve vault path ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
VAULT_PATH=""
if [[ -f "$FOUNDER_YML" ]]; then
    VAULT_PATH=$(grep -A5 'vault:' "$FOUNDER_YML" 2>/dev/null | grep 'path:' | sed 's/.*path:\s*//' | sed 's/#.*//' | xargs || true)
fi
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
[[ -z "$VAULT_PATH" ]] && VAULT_PATH="$HOME/obsidian-vault"

[[ ! -d "$VAULT_PATH" ]] && exit 0

# --- Resolve project name ---
PROJECT_NAME=""
if [[ -f "$FOUNDER_YML" ]]; then
    PROJECT_NAME=$(grep -m1 'name:' "$FOUNDER_YML" 2>/dev/null | sed 's/.*name:\s*//' | xargs || true)
fi
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME=$(basename "$PROJECT_DIR")
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr ' /' '-' | tr -cd '[:alnum:]-_')
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="default"

VAULT_GLOBAL="$VAULT_PATH/Knowledge"
VAULT_PROJ="$VAULT_PATH/Projects/$PROJECT_NAME"

mkdir -p "$VAULT_GLOBAL" "$VAULT_PROJ/sessions" "$VAULT_PROJ/planning" "$VAULT_PROJ/research"

# ============================================================
# GLOBAL — cross-project knowledge
# ============================================================

# experiment-learnings
for _src in "$HOME/.claude/knowledge/experiment-learnings.md" "$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"; do
    [[ -f "$_src" ]] && { cp "$_src" "$VAULT_GLOBAL/learnings.md"; break; }
done

# predictions
PRED_FILE="$HOME/.claude/knowledge/predictions.tsv"
[[ ! -f "$PRED_FILE" ]] && PRED_FILE="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
if [[ -f "$PRED_FILE" ]]; then
    {
        echo "# Predictions"
        echo ""
        echo "| Date | Prediction | Evidence | Result | Correct | Model Update |"
        echo "|------|-----------|----------|--------|---------|--------------|"
        tail -n +2 "$PRED_FILE" | while IFS=$'\t' read -r dt agent pred ev res cor mu; do
            echo "| $dt | ${pred:0:60} | ${ev:0:40} | ${res:0:40} | $cor | ${mu:0:40} |"
        done
    } > "$VAULT_GLOBAL/predictions.md"
fi

# patterns
PATTERNS_FILE="$HOME/.claude/knowledge/patterns.tsv"
[[ ! -f "$PATTERNS_FILE" ]] && PATTERNS_FILE="$PROJECT_DIR/.claude/knowledge/patterns.tsv"
if [[ -f "$PATTERNS_FILE" ]]; then
    {
        echo "# Patterns"
        echo ""
        head -1 "$PATTERNS_FILE" | sed 's/\t/ | /g' | sed 's/^/| /;s/$/ |/'
        head -1 "$PATTERNS_FILE" | sed 's/[^\t]*/----|/g' | sed 's/^/|/'
        tail -n +2 "$PATTERNS_FILE" | sed 's/\t/ | /g' | sed 's/^/| /;s/$/ |/'
    } > "$VAULT_GLOBAL/patterns.md"
fi

# taste profile
for _src in "$HOME/.claude/knowledge/founder-taste.md" "$PROJECT_DIR/.claude/knowledge/founder-taste.md"; do
    [[ -f "$_src" ]] && { cp "$_src" "$VAULT_GLOBAL/taste-profile.md"; break; }
done

# product playbook
for _src in "$HOME/.claude/knowledge/product-playbook.md" "$PROJECT_DIR/.claude/knowledge/product-playbook.md"; do
    [[ -f "$_src" ]] && { cp "$_src" "$VAULT_GLOBAL/product-playbook.md"; break; }
done

# market research (spans projects)
for _pair in \
    "market-context.json:market-context.md" \
    "customer-intel.json:customer-intel.md" \
    "agency-landscape-research.json:agency-landscape.md" \
    "smb-research.json:smb-research.md"; do
    _src="${_pair%%:*}"; _dst="${_pair##*:}"
    for _loc in "$HOME/.claude/cache/$_src" "$PROJECT_DIR/.claude/cache/$_src"; do
        if [[ -f "$_loc" ]]; then
            { echo "# ${_dst%.md}"; echo ""; echo '```'; cat "$_loc"; echo '```'; } > "$VAULT_GLOBAL/$_dst"
            break
        fi
    done
done

# ============================================================
# PROJECT-SPECIFIC
# ============================================================

# Score
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    SCORE=$(jq -r '.score // "?"' "$SCORE_CACHE" 2>/dev/null)
    { echo "# Score: $SCORE/100"; echo ""; echo '```json'; cat "$SCORE_CACHE"; echo '```'; } > "$VAULT_PROJ/score.md"
fi

# Feature health (eval-cache)
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    {
        echo "# Feature Health"
        echo ""
        echo "| Feature | Score | Delivery | Craft | Viability |"
        echo "|---------|-------|----------|-------|-----------|"
        jq -r 'to_entries[] | "| \(.key) | \(.value.score // "?") | \(.value.delivery_score // "?") | \(.value.craft_score // "?") | \(.value.viability_score // "?") |"' "$EVAL_CACHE" 2>/dev/null || true
    } > "$VAULT_PROJ/feature-health.md"
fi

# Strategy
[[ -f "$PROJECT_DIR/.claude/plans/strategy.yml" ]] && \
    { echo "# Strategy"; echo ""; echo '```yaml'; cat "$PROJECT_DIR/.claude/plans/strategy.yml"; echo '```'; } > "$VAULT_PROJ/strategy.md"

# Active plan
for _p in "$PROJECT_DIR/.claude/plans/active-plan.md" "$HOME/.claude/plans/active-plan.md"; do
    [[ -f "$_p" ]] && { cp "$_p" "$VAULT_PROJ/active-plan.md"; break; }
done

# Config snapshot
[[ -f "$FOUNDER_YML" ]] && \
    { echo "# Config"; echo ""; echo '```yaml'; cat "$FOUNDER_YML"; echo '```'; } > "$VAULT_PROJ/config.md"

# Research artifacts
for _pair in \
    "last-research.yml:last-research.md" \
    "last-discovery.yml:last-discovery.md" \
    "last-retro.yml:last-retro.md"; do
    _src="${_pair%%:*}"; _dst="${_pair##*:}"
    for _loc in "$PROJECT_DIR/.claude/cache/$_src" "$HOME/.claude/cache/$_src"; do
        if [[ -f "$_loc" ]]; then
            { echo "# ${_dst%.md}"; echo ""; echo '```'; cat "$_loc"; echo '```'; } > "$VAULT_PROJ/research/$_dst"
            break
        fi
    done
done

# GSD planning state
if [[ -d "$PROJECT_DIR/.planning" ]]; then
    [[ -f "$PROJECT_DIR/.planning/ROADMAP.md" ]] && cp "$PROJECT_DIR/.planning/ROADMAP.md" "$VAULT_PROJ/planning/roadmap.md"
    [[ -f "$PROJECT_DIR/.planning/STATE.md" ]] && cp "$PROJECT_DIR/.planning/STATE.md" "$VAULT_PROJ/planning/state.md"
    [[ -f "$PROJECT_DIR/.planning/PROJECT.md" ]] && cp "$PROJECT_DIR/.planning/PROJECT.md" "$VAULT_PROJ/planning/project.md"
    LATEST_VERIFY=$(find "$PROJECT_DIR/.planning" -name "*VERIFICATION.md" -type f 2>/dev/null | sort | tail -1)
    [[ -n "$LATEST_VERIFY" && -f "$LATEST_VERIFY" ]] && cp "$LATEST_VERIFY" "$VAULT_PROJ/planning/latest-verification.md"
fi

# Session logs
TODAY=$(date +%Y-%m-%d)
SESSION_DIR="$PROJECT_DIR/.claude/sessions"
if [[ -d "$SESSION_DIR" ]]; then
    for sf in "$SESSION_DIR/${TODAY}"*.yml; do
        [[ -f "$sf" ]] || continue
        BASENAME=$(basename "$sf" .yml)
        { echo "# Session: $BASENAME"; echo ""; echo '```yaml'; cat "$sf"; echo '```'; } > "$VAULT_PROJ/sessions/${BASENAME}.md"
    done
fi

# ============================================================
# WIKILINK INJECTION — connect the graph
# ============================================================

# Build a list of all known project names for linking
ALL_PROJECTS=()
if [[ -d "$VAULT_PATH/Projects" ]]; then
    for _pd in "$VAULT_PATH/Projects"/*/; do
        [[ -d "$_pd" ]] || continue
        ALL_PROJECTS+=("$(basename "$_pd")")
    done
fi

# Inject links into project-scoped notes
_inject_project_links() {
    local file="$1"
    [[ -f "$file" ]] || return

    # Add project backlink header if not already present
    if ! grep -q '^\[\[Projects/' "$file" 2>/dev/null; then
        # Prepend project link + knowledge links
        local tmp="${file}.tmp"
        {
            echo "Project: [[Projects/$PROJECT_NAME/config|$PROJECT_NAME]]"
            echo "Related: [[Knowledge/learnings|Learnings]] · [[Knowledge/predictions|Predictions]] · [[Knowledge/patterns|Patterns]]"
            echo ""
            cat "$file"
        } > "$tmp" && mv "$tmp" "$file"
    fi
}

# Link score → feature-health, strategy, active plan
for _f in "$VAULT_PROJ/score.md"; do
    [[ -f "$_f" ]] || continue
    if ! grep -q '\[\[' "$_f" 2>/dev/null; then
        {
            echo "Project: [[Projects/$PROJECT_NAME/config|$PROJECT_NAME]]"
            echo "See also: [[Projects/$PROJECT_NAME/feature-health|Features]] · [[Projects/$PROJECT_NAME/strategy|Strategy]] · [[Projects/$PROJECT_NAME/active-plan|Plan]]"
            echo "Related: [[Knowledge/learnings|Learnings]] · [[Knowledge/predictions|Predictions]]"
            echo ""
            cat "$_f"
        } > "${_f}.tmp" && mv "${_f}.tmp" "$_f"
    fi
done

# Link feature-health → score, strategy
[[ -f "$VAULT_PROJ/feature-health.md" ]] && _inject_project_links "$VAULT_PROJ/feature-health.md"

# Link strategy → score, plan
[[ -f "$VAULT_PROJ/strategy.md" ]] && _inject_project_links "$VAULT_PROJ/strategy.md"

# Link research notes → project + knowledge
for _rf in "$VAULT_PROJ/research/"*.md; do
    [[ -f "$_rf" ]] || continue
    _inject_project_links "$_rf"
done

# Link session notes → project
for _sf in "$VAULT_PROJ/sessions/"*.md; do
    [[ -f "$_sf" ]] || continue
    if ! grep -q '\[\[' "$_sf" 2>/dev/null; then
        {
            echo "Project: [[Projects/$PROJECT_NAME/config|$PROJECT_NAME]] · [[Projects/$PROJECT_NAME/score|Score]]"
            echo ""
            cat "$_sf"
        } > "${_sf}.tmp" && mv "${_sf}.tmp" "$_sf"
    fi
done

# Link planning notes → project
for _pf in "$VAULT_PROJ/planning/"*.md; do
    [[ -f "$_pf" ]] || continue
    _inject_project_links "$_pf"
done

# Link global knowledge → all projects that exist
for _gf in "$VAULT_GLOBAL/learnings.md" "$VAULT_GLOBAL/predictions.md" "$VAULT_GLOBAL/patterns.md"; do
    [[ -f "$_gf" ]] || continue
    if ! grep -q '\[\[Projects/' "$_gf" 2>/dev/null; then
        PROJ_LINKS=""
        for _pn in "${ALL_PROJECTS[@]}"; do
            PROJ_LINKS="${PROJ_LINKS}[[Projects/$_pn/config|$_pn]] · "
        done
        PROJ_LINKS="${PROJ_LINKS% · }"
        {
            echo "Projects: $PROJ_LINKS"
            echo ""
            cat "$_gf"
        } > "${_gf}.tmp" && mv "${_gf}.tmp" "$_gf"
    fi
done

# Cross-link market research → customer intel and vice versa
[[ -f "$VAULT_GLOBAL/market-context.md" ]] && ! grep -q '\[\[' "$VAULT_GLOBAL/market-context.md" 2>/dev/null && \
    { echo "Related: [[Knowledge/customer-intel|Customer Intel]] · [[Knowledge/agency-landscape|Landscape]]"; echo ""; cat "$VAULT_GLOBAL/market-context.md"; } > "$VAULT_GLOBAL/market-context.md.tmp" && mv "$VAULT_GLOBAL/market-context.md.tmp" "$VAULT_GLOBAL/market-context.md"

[[ -f "$VAULT_GLOBAL/customer-intel.md" ]] && ! grep -q '\[\[' "$VAULT_GLOBAL/customer-intel.md" 2>/dev/null && \
    { echo "Related: [[Knowledge/market-context|Market Context]] · [[Knowledge/smb-research|SMB Research]]"; echo ""; cat "$VAULT_GLOBAL/customer-intel.md"; } > "$VAULT_GLOBAL/customer-intel.md.tmp" && mv "$VAULT_GLOBAL/customer-intel.md.tmp" "$VAULT_GLOBAL/customer-intel.md"
