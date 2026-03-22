#!/usr/bin/env bash
# beliefs-parser.sh — Parse beliefs.yml into belief variables for process_belief()
#
# Usage: source this file, then call parse_beliefs_file "$BELIEFS_FILE"
# Requires: process_belief() to be defined before calling parse_beliefs_file
#
# Sets these variables per belief entry before calling process_belief():
#   belief_id, belief_type, belief_metric, belief_scenario, belief_threshold,
#   belief_feature, belief_path, belief_contains, belief_not_contains,
#   belief_exists, belief_min_lines, belief_prompt, belief_min_calibration,
#   belief_window, belief_direction, belief_command, belief_quality,
#   belief_layer, belief_max_gap_days, forbidden_words[], capabilities[]

# Reset all belief variables to empty
_reset_belief_vars() {
    belief_type=""
    belief_metric=""
    belief_scenario=""
    belief_threshold=""
    belief_feature=""
    belief_path=""
    belief_contains=""
    belief_not_contains=""
    belief_exists=""
    belief_min_lines=""
    belief_prompt=""
    belief_min_calibration=""
    belief_window=""
    belief_direction=""
    belief_command=""
    belief_quality=""
    belief_layer=""
    belief_max_gap_days=""
    in_forbidden=false
    in_capabilities=false
    forbidden_words=()
    capabilities=()
}

# Parse a single YAML line and set the corresponding belief variable
# Returns 0 if line was handled, 1 if not
_parse_belief_line() {
    local line="$1"

    # New belief entry
    if echo "$line" | grep -q '^\s*- id:'; then
        # Process previous belief
        process_belief
        # Reset
        belief_id=$(echo "$line" | sed 's/.*id: *//')
        _reset_belief_vars
        return 0
    fi

    # Type
    if echo "$line" | grep -q '^\s*type:'; then
        belief_type=$(echo "$line" | sed 's/.*type: *//')
        return 0
    fi

    # Feature
    if echo "$line" | grep -q '^\s*feature:'; then
        belief_feature=$(echo "$line" | sed 's/.*feature: *//')
        return 0
    fi

    # Quality dimension
    if echo "$line" | grep -q '^\s*quality:'; then
        belief_quality=$(echo "$line" | sed 's/.*quality: *//')
        return 0
    fi

    # Layer (infrastructure | logic | ux)
    if echo "$line" | grep -q '^\s*layer:'; then
        belief_layer=$(echo "$line" | sed 's/.*layer: *//')
        return 0
    fi

    # Metric
    if echo "$line" | grep -q '^\s*metric:'; then
        belief_metric=$(echo "$line" | sed 's/.*metric: *//')
        return 0
    fi

    # Path (for file_check)
    if echo "$line" | grep -q '^\s*path:'; then
        belief_path=$(echo "$line" | sed 's/.*path: *//' | tr -d '"')
        return 0
    fi

    # Contains (for file_check)
    if echo "$line" | grep -q '^\s*contains:'; then
        belief_contains=$(echo "$line" | sed 's/.*contains: *//' | tr -d '"')
        return 0
    fi

    # Not contains (for file_check)
    if echo "$line" | grep -q '^\s*not_contains:'; then
        belief_not_contains=$(echo "$line" | sed 's/.*not_contains: *//' | tr -d '"')
        return 0
    fi

    # Exists (for file_check)
    if echo "$line" | grep -q '^\s*exists:'; then
        belief_exists=$(echo "$line" | sed 's/.*exists: *//' | tr -d '"')
        return 0
    fi

    # Min lines (for file_check)
    if echo "$line" | grep -q '^\s*min_lines:'; then
        belief_min_lines=$(echo "$line" | sed 's/.*min_lines: *//')
        return 0
    fi

    # Prompt (for llm_judge)
    if echo "$line" | grep -q '^\s*prompt:'; then
        belief_prompt=$(echo "$line" | sed 's/.*prompt: *//' | tr -d '"')
        return 0
    fi

    # Scenario (for playwright_task)
    if echo "$line" | grep -q '^\s*scenario:'; then
        belief_scenario=$(echo "$line" | sed 's/.*scenario: *//' | tr -d '"')
        return 0
    fi

    # Threshold (for playwright_task)
    if echo "$line" | grep -q '^\s*threshold_seconds:'; then
        belief_threshold=$(echo "$line" | sed 's/.*threshold_seconds: *//')
        return 0
    fi

    # Min calibration (for bench_check)
    if echo "$line" | grep -q '^\s*min_calibration:'; then
        belief_min_calibration=$(echo "$line" | sed 's/.*min_calibration: *//')
        return 0
    fi

    # Window (for score_trend)
    if echo "$line" | grep -q '^\s*window:'; then
        belief_window=$(echo "$line" | sed 's/.*window: *//')
        return 0
    fi

    # Direction (for score_trend)
    if echo "$line" | grep -q '^\s*direction:'; then
        belief_direction=$(echo "$line" | sed 's/.*direction: *//')
        return 0
    fi

    # Command (for command_check)
    if echo "$line" | grep -q '^\s*command:'; then
        belief_command=$(echo "$line" | sed 's/.*command: *//')
        return 0
    fi

    # Max gap days (for session_continuity)
    if echo "$line" | grep -q '^\s*max_gap_days:'; then
        belief_max_gap_days=$(echo "$line" | sed 's/.*max_gap_days: *//')
        return 0
    fi

    # Forbidden list parsing (for content_check)
    if echo "$line" | grep -q '^\s*forbidden:'; then
        in_forbidden=true
        local inline
        inline=$(echo "$line" | grep -o '\[.*\]' || true)
        if [[ -n "$inline" ]]; then
            while IFS= read -r word; do
                word=$(echo "$word" | tr -d '", []')
                [[ -n "$word" ]] && forbidden_words+=("$word")
            done <<< "$(echo "$inline" | tr ',' '\n')"
            in_forbidden=false
        fi
        return 0
    fi

    if [[ "$in_forbidden" == "true" ]]; then
        if echo "$line" | grep -q '^\s*-'; then
            local word
            word=$(echo "$line" | sed 's/^\s*- *//' | tr -d '"')
            [[ -n "$word" ]] && forbidden_words+=("$word")
        else
            in_forbidden=false
        fi
        return 0
    fi

    # Capabilities list parsing (for feature_review)
    if echo "$line" | grep -q '^\s*capabilities:'; then
        in_capabilities=true
        return 0
    fi

    if [[ "$in_capabilities" == "true" ]]; then
        if echo "$line" | grep -q '^\s*-'; then
            local _cap
            _cap=$(echo "$line" | sed 's/^\s*- *//' | tr -d '"')
            [[ -n "$_cap" ]] && capabilities+=("$_cap")
        else
            in_capabilities=false
        fi
        return 0
    fi

    return 1
}

# Main entry point: parse a beliefs.yml file
# Args: $1 = path to beliefs.yml
# Requires: process_belief() to be defined
parse_beliefs_file() {
    local beliefs_file="$1"
    [[ ! -f "$beliefs_file" ]] && return

    belief_id=""
    _reset_belief_vars

    while IFS= read -r line; do
        _parse_belief_line "$line" || true
    done < "$beliefs_file"

    # Process last belief
    process_belief
}
