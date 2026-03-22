#!/usr/bin/env bash
# belief-checks.sh — History, trend, and runtime belief check functions
#
# Extracted from belief-processor.sh.
# Provides: check_bench, check_command, check_score_trend,
#           check_assertion_trend, check_session_continuity, check_value_velocity
#
# Requires before sourcing:
#   check_pass(), check_warn(), check_fail(), file_mtime(),
#   FOUNDER_DIR, PROJECT_ROOT

check_bench() {
    local bench_result
    bench_result=$("$FOUNDER_DIR/bin/bench.sh" --json 2>/dev/null) || bench_result=""
    if [[ -n "$bench_result" ]] && command -v jq &>/dev/null; then
        local calibration
        calibration=$(echo "$bench_result" | jq -r '.calibration // 0' 2>/dev/null)
        local min_cal="${belief_min_calibration:-80}"
        if [[ "$calibration" -ge "$min_cal" ]]; then
            local bench_passed bench_total
            bench_passed=$(echo "$bench_result" | jq -r '.passed // 0' 2>/dev/null)
            bench_total=$(echo "$bench_result" | jq -r '.total // 0' 2>/dev/null)
            check_pass "$belief_id" "calibration ${calibration}% (${bench_passed}/${bench_total} fixtures)"
        else
            check_fail "$belief_id" "calibration ${calibration}% (need ${min_cal}%)" "warn" 5
        fi
    else
        check_warn "$belief_id" "bench_check: founder bench failed"
    fi
}

check_command() {
    if [[ -n "$belief_command" ]]; then
        local cmd_output
        cmd_output=$(eval "$belief_command" 2>&1) && \
            check_pass "$belief_id" "$cmd_output" || \
            check_fail "$belief_id" "${cmd_output:-command failed}" "warn" 3
    else
        check_warn "$belief_id" "command_check: no command: field"
    fi
}

check_score_trend() {
    local history_file=".claude/scores/history.tsv"
    local window="${belief_window:-10}"
    local direction="${belief_direction:-not_flat}"
    if [[ -f "$history_file" ]]; then
        local hist_lines
        hist_lines=$(wc -l < "$history_file" | tr -d ' ')
        if [[ "$hist_lines" -le 2 ]]; then
            check_warn "$belief_id" "score_trend: not enough history (${hist_lines} lines)"
        else
            local scores
            scores=$(tail -n "$window" "$history_file" | cut -f5 | grep -E '^[0-9]+$')
            local unique
            unique=$(echo "$scores" | sort -u | wc -l | tr -d ' ')
            if [[ "$direction" == "not_flat" ]]; then
                if [[ "$unique" -gt 1 ]]; then
                    check_pass "$belief_id" "score variance: ${unique} unique values in last ${window} runs"
                else
                    check_fail "$belief_id" "score flat: 1 unique value in last ${window} runs" "warn" 3
                fi
            elif [[ "$direction" == "up" ]]; then
                local first_score last_score
                first_score=$(echo "$scores" | head -1)
                last_score=$(echo "$scores" | tail -1)
                if [[ -n "$first_score" && -n "$last_score" && "$last_score" -gt "$first_score" ]]; then
                    check_pass "$belief_id" "score trending up: ${first_score} → ${last_score}"
                else
                    check_fail "$belief_id" "score not trending up: ${first_score:-?} → ${last_score:-?}" "warn" 3
                fi
            fi
        fi
    else
        check_warn "$belief_id" "score_trend: no history.tsv found"
    fi
}

check_assertion_trend() {
    local trend_direction="${belief_direction:-graduating}"
    local trend_window="${belief_window:-5}"
    local history_file=".claude/scores/history.tsv"
    if [[ -f "$history_file" ]]; then
        local hist_lines
        hist_lines=$(wc -l < "$history_file" | tr -d ' ')
        if [[ "$hist_lines" -le 2 ]]; then
            check_warn "$belief_id" "assertion_trend: not enough history (${hist_lines} entries)"
        else
            local scores
            scores=$(tail -n "$trend_window" "$history_file" | cut -f5 | grep -E '^[0-9]+$')
            local first_score last_score
            first_score=$(echo "$scores" | head -1)
            last_score=$(echo "$scores" | tail -1)
            if [[ "$trend_direction" == "graduating" ]]; then
                if [[ -n "$first_score" && -n "$last_score" && "$last_score" -ge "$first_score" ]]; then
                    check_pass "$belief_id" "assertions graduating: ${first_score} → ${last_score}"
                else
                    check_fail "$belief_id" "assertions not graduating: ${first_score:-?} → ${last_score:-?}" "warn" 3
                fi
            elif [[ "$trend_direction" == "not_regressing" ]]; then
                if [[ -n "$first_score" && -n "$last_score" && "$last_score" -ge "$((first_score - 5))" ]]; then
                    check_pass "$belief_id" "assertions stable: ${first_score} → ${last_score}"
                else
                    check_fail "$belief_id" "assertions regressing: ${first_score:-?} → ${last_score:-?}" "warn" 3
                fi
            fi
        fi
    else
        check_warn "$belief_id" "assertion_trend: no history.tsv found"
    fi
}

check_session_continuity() {
    local max_gap="${belief_max_gap_days:-14}"
    local now
    now=$(date +%s)
    local most_recent=0
    for _sc_file in .claude/plans/plan.yml ~/.claude/knowledge/predictions.tsv .claude/scores/history.tsv; do
        local _sc_expanded="${_sc_file/#\~/$HOME}"
        if [[ -f "$_sc_expanded" ]]; then
            local _sc_mtime
            _sc_mtime=$(file_mtime "$_sc_expanded")
            _sc_mtime="${_sc_mtime:-0}"
            [[ "$_sc_mtime" -gt "$most_recent" ]] && most_recent="$_sc_mtime"
        fi
    done
    if [[ "$most_recent" -eq 0 ]]; then
        check_warn "$belief_id" "session_continuity: no trackable files found"
    else
        local gap_days=$(( (now - most_recent) / 86400 ))
        if [[ "$gap_days" -le "$max_gap" ]]; then
            check_pass "$belief_id" "last session ${gap_days} days ago (max ${max_gap})"
        else
            check_fail "$belief_id" "last session ${gap_days} days ago (max ${max_gap})" "warn" 3
        fi
    fi
}

check_value_velocity() {
    local history_file=".claude/scores/history.tsv"
    if [[ -f "$history_file" ]]; then
        local hist_lines
        hist_lines=$(wc -l < "$history_file" | tr -d ' ')
        if [[ "$hist_lines" -le 2 ]]; then
            check_warn "$belief_id" "value_velocity: not enough history"
        else
            local first_score last_score
            first_score=$(sed -n '2p' "$history_file" | cut -f5)
            last_score=$(tail -1 "$history_file" | cut -f5)
            if [[ -n "$first_score" && -n "$last_score" && "$first_score" =~ ^[0-9]+$ && "$last_score" =~ ^[0-9]+$ ]]; then
                local delta=$((last_score - first_score))
                if [[ "$delta" -gt 0 ]]; then
                    check_pass "$belief_id" "score improved by ${delta} points (${first_score} → ${last_score})"
                elif [[ "$delta" -eq 0 ]]; then
                    check_warn "$belief_id" "value_velocity: score unchanged (${first_score})"
                else
                    check_fail "$belief_id" "score declined by ${delta#-} points (${first_score} → ${last_score})" "warn" 3
                fi
            else
                check_warn "$belief_id" "value_velocity: could not parse scores"
            fi
        fi
    else
        check_warn "$belief_id" "value_velocity: no history.tsv found"
    fi
}
