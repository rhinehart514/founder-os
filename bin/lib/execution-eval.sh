#!/usr/bin/env bash
# execution-eval.sh — Runtime eval: actually run commands and check outcomes.
#
# For each feature in founder.yml, runs its declared commands, captures
# stdout/stderr/exit code, checks mechanical properties against the
# "delivers:" claim. Feeds results to generative eval as supplementary evidence.
#
# Usage:
#   source "$FOUNDER_DIR/bin/lib/execution-eval.sh"
#   run_execution_eval "scoring"  # single feature
#   run_execution_eval            # all features
#
# Requires: FOUNDER_DIR, PROJECT_DIR to be set before sourcing.
# Requires: bin/lib/config.sh already sourced for cfg().

# Run a single command and capture results
# Returns JSON-like structured output
_exec_command() {
    local cmd="$1"
    local timeout_s="${2:-30}"
    local start_ms
    start_ms=$(($(date +%s%N 2>/dev/null || echo "$(date +%s)000000000") / 1000000))

    local stdout_file stderr_file
    stdout_file=$(mktemp /tmp/founder-exec-out.XXXXXX)
    stderr_file=$(mktemp /tmp/founder-exec-err.XXXXXX)

    local exit_code=0
    # Expand founder commands to actual paths
    local expanded_cmd="$cmd"
    expanded_cmd="${expanded_cmd/founder /$FOUNDER_DIR/bin/founder }"

    # Run with timeout if available, otherwise run directly
    if command -v timeout &>/dev/null; then
        timeout "$timeout_s" bash -c "$expanded_cmd" >"$stdout_file" 2>"$stderr_file" || exit_code=$?
    elif command -v gtimeout &>/dev/null; then
        gtimeout "$timeout_s" bash -c "$expanded_cmd" >"$stdout_file" 2>"$stderr_file" || exit_code=$?
    else
        bash -c "$expanded_cmd" >"$stdout_file" 2>"$stderr_file" || exit_code=$?
    fi

    local end_ms
    end_ms=$(($(date +%s%N 2>/dev/null || echo "$(date +%s)000000000") / 1000000))
    local runtime_ms=$(( end_ms - start_ms ))

    local stdout_content stderr_content
    stdout_content=$(cat "$stdout_file" 2>/dev/null)
    stderr_content=$(cat "$stderr_file" 2>/dev/null)
    local stdout_lines
    stdout_lines=$(wc -l < "$stdout_file" 2>/dev/null | tr -d ' \n')

    rm -f "$stdout_file" "$stderr_file"

    # Output structured result
    echo "exit_code=$exit_code"
    echo "runtime_ms=$runtime_ms"
    echo "stdout_lines=$stdout_lines"
    echo "stdout_empty=$([[ -z "$stdout_content" ]] && echo true || echo false)"
    echo "stderr_empty=$([[ -z "$stderr_content" ]] && echo true || echo false)"
    echo "has_stack_trace=$([[ "$stderr_content" =~ (Traceback|Error:|at .+:[0-9]|ENOENT|segfault) ]] && echo true || echo false)"
    # First line of stdout for pattern matching
    echo "first_line=$(echo "$stdout_content" | head -1)"
    # Last line for actionable output check
    echo "last_line=$(echo "$stdout_content" | tail -1)"
}

# Check command output against feature's "delivers:" claim
_check_delivery() {
    local feat_name="$1"
    local delivers="$2"
    local exec_result="$3"

    local issues=""
    local checks_passed=0
    local checks_total=0

    # Parse exec result
    local exit_code stdout_empty stderr_empty has_stack_trace runtime_ms stdout_lines
    exit_code=$(echo "$exec_result" | grep '^exit_code=' | cut -d= -f2)
    stdout_empty=$(echo "$exec_result" | grep '^stdout_empty=' | cut -d= -f2)
    stderr_empty=$(echo "$exec_result" | grep '^stderr_empty=' | cut -d= -f2)
    has_stack_trace=$(echo "$exec_result" | grep '^has_stack_trace=' | cut -d= -f2)
    runtime_ms=$(echo "$exec_result" | grep '^runtime_ms=' | cut -d= -f2)
    stdout_lines=$(echo "$exec_result" | grep '^stdout_lines=' | cut -d= -f2)

    # Check 1: Exit code 0
    checks_total=$((checks_total + 1))
    if [[ "$exit_code" -eq 0 ]]; then
        checks_passed=$((checks_passed + 1))
    else
        issues+="exit code $exit_code (expected 0); "
    fi

    # Check 2: Non-empty output
    checks_total=$((checks_total + 1))
    if [[ "$stdout_empty" == "false" ]]; then
        checks_passed=$((checks_passed + 1))
    else
        issues+="empty stdout (command produced no output); "
    fi

    # Check 3: No stack traces
    checks_total=$((checks_total + 1))
    if [[ "$has_stack_trace" == "false" ]]; then
        checks_passed=$((checks_passed + 1))
    else
        issues+="stack trace in stderr; "
    fi

    # Check 4: Reasonable runtime (<10s for CLI)
    checks_total=$((checks_total + 1))
    if [[ "$runtime_ms" -lt 10000 ]]; then
        checks_passed=$((checks_passed + 1))
    else
        issues+="slow: ${runtime_ms}ms (>10s); "
    fi

    # Check 5: Output has substance (>2 lines)
    checks_total=$((checks_total + 1))
    if [[ "$stdout_lines" -gt 2 ]]; then
        checks_passed=$((checks_passed + 1))
    else
        issues+="minimal output ($stdout_lines lines); "
    fi

    echo "pass=$checks_passed"
    echo "total=$checks_total"
    echo "issues=${issues%;* }"
}

