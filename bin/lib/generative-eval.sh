#!/usr/bin/env bash
# generative-eval.sh — Generative eval engine: rubric generation, LLM judging, antisycophancy
#
# Extracted from eval.sh to keep the main file under 1500 lines.
# Sources: generate_feature_rubric(), run_logic_research(), _validate_and_emit(),
#          _apply_logic_antisycophancy(), gather_code_context()
#
# Requires: file_mtime(), FRESH_MODE, EVAL_SAMPLES, FOUNDER_DIR to be set before sourcing.

# Portable timeout wrapper — works on macOS (no GNU coreutils) and Linux
# Usage: _timeout SECONDS COMMAND [ARGS...]
# Returns 124 on timeout (matching GNU timeout behavior)
_timeout() {
    local duration="$1"
    shift
    if command -v timeout &>/dev/null; then
        timeout "$duration" "$@"
    elif command -v gtimeout &>/dev/null; then
        gtimeout "$duration" "$@"
    else
        # Perl-based fallback for macOS without coreutils
        # Uses SIGALRM to kill child after duration seconds, returns 124 on timeout
        perl -e '
            $SIG{ALRM} = sub { kill("TERM", $pid); $timed_out = 1 };
            alarm(shift @ARGV);
            $pid = fork();
            if ($pid == 0) { exec(@ARGV) or exit(127) }
            waitpid($pid, 0);
            alarm(0);
            exit(124) if $timed_out;
            exit($? >> 8);
        ' "$duration" "$@"
    fi
}

