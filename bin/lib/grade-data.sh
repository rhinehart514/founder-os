# grade-data.sh — Data access helpers for grade.sh
#
# Functions: get_feature_score, get_total_score, get_feature_sub_score,
#            get_assertion_pass_rate, get_score_delta, find_score_at_date
#
# Requires: CACHE_FILE, HISTORY_FILE (set by parent grade.sh)

# Read current feature scores from cache
get_feature_score() {
    local feature="$1"
    if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
        # Try nested .features.X.score first, then top-level .X.score (eval-cache format)
        local score
        score=$(jq -r ".features.\"$feature\".score // empty" "$CACHE_FILE" 2>/dev/null)
        if [[ -z "$score" ]]; then
            score=$(jq -r ".\"$feature\".score // empty" "$CACHE_FILE" 2>/dev/null)
        fi
        echo "$score"
    fi
}

get_total_score() {
    if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
        local score
        score=$(jq -r '.score // empty' "$CACHE_FILE" 2>/dev/null)
        # Fallback: try score-cache.json in the same directory
        if [[ -z "$score" ]]; then
            local score_cache="${CACHE_FILE%/*}/score-cache.json"
            [[ -f "$score_cache" ]] && score=$(jq -r '.score // empty' "$score_cache" 2>/dev/null)
        fi
        echo "$score"
    fi
}

# Get a feature's eval sub-score (delivery_score, craft_score, viability_score)
get_feature_sub_score() {
    local feature="$1" sub="$2"
    if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
        local score
        score=$(jq -r ".\"$feature\".${sub} // empty" "$CACHE_FILE" 2>/dev/null)
        [[ -z "$score" ]] && score=$(jq -r ".features.\"$feature\".${sub} // empty" "$CACHE_FILE" 2>/dev/null)
        echo "$score"
    fi
}

# Get assertion pass rate from eval-cache or score-cache
get_assertion_pass_rate() {
    if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
        local pass total rate
        pass=$(jq -r '.assertion_pass_count // empty' "$CACHE_FILE" 2>/dev/null)
        total=$(jq -r '.assertion_total_count // empty' "$CACHE_FILE" 2>/dev/null)
        if [[ -n "$pass" && -n "$total" && "$total" -gt 0 ]]; then
            rate=$((pass * 100 / total))
            echo "$rate"
            return
        fi
        # Fallback: score-cache.json
        local score_cache="${CACHE_FILE%/*}/score-cache.json"
        if [[ -f "$score_cache" ]]; then
            pass=$(jq -r '.assertion_pass_count // .beliefs_passing // empty' "$score_cache" 2>/dev/null)
            total=$(jq -r '.assertion_total_count // .beliefs_total // empty' "$score_cache" 2>/dev/null)
            if [[ -n "$pass" && -n "$total" && "$total" -gt 0 ]]; then
                rate=$((pass * 100 / total))
                echo "$rate"
                return
            fi
        fi
    fi
}

# Get score delta: compare current score to score at prediction date
get_score_delta() {
    local pred_date="$1"
    local current
    current=$(get_total_score)
    [[ -z "$current" || ! "$current" =~ ^[0-9]+$ ]] && return
    local baseline
    baseline=$(find_score_at_date "$pred_date")
    [[ -z "$baseline" || ! "$baseline" =~ ^[0-9]+$ ]] && return
    echo "$((current - baseline))"
}

# Find the score closest to a given date in history.tsv
# History columns: timestamp build structure product capabilities hygiene project_type
# Returns min(build, structure, hygiene) as the composite score (matches score.sh formula)
find_score_at_date() {
    local target_date="$1"
    [[ -z "$target_date" || ! -f "$HISTORY_FILE" ]] && return

    # Convert target date to comparable format
    # Find the row with timestamp closest to (but not after) end of target_date
    # target_date is YYYY-MM-DD, timestamps are ISO (YYYY-MM-DDTHH:MM:SSZ)
    # Use target_date + "T23:59:59Z" so same-day entries are included
    awk -F'\t' -v target="${target_date}T23:59:59Z" '
    NR == 1 { next }  # skip header
    {
        ts = $1
        # Compute composite score: min(build=$2, structure=$3, hygiene=$6)
        s = $2 + 0
        if ($3+0 < s) s = $3 + 0
        if ($6+0 < s) s = $6 + 0

        if (ts <= target) {
            best = s
            best_ts = ts
        }
    }
    END {
        if (best != "") print best
    }
    ' "$HISTORY_FILE"
}