# Feature-specific runtime checks beyond generic command execution
_feature_specific_checks() {
    local feat_name="$1"
    local extra_issues=""
    local extra_pass=0
    local extra_total=0

    case "$feat_name" in
        scoring)
            # Check: founder score produces a numeric score
            extra_total=$((extra_total + 1))
            local score_out
            score_out=$("$FOUNDER_DIR/bin/founder" score . --quiet 2>/dev/null) || score_out=""
            if [[ "$score_out" =~ ^[0-9]+$ ]]; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="score --quiet did not produce numeric output; "
            fi
            # Check: eval --no-generative --json returns valid JSON
            extra_total=$((extra_total + 1))
            local eval_out
            eval_out=$("$FOUNDER_DIR/bin/eval.sh" . --score --json --no-generative 2>/dev/null) || eval_out=""
            if echo "$eval_out" | jq . &>/dev/null 2>&1; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="eval --json did not return valid JSON; "
            fi
            ;;
        learning)
            # Check: founder trail renders without error
            extra_total=$((extra_total + 1))
            if "$FOUNDER_DIR/bin/founder" trail >/dev/null 2>&1; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="founder trail failed; "
            fi
            ;;
        commands)
            # Check: founder help produces multi-line output (lists commands)
            extra_total=$((extra_total + 1))
            local help_out
            help_out=$("$FOUNDER_DIR/bin/founder" help 2>/dev/null) || help_out=""
            local help_lines
            help_lines=$(echo "$help_out" | wc -l | tr -d ' ')
            if [[ "$help_lines" -ge 10 ]]; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="founder help output too short (${help_lines} lines, expected 10+); "
            fi
            ;;
        todo)
            # Check: founder todo produces output or empty-state message
            extra_total=$((extra_total + 1))
            local todo_out
            todo_out=$("$FOUNDER_DIR/bin/founder" todo show 2>/dev/null) || todo_out=""
            if [[ -n "$todo_out" ]]; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="founder todo show produced no output; "
            fi
            ;;
        docs)
            # Check: all referenced file paths in README.md exist
            extra_total=$((extra_total + 1))
            local missing_refs=0
            while IFS= read -r ref_path; do
                [[ -z "$ref_path" ]] && continue
                # Skip URLs, anchors, relative fragments
                [[ "$ref_path" =~ ^https?:// ]] && continue
                [[ "$ref_path" =~ ^# ]] && continue
                [[ "$ref_path" =~ ^\. ]] && continue
                ref_path="${ref_path%%)}"  # strip trailing paren
                if [[ ! -e "$FOUNDER_DIR/$ref_path" && ! -e "$ref_path" ]]; then
                    missing_refs=$((missing_refs + 1))
                fi
            done < <(grep -oE '\[.*?\]\(([^)]+)\)' "$FOUNDER_DIR/README.md" 2>/dev/null | sed 's/.*(\(.*\))/\1/')
            if [[ "$missing_refs" -eq 0 ]]; then
                extra_pass=$((extra_pass + 1))
            else
                extra_issues+="$missing_refs broken links in README.md; "
            fi
            ;;
        install)
            # Check: install.sh --check validates without reinstalling
            extra_total=$((extra_total + 1))
            if [[ -f "$FOUNDER_DIR/install.sh" ]]; then
                # Just check the file is parseable, don't actually run install
                if bash -n "$FOUNDER_DIR/install.sh" 2>/dev/null; then
                    extra_pass=$((extra_pass + 1))
                else
                    extra_issues+="install.sh has syntax errors; "
                fi
            else
                extra_issues+="install.sh not found; "
            fi
            ;;
    esac

    echo "extra_pass=$extra_pass"
    echo "extra_total=$extra_total"
    echo "extra_issues=${extra_issues%;* }"
}

# Main entry: run execution eval for a feature (or all features)
# Outputs: structured text per feature with pass/total/issues
run_execution_eval() {
    local filter="${1:-}"
    local results=""
    local founder_yml="$PROJECT_DIR/config/founder.yml"

    if [[ ! -f "$founder_yml" ]]; then
        echo "execution-eval: no config/founder.yml found" >&2
        return 1
    fi

    # Parse features from founder.yml
    local in_features=false
    local current_feature=""
    local current_commands=""
    local current_delivers=""
    local current_status=""

    while IFS= read -r line; do
        # Detect features section
        if [[ "$line" =~ ^features: ]]; then
            in_features=true
            continue
        fi
        # Exit features section on next top-level key
        if [[ "$in_features" == true && "$line" =~ ^[a-z] && ! "$line" =~ ^[[:space:]] ]]; then
            in_features=false
        fi
        [[ "$in_features" != true ]] && continue

        # Detect feature name (2-space indent, not 3+)
        if [[ "$line" =~ ^\ \ ([a-z][a-z0-9_-]*):$ ]]; then
            local matched_name="${BASH_REMATCH[1]}"
            # Process previous feature if exists
            if [[ -n "$current_feature" && "$current_status" == "active" ]]; then
                if [[ -z "$filter" || "$filter" == "$current_feature" ]]; then
                    results+=$(_run_feature_eval "$current_feature" "$current_commands" "$current_delivers")
                    results+=$'\n'
                fi
            fi
            current_feature="$matched_name"
            current_commands=""
            current_delivers=""
            current_status=""
        fi

        # Parse fields — internal: (new) or commands: (legacy) for CLI commands
        if [[ "$line" =~ (internal|commands):.*\[(.*)\] ]]; then
            local _cmds="${BASH_REMATCH[2]}"
            _cmds="${_cmds//\"/}"
            if [[ -n "$current_commands" && -n "$_cmds" ]]; then
                current_commands="${current_commands}, ${_cmds}"
            else
                current_commands="$_cmds"
            fi
        fi
        if [[ "$line" =~ delivers:.*\"(.*)\" ]]; then
            current_delivers="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ status:[[:space:]]+([a-z]+) ]]; then
            current_status="${BASH_REMATCH[1]}"
        fi
    done < "$founder_yml"

    # Process last feature
    if [[ -n "$current_feature" && "$current_status" == "active" ]]; then
        if [[ -z "$filter" || "$filter" == "$current_feature" ]]; then
            results+=$(_run_feature_eval "$current_feature" "$current_commands" "$current_delivers")
            results+=$'\n'
        fi
    fi

    echo "$results"
}

_run_feature_eval() {
    local feat_name="$1"
    local commands="$2"
    local delivers="$3"

    local total_pass=0
    local total_checks=0
    local all_issues=""

    # Run each declared command
    local OLD_IFS="$IFS"
    IFS=','
    for cmd in $commands; do
        IFS="$OLD_IFS"
        cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$cmd" ]] && continue

        local exec_result
        exec_result=$(_exec_command "$cmd" 30)

        local delivery_result
        delivery_result=$(_check_delivery "$feat_name" "$delivers" "$exec_result")

        local cmd_pass cmd_total cmd_issues
        cmd_pass=$(echo "$delivery_result" | grep '^pass=' | cut -d= -f2)
        cmd_total=$(echo "$delivery_result" | grep '^total=' | cut -d= -f2)
        cmd_issues=$(echo "$delivery_result" | grep '^issues=' | cut -d= -f2-)

        total_pass=$((total_pass + cmd_pass))
        total_checks=$((total_checks + cmd_total))
        [[ -n "$cmd_issues" ]] && all_issues+="[$cmd] $cmd_issues; "
    done
    IFS="$OLD_IFS"

    # Feature-specific checks
    local specific
    specific=$(_feature_specific_checks "$feat_name")
    local extra_pass extra_total extra_issues
    extra_pass=$(echo "$specific" | grep '^extra_pass=' | cut -d= -f2)
    extra_total=$(echo "$specific" | grep '^extra_total=' | cut -d= -f2)
    extra_issues=$(echo "$specific" | grep '^extra_issues=' | cut -d= -f2-)

    total_pass=$((total_pass + extra_pass))
    total_checks=$((total_checks + extra_total))
    [[ -n "$extra_issues" ]] && all_issues+="$extra_issues; "

    # Compute score (0-100)
    local exec_score=0
    if [[ "$total_checks" -gt 0 ]]; then
        exec_score=$((total_pass * 100 / total_checks))
    fi

    echo "EXEC|${feat_name}|${exec_score}|${total_pass}/${total_checks}|${all_issues%;* }"
}

# Format execution results as context for LLM evaluator
format_execution_context() {
    local exec_results="$1"
    local context="=== Execution Eval Results ===
"
    while IFS='|' read -r prefix feat score ratio issues; do
        [[ "$prefix" != "EXEC" ]] && continue
        context+="Feature: $feat — $score/100 ($ratio checks passed)
"
        if [[ -n "$issues" ]]; then
            context+="  Issues: $issues
"
        fi
    done <<< "$exec_results"
    context+="=== End Execution Results ===
"
    echo "$context"
}