# Gather code content for a feature's code paths
# Smart reading: small files fully, large files with targeted extraction
gather_code_context() {
    local code_paths="$1"
    local feat_name="${2:-}"
    local context=""
    local OLD_IFS="$IFS"
    IFS=','
    for path in $code_paths; do
        IFS="$OLD_IFS"
        # Expand ~ to $HOME
        local expanded="${path/#\~/$HOME}"
        if [[ -f "$expanded" ]]; then
            local line_count
            line_count=$(wc -l < "$expanded" 2>/dev/null | tr -d ' ')
            if [[ "$line_count" -le 500 ]]; then
                # Small file: read entirely
                context+="=== $path (${line_count} lines) ===
$(cat "$expanded" 2>/dev/null)

"
            elif [[ "$line_count" -le 2000 ]]; then
                # Medium file: head + tail + feature-relevant functions
                context+="=== $path (${line_count} lines, smart extract) ===
--- first 200 lines ---
$(head -200 "$expanded" 2>/dev/null)
--- last 100 lines ---
$(tail -100 "$expanded" 2>/dev/null)
"
                # Extract functions matching feature name if provided
                if [[ -n "$feat_name" ]]; then
                    local feat_funcs
                    feat_funcs=$(grep -n -i "$feat_name" "$expanded" 2>/dev/null | head -5)
                    if [[ -n "$feat_funcs" ]]; then
                        context+="--- lines matching '$feat_name' ---
${feat_funcs}
"
                    fi
                fi
                context+="
"
            else
                # Large file: function index + most relevant function bodies
                context+="=== $path (${line_count} lines, function index) ===
--- function index ---
$(grep -n -E 'function |^[a-z_]+\(\)|^[a-z_]+ *\(\) *\{|^(export )?(const|let|var) [a-z_]+ *= *(function|\()' "$expanded" 2>/dev/null | head -30)
--- first 100 lines ---
$(head -100 "$expanded" 2>/dev/null)
"
                # Extract the 3 most relevant functions based on feature name
                if [[ -n "$feat_name" ]]; then
                    local match_lines
                    match_lines=$(grep -n -i "$feat_name" "$expanded" 2>/dev/null | head -3 | cut -d: -f1)
                    for ml in $match_lines; do
                        local start=$((ml - 2))
                        [[ "$start" -lt 1 ]] && start=1
                        local end=$((ml + 30))
                        context+="--- around line $ml ---
$(sed -n "${start},${end}p" "$expanded" 2>/dev/null)
"
                    done
                fi
                context+="
"
            fi
        elif [[ -d "$expanded" ]]; then
            context+=$(find "$expanded" -type f \( -name "*.sh" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.mjs" -o -name "*.yml" -o -name "*.md" \) ! -path "*/node_modules/*" 2>/dev/null | head -12 | while read -r f; do
                local fc
                fc=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
                echo "=== $f (${fc} lines) ==="
                if [[ "$fc" -le 500 ]]; then
                    cat "$f" 2>/dev/null
                else
                    head -200 "$f" 2>/dev/null
                    echo "... (${fc} lines total, truncated)"
                fi
                echo ""
            done)
            context+="
"
        else
            echo "eval: feature '${feat_name:-?}' lists code path '${path}' that doesn't exist — check config/founder.yml" >&2
        fi
    done
    IFS="$OLD_IFS"
    echo "$context"
}

# Generate a per-feature rubric via haiku (SWE-bench for features)
# Cached in .claude/cache/rubrics/<feature>.json with 24h TTL
generate_feature_rubric() {
    local feat_name="$1"
    local delivers="$2"
    local for_whom="$3"
    local code_context="$4"

    local rubric_dir=".claude/cache/rubrics"
    local rubric_file="${rubric_dir}/${feat_name}.json"

    # Check cache (24h TTL)
    if [[ -f "$rubric_file" && "$FRESH_MODE" != "true" ]]; then
        local now_ts rubric_mtime rubric_age
        now_ts=$(date +%s)
        rubric_mtime=$(file_mtime "$rubric_file")
        rubric_mtime="${rubric_mtime:-0}"
        rubric_age=$(( now_ts - rubric_mtime ))
        if [[ "$rubric_age" -lt 86400 ]]; then
            return  # Fresh enough
        fi
    fi

    mkdir -p "$rubric_dir"

    local rubric_prompt
    rubric_prompt="You are one of the best product engineers alive, generating a scoring rubric for a specific feature. This rubric will calibrate another engineer. Make it specific to THIS code.

Feature: \"${feat_name}\"
Claim: \"${delivers}\"
Target user: \"${for_whom}\"

Code sample (first 5000 chars):
$(echo "$code_context" | head -c 5000)

Generate a rubric with 4 axes. For EACH axis:
1. What would genuinely impress you (80+) for THIS feature
2. What would disappoint you (40) for THIS code
3. 2-3 concrete things to check (file patterns, function names, code paths)

Axes:
- VALUE: Does this feature deliver real value? Complete implementation vs half-built skeleton?
- QUALITY: Would you trust this code at 3am? What breaks? Where did someone think vs just compile?
- UX: What does using this feel like? Does it feel like the builder uses their own product?
- TASTE: Does this code have taste? Complexity appropriate? Abstractions earned? Or generated slop?

Output ONLY a JSON object:
{\"spec_alignment\":{\"check_80\":\"...\",\"check_40\":\"...\",\"specifics\":[\"...\"]},\"integrity\":{\"check_80\":\"...\",\"check_40\":\"...\",\"specifics\":[\"...\"]},\"ux\":{\"check_80\":\"...\",\"check_40\":\"...\",\"specifics\":[\"...\"]},\"anti_slop\":{\"check_80\":\"...\",\"check_40\":\"...\",\"specifics\":[\"...\"]}}"

    local api_key="${ANTHROPIC_API_KEY:-}"
    local rubric_result=""

    if [[ -z "$api_key" ]]; then
        local tmp_file
        tmp_file=$(mktemp)
        echo "$rubric_prompt" > "$tmp_file"
        rubric_result=$(_timeout "${EVAL_TIMEOUT:-120}" claude -p "$(cat "$tmp_file")" --model haiku --output-format text --append-system-prompt "Output only valid JSON." 2>/dev/null </dev/null) || {
            # Retry without --output-format if flag not supported
            rubric_result=$(_timeout "${EVAL_TIMEOUT:-120}" claude -p "$(cat "$tmp_file")" --model haiku --append-system-prompt "Output only valid JSON." 2>/dev/null </dev/null) || rubric_result=""
        }
        rm -f "$tmp_file"
    else
        local payload
        payload=$(jq -n \
            --arg prompt "$rubric_prompt" \
            '{model:"claude-haiku-4-5-20251001",max_tokens:1500,temperature:0,messages:[{role:"user",content:$prompt}]}')
        local response
        response=$(curl -s "https://api.anthropic.com/v1/messages" \
            -H "x-api-key: $api_key" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "$payload" 2>/dev/null)
        rubric_result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
    fi

    # Parse and cache the rubric
    if [[ -n "$rubric_result" ]]; then
        local cleaned
        cleaned=$(echo "$rubric_result" | sed -E '/^[[:space:]]*`{3,}[a-zA-Z]*[[:space:]]*$/d' | sed -e '/^[[:space:]]*$/d')
        # Extract JSON — try jq first, then python3, then perl
        local rubric_json=""
        if echo "$cleaned" | jq -c . &>/dev/null 2>&1; then
            rubric_json=$(echo "$cleaned" | jq -c .)
        else
            rubric_json=$(echo "$cleaned" | python3 -c '
import sys, json
text = sys.stdin.read()
depth = 0; start = -1
for i, c in enumerate(text):
    if c == "{":
        if depth == 0: start = i
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0 and start >= 0:
            try:
                obj = json.loads(text[start:i+1])
                if isinstance(obj, dict):
                    print(json.dumps(obj, separators=(",",":")))
                    sys.exit(0)
            except: pass
            start = -1
' 2>/dev/null)
            [[ -z "$rubric_json" ]] && rubric_json=$(echo "$cleaned" | perl -0777 -ne 'if (/(\{(?:[^{}]|(?:\{(?:[^{}]|\{[^{}]*\})*\}))*\})/s) { print $1 }' 2>/dev/null)
        fi
        if [[ -n "$rubric_json" ]] && echo "$rubric_json" | jq -c . &>/dev/null 2>&1; then
            echo "$rubric_json" | jq -c . > "$rubric_file" 2>/dev/null || true
        fi
    fi
}

# Code quality audit — evaluates delivery and craft for a feature
# Returns JSON: {"delivery_score":N,"craft_score":N,"score":N,"verdict":"...","gaps":[...],"strengths":[...],"evidence":"..."}
# NOTE: viability is scored separately by /score via agent-backed research
run_logic_research() {
    local feat_name="$1"
    local delivers="$2"
    local for_whom="$3"
    local code_context="$4"

    # Check for per-feature rubric
    local rubric_file=".claude/cache/rubrics/${feat_name}.json"
    local rubric_section=""
    if [[ -f "$rubric_file" ]]; then
        local rubric_age rubric_mtime now_ts
        now_ts=$(date +%s)
        rubric_mtime=$(file_mtime "$rubric_file")
        rubric_mtime="${rubric_mtime:-0}"
        rubric_age=$(( now_ts - rubric_mtime ))
        if [[ "$rubric_age" -lt 86400 ]]; then
            local rubric_content
            rubric_content=$(cat "$rubric_file" 2>/dev/null)
            if [[ -n "$rubric_content" ]]; then
                rubric_section="
FEATURE-SPECIFIC RUBRIC (generated from code inspection — use this instead of generic anchors):
${rubric_content}
"
            fi
        fi
    fi

    local prompt
    prompt="You are one of the best product engineers alive. You have built features at companies people actually use — not enterprise middleware, real products that users love. You have shipped code that handles 10M requests, and you have shipped MVPs in a weekend that got their first 1000 users. You know what good looks like at every stage.

You grade the way you would assess a feature if you were deciding whether to join this startup or invest in it. Not by counting files or checking boxes — by reading the code and forming a judgment: is this good? Is this the work of someone who knows what they are doing? Would users love this?

You are tough but fair. You respect scrappy code that delivers real value over polished code that does not. You respect simplicity. You hate over-engineering, you hate code that claims to do things it does not, and you hate silent failures. You have seen enough code to know the difference between code that works and code that is good.

Feature: \"${feat_name}\"
Claim: \"${delivers}\"
Target user: \"${for_whom}\"

Code:
${code_context}

WHAT THE SCORES MEAN:
- 90-100: Genuinely excellent. You would show this to other engineers as an example. Rare.
- 70-89: Solid. Ships and works. A good engineer built this. Rough edges but nothing embarrassing.
- 50-69: It works but you would not be proud of it. Ships because it has to.
- 30-49: Half-built. Skeleton is there but does not really deliver.
- 0-29: Does not exist or fundamentally broken.

GRADE THESE TWO DIMENSIONS:

1. DELIVERY (delivery_score, 0-100)
   Does this feature deliver real value to the target user? Not does-a-file-exist — does the LOGIC work end-to-end?
   - Would the target user get something they actually care about? Would they come back?
   - Is this a complete feature or a half-finished skeleton with TODOs?
   - Does it solve the problem better than doing nothing? Better than the obvious alternative?
   - How does this compare to the best implementations you have seen of similar features?
   - Cite file:line for what works and what is missing.

2. CRAFT (craft_score, 0-100)
   Is this well-made? Judge both the code quality AND the experience quality:
   - Code: error handling, robustness, architecture fit, readability — does it read like someone who cares?
   - Experience: when it works, is the output clear and useful? When it fails, do you know why?
   - Robustness: first run, empty state, bad input, missing dependencies — does it handle reality?
   - Taste: does this feel like craft or like it was generated? Would you be proud to show it?
   - Cite file:line for the best and worst parts.

NOTE: Viability (market fit, competitive position) is scored separately by /score using agent-backed research. Do NOT score viability here.
${rubric_section}
PROCEDURE:
1. Read all the code. Form an overall impression first — good, bad, somewhere in between.
2. Score each dimension based on your judgment. Trust your instincts — you have seen enough code.
3. For each score, cite 1-2 specific file:line examples that drove your judgment up or down.
4. List the specific gaps (problems) and strengths.
5. DO NOT compute a weighted total — the caller does that.

INTEGRITY:
- You MUST find real problems. If you found zero, you did not look hard enough.
- Every gap must cite file:line. Vague praise or criticism = lazy review.
- Be honest about what stage this code is at. A weekend MVP scoring 85 is suspicious.
- You are grading against the best you have seen, not against average. 70 is genuinely good.

Output ONLY this JSON object — no markdown fences, no text before or after:
{\"delivery_score\":55,\"craft_score\":50,\"gaps\":[\"specific problem with file:line evidence\"],\"strengths\":[\"what genuinely works well\"],\"evidence\":\"1-2 sentence overall judgment\"}"

    local api_key="${ANTHROPIC_API_KEY:-}"
    local result=""
    local _parse_diag=""  # diagnostic info for stderr on parse failure

    if [[ -z "$api_key" ]]; then
        # Try claude CLI — use --output-format text for clean output
        local tmp_file
        tmp_file=$(mktemp)
        echo "$prompt" > "$tmp_file"
        # Capture both stdout and stderr to diagnose failures
        local cli_stderr
        cli_stderr=$(mktemp)
        local _eval_timeout="${EVAL_TIMEOUT:-120}"
        result=$(_timeout "${_eval_timeout}" claude -p "$(cat "$tmp_file")" --model haiku --output-format text --append-system-prompt "Be deterministic. Output only valid JSON. No markdown fences." 2>"$cli_stderr" </dev/null) || {
            local _exit_code=$?
            if [[ "$_exit_code" -eq 124 ]]; then
                _parse_diag="claude CLI timed out after ${_eval_timeout}s"
            else
                _parse_diag="claude CLI exit code $_exit_code; stderr: $(head -5 "$cli_stderr" 2>/dev/null)"
            fi
            result=""
        }
        # If --output-format text is not supported, retry without it
        if [[ -z "$result" && -s "$cli_stderr" ]] && grep -qi 'output-format\|unknown.*flag\|unrecognized' "$cli_stderr" 2>/dev/null; then
            result=$(_timeout "${_eval_timeout}" claude -p "$(cat "$tmp_file")" --model haiku --append-system-prompt "Be deterministic. Output only valid JSON. No markdown fences." 2>/dev/null </dev/null) || result=""
            _parse_diag=""
        fi
        rm -f "$tmp_file" "$cli_stderr"
    else
        # Direct API call with temperature 0 for deterministic output
        # Try structured output via tool_use first (guaranteed valid JSON)
        local use_structured=true
        local payload response
        if [[ "$use_structured" == true ]]; then
            payload=$(jq -n \
                --arg prompt "$prompt" \
                '{
                    model:"claude-haiku-4-5-20251001",
                    max_tokens:4096,
                    temperature:0,
                    tool_choice:{type:"tool",name:"audit_result"},
                    tools:[{
                        name:"audit_result",
                        description:"Top 0.01% product engineer code review — subjective judgment grounded in deep experience",
                        input_schema:{
                            type:"object",
                            properties:{
                                delivery_score:{type:"integer",description:"Delivery 0-100: does this feature deliver real value to the target user?"},
                                craft_score:{type:"integer",description:"Craft 0-100: is this well-made — both code quality and experience quality?"},
                                gaps:{type:"array",items:{type:"string"},description:"Specific problems with file:line citations"},
                                strengths:{type:"array",items:{type:"string"},description:"What genuinely works well"},
                                evidence:{type:"string",description:"1-2 sentence overall judgment"}
                            },
                            required:["delivery_score","craft_score","gaps","strengths","evidence"]
                        }
                    }],
                    messages:[{role:"user",content:$prompt}]
                }')
            response=$(_timeout "${EVAL_TIMEOUT:-120}" curl -s --max-time "${EVAL_TIMEOUT:-120}" "https://api.anthropic.com/v1/messages" \
                -H "x-api-key: $api_key" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d "$payload" 2>/dev/null)

            # Check for API errors first
            local api_error
            api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            if [[ -n "$api_error" ]]; then
                _parse_diag="API error: $api_error"
                result=""
            else
                # Check stop_reason — max_tokens means truncated response
                local stop_reason
                stop_reason=$(echo "$response" | jq -r '.stop_reason // empty' 2>/dev/null)

                # Extract tool_use input (structured JSON)
                result=$(echo "$response" | jq -c '.content[] | select(.type=="tool_use") | .input // empty' 2>/dev/null)
                if [[ -n "$result" && "$result" != "null" && "$result" != "" ]]; then
                    # Structured output — already valid JSON
                    :
                elif [[ "$stop_reason" == "max_tokens" ]]; then
                    # Response was truncated — try to extract partial text content
                    _parse_diag="API response truncated (stop_reason: max_tokens)"
                    result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
                else
                    # Structured output failed — fall back to plain text
                    result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
                    [[ -z "$result" ]] && _parse_diag="API response had no tool_use or text content"
                fi
            fi
        else
            payload=$(jq -n \
                --arg prompt "$prompt" \
                '{model:"claude-haiku-4-5-20251001",max_tokens:2048,temperature:0,messages:[{role:"user",content:$prompt}]}')
            response=$(_timeout "${EVAL_TIMEOUT:-120}" curl -s --max-time "${EVAL_TIMEOUT:-120}" "https://api.anthropic.com/v1/messages" \
                -H "x-api-key: $api_key" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d "$payload" 2>/dev/null)
            # Check for API errors
            local api_error
            api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            if [[ -n "$api_error" ]]; then
                _parse_diag="API error: $api_error"
                result=""
            else
                result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
            fi
        fi
    fi

    # Parse the JSON response — robust extraction handles common LLM output formats
    if [[ -n "$result" ]]; then
        # Strip markdown fences: ```json, ```, and variations
        # Handles: leading whitespace, trailing whitespace, language tags, ````-style fences
        local cleaned
        cleaned=$(echo "$result" | sed -E '/^[[:space:]]*`{3,}[a-zA-Z]*[[:space:]]*$/d')
        # Also strip leading/trailing whitespace lines
        cleaned=$(echo "$cleaned" | sed -e '/^[[:space:]]*$/d')

        # Try 1: full response is valid JSON
        if echo "$cleaned" | jq -c . &>/dev/null 2>&1; then
            local parsed
            parsed=$(echo "$cleaned" | jq -c .)
            _validate_and_emit "$parsed"
            return
        fi

        # Try 2: extract from first { to last } on their own lines
        local json_part
        json_part=$(echo "$cleaned" | sed -n '/^[[:space:]]*{/,/^[[:space:]]*}/p')
        if [[ -n "$json_part" ]] && echo "$json_part" | jq -c . &>/dev/null 2>&1; then
            _validate_and_emit "$(echo "$json_part" | jq -c .)"
            return
        fi

        # Try 3: extract from first { to last } anywhere (not just line-start)
        json_part=$(echo "$cleaned" | sed -n '/[[:space:]]*{/,/}[[:space:]]*$/p')
        if [[ -n "$json_part" ]] && echo "$json_part" | jq -c . &>/dev/null 2>&1; then
            _validate_and_emit "$(echo "$json_part" | jq -c .)"
            return
        fi

        # Try 4: use python3 to extract first valid JSON object (most robust)
        json_part=$(echo "$cleaned" | python3 -c '
import sys, json, re
text = sys.stdin.read()
# Find all potential JSON objects by matching { to }
depth = 0
start = -1
for i, c in enumerate(text):
    if c == "{":
        if depth == 0:
            start = i
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0 and start >= 0:
            candidate = text[start:i+1]
            try:
                obj = json.loads(candidate)
                if isinstance(obj, dict) and ("delivery_score" in obj or "score" in obj):
                    print(json.dumps(obj, separators=(",",":")))
                    sys.exit(0)
            except json.JSONDecodeError:
                pass
            start = -1
# If no object with scores found, try any valid JSON object
depth = 0
start = -1
for i, c in enumerate(text):
    if c == "{":
        if depth == 0:
            start = i
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0 and start >= 0:
            candidate = text[start:i+1]
            try:
                obj = json.loads(candidate)
                if isinstance(obj, dict):
                    print(json.dumps(obj, separators=(",",":")))
                    sys.exit(0)
            except json.JSONDecodeError:
                pass
            start = -1
' 2>/dev/null)
        if [[ -n "$json_part" ]] && echo "$json_part" | jq -c . &>/dev/null 2>&1; then
            _validate_and_emit "$(echo "$json_part" | jq -c .)"
            return
        fi

        # Try 5: use perl to extract first balanced JSON object (handles multi-line, nested braces)
        json_part=$(echo "$cleaned" | perl -0777 -ne 'if (/(\{(?:[^{}]|(?:\{(?:[^{}]|\{[^{}]*\})*\}))*\})/s) { print $1 }' 2>/dev/null)
        if [[ -n "$json_part" ]] && echo "$json_part" | jq -c . &>/dev/null 2>&1; then
            _validate_and_emit "$(echo "$json_part" | jq -c .)"
            return
        fi

        # Try 6: grep any single-line JSON object containing "delivery_score" or "score"
        json_part=$(echo "$cleaned" | grep -o '{[^}]*"delivery_score"[^}]*}' | head -1)
        [[ -z "$json_part" ]] && json_part=$(echo "$cleaned" | grep -o '{[^}]*"score"[^}]*}' | head -1)
        if [[ -n "$json_part" ]] && echo "$json_part" | jq -c . &>/dev/null 2>&1; then
            _validate_and_emit "$(echo "$json_part" | jq -c .)"
            return
        fi

        # Try 7: extract sub-scores or single score from free text and build JSON
        local extracted_value extracted_quality extracted_verdict
        # Match both quoted and unquoted key names, colon with optional spaces
        extracted_value=$(echo "$cleaned" | grep -oE '("|'"'"')?delivery_score("|'"'"')?\s*:\s*[0-9]+' | head -1 | grep -oE '[0-9]+$')
        extracted_quality=$(echo "$cleaned" | grep -oE '("|'"'"')?craft_score("|'"'"')?\s*:\s*[0-9]+' | head -1 | grep -oE '[0-9]+$')
        extracted_verdict=$(echo "$cleaned" | grep -oiE '("|'"'"')?verdict("|'"'"')?\s*:\s*"[A-Z]+"' | head -1 | grep -oE '"[A-Z]+"$' | tr -d '"')
        if [[ -n "$extracted_value" ]]; then
            echo "{\"delivery_score\":${extracted_value},\"craft_score\":${extracted_quality:-${extracted_value}},\"verdict\":\"${extracted_verdict:-PARTIAL}\",\"gaps\":[\"response required free-text extraction — audit may be incomplete\"],\"strengths\":[],\"evidence\":\"parsed from non-JSON response\"}" | _apply_logic_antisycophancy
            return
        fi
        # Legacy fallback: single score
        local extracted_score
        extracted_score=$(echo "$cleaned" | grep -oE '("|'"'"')?score("|'"'"')?\s*:\s*[0-9]+' | head -1 | grep -oE '[0-9]+$')
        if [[ -n "$extracted_score" ]]; then
            echo "{\"delivery_score\":${extracted_score},\"craft_score\":${extracted_score},\"verdict\":\"${extracted_verdict:-PARTIAL}\",\"gaps\":[\"response required free-text extraction — audit may be incomplete\"],\"strengths\":[],\"evidence\":\"parsed from non-JSON response\"}" | _apply_logic_antisycophancy
            return
        fi

        # All parsing attempts failed — log diagnostic
        _parse_diag="${_parse_diag:+$_parse_diag; }response length: ${#result}; first 200 chars: $(echo "$result" | head -c 200)"
    fi

    # Fallback: couldn't parse at all — log diagnostic to stderr
    if [[ -n "$_parse_diag" ]]; then
        echo "[eval] ${feat_name:-unknown}: LLM response unparseable — ${_parse_diag}" >&2
    else
        echo "[eval] ${feat_name:-unknown}: LLM returned empty response (no API key? CLI unavailable?)" >&2
    fi
    echo '{"delivery_score":30,"craft_score":30,"score":30,"verdict":"PARTIAL","gaps":["could not evaluate — LLM response unparseable"],"evidence":"eval failed"}'
}

# Validate parsed JSON has expected score fields, then emit through antisycophancy filter
# Usage: _validate_and_emit '{"delivery_score":55,...}'
_validate_and_emit() {
    local json="$1"

    # Ensure delivery_score exists and is a number
    # NOTE: viability_score removed — scored by /score via agents, not eval
    local ds cs
    ds=$(echo "$json" | jq -r '.delivery_score // empty' 2>/dev/null)
    cs=$(echo "$json" | jq -r '.craft_score // empty' 2>/dev/null)

    # If sub-scores are missing but legacy .score exists, derive from it
    if [[ -z "$ds" || ! "$ds" =~ ^[0-9]+$ ]]; then
        local legacy
        legacy=$(echo "$json" | jq -r '.score // empty' 2>/dev/null)
        if [[ -n "$legacy" && "$legacy" =~ ^[0-9]+$ ]]; then
            # Convert 1-5 scale to 0-100 if needed
            [[ "$legacy" -le 5 ]] && legacy=$((legacy * 20))
            local safe_cs="${cs}"
            [[ -z "$safe_cs" || ! "$safe_cs" =~ ^[0-9]+$ ]] && safe_cs="$legacy"
            json=$(echo "$json" | jq -c --argjson d "$legacy" --argjson c "$safe_cs" \
                '.delivery_score = $d | .craft_score = $c | del(.viability_score)' 2>/dev/null) || true
        fi
    fi

    # Strip viability_score if LLM still returned it (backward compat)
    json=$(echo "$json" | jq -c 'del(.viability_score)' 2>/dev/null) || true

    # Clamp scores to 0-100 range (LLMs occasionally return negatives or >100)
    json=$(echo "$json" | jq -c '
        def clamp: if . < 0 then 0 elif . > 100 then 100 else . end;
        if .delivery_score then .delivery_score = (.delivery_score | clamp) else . end |
        if .craft_score then .craft_score = (.craft_score | clamp) else . end
    ' 2>/dev/null) || true

    # Ensure gaps is an array (LLMs sometimes return a string)
    json=$(echo "$json" | jq -c '
        if (.gaps | type) == "string" then .gaps = [.gaps]
        elif (.gaps | type) != "array" then .gaps = []
        else . end
    ' 2>/dev/null) || true

    echo "$json" | _apply_logic_antisycophancy
}

# Anti-sycophancy filter for audit results (0-100 scale)
# Reads JSON from stdin, applies integrity checks on sub-scores,
# computes weighted total, outputs corrected JSON with .score field
_apply_logic_antisycophancy() {
    local input
    input=$(cat)

    # Extract sub-scores (fall back to legacy .score if sub-scores missing)
    # NOTE: viability is no longer scored by eval — it's scored by /score via agents
    local delivery_score craft_score
    delivery_score=$(echo "$input" | jq -r '.delivery_score // empty' 2>/dev/null)
    craft_score=$(echo "$input" | jq -r '.craft_score // empty' 2>/dev/null)

    # Legacy fallback: if no sub-scores, derive from single .score
    if [[ -z "$delivery_score" || -z "$craft_score" ]]; then
        local legacy_score
        legacy_score=$(echo "$input" | jq -r '.score // 50' 2>/dev/null)
        [[ "$legacy_score" -le 5 ]] && legacy_score=$((legacy_score * 20))
        delivery_score="${delivery_score:-$legacy_score}"
        craft_score="${craft_score:-$legacy_score}"
        input=$(echo "$input" | jq -c --argjson v "$delivery_score" --argjson q "$craft_score" \
            '.delivery_score = $v | .craft_score = $q')
    fi

    # Normalize: if any score came back on 1-5 scale, convert to 0-100
    [[ "$delivery_score" -le 5 ]] && delivery_score=$((delivery_score * 20))
    [[ "$craft_score" -le 5 ]] && craft_score=$((craft_score * 20))

    local gap_count
    gap_count=$(echo "$input" | jq -r '.gaps | length // 0' 2>/dev/null)

    # 0 gaps found → auditor didn't look hard enough. Cap all at 60.
    if [[ "$gap_count" -eq 0 ]]; then
        [[ "$delivery_score" -gt 60 ]] && delivery_score=60
        [[ "$craft_score" -gt 60 ]] && craft_score=60
        input=$(echo "$input" | jq -c '.gaps += ["integrity: 0 problems found — audit was not thorough enough"]')
    fi

    # Any sub-score > 80 with gaps → cap that sub-score at 75
    if [[ "$gap_count" -gt 0 ]]; then
        [[ "$delivery_score" -gt 80 ]] && delivery_score=75
        [[ "$craft_score" -gt 80 ]] && craft_score=75
    fi

    # Any sub-score > 70 with 3+ gaps → cap at 65
    if [[ "$gap_count" -ge 3 ]]; then
        [[ "$delivery_score" -gt 70 ]] && delivery_score=65
        [[ "$craft_score" -gt 70 ]] && craft_score=65
    fi

    # Stage cap: read project stage from founder.yml
    local stage_cap=100
    if [[ -f "config/founder.yml" ]]; then
        local stage
        stage=$(grep 'stage:' config/founder.yml 2>/dev/null | head -1 | sed 's/.*stage: *//')
        case "$stage" in
            mvp)    stage_cap=65 ;;
            early)  stage_cap=75 ;;
            growth) stage_cap=85 ;;
            mature) stage_cap=95 ;;
        esac
    fi
    [[ "$delivery_score" -gt "$stage_cap" ]] && delivery_score="$stage_cap"
    [[ "$craft_score" -gt "$stage_cap" ]] && craft_score="$stage_cap"

    # Compute weighted total in bash (not LLM): delivery*0.6 + craft*0.4
    local score=$(( delivery_score * 60 / 100 + craft_score * 40 / 100 ))

    # Stage cap on total too
    [[ "$score" -gt "$stage_cap" ]] && score="$stage_cap"

    if [[ "$gap_count" -gt 0 && "$score" -gt 80 ]]; then
        input=$(echo "$input" | jq -c '.gaps += ["integrity: score capped — gaps exist"]')
        score=75
    fi

    # Write scores back (strip viability_score if LLM still returned it)
    input=$(echo "$input" | jq -c --argjson v "$delivery_score" --argjson q "$craft_score" --argjson s "$score" \
        '.delivery_score = $v | .craft_score = $q | .score = $s | del(.viability_score)')

    echo "$input"
}
