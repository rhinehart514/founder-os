#!/usr/bin/env bash
# demand-sync.sh — Sync demand-cache.json to Obsidian vault
# Usage: demand-sync.sh [project-dir]
# Creates Dataview-queryable notes in ~/obsidian-vault/demand/
# Target: <100ms

set -euo pipefail

PROJECT_DIR="${1:-.}"
DEMAND_CACHE="$PROJECT_DIR/.claude/cache/demand-cache.json"
VAULT_DIR="$HOME/obsidian-vault/demand"

# Exit silently if no demand data
[[ ! -f "$DEMAND_CACHE" ]] && exit 0
command -v jq &>/dev/null || exit 0

# Ensure vault directory
mkdir -p "$VAULT_DIR"

GENERATED_AT=$(jq -r '.generated_at // "unknown"' "$DEMAND_CACHE" 2>/dev/null)

# --- Jobs note ---
{
    echo "---"
    echo "type: demand-jobs"
    echo "synced_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "source: demand-cache.json"
    echo "---"
    echo ""
    echo "# Jobs"
    echo ""
    echo "Generated: $GENERATED_AT"
    echo ""
    # Extract jobs per feature
    jq -r '
        .features // {} | to_entries[] |
        .key as $feat |
        .value.jobs // [] | to_entries[] |
        "## \($feat) — \(.value.type // "unknown")\n\n" +
        "- **Statement:** \(.value.statement // "none")\n" +
        "- **Importance:** \(.value.importance // 0)/10\n" +
        "- **Satisfaction:** \(.value.satisfaction // 0)/10\n" +
        "- **Opportunity:** \(.value.opportunity_score // 0)/20\n" +
        "- **Evidence:** \(.value.evidence_class // "inferred")\n"
    ' "$DEMAND_CACHE" 2>/dev/null || echo "(no jobs data)"
} > "$VAULT_DIR/jobs.md"

# --- Forces note ---
{
    echo "---"
    echo "type: demand-forces"
    echo "synced_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "source: demand-cache.json"
    echo "---"
    echo ""
    echo "# Forces"
    echo ""
    echo "Generated: $GENERATED_AT"
    echo ""
    jq -r '
        .features // {} | to_entries[] |
        .key as $feat |
        .value.forces // {} |
        "## \($feat)\n\n" +
        "| Force | Description | Strength |\n" +
        "|-------|------------|----------|\n" +
        "| Push | \(.push.description // "-") | \(.push.strength // 0)/10 |\n" +
        "| Pull | \(.pull.description // "-") | \(.pull.strength // 0)/10 |\n" +
        "| Anxiety | \(.anxiety.description // "-") | \(.anxiety.strength // 0)/10 |\n" +
        "| Habit | \(.habit.description // "-") | \(.habit.strength // 0)/10 |\n\n" +
        "**Net switching energy:** \(.net_switching_energy // 0)\n"
    ' "$DEMAND_CACHE" 2>/dev/null || echo "(no forces data)"
} > "$VAULT_DIR/forces.md"

# --- Packages note ---
{
    echo "---"
    echo "type: demand-packages"
    echo "synced_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "source: demand-cache.json"
    echo "---"
    echo ""
    echo "# Packages"
    echo ""
    echo "Generated: $GENERATED_AT"
    echo ""
    jq -r '
        .features // {} | to_entries[] |
        .key as $feat |
        .value.packages // [] | .[] |
        "## \(.customer_name // "Unnamed")\n\n" +
        "- **One-liner:** \(.one_liner // "-")\n" +
        "- **Internal features:** \(.internal_features // [] | join(", "))\n" +
        "- **Serves job:** \(.serves_job // "-")\n" +
        "- **Tier:** \(.tier // "core")\n" +
        "- **Source feature:** \($feat)\n"
    ' "$DEMAND_CACHE" 2>/dev/null || echo "(no packages data)"
} > "$VAULT_DIR/packages.md"

# --- Evidence note ---
{
    echo "---"
    echo "type: demand-evidence"
    echo "synced_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "source: demand-cache.json"
    echo "---"
    echo ""
    echo "# Evidence Summary"
    echo ""
    echo "Generated: $GENERATED_AT"
    echo ""
    # Aggregate evidence counts across all features
    local_observed=0 local_stated=0 local_market=0 local_inferred=0
    while IFS= read -r line; do
        o=$(echo "$line" | jq -r '.observed // 0')
        s=$(echo "$line" | jq -r '.stated // 0')
        m=$(echo "$line" | jq -r '.market // 0')
        i=$(echo "$line" | jq -r '.inferred // 0')
        local_observed=$((local_observed + o))
        local_stated=$((local_stated + s))
        local_market=$((local_market + m))
        local_inferred=$((local_inferred + i))
    done < <(jq -c '.features // {} | to_entries[] | .value.evidence_summary // {}' "$DEMAND_CACHE" 2>/dev/null)

    echo "| Class | Count |"
    echo "|-------|-------|"
    echo "| Observed | $local_observed |"
    echo "| Stated | $local_stated |"
    echo "| Market | $local_market |"
    echo "| Inferred | $local_inferred |"
    echo ""
    echo "**Total evidence points:** $((local_observed + local_stated + local_market + local_inferred))"
    echo ""

    # Per-feature breakdown
    echo "## Per Feature"
    echo ""
    jq -r '
        .features // {} | to_entries[] |
        "- **\(.key)**: demand_tier=\(.value.demand_tier // "unknown"), " +
        "demand_score=\(.value.demand_score // 0), " +
        "evidence: \(.value.evidence_summary.observed // 0)obs/\(.value.evidence_summary.stated // 0)stated/\(.value.evidence_summary.market // 0)market/\(.value.evidence_summary.inferred // 0)inferred"
    ' "$DEMAND_CACHE" 2>/dev/null || echo "(no per-feature data)"
} > "$VAULT_DIR/evidence.md"

echo "demand-sync: wrote 4 notes to $VAULT_DIR" >&2
