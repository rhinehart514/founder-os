#!/usr/bin/env bash
# belief-processor.sh — Process individual beliefs by type
#
# Extracted from eval.sh to keep the main file under 1500 lines.
# Provides: process_belief()
#
# Requires before sourcing:
#   check_pass(), check_warn(), check_fail(), run_dom_eval(), run_copy_eval(),
#   run_self_eval(), file_mtime(), FEATURE_FILTER, SCORE_MODE, NO_LLM, PASS, WARN, FAIL,
#   SRC_DIRS, PROJECT_ROOT, EVAL_URL, FOUNDER_DIR,
#   FEATURE_RESULTS, QUALITY_RESULTS, LAYER_RESULTS, ASSERTION_HISTORY

source "$(dirname "${BASH_SOURCE[0]}")/belief-checks.sh"

process_belief() {
    [[ -z "$belief_id" ]] && return

    # Feature filter: skip beliefs that don't match
    if [[ -n "$FEATURE_FILTER" && "$belief_feature" != "$FEATURE_FILTER" ]]; then
        return
    fi

    # Track pre-counts to detect what this belief contributed
    local _pre_pass=$PASS _pre_warn=$WARN _pre_fail=$FAIL

    case "$belief_type" in
        file_check)
            # Machine-evaluable file assertions from beliefs.yml
            if [[ -n "$belief_path" ]]; then
                # Expand ~ to $HOME, resolve relative paths against project root
                local expanded_path="${belief_path/#\~/$HOME}"
                if [[ "$expanded_path" != /* ]]; then
                    expanded_path="./${expanded_path}"
                fi
                if [[ "$belief_exists" == "false" ]]; then
                    # File should NOT exist
                    if [[ ! -e "$expanded_path" ]]; then
                        check_pass "$belief_id" "$belief_path does not exist"
                    else
                        check_fail "$belief_id" "$belief_path exists but shouldn't" "warn" 2
                    fi
                elif [[ ! -e "$expanded_path" ]]; then
                    # File should exist but doesn't
                    check_fail "$belief_id" "$belief_path not found" "warn" 2
                else
                    # File exists — check contents if specified
                    local file_ok=true
                    local detail="$belief_path exists"
                    if [[ -n "$belief_contains" ]]; then
                        if grep -q "$belief_contains" "$expanded_path" 2>/dev/null; then
                            detail="$belief_path contains '$belief_contains'"
                        else
                            file_ok=false
                            detail="$belief_path missing '$belief_contains'"
                        fi
                    fi
                    if [[ -n "$belief_not_contains" ]]; then
                        if grep -q "$belief_not_contains" "$expanded_path" 2>/dev/null; then
                            file_ok=false
                            detail="$belief_path contains '$belief_not_contains' (forbidden)"
                        fi
                    fi
                    if [[ -n "$belief_min_lines" ]]; then
                        local lines
                        lines=$(wc -l < "$expanded_path" 2>/dev/null | tr -d ' ')
                        if [[ "$lines" -lt "$belief_min_lines" ]]; then
                            file_ok=false
                            detail="$belief_path has $lines lines (need $belief_min_lines)"
                        fi
                    fi
                    if $file_ok; then
                        check_pass "$belief_id" "$detail"
                    else
                        check_fail "$belief_id" "$detail" "warn" 2
                    fi
                fi
            fi
            ;;
        content_check)
            if [[ ${#forbidden_words[@]} -gt 0 && -n "$SRC_DIRS" ]]; then
                local found=0
                for word in "${forbidden_words[@]}"; do
                    local count=$(grep -ri "$word" $SRC_DIRS 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
                    found=$((found + count))
                done
                if [[ "$found" -eq 0 ]]; then
                    check_pass "$belief_id" "0 forbidden words found"
                else
                    check_fail "$belief_id" "$found forbidden word occurrences" "warn" 2
                fi
            fi
            ;;
        route_graph)
            if [[ -d "app" ]]; then
                local route_count=$(find app/ -name 'page.tsx' -o -name 'page.ts' -o -name 'page.jsx' -o -name 'page.js' 2>/dev/null | wc -l | tr -d ' ')
                check_pass "$belief_id" "Next.js app/ routes: $route_count"
            elif [[ -d "pages" ]]; then
                local route_count=$(find pages/ -name '*.tsx' -o -name '*.ts' -o -name '*.jsx' -o -name '*.js' 2>/dev/null | grep -v '_app\|_document\|_error\|api/' | wc -l | tr -d ' ')
                check_pass "$belief_id" "Next.js pages/ routes: $route_count"
            elif [[ -d "src/pages" ]]; then
                local route_count=$(find src/pages/ -name '*.tsx' -o -name '*.ts' -o -name '*.jsx' -o -name '*.js' 2>/dev/null | grep -v '_app\|_document\|_error\|api/' | wc -l | tr -d ' ')
                check_pass "$belief_id" "Next.js src/pages/ routes: $route_count"
            else
                check_warn "$belief_id" "no Next.js route directories found"
            fi
            ;;
        dom_check)
            run_dom_eval
            if [[ -n "$DOM_RESULTS" && -n "$belief_metric" ]]; then
                local result=$(echo "$DOM_RESULTS" | grep "^${belief_metric}:" | head -1)
                local status=$(echo "$result" | cut -d: -f2)
                local detail=$(echo "$result" | cut -d: -f3-)
                if [[ "$status" == "pass" ]]; then
                    check_pass "$belief_id" "$detail"
                else
                    check_fail "$belief_id" "${detail:-dom check failed}" "warn" 3
                fi
            elif [[ -z "$EVAL_URL" ]]; then
                check_warn "$belief_id" "dom_check: no dev server (set EVAL_URL)"
            else
                check_warn "$belief_id" "dom_check: evaluation failed"
            fi
            ;;
        copy_check)
            run_copy_eval
            if [[ -n "$COPY_RESULTS" && -n "$belief_metric" ]]; then
                local result=$(echo "$COPY_RESULTS" | grep "^${belief_metric}:" | head -1)
                local status=$(echo "$result" | cut -d: -f2)
                local detail=$(echo "$result" | cut -d: -f3-)
                if [[ "$status" == "pass" ]]; then
                    check_pass "$belief_id" "$detail"
                else
                    check_fail "$belief_id" "${detail:-copy check failed}" "warn" 3
                fi
            elif [[ -z "$EVAL_URL" ]]; then
                check_warn "$belief_id" "copy_check: no dev server (set EVAL_URL)"
            else
                check_warn "$belief_id" "copy_check: evaluation failed"
            fi
            ;;
        positioning_check)
            run_copy_eval
            if [[ -n "$COPY_RESULTS" && -n "$belief_metric" ]]; then
                local result=$(echo "$COPY_RESULTS" | grep "^${belief_metric}:" | head -1)
                local status=$(echo "$result" | cut -d: -f2)
                local detail=$(echo "$result" | cut -d: -f3-)
                if [[ "$status" == "pass" ]]; then
                    check_pass "$belief_id" "$detail"
                else
                    check_fail "$belief_id" "${detail:-positioning check failed}" "warn" 3
                fi
            elif [[ -z "$EVAL_URL" ]]; then
                check_warn "$belief_id" "positioning_check: no dev server (set EVAL_URL)"
            else
                check_warn "$belief_id" "positioning_check: evaluation failed"
            fi
            ;;
        self_check)
            run_self_eval
            if [[ -n "$SELF_RESULTS" && -n "$belief_metric" ]]; then
                local result=$(echo "$SELF_RESULTS" | grep "^${belief_metric}:" | head -1)
                local status=$(echo "$result" | cut -d: -f2)
                local detail=$(echo "$result" | cut -d: -f3-)
                if [[ "$status" == "pass" ]]; then
                    check_pass "$belief_id" "$detail"
                else
                    check_fail "$belief_id" "${detail:-self check failed}" "warn" 3
                fi
            else
                check_fail "$belief_id" "self check: diagnostic failed" "warn" 3
            fi
            ;;
        llm_judge)
            # LLM-as-judge: Claude evaluates code/files against a quality prompt
            # In --score or --no-llm mode: skip entirely (not counted in totals)
            # Unevaluated beliefs should not penalize the score
            if [[ "$SCORE_MODE" == "true" || "$NO_LLM" == "true" ]]; then
                : # skip — not counted in pass/warn/fail totals
            elif [[ -n "$belief_prompt" ]]; then
                local judge_context=""
                # Gather context from specified paths or feature files
                if [[ -n "$belief_path" ]]; then
                    local expanded_path="${belief_path/#\~/$HOME}"
                    # Resolve relative paths against project root
                    if [[ "$expanded_path" != /* ]]; then
                        expanded_path="./${expanded_path}"
                    fi
                    if [[ -f "$expanded_path" ]]; then
                        judge_context=$(head -500 "$expanded_path" 2>/dev/null)
                    elif [[ -d "$expanded_path" ]]; then
                        # Directory: concatenate first 50 lines of each file
                        judge_context=$(find "$expanded_path" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.sh" -o -name "*.md" \) ! -path "*/node_modules/*" 2>/dev/null | head -10 | while read -r f; do
                            echo "=== $(basename "$f") ==="
                            head -50 "$f" 2>/dev/null
                        done)
                    fi
                elif [[ -n "$belief_feature" ]]; then
                    # Auto-gather context for the feature from SRC_DIRS
                    if [[ -n "$SRC_DIRS" ]]; then
                        judge_context=$(grep -rl "$belief_feature" $SRC_DIRS 2>/dev/null | grep -v node_modules | head -5 | while read -r f; do
                            echo "=== $(basename "$f") ==="
                            head -50 "$f" 2>/dev/null
                        done)
                    fi
                fi

                if [[ -z "$judge_context" ]]; then
                    check_warn "$belief_id" "llm_judge: no context files found"
                else
                    # Call Claude via the Anthropic API (requires ANTHROPIC_API_KEY)
                    local api_key="${ANTHROPIC_API_KEY:-}"
                    if [[ -z "$api_key" ]]; then
                        # Try to use claude CLI as fallback
                        local judge_input="Evaluate this code. Answer ONLY 'pass' or 'fail' on the first line, then a one-sentence reason on the second line.

Question: ${belief_prompt}

Code:
${judge_context}"
                        local judge_result=""
                        # Use a temp file for the prompt to avoid shell escaping issues
                        local judge_tmp
                        judge_tmp=$(mktemp)
                        echo "$judge_input" > "$judge_tmp"
                        judge_result=$(claude -p "$(cat "$judge_tmp")" --model haiku 2>/dev/null </dev/null | head -2) || judge_result=""
                        rm -f "$judge_tmp"

                        if [[ -z "$judge_result" ]]; then
                            check_warn "$belief_id" "llm_judge: claude CLI not available"
                        else
                            local verdict
                            verdict=$(echo "$judge_result" | head -1 | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
                            local reason
                            reason=$(echo "$judge_result" | tail -1)
                            if [[ "$verdict" == "pass" ]]; then
                                check_pass "$belief_id" "$reason"
                            else
                                check_fail "$belief_id" "$reason" "warn" 3
                            fi
                        fi
                    else
                        # Direct API call with curl (faster, no CLI overhead, temperature 0)
                        local judge_payload
                        judge_payload=$(jq -n \
                            --arg prompt "$belief_prompt" \
                            --arg context "$(echo "$judge_context" | head -500)" \
                            '{model:"claude-haiku-4-5-20251001",max_tokens:100,temperature:0,messages:[{role:"user",content:("Evaluate this code. Answer ONLY pass or fail on the first line, then a one-sentence reason on the second line.\n\nQuestion: " + $prompt + "\n\nCode:\n" + $context)}]}')
                        local judge_response
                        judge_response=$(curl -s "https://api.anthropic.com/v1/messages" \
                            -H "x-api-key: $api_key" \
                            -H "anthropic-version: 2023-06-01" \
                            -H "content-type: application/json" \
                            -d "$judge_payload" 2>/dev/null)
                        local judge_text
                        judge_text=$(echo "$judge_response" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"//;s/"$//')
                        if [[ -z "$judge_text" ]]; then
                            check_warn "$belief_id" "llm_judge: API call failed"
                        else
                            local verdict
                            verdict=$(echo "$judge_text" | tr '[:upper:]' '[:lower:]' | head -1)
                            if echo "$verdict" | grep -q "pass"; then
                                check_pass "$belief_id" "$(echo "$judge_text" | tail -1)"
                            else
                                check_fail "$belief_id" "$(echo "$judge_text" | tail -1)" "warn" 3
                            fi
                        fi
                    fi
                fi
            else
                check_warn "$belief_id" "llm_judge: no prompt: field"
            fi
            ;;
        feature_review)
            # Claude evaluates feature completeness — explicit capabilities or inferred
            # In --score or --no-llm mode: skip entirely (not counted in totals)
            # Unevaluated beliefs should not penalize the score
            if [[ "$SCORE_MODE" == "true" || "$NO_LLM" == "true" ]]; then
                : # skip — not counted in pass/warn/fail totals
            else

            # Gather code context for the feature
            local review_context=""
            if [[ -n "$belief_path" ]]; then
                local expanded_path="${belief_path/#\~/$HOME}"
                # Resolve relative paths against project root
                if [[ "$expanded_path" != /* ]]; then
                    expanded_path="./${expanded_path}"
                fi
                if [[ -f "$expanded_path" ]]; then
                    review_context=$(head -500 "$expanded_path" 2>/dev/null)
                elif [[ -d "$expanded_path" ]]; then
                    review_context=$(find "$expanded_path" -type f \( -name "*.sh" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.mjs" -o -name "*.yml" -o -name "*.md" \) ! -path "*/node_modules/*" 2>/dev/null | head -10 | while read -r f; do
                        echo "=== $f ==="
                        head -300 "$f" 2>/dev/null
                    done)
                fi
            elif [[ -n "$belief_feature" ]]; then
                # Auto-discover: find files related to this feature
                review_context=$(grep -rl "$belief_feature" bin/ skills/ lens/ config/ 2>/dev/null | grep -v node_modules | head -8 | while read -r f; do
                    echo "=== $f ==="
                    head -300 "$f" 2>/dev/null
                done)
            fi

            if [[ -z "$review_context" ]]; then
                check_warn "$belief_id" "feature_review: no code found for feature"
            else

            # Build the prompt
            local review_prompt="You are reviewing a feature for completeness. Be honest and critical.

"
            if [[ ${#capabilities[@]} -gt 0 ]]; then
                review_prompt+="The feature claims these capabilities:
"
                for cap in "${capabilities[@]}"; do
                    review_prompt+="- $cap
"
                done
                review_prompt+="
For each capability, respond IMPLEMENTED or MISSING.
Then on the final line write: COMPLETENESS: X/Y (where X = implemented, Y = total)
"
            else
                review_prompt+="Analyze this feature's code. Identify:
1. What capabilities are implemented (working code, not stubs)
2. What's obviously missing for this feature to be complete
3. On the final line: COMPLETENESS: X/Y (your best estimate of implemented/total capabilities)

Be specific. 'Error handling' is too vague. 'Handles invalid input gracefully' is specific.
"
            fi
            review_prompt+="
Feature: ${belief_feature:-unknown}
Code:
${review_context}"

            # Call Claude (reuse llm_judge calling pattern)
            local review_tmp review_result
            review_tmp=$(mktemp)
            echo "$review_prompt" > "$review_tmp"

            local api_key="${ANTHROPIC_API_KEY:-}"
            if [[ -z "$api_key" ]]; then
                review_result=$(claude -p "$(cat "$review_tmp")" --model haiku 2>/dev/null </dev/null) || review_result=""
            else
                local review_payload
                review_payload=$(jq -n \
                    --rawfile prompt "$review_tmp" \
                    '{model:"claude-haiku-4-5-20251001",max_tokens:500,temperature:0,messages:[{role:"user",content:$prompt}]}')
                local review_response
                review_response=$(curl -s "https://api.anthropic.com/v1/messages" \
                    -H "x-api-key: $api_key" \
                    -H "anthropic-version: 2023-06-01" \
                    -H "content-type: application/json" \
                    -d "$review_payload" 2>/dev/null)
                review_result=$(echo "$review_response" | jq -r '.content[0].text // empty' 2>/dev/null)
            fi
            rm -f "$review_tmp"

            if [[ -z "$review_result" ]]; then
                check_warn "$belief_id" "feature_review: Claude not available"
            else
                # Parse COMPLETENESS: X/Y from response
                local completeness
                completeness=$(echo "$review_result" | grep -o 'COMPLETENESS: [0-9]*/[0-9]*' | tail -1)
                if [[ -n "$completeness" ]]; then
                    local impl total pct
                    impl=$(echo "$completeness" | grep -o '[0-9]*' | head -1)
                    total=$(echo "$completeness" | grep -o '[0-9]*' | tail -1)
                    if [[ "$total" -gt 0 ]]; then
                        pct=$(( impl * 100 / total ))
                        if [[ "$pct" -ge 70 ]]; then
                            check_pass "$belief_id" "${belief_feature}: ${impl}/${total} capabilities (${pct}%)"
                        else
                            check_fail "$belief_id" "${belief_feature}: ${impl}/${total} capabilities (${pct}%)" "warn" 3
                        fi
                    else
                        check_warn "$belief_id" "feature_review: could not parse completeness"
                    fi
                else
                    check_warn "$belief_id" "feature_review: no COMPLETENESS line in response"
                fi
            fi
            fi  # end review_context not empty
            fi  # end SCORE_MODE/NO_LLM check
            ;;
        bench_check)
            check_bench
            ;;
        command_check)
            check_command
            ;;
        score_trend)
            check_score_trend
            ;;
        playwright_task)
            if [[ -n "$EVAL_URL" && -n "$belief_scenario" ]]; then
                local threshold="${belief_threshold:-180}"
                local blind_result
                local blind_script=""
                for _bs in "$FOUNDER_DIR"/lens/*/eval/blind-eval.mjs; do
                    [[ -f "$_bs" ]] && blind_script="$_bs" && break
                done
                [[ -z "$blind_script" ]] && blind_script="$FOUNDER_DIR/bin/blind-eval.mjs"
                blind_result=$(node "$blind_script" --url "$EVAL_URL" --task "$belief_scenario" --timeout "$threshold" --eval 2>/dev/null) || blind_result=""
                if [[ -n "$blind_result" && -n "$belief_metric" ]]; then
                    local result=$(echo "$blind_result" | grep "^${belief_metric}:" | head -1)
                    local status=$(echo "$result" | cut -d: -f2)
                    local detail=$(echo "$result" | cut -d: -f3-)
                    if [[ "$status" == "pass" ]]; then
                        check_pass "$belief_id" "$detail"
                    else
                        check_fail "$belief_id" "${detail:-blind eval failed}" "warn" 3
                    fi
                else
                    check_warn "$belief_id" "playwright_task: evaluation failed"
                fi
            else
                check_warn "$belief_id" "playwright_task: no dev server or no scenario (set EVAL_URL)"
            fi
            ;;
        assertion_trend)
            check_assertion_trend
            ;;
        session_continuity)
            check_session_continuity
            ;;
        value_velocity)
            check_value_velocity
            ;;
    esac

    # Track per-feature results
    local _feat="${belief_feature:-unscoped}"
    local _dp=$((PASS - _pre_pass)) _dw=$((WARN - _pre_warn)) _df=$((FAIL - _pre_fail))
    FEATURE_RESULTS="${FEATURE_RESULTS}${_feat}:${_dp}:${_dw}:${_df}
"
    # Track per-feature~quality results
    local _qual="${belief_quality:-unscoped}"
    QUALITY_RESULTS="${QUALITY_RESULTS}${_feat}~${_qual}:${_dp}:${_dw}:${_df}
"
    # Track per-feature~layer results
    local _layer="${belief_layer:-unscoped}"
    LAYER_RESULTS="${LAYER_RESULTS}${_feat}~${_layer}:${_dp}:${_dw}:${_df}
"
    # Track assertion history (for /eval trend)
    local _ah_status="PASS"
    if [[ "$_df" -gt 0 ]]; then _ah_status="FAIL"
    elif [[ "$_dw" -gt 0 ]]; then _ah_status="WARN"
    fi
    ASSERTION_HISTORY="${ASSERTION_HISTORY}$(date '+%Y-%m-%d')\t${_feat}\t${belief_id}\t${belief_type:-unknown}\t${_ah_status}\twarn
"
}
