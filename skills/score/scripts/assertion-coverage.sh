#!/usr/bin/env bash
# assertion-coverage.sh — Map assertion coverage across features
# Shows which features have assertions, which are unmeasured, and distribution.
# Usage: bash assertion-coverage.sh [--json]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BELIEFS="$PROJECT_DIR/lens/product/eval/beliefs.yml"
CONFIG="$PROJECT_DIR/config/founder.yml"
JSON_MODE=false

[[ "${1:-}" == "--json" ]] && JSON_MODE=true

if [[ ! -f "$BELIEFS" ]]; then
    echo "no beliefs.yml — run /eval to establish assertions"
    exit 0
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "no founder.yml — run /onboard to initialize"
    exit 0
fi

# ── Parse active features from founder.yml ──
# Extract feature names that are not killed
ACTIVE_FILE=$(mktemp)
trap 'rm -f "$ACTIVE_FILE" "$COUNTS_FILE" "$ALL_BELIEF_FEATS"' EXIT

awk '
/^features:/ { in_feat=1; next }
in_feat && /^[a-z]/ && !/^[[:space:]]/ { exit }
in_feat && /^  [a-z][a-z0-9_-]*:$/ {
    if (current != "" && !killed) print current
    gsub(/^[[:space:]]+/, "")
    gsub(/:$/, "")
    current = $0
    killed = 0
}
in_feat && /status: killed/ { killed = 1 }
END { if (current != "" && !killed) print current }
' "$CONFIG" > "$ACTIVE_FILE"

# ── Count assertions per feature from beliefs.yml ──
COUNTS_FILE=$(mktemp)
ALL_BELIEF_FEATS=$(mktemp)

awk '
/^[[:space:]]*feature:[[:space:]]/ {
    feat = $0
    sub(/^[[:space:]]*feature:[[:space:]]*/, "", feat)
    gsub(/["'"'"']/, "", feat)
    gsub(/[[:space:]]*$/, "", feat)
    if (feat != "") counts[feat]++
}
/^[[:space:]]*-[[:space:]]*id:/ { total++ }
END {
    for (f in counts) print f "\t" counts[f]
    print "__TOTAL__\t" total+0
}
' "$BELIEFS" > "$COUNTS_FILE"

TOTAL=$(awk -F'\t' '/__TOTAL__/ {print $2}' "$COUNTS_FILE")
TOTAL=${TOTAL:-0}

# Helper: get count for a feature
get_count() {
    local feat="$1"
    local c
    c=$(awk -F'\t' -v f="$feat" '$1 == f {print $2}' "$COUNTS_FILE")
    echo "${c:-0}"
}

# Get all belief features (excluding __TOTAL__)
awk -F'\t' '$1 != "__TOTAL__" {print $1}' "$COUNTS_FILE" | sort > "$ALL_BELIEF_FEATS"

# Compute tagged sum
TAGGED_SUM=$(awk -F'\t' '$1 != "__TOTAL__" {s+=$2} END {print s+0}' "$COUNTS_FILE")
UNTAGGED=$((TOTAL - TAGGED_SUM))

# ── Bar helper ──
bar() {
    local count="$1"
    local total="$2"
    local width=10
    if [[ "$total" -eq 0 ]]; then
        printf '░%.0s' $(seq 1 $width)
        return
    fi
    local filled=$(( count * width / total ))
    [[ $filled -gt $width ]] && filled=$width
    local empty=$((width - filled))
    if [[ $filled -gt 0 ]]; then
        printf '█%.0s' $(seq 1 $filled)
    fi
    if [[ $empty -gt 0 ]]; then
        printf '░%.0s' $(seq 1 $empty)
    fi
}

# ── JSON output ──
if $JSON_MODE; then
    echo "{"
    echo "  \"total_assertions\": $TOTAL,"
    echo "  \"features\": {"

    first=true
    while IFS= read -r feat; do
        count=$(get_count "$feat")
        pct=0
        [[ $TOTAL -gt 0 ]] && pct=$((count * 100 / TOTAL))
        $first || echo ","
        first=false
        printf '    "%s": {"count": %d, "total": %d, "pct": %d, "covered": %s}' \
            "$feat" "$count" "$TOTAL" "$pct" \
            "$( [[ $count -gt 0 ]] && echo "true" || echo "false" )"
    done < "$ACTIVE_FILE"

    # Features in beliefs but not in active features
    while IFS= read -r feat; do
        if ! grep -qx "$feat" "$ACTIVE_FILE"; then
            count=$(get_count "$feat")
            pct=0
            [[ $TOTAL -gt 0 ]] && pct=$((count * 100 / TOTAL))
            $first || echo ","
            first=false
            printf '    "%s": {"count": %d, "total": %d, "pct": %d, "covered": true, "note": "not in active features"}' \
                "$feat" "$count" "$TOTAL" "$pct"
        fi
    done < "$ALL_BELIEF_FEATS"

    echo ""
    echo "  },"
    echo "  \"untagged\": $UNTAGGED,"

    # Uncovered active features
    uncov=""
    while IFS= read -r feat; do
        count=$(get_count "$feat")
        if [[ "$count" -eq 0 ]]; then
            [[ -n "$uncov" ]] && uncov="$uncov, "
            uncov="${uncov}\"$feat\""
        fi
    done < "$ACTIVE_FILE"
    echo "  \"uncovered\": [$uncov]"
    echo "}"
    exit 0
fi

# ── Human-readable output ──
echo "Assertion Coverage:"

while IFS= read -r feat; do
    count=$(get_count "$feat")
    pct=0
    [[ $TOTAL -gt 0 ]] && pct=$((count * 100 / TOTAL))

    printf "  %-16s %2d/%-3d (%2d%%)  " "$feat:" "$count" "$TOTAL" "$pct"
    bar "$count" "$TOTAL"

    if [[ $count -eq 0 ]]; then
        printf "  ⚠ unmeasured"
    fi
    echo ""
done < "$ACTIVE_FILE"

# Show features in beliefs that aren't active (e.g. killed features still have assertions)
while IFS= read -r feat; do
    if ! grep -qx "$feat" "$ACTIVE_FILE"; then
        count=$(get_count "$feat")
        pct=0
        [[ $TOTAL -gt 0 ]] && pct=$((count * 100 / TOTAL))
        printf "  %-16s %2d/%-3d (%2d%%)  " "$feat:" "$count" "$TOTAL" "$pct"
        bar "$count" "$TOTAL"
        printf "  (not active)"
        echo ""
    fi
done < "$ALL_BELIEF_FEATS"

if [[ $UNTAGGED -gt 0 ]]; then
    pct=$((UNTAGGED * 100 / TOTAL))
    printf "  %-16s %2d/%-3d (%2d%%)  " "untagged:" "$UNTAGGED" "$TOTAL" "$pct"
    bar "$UNTAGGED" "$TOTAL"
    echo ""
fi

# Summary
echo ""
covered=0
total_active=0
while IFS= read -r feat; do
    total_active=$((total_active + 1))
    count=$(get_count "$feat")
    [[ $count -gt 0 ]] && covered=$((covered + 1))
done < "$ACTIVE_FILE"
echo "  $covered/$total_active active features covered, $TOTAL total assertions"

# List uncovered
uncovered=""
while IFS= read -r feat; do
    count=$(get_count "$feat")
    if [[ "$count" -eq 0 ]]; then
        uncovered="$uncovered $feat"
    fi
done < "$ACTIVE_FILE"
if [[ -n "$uncovered" ]]; then
    echo "  uncovered:$uncovered"
fi
