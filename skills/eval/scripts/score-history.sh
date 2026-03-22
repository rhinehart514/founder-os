#!/usr/bin/env bash
# score-history.sh — Track eval score history for reproducibility and confidence intervals
# Usage:
#   bash score-history.sh record <feature> <score>     — append score to history
#   bash score-history.sh variance <feature>            — show mean, stddev, confidence interval
#   bash score-history.sh check <feature> <new_score>   — classify delta significance
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HISTORY_FILE="$PROJECT_DIR/.claude/cache/eval-history.json"

# Ensure cache dir exists
mkdir -p "$(dirname "$HISTORY_FILE")"

# Initialize history file if missing
if [[ ! -f "$HISTORY_FILE" ]]; then
    echo "{}" > "$HISTORY_FILE"
fi

if ! command -v jq &>/dev/null; then
    echo "jq not installed — required for score history"
    exit 1
fi

CMD="${1:-}"
FEATURE="${2:-}"

usage() {
    echo "usage: score-history.sh <command> <feature> [score]"
    echo "  record <feature> <score>   — append score with timestamp"
    echo "  variance <feature>         — mean, stddev, confidence interval (last 5)"
    echo "  check <feature> <score>    — classify new score vs history"
    exit 1
}

[[ -z "$CMD" || -z "$FEATURE" ]] && usage

# ── record ──
cmd_record() {
    local score="${3:?usage: score-history.sh record <feature> <score>}"
    local date
    date=$(date +%Y-%m-%d)

    # Append to feature's array in history file
    local tmp
    tmp=$(mktemp)
    jq --arg f "$FEATURE" --argjson s "$score" --arg d "$date" \
        '.[$f] = ((.[$f] // []) + [{"score": $s, "date": $d}])' \
        "$HISTORY_FILE" > "$tmp" && mv "$tmp" "$HISTORY_FILE"

    echo "recorded: $FEATURE = $score ($date)"
}

# ── stats helpers ──
# Compute mean and stddev from last N scores using awk
compute_stats() {
    local feature="$1"
    local n="${2:-5}"

    # Get last N scores as space-separated list
    local scores
    scores=$(jq -r --arg f "$feature" --argjson n "$n" \
        '(.[$f] // []) | .[-$n:] | .[].score' "$HISTORY_FILE" 2>/dev/null)

    if [[ -z "$scores" ]]; then
        echo "0 0 0"
        return 1
    fi

    # Count, mean, stddev via awk
    echo "$scores" | awk '
    {
        vals[NR] = $1
        sum += $1
        count++
    }
    END {
        if (count == 0) { print "0 0 0"; exit 1 }
        mean = sum / count
        sumsq = 0
        for (i = 1; i <= count; i++) {
            sumsq += (vals[i] - mean) ^ 2
        }
        if (count > 1) {
            stddev = sqrt(sumsq / (count - 1))
        } else {
            stddev = 0
        }
        printf "%d %.1f %.1f\n", count, mean, stddev
    }'
}

# ── variance ──
cmd_variance() {
    local count
    count=$(jq -r --arg f "$FEATURE" '(.[$f] // []) | length' "$HISTORY_FILE" 2>/dev/null)

    if [[ "$count" -eq 0 || "$count" == "null" ]]; then
        echo "no history for $FEATURE — run 'record' first"
        exit 0
    fi

    local stats
    stats=$(compute_stats "$FEATURE" 5)
    local n mean stddev
    n=$(echo "$stats" | awk '{print $1}')
    mean=$(echo "$stats" | awk '{print $2}')
    stddev=$(echo "$stats" | awk '{print $3}')

    # Show last 5 scores
    local recent
    recent=$(jq -r --arg f "$FEATURE" '(.[$f] // []) | .[-5:] | .[] | "\(.date): \(.score)"' "$HISTORY_FILE" 2>/dev/null)

    echo "score history: $FEATURE ($n samples)"
    echo "$recent" | sed 's/^/  /'
    echo ""
    printf "  mean:   %s\n" "$mean"
    printf "  stddev: %s\n" "$stddev"

    # Confidence interval (mean +/- 1 stddev)
    local lo hi
    lo=$(echo "$mean $stddev" | awk '{v=$1-$2; printf "%.0f", (v<0?0:v)}')
    hi=$(echo "$mean $stddev" | awk '{v=$1+$2; printf "%.0f", (v>100?100:v)}')
    printf "  95%% range: %s-%s (±1σ)\n" "$lo" "$hi"

    if [[ "$n" -lt 3 ]]; then
        echo "  ⚠ fewer than 3 samples — confidence is low"
    fi
}

# ── check ──
cmd_check() {
    local new_score="${3:?usage: score-history.sh check <feature> <new_score>}"

    local count
    count=$(jq -r --arg f "$FEATURE" '(.[$f] // []) | length' "$HISTORY_FILE" 2>/dev/null)

    if [[ "$count" -eq 0 || "$count" == "null" ]]; then
        echo "no history: first score for $FEATURE — no comparison possible"
        exit 0
    fi

    local stats
    stats=$(compute_stats "$FEATURE" 5)
    local n mean stddev
    n=$(echo "$stats" | awk '{print $1}')
    mean=$(echo "$stats" | awk '{print $2}')
    stddev=$(echo "$stats" | awk '{print $3}')

    # Compute delta in stddev units
    local delta abs_delta classification
    delta=$(echo "$new_score $mean" | awk '{printf "%.1f", $1 - $2}')
    abs_delta=$(echo "$delta" | awk '{v=$1; if(v<0) v=-v; printf "%.1f", v}')

    if [[ $(echo "$stddev" | awk '{print ($1 < 0.01)}') -eq 1 ]]; then
        # Zero stddev — all previous scores identical
        if [[ $(echo "$new_score $mean" | awk '{print ($1 == $2)}') -eq 1 ]]; then
            classification="within noise"
        else
            classification="significant"
        fi
    else
        local sigma_units
        sigma_units=$(echo "$abs_delta $stddev" | awk '{printf "%.1f", $1 / $2}')

        if [[ $(echo "$sigma_units" | awk '{print ($1 <= 1.0)}') -eq 1 ]]; then
            classification="within noise"
        elif [[ $(echo "$sigma_units" | awk '{print ($1 <= 2.0)}') -eq 1 ]]; then
            classification="likely real"
        else
            classification="significant"
        fi
    fi

    echo "$FEATURE: $new_score vs mean $mean (σ=$stddev, δ=$delta)"
    echo "  verdict: $classification"

    case "$classification" in
        "within noise")
            echo "  score is within normal LLM variance — same code, same quality"
            ;;
        "likely real")
            echo "  score moved beyond noise — likely reflects real change"
            ;;
        "significant")
            echo "  large move — investigate: real improvement, or scoring artifact?"
            ;;
    esac

    if [[ "$n" -lt 3 ]]; then
        echo "  ⚠ only $n prior sample(s) — classification is unreliable"
    fi
}

# ── dispatch ──
case "$CMD" in
    record)   cmd_record "$@" ;;
    variance) cmd_variance "$@" ;;
    check)    cmd_check "$@" ;;
    *)        usage ;;
esac
